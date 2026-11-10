--!nonstrict
-- One optional server-owned cooperative vehicle. Clients send only bounded inputs.
local Shared=game:GetService("ReplicatedStorage").Shared
local C=require(Shared.VerityFusionConfig)
local Numeric=require(Shared.Numeric)
local Bridge=require(Shared.PremiumVisualBridge)
local Service={};Service.__index=Service
local allowed={Move=true,Jump=true,Boost=true,Ready=true,Swap=true,Leave=true,Sync=true,Join=true}
local attrs={"VerityFusionSlot","VerityFusionRole","VerityFusionActive","VerityFusionPremiumStyle"}
local function slotRole(slot) return if slot==1 then "Pilot" else "Jumper" end
local function finitePosition(p) return Numeric.isFinite(p.X) and Numeric.isFinite(p.Y) and Numeric.isFinite(p.Z) end

function Service.new(model,data,state,players,clock,stopMovement,notify)
 local self=setmetatable({model=model,data=data,state=state,players=players,clock=clock,stopMovement=stopMovement,notify=notify,
  entries={},limits={},links={},phase="Waiting",round=0,sequence=0,lastPublish=0,pose=C.MergePose()},Service)
 local function remote(name)
  local old=model:FindFirstChild(name);if old then old:Destroy() end
  local event=Instance.new("RemoteEvent");event.Name=name;event.Parent=model;return event
 end
 self.control=remote("FusionControl");self.stateEvent=remote("FusionState")
 table.insert(self.links,self.control.OnServerEvent:Connect(function(player,action,round,value,...)
  if select("#",...)~=0 then return end
  self:Control(player,action,round,value)
 end))
 self.pads={model:FindFirstChild("FusionPad1"),model:FindFirstChild("FusionPad2")}
 for index,pad in self.pads do
  table.insert(self.links,pad.JoinFusion.Triggered:Connect(function(player) self:Join(player,index) end))
 end
 self:Publish();return self
end
function Service:Find(player)
 for slot,e in self.entries do if e.player==player then return e,slot end end
 return nil
end
function Service:Eligible(player)
 if player.Parent~=self.players then return nil end
 local profile=self.data:Get(player.UserId);local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not profile or not self.state.sessions[player.UserId] or not profile.Data.VerityUnlocked
  or not root or not hum or hum.Health<=0 or root.Anchored or hum.SeatPart or not finitePosition(root.Position) then return nil end
 if (player:GetAttribute("VerityRiding") or player:GetAttribute("VerityDiversionKind")) or player:GetAttribute("VerityRaceSlot") or player:GetAttribute("VerityParkourStep")
  or player:GetAttribute("VerityBattleActive") then return nil end
 return char,root,hum
end
function Service:Limit(player,key,interval,now)
 local limits=self.limits[player]
 if not limits then limits={};self.limits[player]=limits end
 if now<(limits[key] or 0) then return false end
 limits[key]=now+interval;return true
end
function Service:Publish(only)
 local now=self.clock();self.sequence+=1
 local entries={}
 for slot=1,2 do
  local e=self.entries[slot]
  if e then
   local profile=self.data:Get(e.player.UserId);local d=profile and profile.Data
   table.insert(entries,{id=e.player.UserId,slot=slot,role=slotRole(slot),ready=e.ready==true,swap=e.swap==true,
    level=d and d.VerityLevel or 1,weatherLook=d and d.WeatherLook or "Auto",equipped=if d then table.clone(d.CosmeticsEquipped) else {}})
  end
 end
 local message={version=C.Version,round=self.round,sequence=self.sequence,phase=self.phase,entries=entries,
  serverTime=now,velocity=Vector3.new(self.vx or 0,self.vy or 0,self.vz or 0),pose=self.pose,mergeAt=self.mergeAt or 0,deadline=self.deadline or 0,retryAt=self.retryAt or 0,boostReady=self.boostReady or 0,
  faults=self.faults or 0,obstacle=self.obstacle or 1,checkpoint=self.checkpointZ or C.StartZ,jump=self.jumpSerial or 0,
  distance=math.clamp(((self.z or C.StartZ)-C.StartZ)/(C.EndZ-C.StartZ),0,1),result=self.result,premiumLook=self.premiumStyle and Bridge.Visual("FusionStyle",self.premiumStyle.id),premiumStyle=self.premiumStyle or {id="default",ownerUserId=0,shared=false}}
 if only then self.stateEvent:FireClient(only,message);return end
 self.lastPublish=now
 self.model:SetAttribute("FusionPhase",self.phase);self.model:SetAttribute("FusionRound",self.round)
 self.model:SetAttribute("FusionMergeAt",self.mergeAt)
 for index,pad in self.pads do
  local enabled=self.phase=="Waiting" and not self.entries[index]
  if pad.JoinFusion.Enabled~=enabled then pad.JoinFusion.Enabled=enabled end
 end
 self.stateEvent:FireAllClients(message)
