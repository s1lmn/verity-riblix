--!nonstrict
local RunService=game:GetService("RunService")
local ContentProvider=game:GetService("ContentProvider")
local CollectionService=game:GetService("CollectionService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage:WaitForChild("Shared",10)
assert(Shared,"Shared modules missing")
local Levels=require(Shared.LevelConfig)
local Profile=require(Shared.VerityAnimationProfile)
local Art=require(Shared.VerityCompanionConfig)
local FaceUI=require(script.Parent.VerityFaceUI)
local Personality=require(Shared.VerityPersonality)
local Version=require(Shared.ProjectVersion)
local Follow=require(Shared.CompanionConfig)
local Ride=require(Shared.VerityRideConfig)
local Race=require(Shared.VerityRaceConfig)
local Cosmetics=require(script.Parent.CosmeticFactory)
local Catalog=require(Shared.CosmeticCatalog)
local Players=game:GetService("Players")
local Factory=require(script.Parent.VerityFactory)
local VFX=require(script.Parent.VerityVFXService)
local Client=game:GetService("Players").LocalPlayer
local ClientModules=if Client then Client:WaitForChild("PlayerScripts",10):WaitForChild("VerityClient",10)
	else game:GetService("StarterPlayer").StarterPlayerScripts:WaitForChild("VerityClient",10)
local Cleanup=require(ClientModules.Cleanup)
local Ledger=require(ClientModules.EventLedger)
local Locale=if Client then require(ClientModules.Locale) else nil
local SpawnProfile=require(Shared.VeritySpawnProfile)
local SpawnVFX=require(script.Parent.VeritySpawnVFX)
local visibility
local Controller={}
Controller.__index=Controller

local function integer(value,minimum,maximum)
	return type(value)=="number" and value==value and value%1==0 and value>=minimum and value<=maximum
end
local function key(owner,plot) return tostring(owner)..":"..tostring(plot) end

function Controller.new(settings,options)
	local editPreview=options and options.editPreview==true
	assert(RunService:IsClient() or (editPreview and RunService:IsStudio() and not RunService:IsRunning()),"Visuals require a client; explicit Studio edit preview is the only exception")
	local self=setmetatable({cleanup=Cleanup.new(),settings=settings,records={},byOwner={},pending={},houseBounds={},dead=false,effects=VFX.new(),
		Emotion=Instance.new("BindableEvent"),Started=Instance.new("BindableEvent"),Completed=Instance.new("BindableEvent"),elapsed=0,completed=0},Controller)
	self.spawn=self.cleanup:Add(SpawnVFX.new(settings));self.SpawnStopped=self.spawn.Stopped
	self.cleanup:Add(self.Emotion);self.cleanup:Add(self.effects);self.cleanup:Add(self.Started);self.cleanup:Add(self.Completed)
	self.cleanup:Add(CollectionService:GetInstanceAddedSignal(Profile.Tag):Connect(function(model) self:Register(model) end))
	self.cleanup:Add(CollectionService:GetInstanceRemovedSignal(Profile.Tag):Connect(function(model) self:Remove(model) end))
	for _,model in CollectionService:GetTagged(Profile.Tag) do self:Register(model) end
	self.cleanup:Add(settings.Changed.Event:Connect(function(values)
		if not values.ReducedMotion then return end
		for _,record in self.records do if record.active then self:Finish(record,os.clock()) end end
	end))
	if not editPreview then
		local assets=ReplicatedStorage:FindFirstChild("VerityCompanionAssets")
		if assets then
			local images={}
			for _, instance in assets:GetDescendants() do
				if instance:IsA("ImageLabel") then table.insert(images,instance) end
			end
			task.spawn(function()
                local ok,err=pcall(function()
                    ContentProvider:PreloadAsync(images,function(id,status)
                        if status~=Enum.AssetFetchStatus.Success then warn("[Verity face] Image unavailable: "..id.." / "..status.Name.."; using loading face") end
                    end)
                end)
                if not ok then warn("[Verity face] Preload failed: "..tostring(err)) end
            end)
		end
		self.cleanup:Add(RunService.RenderStepped:Connect(function(dt)
			self:Tick(os.clock(),math.min(dt,.1))
		end))
	end
	return self
end

function Controller:Register(model,attempt)
	if self.dead or self.records[model] or not model:IsA("Model") or not model:IsDescendantOf(workspace) then return end
	local owner,plot,level,revision=model:GetAttribute("OwnerUserId"),model:GetAttribute("PlotId"),model:GetAttribute("VerityLevel"),model:GetAttribute("StateRevision")
	if not model.PrimaryPart or not integer(owner,if RunService:IsStudio() then -2^53+1 else 1,2^53-1) or owner==0 or not integer(plot,1,128) or not integer(level,1,100)
		or not integer(revision,0,2^53-1) or model:GetAttribute("PresentationVersion")~=Version.Presentation then
		attempt=attempt or 0
		if attempt>=20 then warn("[Verity] Incomplete or incompatible tagged model: "..model.Name);return end
		local ticket={}
		self.pending[model]=ticket
		task.delay(0.1,function()
			if not self.dead and self.pending[model]==ticket and CollectionService:HasTag(model,Profile.Tag) then
				self.pending[model]=nil
				self:Register(model,attempt+1)
			end
		end)
		return
	end
	self.pending[model]=nil
	local identity=key(owner,plot)
	if self.byOwner[identity] then self:Remove(self.byOwner[identity].model) end
	local anchor=model:GetAttribute("VerityOrigin")
	local record={model=model,owner=owner,plot=plot,key=identity,origin=if typeof(anchor)=="CFrame" then anchor else model:GetPivot(),level=level,revision=revision,
		ledger=Ledger.new(),tints={},cleanup=Cleanup.new(),idleStart=os.clock(),baseYaw=0,lastYaw=0,lastLift=0,completed=0}
	for _,p in model:GetDescendants() do if p:IsA("BasePart") and p:GetAttribute("VerityTint")~=nil then table.insert(record.tints,p) end end
	record.ledger:Seed(revision,level)
	self.records[model],self.byOwner[identity]=record,record
	self:Apply(record,Levels.getVerityScale(level),0,0,Factory.Color(level),level)
	-- Identity changes are lifecycle changes, never a way to animate another owner's purchase.
	for _,attribute in {"OwnerUserId","PlotId"} do
		record.cleanup:Add(model:GetAttributeChangedSignal(attribute):Connect(function() self:Remove(model);self:Register(model) end))
	end

 local function refreshCosmetics()
  local pivot,savedScale=model:GetPivot(),model:GetScale()
  model:ScaleTo(1);model:PivotTo(CFrame.identity)
  local equipped={};for slot in Catalog.Slots do local id=model:GetAttribute("Cosmetic_"..slot);if Catalog.Items[id] then equipped[slot]=id end end
  Cosmetics.Apply(model,equipped)
  record.visibility,record.appliedVisibility=nil,nil
  Factory.SetStage(model,record.stageLevel or record.level)
  model:ScaleTo(savedScale);model:PivotTo(pivot)
 end
 for slot in Catalog.Slots do record.cleanup:Add(model:GetAttributeChangedSignal("Cosmetic_"..slot):Connect(refreshCosmetics)) end
 refreshCosmetics()
 -- Existing record owns this observer; initial/restored idle faces make no sound.
 record.cleanup:Add(model:GetAttributeChangedSignal("EmotionUntil"):Connect(function()
  if Client and record.owner==Client.UserId and not record.active
   and (model:GetAttribute("EmotionUntil") or 0)>workspace:GetServerTimeNow() then
   self.Emotion:Fire(model:GetAttribute("Emotion"))
  end
 end))
 local reveal=self.spawn.active
 if reveal and reveal.event.ownerUserId==record.owner and reveal.event.plotId==record.plot then
  reveal.boundModel=model;record.spawnCover=reveal.pose and reveal.pose.cover or 1
  visibility(record,0)
 end
 return record
end

function Controller:Apply(record,scale,lift,yaw,color,level)
	local model=record.model
	if not model:IsDescendantOf(workspace) then return end
	if math.abs(model:GetScale()-scale)>0.000001 then model:ScaleTo(scale) end
	local lifted=record.origin*CFrame.new(0,lift+(record.lifeLift or 0)*scale,0)
 local pose=lifted*CFrame.Angles(0,yaw,0)*CFrame.Angles(record.lifePitch or 0,0,record.lifeRoll or 0)
 local camera=workspace.CurrentCamera
 if record.riding then pose=record.origin end
 if record.racing then pose=record.origin*CFrame.new(0,lift+(record.lifeLift or 0)*scale,0)*CFrame.Angles(record.lifePitch or 0,0,record.lifeRoll or 0)end
 if model:GetAttribute("FollowOwner") and camera and not record.riding and not record.racing then
  -- Rotate around the ball's centre, not its bottom pivot. Giant forms can
  -- look down toward a ground-level camera without shifting into that camera.
  local center=lifted.Position+Vector3.new(0,.85*scale,0)
  local aiming=not record.active and record.abilityAim and (record.abilityAimUntil or 0)>os.clock()
  local target=if aiming then record.abilityAim else camera.CFrame.Position
  if (target-center).Magnitude>.01 then
   local direction=(target-center).Unit
   local up=if math.abs(direction:Dot(Vector3.yAxis))>.98 then record.origin.LookVector else Vector3.yAxis
   local now=os.clock()
   local facing=CFrame.lookAt(center,target,up).Rotation
   local blend=1-math.exp(-Art.FacingSpeed*math.clamp(now-(record.faceFacingAt or now-1/30),0,.1))
   record.faceFacing=if not record.faceFacing or record.teleported then facing else record.faceFacing:Lerp(facing,blend)
   record.faceFacingAt=now
   pose=CFrame.new(center)*record.faceFacing*CFrame.Angles(record.lifePitch or 0,yaw,record.lifeRoll or 0)*CFrame.new(0,-.85*scale,0)
  end
 end
 model:PivotTo(pose)
	for _,p in record.tints do if p.Parent and p:GetAttribute("VerityTint")~=false then p.Color=color end end
	if record.stageLevel~=level then
		Factory.SetStage(model,level)
		local label=model.PrimaryPart:FindFirstChild("LevelLabel")
		if label and label:FindFirstChild("Title") then
			if Locale then Locale.Bind(label.Title, "VERITY • LVL %d", level)
			else label.Title.Text="VERITY • УР. "..level end
		end
		record.stageLevel=level
	end
	local label=model.PrimaryPart:FindFirstChild("LevelLabel")
	if label then label.StudsOffsetWorldSpace=Vector3.new(0,2.05*scale+0.5,0) end
	record.lastYaw,record.lastLift=yaw,lift
end

-- The existing model controller owns attack facing as well as following.
function Controller:AimAbility(owner,target,duration)
 for _,record in self.records do
  if record.owner==owner and not record.active then
   record.abilityAim=target;record.abilityAimUntil=os.clock()+math.min(duration,1.5)
  end
 end
end

-- Local admin preview stays in the existing renderer; no server state or saved attributes change.
function Controller:AdminRecord()
 if not Client or not Client:GetAttribute("VerityAdmin") then return nil end
 for _,record in self.records do if record.owner==Client.UserId then return record end end
 return nil
end
function Controller:AdminLevel(level,animate)
 local record=self:AdminRecord()
 if not record or level~=nil and not integer(level,1,100) then return nil end
 if record.active and not record.active.event.preview then return nil end
 if record.active then self.effects:CancelUpgrade(record.model);record.active=nil end
 record.adminLevel=level;record.adminEmotion=nil;record.growthCover=0
 self.effects:HideGrowth()
 if animate and level and level>1 then
  local event={preview=true,eventId="admin_"..tostring(os.clock()),ownerUserId=record.owner,plotId=record.plot,
   oldLevel=level-1,newLevel=level,oldScale=Levels.getVerityScale(level-1),newScale=Levels.getVerityScale(level),stateRevision=record.revision}
  record.active={event=event,started=os.clock(),yaw=record.lastYaw,lift=record.lastLift,burst=false}
  self.effects:BeginUpgrade(record.model,record.model:GetPivot(),event.newScale,level,os.clock(),Factory.Color(level))
  return event
 end
 return true
end
function Controller:AdminClear()
 if not Client then return end
 for _,record in self.records do
  if record.owner==Client.UserId then
   record.adminLevel=nil;record.adminEmotion=nil;record.growthCover=0
   if record.active and record.active.event.preview then record.active=nil;self.effects:CancelUpgrade(record.model) end
  end
 end
 self.effects:HideGrowth()
end
function Controller:AdminEmotion(emotion)
 local record=self:AdminRecord()
 if not record or not Art.Textures[emotion] then return false end
 record.adminEmotion=emotion;record.adminEmotionUntil=os.clock()+4
 record.appliedVisibility=nil
 return true
end

function Controller:BeginSpawn(event)
 if not Client or event.ownerUserId~=Client.UserId or not integer(event.plotId,1,128)
  or type(event.eventId)~="string" or #event.eventId>128 or event.kind~="VeritySpawned" then return false end
 -- Player attribute survives UI recreation. Existing saves never emit a new spawn event.
 if Client:GetAttribute("VerityBoxRevealSeen")==event.eventId then return false end
 local plots=workspace:FindFirstChild("CorePlots")
 local plot=plots and plots:FindFirstChild(string.format("Plot_%02d",event.plotId))
 local box=plot and plot:FindFirstChild("CoreDeliveryBox")
 if not box or not box:IsA("BasePart") then return false end
 if not self.spawn:Begin(event,box,os.clock()) then return false end
 Client:SetAttribute("VerityBoxRevealSeen",event.eventId)
 local record=self.byOwner[key(event.ownerUserId,event.plotId)]
 if record then
  self.spawn.active.boundModel=record.model;record.spawnCover=1;visibility(record,record.visibility or 0)
 end
 return true
end

function Controller:HandleWorld(event)
	if type(event)~="table" or event.kind~="VerityLevelChanged" then return false end
	if not integer(event.oldLevel,1,99) or event.newLevel~=event.oldLevel+1
		or not integer(event.stateRevision,0,2^53-1) or type(event.eventId)~="string" or #event.eventId>128
		or not integer(event.ownerUserId,if RunService:IsStudio() then -2^53+1 else 1,2^53-1) or event.ownerUserId==0 or not integer(event.plotId,1,128) then return false end
	if type(event.oldScale)~="number" or type(event.newScale)~="number" or event.oldScale~=event.oldScale or event.newScale~=event.newScale
		or math.abs(event.oldScale-Levels.getVerityScale(event.oldLevel))>0.000001
		or math.abs(event.newScale-Levels.getVerityScale(event.newLevel))>0.000001 then return false end
	local record=self.byOwner[key(event.ownerUserId,event.plotId)]
	if not record then return false end -- Streaming-in applies current attributes, without old celebrations.
	record.adminLevel=nil;record.adminEmotion=nil
 if record.active and record.active.event.preview then record.active=nil;self.effects:CancelUpgrade(record.model) end
 record.ledger:Push(event)
 return true
end

function Controller:Finish(record,now)
	local active=record.active
	if not active then return end
	local event=active.event
 if event.preview then
  record.adminLevel=event.newLevel;record.active=nil;record.growthCover=0
  self:Apply(record,event.newScale,0,record.baseYaw,Factory.Color(event.newLevel),event.newLevel)
  return
 end
	record.level,record.revision,record.idleStart=event.newLevel,event.stateRevision,now
	-- Full turns belong to Profile.Sample during the upgrade only. Carrying
 -- the idle heading forward could leave the face turned away after level 100.
 record.baseYaw=0
	local lift=if Profile.Stage(record.level)>=2 and not self.settings.values.ReducedMotion then 0.05*event.newScale else 0
	self:Apply(record,event.newScale,lift,record.baseYaw,Factory.Color(record.level),record.level)
	record.model:SetAttribute("PresentedLevel",record.level)
	record.model:SetAttribute("PresentedRevision",record.revision)
	record.active=nil
	record.completed+=1;self.completed+=1
	self.Completed:Fire(event,record.model)
end

visibility=function(record,alpha)
 record.visibility=alpha
 alpha=math.max(alpha,record.growthCover or 0,record.spawnCover or 0)
 local model=record.model
 local body=model:FindFirstChild("Body")
 local face=body and body:FindFirstChild("FaceGui")
 local image=face and FaceUI.Image(face)
 local textured=false
 if image then
  local emotion=if record.adminEmotion and os.clock()<(record.adminEmotionUntil or 0) then record.adminEmotion elseif workspace:GetServerTimeNow()<(model:GetAttribute("EmotionUntil") or 0)
   then model:GetAttribute("Emotion") else "Joy"
  local asset=Art.Textures[emotion] or Art.Textures.Joy
  if image.Image~=asset then image.Image=asset end
  textured=FaceUI.Refresh(face,alpha)
 end
 local faceEnabled=face and face.Enabled or false
 if record.textured~=textured or record.faceEnabled~=faceEnabled then
  record.textured=textured;record.faceEnabled=faceEnabled;record.appliedVisibility=nil
 end
 if record.appliedVisibility==alpha then return end
 record.appliedVisibility=alpha
 for _,p in record.model:GetDescendants() do if p:IsA("BasePart") then
  p.LocalTransparencyModifier=if faceEnabled and (p.Name=="Eye" or p.Name=="Smile") then 1 else alpha
 end end
 local primary=record.model.PrimaryPart
 local label=primary and primary:FindFirstChild("LevelLabel");if label then label.Enabled=alpha<.7 end
end

function Controller:Follow(record,now,dt)
 if not record.model:GetAttribute("FollowOwner") then return true end
 local owner=Players:GetPlayerByUserId(record.owner)
 local char=owner and owner.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 then record.lifeState=nil;record.model:SetAttribute("CompanionMode","Hidden");visibility(record,1);self.effects:Hide(record.model);self.effects:CancelUpgrade(record.model);return false end
 record.racing=false
 local raceSlot=owner:GetAttribute("VerityRaceSlot")
 if type(raceSlot)=="number" and raceSlot%1==0 and raceSlot>=1 and raceSlot<=Race.MaxPlayers then
  record.racing=true;record.riding=false
  record.raceLevel=owner:GetAttribute("VerityRaceLevel") or record.level
  local started=owner:GetAttribute("VerityRaceStartedAt")
  local elapsed=started and math.max(0,workspace:GetServerTimeNow()-started)
  local target=Race.Position(raceSlot,elapsed,owner:GetAttribute("VerityRaceFinishSeconds"),owner:GetAttribute("VerityRaceSeed"),.85*Levels.getVerityScale(record.raceLevel))
  record.teleported=(record.origin.Position-target).Magnitude>Follow.TeleportDistance
  record.origin=CFrame.new(target)*CFrame.Angles(0,math.pi,0)
  record.velocity=if started then Vector3.new(0,0,10) else Vector3.zero
  record.lastRoot=root.Position;record.mode="Racing";record.followStarted=false
  record.model:SetAttribute("CompanionMode","Racing");visibility(record,0)
  return true
 end
 record.riding=owner:GetAttribute("VerityRiding")==true
 local scale=Levels.getVerityScale(if record.riding then record.model:GetAttribute("VerityLevel") else record.adminLevel or record.model:GetAttribute("VerityLevel"))
 if record.riding then
  record.origin=CFrame.new(root.Position-Vector3.new(0,1.7*scale+Ride.SeatOffset,0))*root.CFrame.Rotation
  record.lastRoot=root.Position;record.mode="Riding";record.followStarted=false
  local phase=owner:GetAttribute("VerityRidePhase")
  local y0,y1=owner:GetAttribute("VerityRideY0"),owner:GetAttribute("VerityRideY1")
  local progress=if y0 and y1 and math.abs(y1-y0)>.01 then math.clamp((root.Position.Y-y0)/(y1-y0),0,1) else 1
  progress=progress*progress*(3-2*progress)
  local alpha=if phase=="Takeoff" then 1-progress elseif phase=="Landing" then progress else 0
  record.model:SetAttribute("CompanionMode","Riding");visibility(record,alpha)
  return true
 end
 local x,y,z=Follow.Offset(scale,record.plot)
 local heading=root.CFrame.Rotation
 local teleport=record.lastRoot and (record.lastRoot-root.Position).Magnitude>Follow.TeleportDistance
 record.teleported=teleport
 record.velocity=root.AssemblyLinearVelocity
 if not record.heading or teleport then record.heading=heading
 else record.heading=record.heading:Lerp(heading,1-math.exp(-Art.HeadingSpeed*(dt or 1/30))) end
 local target=root.Position+record.heading:VectorToWorldSpace(Vector3.new(x,y,z))
 local mode="Following"
 if scale>Follow.IndoorMaxScale then
  if not record.surfaceAt or now-record.surfaceAt>=Follow.RayInterval then
   record.surfaceAt=now
   local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include
   local world=workspace:FindFirstChild("GeneratedWorld");ray.FilterDescendantsInstances=if world then {world} else {}
   local height=-math.huge
   local plots=world and world:FindFirstChild("Plots")
   local radius=scale*Follow.EnvelopeRadius
   local ownerRoof
   if plots then for _,plot in plots:GetChildren() do
    local house=plot:FindFirstChild("House")
    if house and house.PrimaryPart then
     local bounds=self.houseBounds[house]
     if not bounds then local cf,size=house:GetBoundingBox();bounds={cf=cf,size=size};self.houseBounds[house]=bounds end
     local ownerLocal=bounds.cf:PointToObjectSpace(root.Position)
     local size=bounds.size
     local top=bounds.cf.Position.Y+size.Y/2
     if math.abs(ownerLocal.X)<size.X/2 and math.abs(ownerLocal.Z)<size.Z/2 and math.abs(ownerLocal.Y)<size.Y/2+3 then
      ownerRoof=math.max(ownerRoof or -math.huge,top)
     end
     local targetLocal=bounds.cf:PointToObjectSpace(target)
     if math.abs(targetLocal.X)<=size.X/2+radius and math.abs(targetLocal.Z)<=size.Z/2+radius then height=math.max(height,top) end
    end
   end end
   record.ownerRoof=ownerRoof
   for house in self.houseBounds do if not house:IsDescendantOf(workspace) then self.houseBounds[house]=nil end end
   local r=scale*Follow.EnvelopeRadius
   for _,delta in {Vector3.zero,Vector3.new(r,0,0),Vector3.new(-r,0,0),Vector3.new(0,0,r),Vector3.new(0,0,-r)} do
    local hit=workspace:Raycast(Vector3.new(target.X+delta.X,180,target.Z+delta.Z),Vector3.new(0,-300,0),ray)
    if hit then height=math.max(height,hit.Position.Y) end
   end
   record.surfaceY=height
  end
  if record.ownerRoof then
   target=Vector3.new(root.Position.X,record.ownerRoof+Follow.RoofClearance,root.Position.Z);mode="RoofHover"
  elseif target.Y<(record.surfaceY or -math.huge)+Follow.RoofClearance then
   target=Vector3.new(target.X,record.surfaceY+Follow.RoofClearance,target.Z);mode="RoofHover"
  end
 else
  local start=root.Position+Vector3.new(0,1,0)
  local lift=Vector3.new(0,.85*scale,0)
  local delta=target+lift-start
  if not record.wallAt or now-record.wallAt>=Profile.FrameInterval
   or teleport or record.wallScale~=scale or record.lastRoot and (root.Position-record.lastRoot).Magnitude>2 then
   record.wallAt,record.wallScale=now,scale
   record.wallFraction=1
   if delta.Magnitude>.01 then
    local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include
    local world=workspace:FindFirstChild("GeneratedWorld");ray.FilterDescendantsInstances=if world then {world} else {}
    local hit=workspace:Spherecast(start,.85*scale,delta,ray)
    if hit then record.wallFraction=math.max(0,hit.Distance-.25)/delta.Magnitude end
   end
  end
  target=start+delta*record.wallFraction-lift
 end
 -- Offsets follow owner heading; the expression faces the viewing camera.
 local camera=workspace.CurrentCamera
 local aiming=record.abilityAim and (record.abilityAimUntil or 0)>now and not record.active
 local gaze=if aiming then Vector3.new(record.abilityAim.X-target.X,0,record.abilityAim.Z-target.Z)
  else camera and Vector3.new(camera.CFrame.Position.X-target.X,0,camera.CFrame.Position.Z-target.Z)
 local facing=if gaze and gaze.Magnitude>.01 then CFrame.lookAt(Vector3.zero,gaze).Rotation else heading
 local cf=CFrame.new(target)*facing
 local distance=(record.origin.Position-target).Magnitude
 if not record.followStarted or teleport or distance>Follow.TeleportDistance or (record.mode~=mode and mode=="RoofHover") then
  record.origin=cf;record.followStarted=true
 else
  local step=dt or 1/30
  local position=record.origin.Position:Lerp(target,Follow.Blend(step))
  local rotation=record.origin.Rotation:Lerp(facing,1-math.exp(-Art.FacingSpeed*step))
  record.origin=CFrame.new(position)*rotation
 end
 record.lastRoot=root.Position;record.mode=mode
 record.model:SetAttribute("CompanionMode",mode)
 local camera=workspace.CurrentCamera
 local center=record.origin.Position+Vector3.new(0,.85*record.model:GetScale(),0)
 local alpha=if camera then math.clamp((.9*record.model:GetScale()+Follow.CameraMargin-(camera.CFrame.Position-center).Magnitude)/Follow.CameraMargin,0,1) else 0
 visibility(record,alpha)
 if alpha>=.7 then self.effects:CancelUpgrade(record.model) end
 return true
end

function Controller:Tick(now,dt)
 local reveal=self.spawn.active
 if reveal and reveal.boundModel and not reveal.boundModel:IsDescendantOf(workspace) then self.spawn:Stop(false) end
 self.spawn:Tick(now)
 reveal=self.spawn.active
	local camera=workspace.CurrentCamera
	local showingGrowth=false
	if self.settings.values.ReducedEffects or self.settings.values.ReducedMotion then self.effects:SuppressBursts() end
	for model,record in self.records do
		if not model:IsDescendantOf(workspace) then self:Remove(model);continue end
		local spawning=reveal and reveal.event.ownerUserId==record.owner and reveal.event.plotId==record.plot
  record.spawnCover=if spawning then reveal.pose.cover else 0
  if spawning then reveal.boundModel=model end
  if not self:Follow(record,now,dt) then continue end
  if record.racing and record.active then
   self.effects:CancelUpgrade(model);self:Finish(record,now)
  end
  if spawning and not self.settings.values.ReducedMotion then
   local start=CFrame.new(reveal.origin.Position+Vector3.new(0,1.15,0))*record.origin.Rotation
   record.origin=start:Lerp(record.origin,reveal.pose.join)
  end
		local near=(record.visibility or 0)<.1 and camera~=nil and (camera.CFrame.Position-record.origin.Position).Magnitude<Profile.IdleDistance
		local reduced=self.settings.values.ReducedMotion
		if not record.active then
			local event=if spawning or record.adminLevel or record.racing then nil else record.ledger:Pop()
			if event then
				record.active={event=event,started=now,yaw=record.lastYaw,lift=record.lastLift,burst=false}
				self.Started:Fire(event,model)
				if near and not reduced and not self.settings.values.ReducedEffects then
					self.effects:BeginUpgrade(model,model:GetPivot(),event.newScale,event.newLevel,now,Factory.Color(event.newLevel))
				end
			end
		end
		local active=record.active
		record.growthCover=0
		record.lifeState=record.lifeState or {}
		local velocity=record.origin:VectorToObjectSpace(record.velocity or Vector3.zero)
		record.lifePitch,record.lifeRoll,record.lifeLift=Personality.Step(record.lifeState,velocity.X,velocity.Z,dt or 1/60,now,reduced or not near or active~=nil or spawning==true or (record.abilityAimUntil or 0)>now,record.teleported)
		local body=model:FindFirstChild("Body")
		local face=body and body:FindFirstChild("FaceGui")
		if face then
			record.faceLife=record.faceLife or {}
			local emotion=if record.adminEmotion and os.clock()<(record.adminEmotionUntil or 0) then record.adminEmotion elseif workspace:GetServerTimeNow()<(model:GetAttribute("EmotionUntil") or 0) then model:GetAttribute("Emotion") else "Joy"
			FaceUI.Animate(face,now,record.owner,emotion,model:GetAttribute("EmotionUntil"),record.faceLife,reduced or not near,self.settings.values.ReducedEffects or not near)
		end
		local renderLevel=if record.racing then record.raceLevel elseif record.riding then record.level else record.adminLevel or record.level
  local scale=Levels.getVerityScale(renderLevel)
		local stage=Profile.Stage(renderLevel)
		if active then
			local event=active.event
			local alpha=math.min(1,(now-active.started)/Profile.Duration(event.newLevel))
			local pose=Profile.Sample(event.oldLevel,event.newLevel,alpha,reduced)
			local oldColor,newColor=Factory.Color(event.oldLevel),Factory.Color(event.newLevel)
			local ownGrowth=Client and event.ownerUserId==Client.UserId
				and not reduced and not self.settings.values.ReducedEffects and near
			if ownGrowth then
				showingGrowth=true
				record.growthCover=Profile.Conceal(alpha)
			end
			local targetLift=if pose.stage>=2 and not reduced then event.newScale*0.05 else 0
			local lift=active.lift+(targetLift-active.lift)*pose.blend+pose.lift
			self:Apply(record,pose.scale,lift,active.yaw+pose.yaw,oldColor:Lerp(newColor,pose.blend),if alpha>=0.58 then event.newLevel else event.oldLevel)
			if ownGrowth then
				self.effects:Growth(model:GetPivot(),pose.scale,alpha,Profile.Bloom,
					newColor,Profile.IsMilestone(event.newLevel),model)
			end
			scale,stage=pose.scale,pose.stage
			if alpha>=Profile.Bloom and not active.burst then
				active.burst=true
				if near and not reduced and not self.settings.values.ReducedEffects then self.effects:Burst(model,model:GetPivot(),scale,event.newLevel,now,newColor) end
			end
			if alpha>=1 then self:Finish(record,now);scale=event.newScale end
		else
			local phase=now-record.idleStart
			local hover=if stage>=2 then 0.05*scale else 0
			local lift=if reduced or not near then 0 else hover+math.sin(phase*(if stage==5 then 1.4 else 2))*scale*(if stage==0 then 0.012 elseif stage==5 then 0.035 else 0.025)
			local yaw=(if (record.abilityAimUntil or 0)>now then 0 else record.baseYaw)+(if reduced or not near or (record.abilityAimUntil or 0)>now then 0 else math.sin(phase*(if stage==5 then .85 else 1.5))*(if stage==1 then .12 elseif stage>=4 then .06 else .08))
			if record.model:GetAttribute("FollowOwner") or near or record.lastLift~=0 then self:Apply(record,scale*(if spawning then reveal.pose.scale else 1),lift,yaw,Factory.Color(renderLevel),renderLevel) end
		end
		visibility(record,record.visibility or 0)
		self.effects:Update(model,model:GetPivot(),scale,stage,now,self.settings.values.ReducedEffects,
			near and not active and not spawning,renderLevel,reduced,record.teleported)
	end
	if not showingGrowth then self.effects:HideGrowth() end
	self.effects:Tick(now)
end

function Controller:Remove(model)
	self.pending[model]=nil
	local record=self.records[model]
	if not record then return end
	record.growthCover=0;record.spawnCover=0
	visibility(record,0)
	record.cleanup:Destroy()
	self.effects:Remove(model)
	self.records[model]=nil
	if self.byOwner[record.key]==record then self.byOwner[record.key]=nil end
end
function Controller:Destroy()
	self.dead=true
	for model in table.clone(self.records) do self:Remove(model) end
	table.clear(self.pending)
	self.cleanup:Destroy()
end
return Controller
