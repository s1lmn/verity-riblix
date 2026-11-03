--!nonstrict
-- Studio-only server presentation fixture. No cash, datastore, purchases or real progression.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and RunService:IsServer(),"Animation fixture requires a Studio test server")
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local Factory=require(ReplicatedStorage.World.VerityFactory)
local Levels=require(ReplicatedStorage.Shared.LevelConfig)
local F={Records={},started=false}

local function create(record,level)
	if record.model then record.model:Destroy() end
	record.level=level
	record.revision+=1
	record.model=Factory.Create(record.folder,record.origin,{ownerUserId=record.owner,plotId=record.plotId,level=level,stateRevision=record.revision})
	return record.model
end

function F.SetLevel(player,level)
	local record=assert(F.Records[player],"Preview player missing")
	Levels.getVerityScale(level)
	return create(record,level)
end

function F.Step(player)
	local record=assert(F.Records[player],"Preview player missing")
	if record.level>=100 then return false end
	local old=record.level
	record.level+=1;record.revision+=1
	local event={version=1,kind="VerityLevelChanged",eventId=HttpService:GenerateGUID(false),
		ownerUserId=record.owner,plotId=record.plotId,oldLevel=old,newLevel=record.level,
		oldScale=Levels.getVerityScale(old),newScale=Levels.getVerityScale(record.level),stateRevision=record.revision}
	record.model:SetAttribute("VerityLevel",record.level)
	record.model:SetAttribute("StateRevision",record.revision)
	F.WorldEvent:FireAllClients(event)
	F.LastEvent=event
	return true,event
end

function F.Add(player)
	if F.Records[player] then return end
	local plotId=1
	local occupied={}
	for _,record in F.Records do occupied[record.plotId]=true end
	while occupied[plotId] do plotId+=1 end
	local plot=F.Plots:FindFirstChild(string.format("Plot_%02d",plotId))
	if not plot then return end
	local folder=Instance.new("Folder")
	folder.Name,folder.Parent="AnimationPreview",plot
	local record={folder=folder,origin=plot.Markers.VerityOrigin.CFrame,owner=math.max(1,math.abs(player.UserId)),plotId=plotId,revision=0}
	F.Records[player]=record
	create(record,1)
	local marker=Instance.new("Part")
	marker.Name,marker.Size,marker.CFrame="PreviewControls",Vector3.one,record.origin*CFrame.new(7,3,0)
	marker.Transparency,marker.Anchored,marker.CanCollide,marker.CanTouch,marker.CanQuery=1,true,false,false,false
	marker.Parent=folder
	local function prompt(name,text,key,callback)
		local p=Instance.new("ProximityPrompt")
		p.Name,p.ActionText,p.ObjectText=name,text,"ANIMATION PREVIEW • no real progress"
		p.KeyboardKeyCode,p.RequiresLineOfSight,p.MaxActivationDistance=key,false,12
		p.Exclusivity=Enum.ProximityPromptExclusivity.OnePerButton
		p.Triggered:Connect(function(who)
			if who~=player or not who.Character then return end
			local root=who.Character:FindFirstChild("HumanoidRootPart")
			if not root or (root.Position-marker.Position).Magnitude>14 then return end
			callback()
		end)
		p.Parent=marker
	end
	prompt("NextLevel","Upgrade preview",Enum.KeyCode.E,function() F.Step(player) end)
	prompt("NextStage","Sample next milestone",Enum.KeyCode.R,function()
		for _,stage in Levels.Milestones do
			if record.level<stage.level then
				local model=create(record,stage.level-1)
				task.delay(0.5,function() if F.Records[player]==record and record.model==model then F.Step(player) end end)
				return
			end
		end
	end)
	prompt("Reset","Reset preview",Enum.KeyCode.T,function() create(record,1) end)
	local function position(character)
		local root=character:WaitForChild("HumanoidRootPart",5)
		if root then character:PivotTo(CFrame.lookAt(record.origin.Position+Vector3.new(10,3,10),record.origin.Position+Vector3.new(0,1,0))) end
	end
	record.characterConnection=player.CharacterAdded:Connect(position)
	if player.Character then task.spawn(position,player.Character) end
end

function F.Start()
	if F.started then return F end
	assert(not ReplicatedStorage:FindFirstChild("Remotes"),"Use a disposable preview place without Core; fixture never replaces Core remotes")
	F.started=true
	local remotes=Instance.new("Folder")
	remotes.Name,remotes.Parent="Remotes",ReplicatedStorage
	F.WorldEvent=Instance.new("RemoteEvent")
	F.WorldEvent.Name,F.WorldEvent.Parent="WorldEvent",remotes
	local world=workspace:WaitForChild("GeneratedWorld",20)
	assert(world,"World failed to build")
	F.Plots=assert(world:FindFirstChild("Plots"))
	Players.PlayerAdded:Connect(F.Add)
	Players.PlayerRemoving:Connect(function(player)
		local record=F.Records[player]
		if record then record.characterConnection:Disconnect();record.folder:Destroy();F.Records[player]=nil end
	end)
	for _,player in Players:GetPlayers() do F.Add(player) end
	return F
end
return F
