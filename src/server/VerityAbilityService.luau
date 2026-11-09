--!nonstrict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=ReplicatedStorage.Shared
local Forms=require(Shared.VerityAbilities)
local Catalog=require(Shared.AbilityCatalog)
local Numeric=require(Shared.Numeric)
local Levels=require(Shared.LevelConfig)
local Ride=require(Shared.VerityRideConfig)
local Parkour=require(Shared.ParkourConfig)
local SecretsConfig=require(Shared.SecretsConfig)
local AdventureConfig=require(Shared.AdventureConfig)
local Service={};Service.__index=Service

function Service.new(data,state,world,targets)
	local self=setmetatable({data=data,state=state,world=world,targets=targets,active={},attacks={},requests={},steering={},cooldowns={}},Service)
	local remote=Instance.new("RemoteEvent");remote.Name="UseVerityAbility"
	remote.OnServerEvent:Connect(function(player,slot,direction,...)
		if select("#",...)>0 then return end
		self:Activate(player,slot,direction)
	end)
	remote.Parent=ReplicatedStorage;self.remote=remote
	return self
end
function Service:Character(player)
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health<=0 or humanoid.SeatPart or root.Anchored then return nil end
	return character,root,humanoid
end
function Service:Equipped(slot,profile)
 return Catalog.Equipped(profile.Data,slot,profile.HeroPassOwned)
end
function Service:BlockReason(player,slot)
 if player:GetAttribute("VerityDiversionKind") and not (self.adventures and self.adventures:AllowsPower(player,slot)) then return "DIVERSION_POWER" end
 if player:GetAttribute("VerityFusionSlot") then return "FUSION_POWER" end
 if player:GetAttribute("VerityRaceSlot") then return "RACE_POWER" end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 if player:GetAttribute("VerityParkourStep") or root and Parkour.Contains(root.Position.X,root.Position.Z) then return "PARKOUR_POWER" end
 if slot=="Ride" and player:GetAttribute("VerityBattleActive") then return "BATTLE_OTHER_ACTIVITY" end
 if slot=="Mobility" and player:GetAttribute("VerityRiding") then return "RIDING_POWER" end
 return nil
end
function Service:SlotSnapshot(player)
 local result={};local profile=self.data:Get(player.UserId);if not profile then return result end
 local now=workspace:GetServerTimeNow();local character,root=self:Character(player)
 for _,slot in {"Mobility","Attack"} do
  local item,id=self:Equipped(slot,profile)
  local ready=(self.cooldowns[player] or {})[slot] or 0
  local untilTime=player:GetAttribute(if slot=="Mobility" then "VerityMobilityUntil" else "VerityAttackUntil") or 0
  local reason=self:BlockReason(player,slot)
  if not profile.Data.VerityUnlocked then reason="BOX_NOT_OPENED" elseif not character then reason="CHARACTER_UNAVAILABLE"
  elseif slot=="Attack" and not reason and self:IsAttackBlocked(player,root) and not (self.secrets and self.secrets:CanAimMechanism(player,item)) and not (self.adventures and self.adventures:CanAimMechanism(player,item)) then reason="SAFE_ZONE" end
  result[slot]={slot=slot,itemId=id,name=item and item.Name,key=if slot=="Mobility" then "F" else "G",
   gamepadKey=if slot=="Mobility" then "ButtonL1" else "ButtonR1",icon=item and Catalog.Icons[id] or (if slot=="Mobility" then "◇" else "✦"),empty=item==nil,
   duration=item and (if slot=="Mobility" and item.MobilityAction then item.FlightDuration else item.Duration) or 0,
   emptyAction="OpenAbilityCollection",blockedReason=reason,
   readyAt=ready,activeUntil=untilTime,active=untilTime>now,canUse=item~=nil and reason==nil and ready<=now and untilTime<=now}
 end
 return result
