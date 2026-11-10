--!nonstrict
-- Same authoritative interactions, now driven by a saved optional story cursor.
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.TaskConfig)
local Story=require(Shared.StoryConfig)
local Rewards=require(Shared.ActivityRewards)
local Service={};Service.__index=Service
function Service.new(data,state,economy,clock,isNear,canAct)
 return setmetatable({data=data,state=state,economy=economy,clock=clock,isNear=isNear,canAct=canAct},Service)
end
function Service:Ensure(userId)
 local profile,session=self.data:Get(userId),self.state.sessions[userId]
 if not profile or not session then return nil end
 local data=profile.Data;local chapter=Story.Chapters[data.StoryChapter]
 local available=data.VerityUnlocked and data.TutorialCompleted
 local changed=false
 for id,definition in Config do
  local previous=session.Tasks[id]
  if not previous then previous={Active=false,Step=1,CooldownUntil=0};session.Tasks[id]=previous end
  local current=chapter and chapter.TaskId==id
  local active=current and available and not data.StoryPaused or false
  local step=if current then data.StoryStep else 1
  if previous.Active~=active or previous.Step~=step then
   previous.Active=active;previous.Step=step;previous.StepAt=self.clock();previous.HoldStartedAt=nil;changed=true
  end
 end
 return profile,session,chapter,changed
end
function Service:_state(userId,id)
 local profile,session,chapter=self:Ensure(userId)
 if not profile or not chapter or chapter.TaskId~=id then return nil end
 return session.Tasks[id],profile,chapter
end
function Service:SetGuide(userId,enabled)
 local profile=self.data:Get(userId)
 if not profile or not self.state.sessions[userId] then return "NOT_READY" end
 if not profile.Data.VerityUnlocked or not profile.Data.TutorialCompleted then return "STORY_NOT_READY" end
 if not Story.Chapters[profile.Data.StoryChapter] then return "STORY_FINISHED" end
 if profile.Data.StoryPaused==enabled then
  profile.Data.StoryPaused=not enabled;self.data:Touch(profile)
 end
 self:Ensure(userId)
 return "OK"
end
-- Compatibility for the old endpoint. It can only resume the current chapter.
function Service:Start(userId,id)
 local progress=self:_state(userId,id)
 if not progress then return "STORY_ORDER_REQUIRED" end
 return self:SetGuide(userId,true)
end
function Service:_reward(userId,id,progress,profile,chapter)
 local data=profile.Data
 if data.StoryChapter~=chapter.Index then return "NOT_ACTIVE",0 end
 local quote=Rewards.Task(data.VerityLevel,id,Config[id].Reward)*self.economy:GetMultiplier(profile)
 local ok,cash=self.economy:AddCash(userId,quote)
 if not ok then return "NOT_READY",0 end
 -- Cash, item and chapter cursor share one profile transaction with no yield.
 if chapter.Item then data.CosmeticsOwned[chapter.Item]=true end
 data.StoryChapter+=1;data.StoryStep=1
 progress.Active=false;progress.HoldStartedAt=nil
 self.state:CompleteActivity(profile,id);self.data:Touch(profile)
 self:Ensure(userId)
 self.state:Publish(userId,true)
 if self.onReward then self.onReward(userId,cash,id,chapter.Item) end
 -- Save this same profile, never grant again in a separate asynchronous callback.
 task.defer(function()
  if self.data:Get(userId)==profile and profile.Dirty and not profile.Saving then self.data:SaveAsync(userId,false) end
 end)
 return "OK",cash
