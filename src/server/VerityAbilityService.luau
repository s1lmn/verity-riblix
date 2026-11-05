--!nonstrict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Shared=ReplicatedStorage.Shared
local Forms=require(Shared.VerityAbilities)
local Catalog=require(Shared.AbilityCatalog)
local Numeric=require(Shared.Numeric)
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
function Service:IsSafe(player,root)
	if workspace:GetServerTimeNow()<(player:GetAttribute("VerityProtectedUntil") or 0) then return true end
	if player.Character and player.Character:FindFirstChildOfClass("ForceField") then return true end
	-- All physical house footprints are sanctuaries, even before their walls are built.
	for _,anchors in self.world.anchors do
		local house=anchors.WorkshopHouse
		if not house then continue end
		local p=house:GetPivot():PointToObjectSpace(root.Position)
		if p.Y>=-2 and p.Y<=34 and ((math.abs(p.X)<18 and p.Z>-16 and p.Z<18)
			or (math.abs(p.X)<27 and p.Z>=-57 and p.Z<=-14)) then return true end
	end
	return false
end
function Service:Refresh(player,character,snapshot)
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or not snapshot then return end
	local current=self.active[player]
	local profile=self.data:Get(player.UserId)
	local equipped=profile and profile.Data.AbilitiesEquipped.Mobility
	if profile and not Catalog.Equipped(profile.Data,"Mobility",profile.HeroPassOwned) then equipped=nil end
	if current and (current.character~=character or current.id~=equipped or humanoid.Health<=0) then self:Stop(player);current=nil end
	if humanoid.Health<=0 then return end
	local form=if snapshot.VerityUnlocked then Forms.Get(snapshot.VerityLevel) else nil
	humanoid.WalkSpeed=if current and current.speed then current.speed elseif form then form.speed else 16
	humanoid.UseJumpPower=true;humanoid.JumpPower=if form then form.jump else 50
end
function Service:Stop(player,stopAttacks)
	if stopAttacks~=false then self.attacks[player]=nil end
	local current=self.active[player]
	if not current then return end
	self.active[player]=nil
	if current.attachment then current.attachment:Destroy() end
	if current.ownsPhysics and current.root:IsDescendantOf(workspace) and current.root:CanSetNetworkOwnership() then
		if current.dash then current.root.AssemblyLinearVelocity=Vector3.yAxis*current.root.AssemblyLinearVelocity.Y end
		current.root:SetNetworkOwnershipAuto()
	end
	local profile=self.data:Get(player.UserId)
	local humanoid=current.character:FindFirstChildOfClass("Humanoid")
	if humanoid and profile then humanoid.WalkSpeed=Forms.Get(profile.Data.VerityLevel).speed end
	player:SetAttribute("VerityShieldUntil",nil)
	player:SetAttribute("VerityMobilityUntil",nil)
end
function Service:Remove(player)
	self:Stop(player);self.requests[player]=nil;self.steering[player]=nil;self.cooldowns[player]=nil
end
function Service:Candidates()
	local candidates={}
	for _,player in Players:GetPlayers() do
		local character,root,humanoid=self:Character(player)
		local profile=self.data:Get(player.UserId)
		if root and profile and profile.Data.VerityUnlocked and self.state.sessions[player.UserId] and not self:IsSafe(player,root) then
			table.insert(candidates,{part=root,humanoid=humanoid,player=player,character=character})
		end
	end
	for part,r in self.targets.records do
		if r.health>0 and part.Parent then table.insert(candidates,{part=part}) end
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
	local exclude,include={character},{}
	if ignoredCharacter then table.insert(exclude,ignoredCharacter) end
	for _,player in Players:GetPlayers() do
		local other=player.Character
		if other and other~=character then
			table.insert(exclude,other)
			if other~=ignoredCharacter then table.insert(include,other) end
		end
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
		if candidate.player==player then return 0 end
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
	if self:IsSafe(player,root) then
		self.remote:FireClient(player,{kind="Blocked",code="SAFE_ZONE"});return false
	end
	local head=character:FindFirstChild("Head")
	local origin=if head then head.Position else root.Position+Vector3.new(0,2,0)
	local cover,bodies=self:CombatRays(character)
	local result=cast(origin,origin+direction*item.Range,cover,bodies)
	local endpoint=if result then result.Position else origin+direction*item.Range
	local candidates=self:Candidates();local primary
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
			local equipped=profile and profile.Data.AbilitiesEquipped.Attack
			if profile and not Catalog.Equipped(profile.Data,"Attack",profile.HeroPassOwned) then equipped=nil end
			if self.attacks[player]~=token or liveCharacter~=character or not liveRoot or equipped~=id or self:IsSafe(player,liveRoot) then return end
			local liveHead=liveCharacter:FindFirstChild("Head")
			local currentOrigin=if liveHead then liveHead.Position else liveRoot.Position+Vector3.new(0,2,0)
			local liveCover,liveBodies=self:CombatRays(liveCharacter)
			for index,candidate in victims do
				if not candidate.part.Parent then continue end
				local delta=candidate.part.Position-liveRoot.Position
				if delta.Magnitude>item.Range+(item.ChainRange or item.Radius or 0) then continue end
				-- Recheck cover on each laser tick, including newly closed doors.
				local hit=cast(currentOrigin,candidate.part.Position,liveCover,liveBodies)
				if hit and self:Matches(candidate,hit.Instance) then
					dealt+=self:Hit(player,candidate,item.Damage/ticks*(if item.Chains then .8^(index-1) else 1))
				end
			end
			if tick==ticks and self.attacks[player]==token then
				self.attacks[player]=nil
				self.remote:FireClient(player,{kind="CombatResult",damage=dealt})
			end
		end)
	end
	return true