end
function Service:IsAttackBlocked(player,root)
 if SecretsConfig.Sanctuary(root.Position) or AdventureConfig.TrialContains(root.Position) or AdventureConfig.CaveContains(root.Position) then return true end
 if player:GetAttribute("VerityDiversionKind") then return true end
 if player:GetAttribute("VerityFusionSlot") then return true end
 if player:GetAttribute("VerityParkourStep") then return true end
 if player:GetAttribute("VerityRaceSlot") then return true end
	if workspace:GetServerTimeNow()<(player:GetAttribute("VerityProtectedUntil") or 0) then return true end
	if player.Character and player.Character:FindFirstChildOfClass("ForceField") then return true end
 return false
end

-- Players can use powers here, while the house remains protected from PvP.
function Service:IsInHouse(root)
	for _,anchors in self.world.anchors do
		local house=anchors.WorkshopHouse
		if not house then continue end
		local p=house:GetPivot():PointToObjectSpace(root.Position)
		if p.Y>=-2 and p.Y<=34 and ((math.abs(p.X)<18 and p.Z>-16 and p.Z<18)
			or (math.abs(p.X)<27 and p.Z>=-57 and p.Z<=-14)) then return true end
	end
	return false
end
function Service:IsSafe(player,root)
 return self:IsAttackBlocked(player,root) or self:IsInHouse(root)
end

function Service:Refresh(player,character,snapshot)
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not snapshot then return end
	local current=self.active[player]
	local profile=self.data:Get(player.UserId)
	local equipped=profile and profile.Data.AbilitiesEquipped.Mobility
	if profile and not Catalog.Equipped(profile.Data,"Mobility",profile.HeroPassOwned) then equipped=nil end
	if current and (current.character~=character or (not current.ride and current.id~=equipped) or (current.ride and (not snapshot.VerityUnlocked or snapshot.VerityLevel<Ride.MinLevel or snapshot.VerityLevel~=current.level)) or humanoid.Health<=0) then self:Stop(player);current=nil end
	if humanoid.Health<=0 then return end
 if player:GetAttribute("VerityFusionActive") or player:GetAttribute("VerityDiversionKind")=="Arcade" then humanoid.WalkSpeed=0;humanoid.JumpPower=0;return end
	local form=if snapshot.VerityUnlocked then Forms.Get(snapshot.VerityLevel) else nil
 if player:GetAttribute("VerityParkourStep") then
  humanoid.WalkSpeed=Parkour.WalkSpeed;humanoid.UseJumpPower=true;humanoid.JumpPower=Parkour.JumpPower
  return
 end
	humanoid.WalkSpeed=if current and current.phase then 0 elseif current and current.speed then current.speed elseif form then form.speed else 16
	humanoid.UseJumpPower=true;humanoid.JumpPower=if form then form.jump else 50
end
function Service:Stop(player,stopAttacks)
	if stopAttacks~=false then self.attacks[player]=nil;player:SetAttribute("VerityAttackUntil",nil) end
	local current=self.active[player]
	if not current then return end
	if current.transition then current.transition:Disconnect();current.transition=nil end
 if current.ride then
  local _,root,humanoid=self:Character(player)
  if root and player.Character==current.character then
   local landing=self:RideLanding(current,root.Position) or self:RideLanding(current,current.launch)
   if landing then root.CFrame=CFrame.new(landing)*root.CFrame.Rotation end
   root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
  end
  if current.hull then current.hull:Destroy() end
  player:SetAttribute("VerityRiding",nil)
  player:SetAttribute("VerityRidePhase",nil)
  player:SetAttribute("VerityRideY0",nil);player:SetAttribute("VerityRideY1",nil)
 end
 self.active[player]=nil
	if current.attachment then current.attachment:Destroy() end
	if current.ownsPhysics and current.root and current.root:IsDescendantOf(workspace) and current.root:CanSetNetworkOwnership() then
		if current.dash then current.root.AssemblyLinearVelocity=Vector3.yAxis*current.root.AssemblyLinearVelocity.Y end
		current.root:SetNetworkOwnershipAuto()
	end
	local profile=self.data:Get(player.UserId)
	local humanoid=current.character:FindFirstChildOfClass("Humanoid")
	if humanoid and profile then
  local inCourse=player:GetAttribute("VerityParkourStep")~=nil
  humanoid.WalkSpeed=if inCourse then Parkour.WalkSpeed else Forms.Get(profile.Data.VerityLevel).speed
  humanoid.UseJumpPower=true;humanoid.JumpPower=if inCourse then Parkour.JumpPower else Forms.Get(profile.Data.VerityLevel).jump
 end
	player:SetAttribute("VerityShieldUntil",nil)
	player:SetAttribute("VerityMobilityUntil",nil)