end
function Service:Complete(userId,id,trustedStep)
 local progress,profile,chapter=self:_state(userId,id)
 if not progress or not progress.Active then return "NOT_ACTIVE",0 end
 if self.canAct and not self.canAct(userId) then progress.HoldStartedAt=nil;return "TASK_OTHER_ACTIVITY",0 end
 local definition=Config[id];local stage=definition.Steps[progress.Step]
 if not stage or profile.Data.StoryStep~=progress.Step then return "NOT_ACTIVE",0 end
 if stage.Mode=="Prompt" and trustedStep~=progress.Step then return "INTERACTION_REQUIRED",0 end
 local near,alive=self.isNear(userId,id,progress.Step)
 if not near or not alive then progress.HoldStartedAt=nil;return "TOO_FAR",0 end
 if self.clock()-(progress.StepAt or self.clock())<.45 then return "HOLD_REQUIRED",0 end
 if stage.Mode=="Hold" and (not progress.HoldStartedAt or self.clock()-progress.HoldStartedAt<stage.HoldSeconds) then return "HOLD_REQUIRED",0 end
 if progress.Step==#definition.Steps then return self:_reward(userId,id,progress,profile,chapter) end
 profile.Data.StoryStep+=1;self.data:Touch(profile)
 self:Ensure(userId)
 if self.onStage then self.onStage(userId,id,stage.Prop) end
 self.state:Publish(userId,true)
 return "OK",0
end
function Service:Interact(userId,id,index)
 local progress=self:_state(userId,id)
 if not progress or not progress.Active or progress.Step~=index then return end
 self:Complete(userId,id,index);self.state:Publish(userId,true)
end
function Service:Projection(userId)
 local profile,session,chapter=self:Ensure(userId)
 if not profile then return {},nil end
 local data=profile.Data;local tasks={};local available=data.VerityUnlocked and data.TutorialCompleted
 local multiplier=self.economy:GetMultiplier(profile)
 for id,definition in Config do
  local c=Story.ByTask[id];local p=session.Tasks[id]
  local done=c.Index<data.StoryChapter;local current=chapter and chapter.TaskId==id
  local step=if done then #definition.Steps elseif current then data.StoryStep else 1
  tasks[id]={taskId=id,chapter=c.Index,completedThisVisit=done,
   status=if done then "Done" elseif current and available then (if data.StoryPaused then "Paused" else "Active") else "Locked",
   step=step,stepCount=#definition.Steps,cooldownEndsAt=0,reward=Rewards.Task(data.VerityLevel,id,definition.Reward)*multiplier,
   targetPosition=if self.state.TaskPosition then self.state.TaskPosition(id,step) else nil,
   holdStartedAt=p.HoldStartedAt,holdSeconds=definition.Steps[step].HoldSeconds,Active=p.Active,CooldownUntil=0}
 end
 return tasks,{chapter=data.StoryChapter,total=#Story.Chapters,taskId=chapter and chapter.TaskId,
  paused=data.StoryPaused,completed=chapter==nil,available=available,optional=true}
end
function Service:Tick()
 local now=self.clock()
 for userId in self.state.sessions do
  local profile,session,chapter,changed=self:Ensure(userId)
  if not profile then continue end
  if changed then self.state:Publish(userId,true) end
  local progress=chapter and session.Tasks[chapter.TaskId]
  if not progress or not progress.Active then continue end
  local stage=Config[chapter.TaskId].Steps[progress.Step]
  if stage.Mode=="Prompt" then continue end
  local near,alive=self.isNear(userId,chapter.TaskId,progress.Step)
  if not near or not alive or self.canAct and not self.canAct(userId) then
   if progress.HoldStartedAt then progress.HoldStartedAt=nil;self.state:Publish(userId,true) end
  elseif stage.Mode=="Reach" then self:Complete(userId,chapter.TaskId)
  else
   if not progress.HoldStartedAt then progress.HoldStartedAt=now;self.state:Publish(userId,true) end
   if now-progress.HoldStartedAt>=stage.HoldSeconds then self:Complete(userId,chapter.TaskId) end
  end
 end
end
function Service:OnDeath(userId)
 local session=self.state.sessions[userId]
 if not session then return end
 session.PhoneOpen=false
 for _,progress in session.Tasks do progress.HoldStartedAt=nil;progress.StepAt=self.clock() end
 -- Saved chapter/stage survive death; a partial timed hold never does.
end
return Service
