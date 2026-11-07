--!nonstrict
-- Only authoritative position/ordered touches advance a run; no completion remote.
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.ParkourConfig)
local Numeric=require(Shared.Numeric)
local Rewards=require(Shared.ActivityRewards)
local Service={};Service.__index=Service
function Service.new(data,state,economy,clock,notify,resetMovement)
 return setmetatable({data=data,state=state,economy=economy,clock=clock,notify=notify,resetMovement=resetMovement,runs={},ready={},links={},entryHints={},positions={}},Service)
end
function Service:Character(player)
 local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
 return if r and h and h.Health>0 and not r.Anchored and not h.SeatPart then c else nil,r
end
function Service:SetRun(player,run)
 local changed=(self.runs[player]~=nil)~=(run~=nil)
 self.runs[player]=run
 player:SetAttribute("VerityParkourStep",if run then run.index else nil)
 player:SetAttribute("VerityParkourCheckpoint",if run then run.checkpoint else nil)
 player:SetAttribute("VerityParkourStartedAt",if run then run.started else nil)
 player:SetAttribute("VerityParkourFaults",if run then run.faults else nil)
 if changed then self.state:Publish(player.UserId,true) end
end
-- Resolve support from the character root rather than limb touch events.
function Service:FeetOffset(character,root)
 local h=character:FindFirstChildOfClass("Humanoid")
 local leg=character:FindFirstChild("Left Leg")
 return root.Size.Y/2+(if h.RigType==Enum.HumanoidRigType.R6 then (if leg then leg.Size.Y else 2) else h.HipHeight)
end
function Service:GroundedIndex(character, root)
 local position = root.Position
 if not self.supportRay or root.AssemblyLinearVelocity.Y > 12
  or not Numeric.isFinite(position.X) or not Numeric.isFinite(position.Y) or not Numeric.isFinite(position.Z) then return nil end
 local feet = self:FeetOffset(character, root)
 local hit = workspace:Raycast(position, Vector3.new(0, -feet - 1.1, 0), self.supportRay)
 if hit and math.abs(hit.Distance - feet) <= 1.1 then
  return self.padIds[hit.Instance]
 end
 return nil
end
function Service:Start(player,fromPrompt)
 if self.runs[player] then return false end
 if player:GetAttribute("VerityRiding") or player:GetAttribute("VerityRaceSlot") or player:GetAttribute("VerityFusionSlot") or player:GetAttribute("VerityBattleActive") then return false end
 local profile=self.data:Get(player.UserId);local c,root=self:Character(player)
 if not profile or not self.state.sessions[player.UserId] or not profile.Data.VerityUnlocked or not c then return false end
 if not fromPrompt and self:GroundedIndex(c, root) ~= 1 then return false end
 if self.resetMovement then self.resetMovement(player) end
 root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
 if fromPrompt then
  local p=Config.Pads[1]
  local position=Vector3.new(p.x,p.y+.5+self:FeetOffset(c,root)+.15,p.z)
  c:PivotTo(CFrame.new(position)*root.CFrame.Rotation)
 end
 local now=self.clock()
 self:SetRun(player,{character=c,index=1,checkpoint=1,started=now,faults=0,lastStep=now})
 self.notify(player.UserId,"PARKOUR_STARTED",0)
 return true
end
function Service:Advance(player,index)
 if player:GetAttribute("VerityRiding") or player:GetAttribute("VerityRaceSlot") or player:GetAttribute("VerityFusionSlot") or player:GetAttribute("VerityBattleActive") then return false end
 local profile=self.data:Get(player.UserId)
 local character=self:Character(player)
 local pad=Config.Pads[index]
 if not profile or not self.state.sessions[player.UserId] or not profile.Data.VerityUnlocked or not character or not pad then return false end
 local now=self.clock();local run=self.runs[player]
 if not run or run.character~=character or index<=run.index or now-run.started>Config.MaximumRunSeconds then return false end
 -- Intermediate walking surfaces are not mandatory landing events. An ordinary
 -- jump may cross them; marked checkpoints and transfer gates must be visited.
 local missed=index-run.index>4
 for skipped=run.index+1,index-1 do
  if Config.Pads[skipped].checkpoint or Config.Pads[skipped].gate then missed=true;break end
 end
 if missed then
  self:Return(player,false);self.notify(player.UserId,"PARKOUR_GATE_MISSED",0);return false
 end

 run.index=index;run.lastStep=now
 if pad.checkpoint then run.checkpoint=index;self.notify(player.UserId,"PARKOUR_CHECKPOINT",0) end
 self:SetRun(player,run)
 if pad.finish then self.notify(player.UserId,"PARKOUR_CORE_READY",0) end
 return true