end
function Service:Remove(player)
	self:Stop(player);self.requests[player]=nil;self.steering[player]=nil;self.cooldowns[player]=nil
end
function Service:Candidates(attacker,includePlayers)
	local candidates={}
	for _,player in (if includePlayers then Players:GetPlayers() else {}) do
		local character,root,humanoid=self:Character(player)
		local profile=self.data:Get(player.UserId)
		if root and profile and profile.Data.VerityUnlocked and self.state.sessions[player.UserId] and not self:IsSafe(player,root) and not player:GetAttribute("VerityBattleActive") and not (attacker and attacker:GetAttribute("VerityBattleActive")) then
			table.insert(candidates,{part=root,humanoid=humanoid,player=player,character=character})
		end
	end
	for part,r in self.targets.records do
		if r.health>0 and part.Parent and (not r.arenaOnly or attacker and self.arena and self.arena:IsParticipant(attacker)) then table.insert(candidates,{part=part}) end
	end
	return candidates
end
local function rayParams(filter,kind,physical)
	local params=RaycastParams.new()
	params.FilterType,params.FilterDescendantsInstances=kind,filter
	params.IgnoreWater,params.RespectCanCollide=true,physical
	return params
end

function Service:CombatRays(character,ignoredCharacter)
 if self.arena then self.arena:UpdateMotion(workspace:GetServerTimeNow()) end
	local exclude,include={character},{}
	local caster=Players:GetPlayerFromCharacter(character)
	local arenaShot=caster and self.arena and self.arena:IsParticipant(caster)
	if ignoredCharacter then table.insert(exclude,ignoredCharacter) end
	for _,player in Players:GetPlayers() do
		local other=player.Character
		if other and other~=character then
			table.insert(exclude,other)
			if other~=ignoredCharacter and not arenaShot then table.insert(include,other) end
		end
	end
	for part,r in self.targets.records do
		if r.arenaOnly and arenaShot and r.health>0 and part.Parent then table.insert(include,part) end
	end
	return rayParams(exclude,Enum.RaycastFilterType.Exclude,true), rayParams(include,Enum.RaycastFilterType.Include,false)
end

local function cast(origin,destination,cover,bodies)
	local delta=destination-origin
	if delta.Magnitude<=.01 then return nil end
	-- Decorative parts do not stop a shot. Noncollidable avatar limbs still count as hits.
	local solid=workspace:Raycast(origin,delta,cover)
	local body=workspace:Raycast(origin,delta,bodies)
	return if body and (not solid or body.Distance<solid.Distance) then body else solid
end
function Service:Matches(candidate,instance)
	return instance==candidate.part or (candidate.character and instance:IsDescendantOf(candidate.character))
end
function Service:Hit(player,candidate,damage)
	if candidate.player then
		if candidate.player==player or candidate.player:GetAttribute("VerityBattleActive") or player:GetAttribute("VerityBattleActive") then return 0 end
		local character,root,humanoid=self:Character(candidate.player)
		if not root or character~=candidate.character or self:IsSafe(candidate.player,root) then return 0 end
		local shield=(candidate.player:GetAttribute("VerityShieldUntil") or 0)>workspace:GetServerTimeNow()
		local before=humanoid.Health
		humanoid:TakeDamage(damage*(if shield then .25 else 1))
		return math.max(0,before-humanoid.Health)
	end
	return self.targets:Damage(candidate.part,damage,player.UserId)