end

local function addVelocity(current,name)
	local root=current.root
	local attachment=Instance.new("Attachment");attachment.Name=name;attachment.Parent=root
	local velocity=Instance.new("LinearVelocity")
	velocity.Attachment0,velocity.RelativeTo=attachment,Enum.ActuatorRelativeTo.World
	velocity.MaxForce=root.AssemblyMass*1800
	current.attachment,current.velocity=attachment,velocity
	return velocity
end

function Service:Activate(player,slot,direction)
	local now=workspace:GetServerTimeNow()
	if slot=="Steer" then
		if now-(self.steering[player] or -math.huge)<.15 then return end
		self.steering[player]=now
		local current=self.active[player]
		if not current or not current.flight or now>=current.untilTime or player.Character~=current.character then return end
		if typeof(direction)~="Vector3" or not Numeric.isFinite(direction.X) or not Numeric.isFinite(direction.Y)
			or not Numeric.isFinite(direction.Z) or direction.Magnitude>1.1 then return end
		local _,root=self:Character(player);if not root then return end
		local vertical=if root.Position.Y>80 then math.min(0,direction.Y) else direction.Y
		current.velocity.VectorVelocity=Vector3.new(direction.X*current.speed,vertical*22,direction.Z*current.speed)
		return
	end
	if now-(self.requests[player] or -math.huge)<.15 then return end
	self.requests[player]=now
	if slot~="Mobility" and slot~="Attack" then return end
	local profile=self.data:Get(player.UserId)
	if not profile or not self.state.sessions[player.UserId] or not profile.Data.VerityUnlocked then return end
	local item,id=Catalog.Equipped(profile.Data,slot,profile.HeroPassOwned)
	if not item then return end
	local character,root,humanoid=self:Character(player)
	if not root then return end
	local cooldowns=self.cooldowns[player] or {};self.cooldowns[player]=cooldowns
	if now<(cooldowns[slot] or 0) then return end
	if slot=="Attack" then
		if typeof(direction)~="Vector3" or not Numeric.isFinite(direction.X) or not Numeric.isFinite(direction.Y)
			or not Numeric.isFinite(direction.Z) or direction.Magnitude<.1 or direction.Magnitude>2 then return end
		if not self:Attack(player,item,id,character,root,direction.Unit) then return end
		cooldowns[slot]=now+item.Cooldown;player:SetAttribute("VerityAttackReadyAt",cooldowns[slot]);return
	end
	local action=item.MobilityAction or item.Action
	local duration=if item.MobilityAction then item.FlightDuration else item.Duration
	local usesPhysics=action=="dash" or action=="leap" or action=="flight"
	if usesPhysics and not root:CanSetNetworkOwnership() then return end
	local dashDirection
	if action=="dash" then
		local facing=root.CFrame.LookVector*Vector3.new(1,0,1)
		if facing.Magnitude<.01 then return end
		dashDirection=facing.Unit
		local params=rayParams({character},Enum.RaycastFilterType.Exclude,true)
		local hit=workspace:Spherecast(root.Position,.95,dashDirection*(item.Power*duration+1.25),params)
		if hit then
			if hit.Distance<3 then self.remote:FireClient(player,{kind="Blocked",code="OBSTACLE"});return end
			duration=math.min(duration,(hit.Distance-1.25)/item.Power)
		end
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
		current.dash=true
		local velocity=addVelocity(current,"VerityDash")
		velocity.VelocityConstraintMode=Enum.VelocityConstraintMode.Plane
		velocity.PrimaryTangentAxis,velocity.SecondaryTangentAxis=Vector3.xAxis,Vector3.zAxis
		velocity.PlaneVelocity=Vector2.new(dashDirection.X,dashDirection.Z)*item.Power
		velocity.Parent=current.attachment
	elseif action=="leap" then
		local velocity=root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity=Vector3.new(velocity.X,item.Power,velocity.Z)
	elseif action=="sprint" then current.speed=item.Power;humanoid.WalkSpeed=current.speed
	elseif action=="flight" then
		current.flight=true;current.speed=item.FlightSpeed or item.Power;humanoid.WalkSpeed=current.speed
		local velocity=addVelocity(current,"VerityFlight")
		velocity.VectorVelocity=Vector3.new(0,8,0)
		velocity.Parent=current.attachment
	end
	self.remote:FireAllClients({kind="Mobility",ownerUserId=player.UserId,itemId=id,origin=root.Position,duration=duration,endsAt=now+duration})
	task.delay(duration,function() if self.active[player]==current then self:Stop(player,false) end end)
end
return Service