end
function Service:Finish(player)
 local run=self.runs[player];local profile=self.data:Get(player.UserId)
 local character,root=self:Character(player);local now=self.clock()
 if not run or not profile or not self.state.sessions[player.UserId] or not character or run.character~=character
  or now-run.started>Config.MaximumRunSeconds or run.index~=#Config.Pads
  or self:GroundedIndex(character, root)~=#Config.Pads then return false end
  if now-run.started<Config.MinimumRunSeconds then
   if now>=(run.finishHintAt or 0) then run.finishHintAt=now+3;self.notify(player.UserId,"PARKOUR_TOO_FAST",0) end
   return false
  end
  if now<(self.ready[player] or 0) then
   self:SetRun(player,nil)
   if self.model then self.model:SetAttribute("CoreActivatedAt",now) end
   if self.onCompleted then self.onCompleted(player.UserId) end
   self.notify(player.UserId,"PARKOUR_PRACTICE",0);return true
  end
  if run.finishing then return false end
  run.finishing=true
  local seconds=now-run.started
  local medal,bonus=Config.Medal(seconds,run.faults or 0)
  local amount=Rewards.Base(profile.Data.VerityLevel,"Parkour")*bonus*self.economy:GetMultiplier(profile)
  local ok,reward=self.economy:AddCash(player.UserId,amount)
  if not ok then
   run.finishing=nil
   if now>=(run.rewardHintAt or 0) then run.rewardHintAt=now+3;self.notify(player.UserId,"PARKOUR_REWARD_RETRY",0) end
   return false
  end
  -- Cash grant is synchronous. Complete/lock only after success; a temporary
  -- refusal leaves the completed route available for another console activation.
  self.ready[player]=now+Config.Cooldown;self:SetRun(player,nil)
  if self.model then self.model:SetAttribute("CoreActivatedAt",now) end
  player:SetAttribute("VerityParkourReadyAt",self.ready[player])
  player:SetAttribute("VerityParkourMedal",medal);player:SetAttribute("VerityParkourFinishTime",seconds)
  local best=player:GetAttribute("VerityParkourBest")
  if not best or seconds<best then player:SetAttribute("VerityParkourBest",seconds) end
  self.state:CompleteActivity(profile,"Parkour")
  if self.onCompleted then self.onCompleted(player.UserId) end
  self.state:Publish(player.UserId,true);self.notify(player.UserId,"PARKOUR_FINISH",reward)
  return true
end
function Service:Return(player,exit)
 local c,r=self:Character(player);local run=self.runs[player]
 if not c or (run and run.character~=c) then self:SetRun(player,nil);return end
 if self.resetMovement then self.resetMovement(player) end
 r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
 if exit then
  self:SetRun(player,nil);c:PivotTo(CFrame.new(Config.ExitPosition))
 elseif run then
  local p=Config.Pads[run.checkpoint];run.index=run.checkpoint;run.faults=(run.faults or 0)+1;run.lastStep=self.clock();run.hazardUntil=self.clock()+1.5
  local platform=self.pads[run.checkpoint]
  local position=platform.Position+Vector3.new(0,.5+self:FeetOffset(c,r)+.15,0)
  c:PivotTo(CFrame.new(position)*r.CFrame.Rotation);self:SetRun(player,run)
 end
 self.positions[player]={character=c,position=r.Position,at=self.clock()}
end
-- Called from the existing Heartbeat, not the slower house update. Every
-- nearby hazard is checked even if a route marker was missed or no run is active.
function Service:Tick()
 if not self.players then return end
 local now=self.clock()
 for _,player in self.players:GetPlayers() do
  local c,r=self:Character(player);local run=self.runs[player]
  if not c or not self.state.sessions[player.UserId] then
   if run then self:SetRun(player,nil) end
   self.positions[player]=nil;continue
  end
  local pos=r.Position
  if not Numeric.isFinite(pos.X) or not Numeric.isFinite(pos.Y) or not Numeric.isFinite(pos.Z) then continue end
  local profile=self.data:Get(player.UserId)
  if run and (run.character~=c or now-run.started>Config.MaximumRunSeconds or not profile) then
   self:SetRun(player,nil)
   run=nil
  end
  if not Config.Contains(pos.X,pos.Z) then
   if run then self:Return(player,false) else self.positions[player]=nil end
   continue
  end
  if not profile or not profile.Data.VerityUnlocked then continue end
  local grounded=self:GroundedIndex(c,r)
  if not run and grounded==1 then self:Start(player,false);run=self.runs[player] end
  local previous=self.positions[player]
  local from=if previous and previous.character==c and now-previous.at<.25 and (previous.position-pos).Magnitude<24 then previous.position else pos
  local feet=self:FeetOffset(c,r)
  local hit=false
  if not run or now>=(run.hazardUntil or 0) then
   for _,index in self.hazards do
    local platform=self.pads[index]
    if not platform or not platform.Parent then continue end
    local delta=platform.Position-pos
    if math.abs(delta.X)>24 or math.abs(delta.Z)>24 or math.abs(delta.Y)>16 then continue end
    if Config.HazardCrosses(index,from,pos,now,platform.CFrame,feet) then
     self:Return(player,run==nil);self.notify(player.UserId,"PARKOUR_RETRY",0);hit=true;break
    end
   end
  end
  if not hit and run then
   if pos.Y<Config.ResetBelow or pos.Y-feet<self.pads[run.index].Position.Y-3 then
    self:Return(player,false)
   elseif grounded and grounded>run.index then
    self:Advance(player,grounded)
   end
  elseif not hit and grounded==#Config.Pads and now>=(self.ready[player] or 0) and now>=(self.entryHints[player] or 0) then
   self.entryHints[player]=now+30;self.notify(player.UserId,"PARKOUR_START_REQUIRED",0)
  end
  self.positions[player]={character=c,position=r.Position,at=now}
 end