end
function Service:Attack(player,item,id,character,root,direction)
 if self.adventures then
  local target=self.adventures:TryLaser(player,item,character,root,direction)
  if target then
   local head=character:FindFirstChild("Head")
   self.remote:FireAllClients({kind="Attack",ownerUserId=player.UserId,itemId=id,origin=if head then head.Position else root.Position,points={target},duration=item.Duration or .8})
   return true
  end
 end
 if self.secrets then
  local target=self.secrets:TryLaser(player,item,character,root,direction)
  if target then
   local head=character:FindFirstChild("Head")
   self.remote:FireAllClients({kind="Attack",ownerUserId=player.UserId,itemId=id,
    origin=if head then head.Position else root.Position,points={target},duration=item.Duration or .8})
   return true -- mechanism interaction emits no player damage or combat target reward
  end
 end
	if self:IsAttackBlocked(player,root) then
		self.remote:FireClient(player,{kind="Blocked",code="SAFE_ZONE"});return false
	end
	local head=character:FindFirstChild("Head")
	local origin=if head then head.Position else root.Position+Vector3.new(0,2,0)
	local cover,bodies=self:CombatRays(character)
	local result=cast(origin,origin+direction*item.Range,cover,bodies)
	local endpoint=if result then result.Position else origin+direction*item.Range
	local candidates=self:Candidates(player,not self:IsInHouse(root));local primary
	for _,candidate in candidates do
		if candidate.player~=player and result and self:Matches(candidate,result.Instance) then primary=candidate;break end
	end
	-- Small aim assistance for touch/gamepad; walls still win the server raycast.
	if not primary then
		local best=.987
		for _,candidate in candidates do
			if candidate.player==player then continue end
			local delta=candidate.part.Position-origin
			if delta.Magnitude<1 or delta.Magnitude>item.Range then continue end
			local dot=direction:Dot(delta.Unit)
			if dot<=best then continue end
			local hit=cast(origin,candidate.part.Position,cover,bodies)
			if hit and self:Matches(candidate,hit.Instance) then best=dot;primary=candidate;endpoint=hit.Position end
		end
	end
	local points={endpoint};local victims={}
	if primary then table.insert(victims,primary) end
	if item.Radius then
		table.clear(victims)
		for _,candidate in candidates do
			if candidate.player==player or (candidate.part.Position-endpoint).Magnitude>item.Radius then continue end
			-- No damage through a wall: validate direct sight from the caster too.
			local hit=cast(origin,candidate.part.Position,cover,bodies)
			if hit and self:Matches(candidate,hit.Instance) then table.insert(victims,candidate) end
		end
	elseif primary and item.Chains then
		local used={[primary.part]=true};local from=primary.part.Position;local fromInstance=primary.character or primary.part
		for _=2,item.Chains do
			local nextTarget;local nearest=item.ChainRange
			local chainCover,chainBodies=self:CombatRays(character,fromInstance)
			for _,candidate in candidates do
				local distance=(candidate.part.Position-from).Magnitude
				if candidate.player==player or used[candidate.part] or distance>nearest then continue end
				local hit=cast(from+Vector3.new(0,2,0),candidate.part.Position,chainCover,chainBodies)
				-- Check from the owner as well; avoids chaining through cover.
				local ownerHit=cast(origin,candidate.part.Position,cover,bodies)
				if ownerHit and self:Matches(candidate,ownerHit.Instance) and (not hit or self:Matches(candidate,hit.Instance)) then
					nextTarget=candidate;nearest=distance
				end
			end
			if not nextTarget then break end
			used[nextTarget.part]=true;table.insert(victims,nextTarget);from=nextTarget.part.Position
			fromInstance=nextTarget.character or nextTarget.part;table.insert(points,from)
		end
	end
	local token={};self.attacks[player]=token
	local dealt=0
	self.remote:FireAllClients({kind="Attack",ownerUserId=player.UserId,itemId=id,origin=origin,points=points,duration=item.Duration or .5})
	local ticks=if item.Action=="laser" then 3 else 1
	for tick=1,ticks do
		task.delay(.16+(tick-1)*.2,function()
			local profile=self.data:Get(player.UserId)
			local liveCharacter,liveRoot=self:Character(player)
			local equipped
			if profile then local _;_,equipped=self:Equipped("Attack",profile) end
			if self.attacks[player]~=token or liveCharacter~=character or not liveRoot or equipped~=id or self:IsAttackBlocked(player,liveRoot) then return end
			local liveHead=liveCharacter:FindFirstChild("Head")
			local currentOrigin=if liveHead then liveHead.Position else liveRoot.Position+Vector3.new(0,2,0)
			local liveCover,liveBodies=self:CombatRays(liveCharacter)
			for index,candidate in victims do
				if not candidate.part.Parent or (candidate.player and self:IsInHouse(liveRoot)) then continue end
				local delta=candidate.part.Position-liveRoot.Position
				if delta.Magnitude>item.Range+(item.ChainRange or item.Radius or 0) then continue end
				-- Recheck cover on each laser tick, including newly closed doors.
				local hit=cast(currentOrigin,candidate.part.Position,liveCover,liveBodies)
				if hit and self:Matches(candidate,hit.Instance) then
					dealt+=self:Hit(player,candidate,item.Damage/ticks*(if item.Chains then .8^(index-1) else 1))
				end
			end
			if tick==ticks and self.attacks[player]==token then
				self.attacks[player]=nil;player:SetAttribute("VerityAttackUntil",nil)
				self.remote:FireClient(player,{kind="CombatResult",damage=dealt})
			end
		end)
	end
	return true