end
function Service:RefreshPremiumStyle()
 local previous=self.premiumStyle
 local style=if self.premium and (self.phase=="Merging" or self.phase=="Running") then self.premium:FusionStyle(self.entries) else {id="default",ownerUserId=0,shared=false}
 self.premiumStyle=style
 self.model:SetAttribute("FusionPremiumStyle",style.id);self.model:SetAttribute("FusionPremiumOwner",style.ownerUserId)
 for _,entry in self.entries do
  if self.phase=="Merging" or self.phase=="Running" then entry.player:SetAttribute("VerityFusionPremiumStyle",style.id) end
 end
 if not previous or previous.id~=style.id or previous.ownerUserId~=style.ownerUserId then self:Publish() end
end
function Service:Role(entry,slot)
 entry.player:SetAttribute("VerityFusionSlot",slot)
 entry.player:SetAttribute("VerityFusionRole",slotRole(slot))
 self.state:Publish(entry.player.UserId,true)
end
function Service:Join(player,slot)
 local pad=self.pads[slot]
 local now=self.clock()
 if not pad or self.phase~="Waiting" or not self:Limit(player,"Join",.5,now)
  or self:Find(player) or self.entries[slot] then return end
 local char,root,hum=self:Eligible(player)
 if not char or (root.Position-pad.Position).Magnitude>C.JoinReach+1 then return end
 local entry={player=player,character=char,root=root,hum=hum,joined=now,ready=false,swap=false}
 self.entries[slot]=entry
 self:Role(entry,slot)
 self:Publish()
end
function Service:Freeze(entry)
 local player,root,hum=entry.player,entry.root,entry.hum
 self.stopMovement(player)
 entry.joinPose=root.CFrame
 entry.restore={anchored=root.Anchored,auto=hum.AutoRotate,speed=hum.WalkSpeed,power=hum.JumpPower,collide={}}
 local function part(p)
  if p:IsA("BasePart") then entry.restore.collide[p]=p.CanCollide;p.CanCollide=false end
 end
 for _,p in entry.character:GetDescendants() do part(p) end
 entry.added=entry.character.DescendantAdded:Connect(part)
 root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero;root.Anchored=true
 hum.AutoRotate=false;hum.WalkSpeed=0;hum.JumpPower=0;hum.Jump=false
 player:SetAttribute("VerityFusionActive",true)
 self.state:Publish(player.UserId,true)
end
function Service:Restore(entry,slot)
 local player,root,hum=entry.player,entry.root,entry.hum
 for _,name in attrs do player:SetAttribute(name,nil) end
 if entry.added then entry.added:Disconnect();entry.added=nil end
 local saved=entry.restore
 if saved then
  for part,value in saved.collide do if part.Parent then part.CanCollide=value end end
  if root.Parent then
   if player.Character==entry.character and hum.Parent and hum.Health>0 then
    local exit=C.Hub+Vector3.new((slot-1.5)*7,3.8,6)
    entry.character:PivotTo(CFrame.new(exit)*CFrame.Angles(0,math.pi,0))
   end
   root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero;root.Anchored=saved.anchored
  end
  if hum.Parent then hum.AutoRotate=saved.auto;hum.WalkSpeed=saved.speed;hum.JumpPower=saved.power;hum.Jump=false end
  entry.restore=nil
 end
 if player.Parent==self.players then self.state:Publish(player.UserId,true) end
end
function Service:Begin()
 local pilot,jumper=self.entries[1],self.entries[2]
 if self.phase~="Waiting" or not pilot or not jumper or pilot.player==jumper.player
  or not pilot.ready or not jumper.ready then return end
 for _,entry in {pilot,jumper} do
  local character,root=self:Eligible(entry.player)
  if not root or character~=entry.character or (root.Position-C.Hub).Magnitude>C.QueueReach then
   self:Remove(entry.player)
   return
  end
 end
 local now=self.clock()
 self.round+=1;self.phase="Merging";self.mergeAt=now;self.deadline=now+C.MergeSeconds;self.result=nil
 self.x,self.z,self.y,self.yaw=0,C.StartZ,0,0
 self.vx,self.vz,self.vy=0,0,0;self.move=Vector2.zero;self.lastMove=0
 self.obstacle=1;self.checkpointX,self.checkpointZ=0,C.StartZ;self.faults=0;self.retryAt=0
 self.jumpSerial=0;self.jumpUntil=0;self.boostUntil=0;self.boostReady=0
 self.pose=C.MergePose()
 for _,e in self.entries do self:Freeze(e) end
 self:RefreshPremiumStyle()
 self:PlaceRiders();self:Publish()
