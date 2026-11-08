--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.ArcadeConfig)
local Numeric=require(RS.Shared.Numeric)
local Service={};Service.__index=Service
function Service.new(world,data,state,players,clock,abilities,notify)
 local self=setmetatable({world=world,data=data,state=state,players=players,clock=clock,abilities=abilities,notify=notify,
  runs={},machines={},limits={},links={},serial=0,random=Random.new()},Service)
 self.remote=Instance.new("RemoteEvent");self.remote.Name="VerityArcade";self.remote.Parent=RS
 for plotId,record in world.houseProgression.plots do
  table.insert(self.links,record.homeDecor.arcadePrompt.Triggered:Connect(function(p)self:Start(p,plotId)end))
 end
 table.insert(self.links,self.remote.OnServerEvent:Connect(function(p,action,round,direction,...)
  if select("#",...)~=0 or not Numeric.isInteger(round,0,1e12) then return end
  if action~="Move" and action~="Sync" and action~="Leave" then return end
  if action=="Move" then if direction~=-1 and direction~=1 then return end elseif direction~=nil then return end
  local r=self.runs[p]
  if action=="Leave" then if r and r.round==round then self:Finish(p,false) end;return end
  local now=clock();if now<(self.limits[p] or 0) then return end;self.limits[p]=now+.08
  if action=="Sync" then if r then self:Publish(p,r) end;return end
  if not r or r.round~=round or not self:Character(p,r) then return end
  self:Advance(p,r,now);if self.runs[p]~=r or now-r.moved<C.MoveCooldown then return end
  r.moved=now;r.lane=math.clamp(r.lane+direction,1,3);self:Publish(p,r)
 end))
 return self
end
function Service:Character(p,r)
 local profile=self.data:Get(p.UserId);local char=p.Character
 local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 if p.Parent~=self.players or not profile or profile.Closing or not self.state.sessions[p.UserId]
  or not profile.Data.VerityUnlocked or not root or not hum or hum.Health<=0 or root.Anchored or hum.SeatPart
  or not Numeric.isFinite(root.Position.Magnitude) then return nil end
 if r and (r.character~=char or p:GetAttribute("VerityDiversionKind")~="Arcade") then return nil end
 return root,profile,char
end
function Service:Machine(p,plotId,root)
 local record=self.world.houseProgression.plots[plotId]
 if not record or not record.state or not record.state.VerityUnlocked or not record.state.HomeStyle.owned.home_arcade or record.state.HouseIncomeLevel<2 then return nil end
 if record.state.HouseDoorLocked and record.state.ownerUserId~=p.UserId and record.insideGuests[p.UserId]~=p.Character then return nil end
 local point=record.pivot:PointToObjectSpace(root.Position)
 if math.abs(point.X)>=24 or point.Z> -14 or point.Z< -54 or point.Y<0 or point.Y>15 then return nil end
 local prompt=record.homeDecor.arcadePrompt
 if (root.Position-prompt.Parent.Position).Magnitude>C.Reach then return nil end
 return record
end
function Service:Start(p,plotId)
 if self.runs[p] then return end
 local root,profile,char=self:Character(p);if not root then return end
 for _,name in {"VerityDiversionKind","VerityFusionSlot","VerityRaceSlot","VerityParkourStep","VerityBattleActive","VerityRiding"} do
  if p:GetAttribute(name) and not (name=="VerityDiversionKind" and self.adventures and self.adventures:CanUsePartyArcade(p,plotId)) then return end
 end
 if self.adventures and self.adventures:ArcadeReserved(plotId) and not self.adventures:CanUsePartyArcade(p,plotId) then self.notify(p.UserId,"PARTY_ARCADE_RESERVED");return end
 local record=self:Machine(p,plotId,root);if not record then return end
 if self.machines[plotId] then self.notify(p.UserId,"ARCADE_BUSY");return end
 self.abilities:Stop(p)
 local now=self.clock();self.serial+=1;local seed=self.random:NextInteger(1,2147483646)
 local r={round=self.serial,character=char,plot=plotId,started=now,deadline=now+C.Duration,seed=seed,plan=C.Plan(seed),
  index=1,lane=2,lives=3,score=0,combo=0,moved=now-1,feedback=0,lastPublish=now}
 self.runs[p]=r;self.machines[plotId]=p;record.homeDecor.arcadePrompt:SetAttribute("MachineUserId",p.UserId)
 p:SetAttribute("VerityDiversionKind","Arcade");self.state:Publish(p.UserId,true);self:Publish(p,r)