end

-- Sustain the short dash against humanoid ground friction; use a body sweep,
-- not the attack ray, so a wall limits travel instead of cancelling every dash.
function Service:DashVelocity(character,root,item)
 local facing=root.CFrame.LookVector
 local direction=Vector3.new(facing.X,0,facing.Z)
 if direction.Magnitude<.01 then return nil end
 direction=direction.Unit
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 params.FilterDescendantsInstances={character};params.RespectCanCollide=true;params.IgnoreWater=true
 local distance=item.Power*item.Duration
 local size=Vector3.new(root.Size.X*.9,root.Size.Y*.8,root.Size.Z*.9)
 local hit=workspace:Blockcast(root.CFrame,size,direction*distance,params)
 if hit then distance=math.min(distance,math.max(0,hit.Distance-.4)) end
 if distance<=.05 then return nil end
 return direction*math.min(item.Power,distance/item.Duration)
end
function Service:Drive(current,root,velocity,plane)
 local attachment=Instance.new("Attachment");attachment.Name=if plane then "VerityDash" else "VerityFlight"
 attachment.Parent=root;current.attachment=attachment
 local drive=Instance.new("LinearVelocity");drive.Attachment0=attachment;drive.RelativeTo=Enum.ActuatorRelativeTo.World
 if plane then
  drive.VelocityConstraintMode=Enum.VelocityConstraintMode.Plane
  drive.PrimaryTangentAxis=Vector3.xAxis;drive.SecondaryTangentAxis=Vector3.zAxis
  drive.PlaneVelocity=Vector2.new(velocity.X,velocity.Z)
 else
  drive.VelocityConstraintMode=Enum.VelocityConstraintMode.Vector;drive.VectorVelocity=velocity
 end
 drive.ForceLimitsEnabled=true;drive.MaxForce=root.AssemblyMass*1800;drive.Parent=attachment;current.velocity=drive
end
function Service:WatchFlightInput(player,current)
 current.lastSteerAt=workspace:GetServerTimeNow()
 if current.steerWatching then return end
 current.steerWatching=true
 local function check()
  if self.active[player]~=current or not current.velocity then current.steerWatching=false;return end
  local remaining=.35-(workspace:GetServerTimeNow()-current.lastSteerAt)
  if remaining>0 then task.delay(remaining,check);return end
  current.steerWatching=false
  -- A stale input timer must never stop the guided takeoff/landing transition.
  if not current.phase and current.velocity.Parent then current.velocity.VectorVelocity=Vector3.zero end
 end
 task.delay(.35,check)
end
-- Landing considers physical surfaces only; visual companion parts never support the rider.
function Service:RideLanding(current,position)
 local ray=RaycastParams.new();ray.FilterDescendantsInstances={current.character};ray.RespectCanCollide=true
 local overlap=OverlapParams.new();overlap.FilterDescendantsInstances={current.character};overlap.RespectCanCollide=true
 for _,offset in {Vector3.zero,Vector3.new(6,0,0),Vector3.new(-6,0,0),Vector3.new(0,0,6),Vector3.new(0,0,-6)} do
  local hit=workspace:Raycast(position+offset+Vector3.new(0,2,0),Vector3.new(0,-220,0),ray)
  if hit and hit.Normal.Y>.65 then
   local target=hit.Position+Vector3.new(0,current.groundOffset,0)
   if #workspace:GetPartBoundsInBox(CFrame.new(target),Vector3.new(4,current.groundOffset*2-.2,4),overlap)==0 then return target end
  end
 end
 return nil