end
function Service:Bind(model,players)
 self.players=players;self.pads={};self.model=model;self.movers={};self.hazards={};self.padIds={}
 self.supportRay=RaycastParams.new();self.supportRay.FilterType=Enum.RaycastFilterType.Include
 local supports={}
 local console=model:FindFirstChild("ActivateCore",true)
 if console then table.insert(self.links,console.Triggered:Connect(function(player)
  local _,root=self:Character(player)
  if root and (root.Position-console.Parent.Position).Magnitude<=console.MaxActivationDistance+2 then
   if not self.runs[player] then self.notify(player.UserId,"PARKOUR_START_REQUIRED",0)
   elseif self.runs[player].index~=#Config.Pads then self.notify(player.UserId,"PARKOUR_MISSED_STEP",0)
   else self:Finish(player) end
  end
 end)) end
 local start=model:FindFirstChild("StartCourse",true)
 if start then table.insert(self.links,start.Triggered:Connect(function(player)
  local _,root=self:Character(player)
  if root and (root.Position-start.Parent.Position).Magnitude<=start.MaxActivationDistance+2 then self:Start(player,true) end
 end))end
 for index in Config.Pads do
  local p=model:FindFirstChild(string.format("Pad%02d",index))
  if p then
   self.pads[index]=p;self.padIds[p]=index;table.insert(supports,p)
   p.CanTouch=false
   local definition=Config.Pads[index]
   if definition.hazard then table.insert(self.hazards,index) end
   if definition.motion then
    local attachment=Instance.new("Attachment");attachment.Name="FactoryMotionAnchor";attachment.Parent=p
    local position=Instance.new("AlignPosition");position.Name="FactoryPosition";position.Mode=Enum.PositionAlignmentMode.OneAttachment
    position.Attachment0=attachment;position.ApplyAtCenterOfMass=true;position.MaxForce=1e7;position.MaxVelocity=12;position.Responsiveness=35
    local target=Config.PadFrame(index,self.clock());position.Position=target.Position;position.Parent=p
    local orientation=Instance.new("AlignOrientation");orientation.Name="FactoryOrientation";orientation.Mode=Enum.OrientationAlignmentMode.OneAttachment
    orientation.Attachment0=attachment;orientation.CFrame=CFrame.identity;orientation.MaxTorque=1e7;orientation.Responsiveness=40;orientation.Parent=p
    p.CFrame=target;p.Anchored=false;p:SetNetworkOwner(nil)
    self.movers[index]={part=p,drive=position,attachment=attachment,orientation=orientation}
   elseif definition.belt then
    p.AssemblyLinearVelocity=definition.direction*definition.belt
   end
  end
 end
 self.supportRay.FilterDescendantsInstances=supports
 for _,name in {"ExitCourse","ReturnToStart"} do
  local prompt=model:FindFirstChild(name,true)
  if prompt then table.insert(self.links,prompt.Triggered:Connect(function(player)
   local _,r=self:Character(player);local p=prompt.Parent
   if r and (r.Position-p.Position).Magnitude<=prompt.MaxActivationDistance+2 then self:Return(player,true) end
  end)) end
 end
end
-- Physical platforms have one server constraint owner. Clients render replicated
-- geometry; they never reposition a collision platform or grant progress.
function Service:UpdateMotion(now)
 for index,mover in self.movers or {} do
  if mover.part:IsDescendantOf(workspace) then
   mover.drive.Position=Config.PadFrame(index,now).Position
   if (mover.part.Position-mover.drive.Position).Magnitude>30 then
    mover.part.CFrame=Config.PadFrame(index,now);mover.part.AssemblyLinearVelocity=Vector3.zero;mover.part.AssemblyAngularVelocity=Vector3.zero
   end
  end
 end
end
function Service:Remove(player)self:SetRun(player,nil);self.ready[player]=nil;self.entryHints[player]=nil;self.positions[player]=nil end
function Service:Destroy()
 for _,link in self.links do link:Disconnect()end;self.links={}
 for player in self.runs do self:SetRun(player,nil) end
 for _,mover in self.movers or {} do
  if mover.part.Parent then mover.part.Anchored=true;mover.part.AssemblyLinearVelocity=Vector3.zero;mover.part.AssemblyAngularVelocity=Vector3.zero end
  mover.drive:Destroy();mover.orientation:Destroy();mover.attachment:Destroy()
 end
 for index,p in self.pads or {} do if p.Parent and Config.Pads[index].belt then p.AssemblyLinearVelocity=Vector3.zero end end
 table.clear(self.ready);table.clear(self.entryHints);table.clear(self.positions)
 self.players=nil;self.pads=nil;self.model=nil;self.movers=nil;self.hazards=nil;self.padIds=nil;self.supportRay=nil
end
return Service