end
function Service:Publish(p,r,phase,newBest)
 local profile=self.data:Get(p.UserId)
 self.remote:FireClient(p,{version=C.Version,round=r.round,phase=phase or "Playing",started=r.started,deadline=r.deadline,
  seed=r.seed,lane=r.lane,lives=r.lives,score=r.score,combo=r.combo,index=r.index,feedback=r.feedback,
  judgement=r.judgement,prizes=r.prizes or {},best=profile and profile.Data.ArcadeBestScore or 0,newBest=newBest==true})
 r.lastPublish=self.clock()
end
function Service:Finish(p,award)
 local r=self.runs[p];if not r then return end
 self.runs[p]=nil;self.machines[r.plot]=nil
 local record=self.world.houseProgression.plots[r.plot]
 if record then record.homeDecor.arcadePrompt:SetAttribute("MachineUserId",nil) end
 if p:GetAttribute("VerityDiversionKind")=="Arcade" then p:SetAttribute("VerityDiversionKind",nil) end
 local profile=self.data:Get(p.UserId);local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
 local newBest=false
 if award and profile and not profile.Closing and self.state.sessions[p.UserId] and p.Character==r.character and hum and hum.Health>0 then
  newBest=r.score>profile.Data.ArcadeBestScore
  profile.Data.ArcadeBestScore=math.max(profile.Data.ArcadeBestScore,r.score)
  r.prizes={}
  for _,prize in C.Prizes do
   if r.score>=prize.Score and not profile.Data.CosmeticsOwned[prize.Id] then
    profile.Data.CosmeticsOwned[prize.Id]=true;table.insert(r.prizes,prize.Name)
   end
  end
  self.data:Touch(profile)
 end
 if self.adventures then self.adventures:ArcadeFinished(p,r,award) end
 self.state:Publish(p.UserId,true) -- existing Abilities.Refresh restores movement after removing the activity flag
 if p.Parent==self.players then self:Publish(p,r,if award then "Finished" else "Left",newBest) end
end
function Service:Advance(p,r,now)
 local changed=false
 while r.plan[r.index] and now>=r.started+r.plan[r.index].at do
  local drop=r.plan[r.index];r.index+=1;r.feedback+=1;changed=true
  if drop.star then
   if r.lane==drop.lane then r.combo+=1;r.score+=10+math.min(15,r.combo)*2;r.judgement="STAR"
   else r.combo=0;r.judgement="MISS" end
  elseif r.lane==drop.lane then r.lives-=1;r.combo=0;r.score=math.max(0,r.score-10);r.judgement="HIT"
  else r.judgement="DODGE" end
  if r.lives<=0 then self:Finish(p,true);return end
 end
 if now>=r.deadline then self:Finish(p,true);return end
 if changed or now-r.lastPublish>=.5 then self:Publish(p,r) end
end
function Service:Tick()
 local now=self.clock()
 for p,r in self.runs do
  local root=self:Character(p,r)
  if not root or not self:Machine(p,r.plot,root) then self:Finish(p,false)
  else self:Advance(p,r,now) end
 end
end
function Service:Remove(p) self:Finish(p,false);self.limits[p]=nil end
function Service:Destroy()
 for p in self.runs do self:Finish(p,false) end
 for _,link in self.links do link:Disconnect() end
 self.remote:Destroy()
end
return Service