end
-- One cancellable transition uses the existing force controller, never a CFrame tween.
function Service:RideTransition(player,current,target,phase,complete)
 if current.transition then current.transition:Disconnect() end
 current.phase=phase;current.velocity.VectorVelocity=Vector3.zero
 local hum=current.character:FindFirstChildOfClass("Humanoid");if hum then hum.WalkSpeed=0 end
 player:SetAttribute("VerityRideY0",current.root.Position.Y);player:SetAttribute("VerityRideY1",target.Y)
 player:SetAttribute("VerityRidePhase",phase)
 local started=workspace:GetServerTimeNow()
 current.transition=RunService.Heartbeat:Connect(function(dt)
  if self.active[player]~=current then if current.transition then current.transition:Disconnect();current.transition=nil end;return end
  local character,root=self:Character(player)
  if character~=current.character then self:Stop(player);return end
  local delta=target-root.Position
  if delta.Magnitude<.45 then
   current.transition:Disconnect();current.transition=nil;current.phase=nil
   current.velocity.VectorVelocity=Vector3.zero
   complete();return
  end
  if workspace:GetServerTimeNow()-started>Ride.TransitionTimeout then self:Stop(player);return end
  local speed=if phase=="Takeoff" then Ride.TakeoffSpeed else Ride.LandingSpeed
  local desired=delta.Unit*math.min(speed,delta.Magnitude*6)
  current.velocity.VectorVelocity=current.velocity.VectorVelocity:Lerp(desired,1-math.exp(-10*math.min(dt,.1)))
 end)
end
function Service:Dismount(player,current)
 if self.active[player]~=current or current.phase=="Landing" then return end
 local _,root=self:Character(player);if not root then self:Stop(player);return end
 local target=self:RideLanding(current,root.Position) or self:RideLanding(current,current.launch)
 if not target then
  self.remote:FireClient(player,{kind="Blocked",code="RIDE_LANDING"})
  current.untilTime=workspace:GetServerTimeNow()+10;player:SetAttribute("VerityMobilityUntil",current.untilTime)
  if not current.landingRetry then
   current.landingRetry=true
   task.delay(10,function()
    current.landingRetry=nil
    if self.active[player]==current then self:Dismount(player,current) end
   end)
  end
  return
 end
 -- Remove the orb collider before descending; otherwise it holds the rider above the ground.
 if current.hull then current.hull:Destroy();current.hull=nil end
 local ray=RaycastParams.new();ray.FilterDescendantsInstances={current.character};ray.RespectCanCollide=true
 local delta=target-root.Position
 if delta.Magnitude>120 or delta.Magnitude<.45 or workspace:Blockcast(root.CFrame,Vector3.new(4,5,4),delta,ray) then
  -- Obstructed paths use the validated emergency return, never a tween through a wall.
  self:Stop(player);return
 end
 current.untilTime=workspace:GetServerTimeNow()+Ride.TransitionTimeout
 player:SetAttribute("VerityMobilityUntil",current.untilTime)
 self:RideTransition(player,current,target,"Landing",function() self:Stop(player) end)
