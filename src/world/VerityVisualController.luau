--!nonstrict
local RunService=game:GetService("RunService")
local CollectionService=game:GetService("CollectionService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Shared=ReplicatedStorage:WaitForChild("Shared",10)
assert(Shared,"Shared modules missing")
local Levels=require(Shared.LevelConfig)
local Profile=require(Shared.VerityAnimationProfile)
local Version=require(Shared.ProjectVersion)
local Factory=require(script.Parent.VerityFactory)
local VFX=require(script.Parent.VerityVFXService)
local Client=game:GetService("Players").LocalPlayer
local ClientModules=if Client then Client:WaitForChild("PlayerScripts",10):WaitForChild("VerityClient",10)
	else game:GetService("StarterPlayer").StarterPlayerScripts:WaitForChild("VerityClient",10)
local Cleanup=require(ClientModules.Cleanup)
local Ledger=require(ClientModules.EventLedger)
local Controller={}
Controller.__index=Controller

local function integer(value,minimum,maximum)
	return type(value)=="number" and value==value and value%1==0 and value>=minimum and value<=maximum
end
local function key(owner,plot) return tostring(owner)..":"..tostring(plot) end

function Controller.new(settings,options)
	local editPreview=options and options.editPreview==true
	assert(RunService:IsClient() or (editPreview and RunService:IsStudio() and not RunService:IsRunning()),"Visuals require a client; explicit Studio edit preview is the only exception")
	local self=setmetatable({cleanup=Cleanup.new(),settings=settings,records={},byOwner={},pending={},dead=false,effects=VFX.new(),
		Started=Instance.new("BindableEvent"),Completed=Instance.new("BindableEvent"),elapsed=0,completed=0},Controller)
	self.cleanup:Add(self.effects);self.cleanup:Add(self.Started);self.cleanup:Add(self.Completed)
	self.cleanup:Add(CollectionService:GetInstanceAddedSignal(Profile.Tag):Connect(function(model) self:Register(model) end))
	self.cleanup:Add(CollectionService:GetInstanceRemovedSignal(Profile.Tag):Connect(function(model) self:Remove(model) end))
	for _,model in CollectionService:GetTagged(Profile.Tag) do self:Register(model) end
	self.cleanup:Add(settings.Changed.Event:Connect(function(values)
		if not values.ReducedMotion then return end
		for _,record in self.records do if record.active then self:Finish(record,os.clock()) end end
	end))
	if not editPreview then
		self.cleanup:Add(RunService.RenderStepped:Connect(function(dt)
			self.elapsed+=dt
			if self.elapsed<Profile.FrameInterval then return end
			self.elapsed=0
			self:Tick(os.clock())
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
	local record={model=model,key=identity,origin=if typeof(anchor)=="CFrame" then anchor else model:GetPivot(),level=level,revision=revision,
		ledger=Ledger.new(),tints={},cleanup=Cleanup.new(),idleStart=os.clock(),baseYaw=0,lastYaw=0,lastLift=0,completed=0}
	for _,p in model:GetDescendants() do if p:IsA("BasePart") and p:GetAttribute("VerityTint") then table.insert(record.tints,p) end end
	record.ledger:Seed(revision,level)
	self.records[model],self.byOwner[identity]=record,record
	self:Apply(record,Levels.getVerityScale(level),0,0,Factory.Color(level),level)
	-- Identity changes are lifecycle changes, never a way to animate another owner's purchase.
	for _,attribute in {"OwnerUserId","PlotId"} do
		record.cleanup:Add(model:GetAttributeChangedSignal(attribute):Connect(function() self:Remove(model);self:Register(model) end))
	end
	return record
end

function Controller:Apply(record,scale,lift,yaw,color,level)
	local model=record.model
	if not model:IsDescendantOf(workspace) then return end
	if math.abs(model:GetScale()-scale)>0.000001 then model:ScaleTo(scale) end
	model:PivotTo(record.origin*CFrame.new(0,lift,0)*CFrame.Angles(0,yaw,0))
	for _,p in record.tints do if p.Parent then p.Color=color end end
	if record.stageLevel~=level then
		Factory.SetStage(model,level)
		local label=model.PrimaryPart:FindFirstChild("LevelLabel")
		if label and label:FindFirstChild("Title") then label.Title.Text="VERITY • LVL "..level end
		record.stageLevel=level
	end
	local label=model.PrimaryPart:FindFirstChild("LevelLabel")
	if label then label.StudsOffsetWorldSpace=Vector3.new(0,2.05*scale+0.5,0) end
	record.lastYaw,record.lastLift=yaw,lift
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
	record.ledger:Push(event)
	return true
end

function Controller:Finish(record,now)
	local active=record.active
	if not active then return end
	local event=active.event
	record.level,record.revision,record.idleStart=event.newLevel,event.stateRevision,now
	record.baseYaw=active.yaw+(if not self.settings.values.ReducedMotion and (event.newLevel==75 or event.newLevel==100) then 2*math.pi else 0)
	local lift=if Profile.Stage(record.level)>=2 and not self.settings.values.ReducedMotion then 0.05*event.newScale else 0
	self:Apply(record,event.newScale,lift,record.baseYaw,Factory.Color(record.level),record.level)
	record.model:SetAttribute("PresentedLevel",record.level)
	record.model:SetAttribute("PresentedRevision",record.revision)
	record.active=nil
	record.completed+=1;self.completed+=1
	self.Completed:Fire(event,record.model)
end

function Controller:Tick(now)
	local camera=workspace.CurrentCamera
	if self.settings.values.ReducedEffects then self.effects:SuppressBursts() end
	for model,record in self.records do
		if not model:IsDescendantOf(workspace) then self:Remove(model);continue end
		local near=camera~=nil and (camera.CFrame.Position-record.origin.Position).Magnitude<Profile.IdleDistance
		local reduced=self.settings.values.ReducedMotion
		if not record.active then
			local event=record.ledger:Pop()
			if event then
				record.active={event=event,started=now,yaw=record.lastYaw,lift=record.lastLift,burst=false}
				self.Started:Fire(event,model)
			end
		end
		local active=record.active
		local scale=Levels.getVerityScale(record.level)
		local stage=Profile.Stage(record.level)
		if active then
			local event=active.event
			local alpha=math.min(1,(now-active.started)/Profile.Duration(event.newLevel))
			local pose=Profile.Sample(event.oldLevel,event.newLevel,alpha,reduced)
			local targetLift=if pose.stage>=2 and not reduced then event.newScale*0.05 else 0
			local lift=active.lift+(targetLift-active.lift)*pose.blend+pose.lift
			self:Apply(record,pose.scale,lift,active.yaw+pose.yaw,Factory.Color(event.oldLevel):Lerp(Factory.Color(event.newLevel),pose.blend),if alpha>=0.58 then event.newLevel else event.oldLevel)
			scale,stage=pose.scale,pose.stage
			if alpha>=0.45 and not active.burst then
				active.burst=true
				if near and not self.settings.values.ReducedEffects then self.effects:Burst(model,model:GetPivot(),scale,event.newLevel,now) end
			end
			if alpha>=1 then self:Finish(record,now);scale=event.newScale end
		else
			local phase=now-record.idleStart
			local hover=if stage>=2 then 0.05*scale else 0
			local lift=if reduced or not near then 0 else hover+math.sin(phase*(if stage==5 then 1.4 else 2))*scale*(if stage==0 then 0.012 elseif stage==5 then 0.035 else 0.025)
			local yaw=record.baseYaw+(if reduced or not near then 0 elseif stage>=4 then phase*(if stage==5 then 0.16 else 0.24) else math.sin(phase*1.5)*(if stage==1 then 0.12 else 0.08))
			if near or record.lastLift~=0 then self:Apply(record,scale,lift,yaw,Factory.Color(record.level),record.level) end
		end
		self.effects:Update(model,model:GetPivot(),scale,stage,now,self.settings.values.ReducedEffects,near)
	end
	self.effects:Tick(now)
end

function Controller:Remove(model)
	self.pending[model]=nil
	local record=self.records[model]
	if not record then return end
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