end
function Service:PlaceRiders()
 for slot,e in self.entries do
  if e.root.Parent and e.player.Character==e.character then
   local seat=C.Seat(slot)
   if self.phase=="Merging" then
    local alpha=math.clamp((self.clock()-self.mergeAt)/C.MergeSeconds,0,1)
    seat=CFrame.new(seat.Position.X,2.9+(seat.Position.Y-2.9)*math.clamp((alpha-.60)/.40,0,1),seat.Position.Z)
   end
   local target=self.pose*seat
   if self.phase=="Merging" and e.joinPose then
    local t=math.clamp((self.clock()-self.mergeAt)/(C.MergeSeconds*.55),0,1);t=t*t*(3-2*t)
    target=e.joinPose:Lerp(target,t)
   end
   if e.root.CFrame~=target then e.root.CFrame=target end
  end
 end
end
function Service:Award(entry)
 local userId=entry.player.UserId;local profile=self.data:Get(userId)
 if not profile or not self.state.sessions[userId] or not profile.Data.VerityUnlocked then return false end
 self.state:CompleteActivity(profile,"Fusion")
 if profile.Data.CosmeticsOwned[C.Reward] then return false end
 profile.Data.CosmeticsOwned[C.Reward]=true;self.data:Touch(profile);self.state:Publish(userId,true)
 task.defer(function()
  if self.data:Get(userId)==profile and profile.Dirty and not profile.Saving then self.data:SaveAsync(userId,false) end
 end)
 return true
end
function Service:Finish(won,reason,quiet)
 if self.phase~="Merging" and self.phase~="Running" then return end
 local now=self.clock();local entries=self.entries
 self.phase="Results";self.result=if won then "Won" else "Ended";self.deadline=now+C.ResultSeconds
 self.entries={};self.move=Vector2.zero
 if won then self.pose=C.MergePose() end
 for slot,e in entries do
  self:Restore(e,slot)
  if e.player.Parent==self.players and not quiet then
   local code=reason or "FUSION_ENDED"
   if won then code=if self:Award(e) then "FUSION_PRIZE" else "FUSION_WIN" end
   self.notify(e.player.UserId,code)
  end
 end
 self:Publish()
end
function Service:Remove(player,forget)
 local e,slot=self:Find(player)
 if e then
  if self.phase=="Merging" or self.phase=="Running" then self:Finish(false,"FUSION_ENDED")
  else
   self.entries[slot]=nil;self:Restore(e,slot)
   for _,other in self.entries do other.ready=false;other.swap=false end
   self:Publish()
  end
 end
 if forget then self.limits[player]=nil end
end
function Service:Control(player,action,round,value)
 if player.Parent~=self.players or type(action)~="string" or not allowed[action] or type(round)~="number" or not Numeric.isFinite(round) then return end
 local now=self.clock()
 if action=="Sync" then
  if value==nil and self:Limit(player,"Sync",1,now) then self:Publish(player) end
  return
 end
 if round~=self.round then return end
 if action=="Join" then
  if value==1 or value==2 then self:Join(player,value) end
  return
 end
 local entry,slot=self:Find(player);if not entry then return end
 if action=="Move" then
  if self.phase~="Running" or slot~=1 or typeof(value)~="Vector2" or not self:Limit(player,"Move",.065,now)
   or not Numeric.isFinite(value.X) or not Numeric.isFinite(value.Y) or value.Magnitude>1.02 then return end
  self.move=if value.Magnitude>1 then value.Unit else value;self.lastMove=now;return
 end
 if (action=="Ready" and type(value)~="boolean") or (action~="Ready" and value~=nil)
  or not self:Limit(player,action,.22,now) then return end
 if action=="Leave" then self:Remove(player);return end
 if self.phase=="Waiting" then
  if action=="Ready" then
   if entry.ready==value then self:Publish(player);return end
   entry.ready=value;entry.swap=false;self:Publish();self:Begin()
  elseif action=="Swap" and self.entries[1] and self.entries[2] then
   entry.swap=not entry.swap;entry.ready=false
   if self.entries[1].swap and self.entries[2].swap then
    self.entries[1],self.entries[2]=self.entries[2],self.entries[1]
    for i,e in self.entries do e.swap=false;e.ready=false;self:Role(e,i) end
   end
   self:Publish()
  end
  return
 end
 if self.phase~="Running" or now<(self.retryAt or 0) or slot~=2 then return end
 if action=="Jump" then self.jumpUntil=now+.18
 elseif action=="Boost" and now>=self.boostReady then self.boostUntil=now+C.BoostSeconds;self.boostReady=now+C.BoostCooldown end