end
function Service:Ride(player,profile,now)
 local current=self.active[player]
 if current and current.ride then
  if not current.phase then self:Dismount(player,current) end;return
 end
 if profile.Data.VerityLevel<Ride.MinLevel then return end
 if player:GetAttribute("VerityParkourStep") then self.remote:FireClient(player,{kind="Blocked",code="RIDE_PARKOUR"});return end
 local character,root,humanoid=self:Character(player)
 if not root or not root:CanSetNetworkOwnership() then return end
 local scale=Levels.getVerityScale(profile.Data.VerityLevel)
 local diameter=1.7*scale
 local height=diameter+Ride.SeatOffset
 local ray=RaycastParams.new();ray.FilterDescendantsInstances={character};ray.RespectCanCollide=true
 -- Check the full takeoff corridor as well as the future ball volume.
 if workspace:Blockcast(root.CFrame,Vector3.new(4,5,4),Vector3.new(0,height,0),ray) then self.remote:FireClient(player,{kind="Blocked",code="RIDE_SPACE"});return end
 local overlap=OverlapParams.new();overlap.FilterDescendantsInstances={character};overlap.RespectCanCollide=true
 local centre=root.Position+Vector3.new(0,diameter/2,0)
 if #workspace:GetPartBoundsInRadius(centre,diameter/2+.2,overlap)>0 then self.remote:FireClient(player,{kind="Blocked",code="RIDE_SPACE"});return end
 self:Stop(player,false)
 root:SetNetworkOwner(nil)
 current={character=character,root=root,id="verity_ride",ride=true,flight=true,ownsPhysics=true,
  level=profile.Data.VerityLevel,speed=Ride.Speed,untilTime=now+Ride.Duration,launch=root.Position,groundOffset=math.max(3,humanoid.HipHeight+root.Size.Y/2)}
 self.active[player]=current
 local hull=Instance.new("Part");hull.Name="VerityRideHull";hull.Shape=Enum.PartType.Ball
 hull.Size=Vector3.one*diameter;hull.Transparency=1;hull.Massless=true;hull.CanTouch=false;hull.CanQuery=false;hull.CanCollide=false
 hull.CFrame=root.CFrame*CFrame.new(0,-diameter/2-Ride.SeatOffset,0);hull.Parent=character
 local weld=Instance.new("WeldConstraint");weld.Part0=root;weld.Part1=hull;weld.Parent=hull;current.hull=hull
 root.AssemblyLinearVelocity=Vector3.zero
 humanoid.WalkSpeed=Ride.Speed;humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
 player:SetAttribute("VerityRiding",true);player:SetAttribute("VerityMobilityUntil",current.untilTime)
 self:Drive(current,root,Vector3.zero,false)
 self:RideTransition(player,current,current.launch+Vector3.new(0,height,0),"Takeoff",function()
  if current.hull then current.hull.CanCollide=true end
  humanoid.WalkSpeed=Ride.Speed;player:SetAttribute("VerityRidePhase","Cruise")
  self:WatchFlightInput(player,current)
 end)
 task.delay(Ride.Duration,function() if self.active[player]==current then self:Dismount(player,current) end end)
