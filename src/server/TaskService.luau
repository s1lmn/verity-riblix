--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.TaskConfig)
local Rewards = require(Shared.ActivityRewards)
local TaskService = {}
TaskService.__index = TaskService
function TaskService.new(data, state, economy, clock, isNear, canAct)
 return setmetatable({data=data,state=state,economy=economy,clock=clock,isNear=isNear,canAct=canAct},TaskService)
end
function TaskService:_state(userId, taskId)
 local profile,session=self.data:Get(userId),self.state.sessions[userId]
 local definition=Config[taskId]
 if not profile or not session or not definition then return nil,nil end
 if not session.Tasks[taskId] then
  session.Tasks[taskId]={Active=false,Step=1,CooldownUntil=profile.Data[definition.CooldownField][taskId] or 0}
 end
 return session.Tasks[taskId],profile
end
function TaskService:Start(userId,taskId)
 local progress,profile=self:_state(userId,taskId)
 if not progress then return "NOT_READY" end
 if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
 if self.canAct and not self.canAct(userId) then return "TASK_OTHER_ACTIVITY" end
 if self.clock()<progress.CooldownUntil then return "COOLDOWN" end
 if progress.Active then return "OK" end -- idempotent path selection; keep stage progress
 -- One guided job at a time. Completed stages survive free switching during this visit.
 for _,previous in self.state.sessions[userId].Tasks do
  previous.Active=false;previous.HoldStartedAt=nil
 end
 if (progress.Step or 1)>#Config[taskId].Steps then progress.Step=1 end
 progress.Active,progress.Step,progress.StepAt=true,progress.Step or 1,self.clock()
 progress.HoldStartedAt=nil
 self.data:Touch(profile)
 return "OK"
end
function TaskService:_reward(userId,taskId,progress,profile)
 local definition=Config[taskId]
 local ok,actual=self.economy:AddCash(userId,Rewards.Task(profile.Data.VerityLevel,taskId,definition.Reward)*self.economy:GetMultiplier(profile))
 if not ok then progress.HoldStartedAt=nil;return "NOT_READY",0 end
 -- AddCash and this transition never yield; duplicate interactions cannot grant twice.
 progress.Active,progress.HoldStartedAt=false,nil
 progress.Step=#definition.Steps+1;progress.CompletedThisVisit=true
 progress.CooldownUntil=self.clock()+definition.Cooldown
 profile.Data[definition.CooldownField][taskId]=progress.CooldownUntil
 self.state:CompleteActivity(profile,taskId);self.data:Touch(profile)
 if self.onReward then self.onReward(userId,actual,taskId) end
 return "OK",actual
end
function TaskService:Complete(userId,taskId,trustedStep)
 local progress,profile=self:_state(userId,taskId)
 if not progress or not progress.Active then return "NOT_ACTIVE",0 end
 if self.canAct and not self.canAct(userId) then progress.HoldStartedAt=nil;return "TASK_OTHER_ACTIVITY",0 end
 local definition=Config[taskId]
 local stage=definition.Steps[progress.Step]
 if not stage then return "NOT_ACTIVE",0 end
 -- Only a native server prompt can complete a Prompt stage, never TaskComplete remote.
 if stage.Mode=="Prompt" and trustedStep~=progress.Step then return "INTERACTION_REQUIRED",0 end
 local near,alive=self.isNear(userId,taskId,progress.Step)
 if not near or not alive then progress.HoldStartedAt=nil;return "TOO_FAR",0 end
 if self.clock()-(progress.StepAt or self.clock())<.45 then return "HOLD_REQUIRED",0 end
 if stage.Mode=="Hold" and (not progress.HoldStartedAt or self.clock()-progress.HoldStartedAt<stage.HoldSeconds) then return "HOLD_REQUIRED",0 end
 if progress.Step==#definition.Steps then return self:_reward(userId,taskId,progress,profile) end
 progress.Step+=1;progress.StepAt=self.clock();progress.HoldStartedAt=nil
 if self.onStage then self.onStage(userId,taskId,stage.Prop) end
 self.data:Touch(profile)
 self.state:Publish(userId,true)
 return "OK",0
end
function TaskService:Interact(userId,taskId,index)
 local progress=self:_state(userId,taskId)
 if not progress then return end
 if not progress.Active then
  local expected=if progress.Step>#Config[taskId].Steps then 1 else progress.Step
  if index~=expected or self:Start(userId,taskId)~="OK" then return end
  -- The native hold accepts/resumes the job and completes this interaction.
  progress.StepAt=self.clock()-.5
  self:Complete(userId,taskId,index)
  self.state:Publish(userId,true)
  return
 end
 if progress.Step~=index then return end
 self:Complete(userId,taskId,index)
 self.state:Publish(userId,true)
end
function TaskService:Tick()
 local now=self.clock()
 for userId,session in self.state.sessions do
  for id,progress in session.Tasks do
   if not progress.Active then
    if progress.Step>#Config[id].Steps and now>=progress.CooldownUntil then
     progress.Step=1
     local profile=self.data:Get(userId);if profile then self.data:Touch(profile) end
    end
    continue
   end
   local stage=Config[id].Steps[progress.Step]
   if not stage or stage.Mode=="Prompt" then continue end
   local near,alive=self.isNear(userId,id,progress.Step)
   if not near or not alive or (self.canAct and not self.canAct(userId)) then
    if progress.HoldStartedAt then
     progress.HoldStartedAt=nil
     local profile=self.data:Get(userId);if profile then self.data:Touch(profile) end
    end
   elseif stage.Mode=="Reach" then self:Complete(userId,id)
   else
    if not progress.HoldStartedAt then progress.HoldStartedAt=now;local profile=self.data:Get(userId);if profile then self.data:Touch(profile) end end
    if now-progress.HoldStartedAt>=stage.HoldSeconds then self:Complete(userId,id) end
   end
  end
 end
end
function TaskService:OnDeath(userId)
 local session,profile=self.state.sessions[userId],self.data:Get(userId)
 if not session then return end
 session.PhoneOpen=false
 for _,progress in session.Tasks do progress.Active=false;progress.Step=1;progress.HoldStartedAt=nil end
 if profile then self.data:Touch(profile) end
end
return TaskService