end
function Service:Fault(now)
 self.faults+=1
 if self.faults>=C.MaxFaults then self:Finish(false,"FUSION_FAILED");return end
 self.x,self.z,self.y=self.checkpointX,self.checkpointZ,0;self.vx,self.vz,self.vy=0,0,0
 self.yaw=0;self.jumpUntil=0;self.boostUntil=0;self.retryAt=now+C.RetrySeconds
 self.pose=C.Pose(self.x,self.z,0,0);self:PlaceRiders();self:Publish()
end
function Service:Drive(dt,now)
 local move=if now-self.lastMove<C.InputTimeout then self.move else Vector2.zero
 local speed=if now<self.boostUntil then C.BoostSpeed else C.Speed
 local blend=1-math.exp(-12*dt)
 self.vx+=(move.X*speed-self.vx)*blend;self.vz+=(move.Y*speed-self.vz)*blend
 if self.y<=.001 and self.vy<=0 and now<self.jumpUntil then
  self.vy=C.JumpSpeed;self.jumpUntil=0;self.jumpSerial+=1
 end
 self.vy-=C.Gravity*dt;self.y=math.max(0,self.y+self.vy*dt)
 if self.y==0 then self.vy=0 end
 self.x=math.clamp(self.x+self.vx*dt,-C.HalfWidth+C.Radius,C.HalfWidth-C.Radius)
 self.z=math.clamp(self.z+self.vz*dt,self.checkpointZ,C.EndZ)
 local o=C.Obstacles[self.obstacle]
 if o then
  if C.ObstacleHit(o,self.x,self.z,self.y,now) then self:Fault(now);return end
  if self.z>=o.z+o.half+7 then self.checkpointX,self.checkpointZ=self.x,self.z;self.obstacle+=1 end
 elseif self.z>=C.EndZ then self:Finish(true);return end
 self.yaw+=(-self.vx*.052-self.yaw)*blend
 self.pose=C.Pose(self.x,self.z,self.y,self.yaw)
end
function Service:Tick(dt)
 local now=self.clock()
 if self.phase=="Results" then
  if now>=self.deadline then self.phase="Waiting";self.deadline=nil;self.mergeAt=nil;self:RefreshPremiumStyle();self:Publish() end
  return
 end
 if self.phase=="Waiting" then
  if now<(self.queuePollAt or 0) then return end;self.queuePollAt=now+.2
  for _,e in self.entries do
   local c,root=self:Eligible(e.player)
   if c~=e.character or now-e.joined>C.QueueSeconds or (root.Position-C.Hub).Magnitude>C.QueueReach then self:Remove(e.player);break end
  end
  return
 end
 for _,e in self.entries do
  if e.player.Parent~=self.players or e.player.Character~=e.character or not e.root.Parent or not e.hum.Parent
   or not e.root.Anchored or e.hum.Health<=0 or not self.data:Get(e.player.UserId) or not self.state.sessions[e.player.UserId] then
   self:Finish(false,"FUSION_ENDED");return
  end
 end
 if self.phase=="Merging" then
  if now>=self.deadline then
   self.phase="Running";self.deadline=now+C.RunSeconds;self.pose=C.Pose(0,C.StartZ,0,0)
   self:PlaceRiders();self:Publish();return
  end
 elseif now>=self.deadline then self:Finish(false,"FUSION_TIME");return
 elseif now>=self.retryAt then
  -- Bound step length even after a late frame so a gap or gate cannot be skipped.
  local remaining=math.min(dt,.12)
  while remaining>0 and self.phase=="Running" and now>=self.retryAt do
   local step=math.min(remaining,1/45);remaining-=step;self:Drive(step,now)
  end
  if self.phase~="Running" then return end
 end
 self:PlaceRiders()
 if now-self.lastPublish>=C.PublishInterval then self:Publish() end
end
function Service:Destroy()
 if self.phase=="Merging" or self.phase=="Running" then self:Finish(false,nil,true) end
 for slot,e in self.entries do self:Restore(e,slot) end
 table.clear(self.entries);table.clear(self.limits)
 self.model:SetAttribute("FusionPremiumStyle","default");self.model:SetAttribute("FusionPremiumOwner",0)
 for _,link in self.links do link:Disconnect() end;table.clear(self.links)
 self.control:Destroy();self.stateEvent:Destroy()
end
return Service