end
function Service:Activate(player,slot,direction)
	local now=workspace:GetServerTimeNow()
 if slot=="Steer" then
  local reason=self:BlockReason(player,"Mobility")
  if reason and reason~="RIDING_POWER" then self:Stop(player);return end
		if now-(self.steering[player] or -math.huge)<.08 then return end
		self.steering[player]=now
		local current=self.active[player]
		if not current or current.phase or not current.flight or not current.velocity or now>=current.untilTime or player.Character~=current.character then return end
		if typeof(direction)~="Vector3" or not Numeric.isFinite(direction.X) or not Numeric.isFinite(direction.Y)
			or not Numeric.isFinite(direction.Z) or direction.Magnitude>1.1 then return end
		local _,root=self:Character(player);if not root then return end
		local vertical=if root.Position.Y>80 then math.min(0,direction.Y) else direction.Y
		current.velocity.VectorVelocity=Vector3.new(direction.X*current.speed,vertical*22,direction.Z*current.speed)
  self:WatchFlightInput(player,current)
		return
	end
	if now-(self.requests[player] or -math.huge)<.15 then return end
	self.requests[player]=now
	if slot~="Mobility" and slot~="Attack" and slot~="Ride" then return end
	local reason=self:BlockReason(player,slot)
 if reason then self.remote:FireClient(player,{kind="Blocked",code=reason});return end
 local profile=self.data:Get(player.UserId)
	if not profile or not self.state.sessions[player.UserId] or not profile.Data.VerityUnlocked then return end
 if slot=="Ride" and player:GetAttribute("VerityBattleActive") then return end
 if slot=="Ride" then self:Ride(player,profile,now);return end
 if self.active[player] and self.active[player].ride and slot=="Mobility" then return end
 local item,id=self:Equipped(slot,profile)
	if not item then return end
	local character,root,humanoid=self:Character(player)
	if not root then return end
	local cooldowns=self.cooldowns[player] or {};self.cooldowns[player]=cooldowns
	if now<(cooldowns[slot] or 0) then return end
	if slot=="Attack" then
		if typeof(direction)~="Vector3" or not Numeric.isFinite(direction.X) or not Numeric.isFinite(direction.Y)
			or not Numeric.isFinite(direction.Z) or direction.Magnitude<.1 or direction.Magnitude>2 then return end
		if not self:Attack(player,item,id,character,root,direction.Unit) then return end
		cooldowns[slot]=now+item.Cooldown;player:SetAttribute("VerityAttackReadyAt",cooldowns[slot])
  player:SetAttribute("VerityAttackUntil",now+(if item.Action=="laser" then .56 else .16));return
	end
	local action=item.MobilityAction or item.Action
	local duration=if item.MobilityAction then item.FlightDuration else item.Duration
 local dashVelocity=if action=="dash" then self:DashVelocity(character,root,item) else nil
 if action=="dash" and not dashVelocity then
  self.remote:FireClient(player,{kind="Blocked",code="OBSTACLE"});return
 end
 local usesPhysics=action=="dash" or action=="leap" or action=="flight"
 if usesPhysics and not root:CanSetNetworkOwnership() then
  self.remote:FireClient(player,{kind="Blocked",code="MOVEMENT_UNAVAILABLE"});return
 end
 self:Stop(player,false)
 if usesPhysics then root:SetNetworkOwner(nil) end
	cooldowns[slot]=now+(item.FlightCooldown or item.Cooldown)
	player:SetAttribute("VerityAbilityReadyAt",cooldowns[slot])
	player:SetAttribute("VerityMobilityUntil",now+duration)
	player:SetAttribute("VerityMobilityColor",item.Color)
	local current={character=character,id=id,root=root,untilTime=now+duration,ownsPhysics=usesPhysics};self.active[player]=current
	if action=="shield" then player:SetAttribute("VerityShieldUntil",now+duration)
	elseif action=="dash" then
  current.dash=true;current.speed=dashVelocity.Magnitude;humanoid.WalkSpeed=current.speed
  self:Drive(current,root,dashVelocity,true)
	elseif action=="leap" then
		-- ChangeState must run on the simulator that owns this assembly.
		-- Give replication one physics step before launching, then return control.
		humanoid.Jump=false;humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		task.spawn(function()
			RunService.Heartbeat:Wait()
			if self.active[player]~=current or player.Character~=character or humanoid.Health<=0
				or not root:IsDescendantOf(workspace) or not humanoid.Parent or root.Anchored or humanoid.SeatPart then return end
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			-- Reach the launch speed even while falling; don't add to an upward jump.
			local deltaY=math.max(0,item.Power-root.AssemblyLinearVelocity.Y)
			root:ApplyImpulse(Vector3.yAxis*root.AssemblyMass*deltaY)
			task.delay(.2,function()
				if self.active[player]~=current or not root:IsDescendantOf(workspace) then return end
				if root:CanSetNetworkOwnership() then root:SetNetworkOwnershipAuto();current.ownsPhysics=false end
			end)
		end)
	elseif action=="sprint" then current.speed=item.Power;humanoid.WalkSpeed=current.speed
	elseif action=="flight" then
		current.speed=item.FlightSpeed or item.Power;humanoid.WalkSpeed=current.speed
  current.flight=true
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
  self:Drive(current,root,Vector3.new(0,8,0),false)
  self:WatchFlightInput(player,current)
	end
	if self.adventures then self.adventures:ObserveMobility(player,item,action,duration) end
 self.remote:FireAllClients({kind="Mobility",ownerUserId=player.UserId,itemId=id,origin=root.Position,duration=duration,endsAt=now+duration})
	task.delay(duration,function() if self.active[player]==current then self:Stop(player,false) end end)
end
return Service
