--!nonstrict
-- Real Studio instances and the production renderer, explicitly driven in Edit.
-- Does not claim to test client/server networking, purchases, or a Play session.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Use only in Studio Edit")
local Factory=require(RS.World.VerityFactory)
local Renderer=require(RS.World.VerityVisualController)
local Levels=require(RS.Shared.LevelConfig)
local Profile=require(RS.Shared.VerityAnimationProfile)
local F={counter=0}

function F.Start()
	if F.controller then return F end
	assert(not workspace:FindFirstChild("EditorAnimationPreview"),"Remove the previous owned editor preview explicitly")
	F.root=Instance.new("Folder")
	F.root.Name,F.root.Parent="EditorAnimationPreview",workspace
	local floor=Instance.new("Part")
	floor.Name,floor.Size,floor.CFrame="PreviewPlatform",Vector3.new(17,0.5,17),CFrame.new(0,-0.25,0)
	floor.Anchored,floor.Color,floor.Material=true,Color3.fromRGB(100,245,180),Enum.Material.SmoothPlastic
	floor.Parent=F.root
	F.settings={values={ReducedMotion=false,ReducedEffects=false},Changed=Instance.new("BindableEvent")}
	F.controller=Renderer.new(F.settings,{editPreview=true})
	F.SetLevel(1)
	workspace.CurrentCamera.CFrame=CFrame.lookAt(Vector3.new(14,9,-20),Vector3.new(0,6,0))
	return F
end

function F.SetLevel(level)
	if F.model then F.controller:Remove(F.model);F.model:Destroy() end
	F.model=Factory.Create(F.root,CFrame.new(0,0.05,0),{ownerUserId=1,plotId=1,level=level,stateRevision=0})
	F.controller:Register(F.model)
	return F.model
end

function F.Event(level)
	F.counter+=1
	return {version=1,kind="VerityLevelChanged",eventId="edit-check-"..F.counter,ownerUserId=1,plotId=1,
		oldLevel=level,newLevel=level+1,oldScale=Levels.getVerityScale(level),newScale=Levels.getVerityScale(level+1),stateRevision=level}
end

function F.Animate(oldLevel)
	F.SetLevel(oldLevel)
	local event=F.Event(oldLevel)
	F.model:SetAttribute("VerityLevel",event.newLevel)
	F.model:SetAttribute("StateRevision",event.stateRevision)
	F.controller:HandleWorld(event)
	local started=os.clock()
	local duration=Profile.Duration(oldLevel+1)
	local samples={}
	repeat
		F.controller:Tick(os.clock())
		table.insert(samples,F.model:GetScale())
		task.wait(Profile.FrameInterval)
	until os.clock()-started>duration+0.08
	F.controller:Tick(started+duration+0.2)
	assert(math.abs(F.model:GetScale()-event.newScale)<0.00001)
	return {level=oldLevel+1,scale=F.model:GetScale(),samples=#samples,crownVisible=F.model.Crown.Band.Transparency==0}
end

function F.CheckAll()
	F.SetLevel(1)
	local record=F.controller.records[F.model]
	local base=F.controller.completed
	F.model:SetAttribute("VerityLevel",100)
	F.model:SetAttribute("StateRevision",99)
	for level=99,1,-1 do F.controller:HandleWorld(F.Event(level)) end
	-- Same transition with a different id must not block the rest of the queue.
	F.controller:HandleWorld(F.Event(1))
	local now=os.clock()
	local peaks={}
	for level=1,99 do
		F.controller:Tick(now)
		local duration=Profile.Duration(level+1)
		F.controller:Tick(now+duration*0.58)
		peaks[level]=F.model:GetScale()
		assert(peaks[level]<=Levels.getVerityScale(level+1)*Profile.MaxExpansion+0.00001)
		F.controller:Tick(now+duration+0.0001)
		assert(record.level==level+1 and math.abs(F.model:GetScale()-Levels.getVerityScale(level+1))<0.00001)
		now+=duration+0.1
		if level%10==0 then task.wait() end
	end
	assert(F.controller.completed-base==99)
	assert(#record.ledger.queue==0)
	assert(F.controller.effects.created<=64)
	F.controller.effects:Tick(now+3)
	assert(#F.controller.effects.active==0)
	return {transitions=99,scale=F.model:GetScale(),queued=#record.ledger.queue,
		pooledParts=F.controller.effects.created,activeBursts=#F.controller.effects.active,footprint=Profile.Footprint()}
end

function F.Destroy()
	if F.controller then F.controller:Destroy();F.controller=nil end
	if F.root then F.root:Destroy();F.root=nil end
	if F.settings then F.settings.Changed:Destroy();F.settings=nil end
	F.model=nil
end
return F
