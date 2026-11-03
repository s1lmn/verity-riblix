--!nonstrict
if not game:GetService("RunService"):IsStudio() then return end
local Players=game:GetService("Players");local Test=game:GetService("StudioTestService")
local Http=game:GetService("HttpService");local args=Test:GetTestArgs()
local expected=if type(args)=="table" then args.players or 1 else 1
local bridge=Instance.new("Folder");bridge.Name="FinalSmokeBridge"
local command=Instance.new("RemoteEvent");command.Name="Command";command.Parent=bridge
local report=Instance.new("RemoteEvent");report.Name="Report";report.Parent=bridge;bridge.Parent=game.ReplicatedStorage
local ready,replies={},{};local count,checks=0,{}
report.OnServerEvent:Connect(function(player,payload)
	if type(payload)~="table"then return end
	if payload.kind=="ready"then ready[player]=payload
	elseif payload.kind=="result"then replies[payload.token]=payload
	elseif payload.kind=="progress"then bridge:SetAttribute("GrowthLevel",payload.level)end
end)
local function check(value,label)count+=1;assert(value,label);table.insert(checks,label)end
local function waitFor(fn,timeout,label)
	local deadline=os.clock()+(timeout or 20)
	repeat local v=fn();if v then return v end;task.wait(0.05)until os.clock()>deadline
	error(label or "Server timeout")
end
local function ask(player,kind,payload,timeout)
	local token=Http:GenerateGUID(false);command:FireClient(player,token,kind,payload or {})
	local response=waitFor(function()return replies[token]end,timeout or 25,"Client command timeout: "..kind)
	replies[token]=nil;assert(response.ok,response.error);return response.result
end
local ok,failure=pcall(function()
	waitFor(function()return game.ServerScriptService.Core:GetAttribute("CoreReady")end,30,"Core startup failed")
	local s=require(game.ServerScriptService.Core.Runtime).GetServices()
	check(require(game.ReplicatedStorage.Shared.GameConfig).StudioDataMode=="Memory","ephemeral smoke profiles")
	waitFor(function()
		if #Players:GetPlayers()~=expected then return false end
		for _,p in Players:GetPlayers()do if not ready[p] or not s.DataService:Get(p.UserId)or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart")then return false end end
		return true
	end,60,"UI/Core handshake not ready")
	check(not workspace:FindFirstChild("PlayerInteriors"),"no obsolete private rooms")
	check(not game.ServerStorage:FindFirstChild("InteriorTemplates"),"no hidden template import")
	check(not game.ReplicatedStorage.Remotes:FindFirstChild("InteriorTransition"),"no doorway transition remote")
	check(workspace.GeneratedWorld:GetAttribute("BuilderVersion")=="open-neighborhood-5","correct World v5")
	local roster=Players:GetPlayers();table.sort(roster,function(a,b)return a.UserId<b.UserId end)
	for _,p in roster do
		local plotId=s.PlotService.owners[p.UserId]
		local anchors=s.WorldIntegration.anchors[plotId]
		check(ready[p].versionIssue==nil,"UI map version agrees for "..p.Name)
		local before=ask(p,"inspect")
		check(before.guiCount==1 and before.cash==0 and not before.model,"one real UI; no fake money/model before unpack "..p.Name)
		-- Walk into an actual house, including another player's plot in multiplayer.
		local visit=if expected>1 then s.PlotService.owners[roster[(table.find(roster,p)%#roster)+1].UserId]else plotId
		local house=workspace.GeneratedWorld.Plots[string.format("Plot_%02d",visit)].House
		p.Character:PivotTo(s.WorldIntegration.anchors[visit].HouseEntrance.CFrame)
		ask(p,"walk",{position=house.Markers.EntryPoint.Position})
		waitFor(function()return(p.Character.HumanoidRootPart.Position-house.Markers.EntryPoint.Position).Magnitude<5 end,10,"House doorway blocked")
		check(not s.InteriorService,"walk-in guest access has no private owner gate")
		p.Character:PivotTo(anchors.DeliveryPoint.CFrame+Vector3.new(0,2,0));task.wait(0.1)
		waitFor(function()return s.DataService:Get(p.UserId).Data.DeliveryState=="Delivered"end,5,"No box")
		check(ask(p,"request",{action="OpenBox"}).success,"UI transport unpacks owned Verity "..p.Name)
		waitFor(function()return ask(p,"inspect").model end,10,"Canonical Verity did not replicate")
		ask(p,"phone",{open=true})
		local swipe=ask(p,"swipe")
		check(swipe.success and swipe.reward==2,"real phone handler receives Core reward "..p.Name)
		local last=s.PlayerStateService.sessions[p.UserId].LastSwipeAt
		check(ask(p,"replay").replayed and s.PlayerStateService.sessions[p.UserId].LastSwipeAt==last,"duplicate wire request not paid twice "..p.Name)
		ask(p,"phone",{open=false})
	end
	local first=roster[1];local id=first.UserId;local profile=s.DataService:Get(id)
	for _,taskId in {"PRESS_BUTTON","REACH_POINT","STAND_ON_PLATFORM"}do
		check(ask(first,"request",{action="TaskStart",args={taskId=taskId}}).success,"UI starts "..taskId)
		local target=s.WorldIntegration.targets[taskId]
		first.Character:PivotTo(target.CFrame+Vector3.new(0,3,0));task.wait(0.15)
		if taskId=="PRESS_BUTTON"then ask(first,"prompt")end
		waitFor(function()return not s.PlayerStateService.sessions[id].Tasks[taskId].Active end,5,"Task failed "..taskId)
		check(s.PlayerStateService.sessions[id].Tasks[taskId].CooldownUntil>workspace:GetServerTimeNow(),"physical server task completion "..taskId)
	end
	s.EconomyService:AddCash(id,1e14);s.PlayerStateService:Publish(id,true)
	if expected==1 then
		local result=ask(first,"grow",nil,210)
		check(result.purchases==99 and result.level==100,"99 actual UI/Core purchases reach100")
		check(math.abs(result.scale-5)<1e-5 and result.completed==99,"99 canonical animations settle at5x")
		check(string.find(result.label,"5×",1,true)~=nil,"final UI shows5x")
		check(not ask(first,"request",{action="UpgradeVerity"}).success,"UI/Core reject level101")
	else
		check(ask(first,"request",{action="UpgradeVerity"}).success,"first player upgrades through real UI")
		for _,p in roster do if p~=first then check(s.DataService:Get(p.UserId).Data.VerityLevel==1,"independent guest progress "..p.Name)end end
	end
	check(ask(first,"reload").success,"UI reload re-synchronizes numeric operations")
	local inspection=ask(first,"inspect")
	check(inspection.guiCount==1 and inspection.prototypeCount==0,"one UI and no art-gallery collision after reload")
	local old=first.Character;old:FindFirstChildOfClass("Humanoid").Health=0
	waitFor(function()return first.Character~=old and first.Character and first.Character:FindFirstChild("HumanoidRootPart")end,20,"Respawn failed")
	check(ask(first,"inspect").guiCount==1,"respawn keeps one UI")
	if expected>1 then
		local leaving=roster[#roster];local plotId=s.PlotService.owners[leaving.UserId]
		local house=workspace.GeneratedWorld.Plots[string.format("Plot_%02d",plotId)].House
		command:FireClient(leaving,Http:GenerateGUID(false),"leave",{})
		waitFor(function()return s.DataService.profiles[leaving.UserId]==nil and s.PlotService.owners[leaving.UserId]==nil end,15,"Leave cleanup failed")
		check(house.Parent~=nil,"leaving preserves physical shared house")
	end
end)
local result={status=if ok then "PASS"else "FAIL",players=expected,assertions=count,checks=checks,
	error=if ok then nil else tostring(failure),kind="real UI/Core/World v5 end-to-end",maxScale=5,
	dataMode="Studio Memory",seededTestMoney=true}
bridge:SetAttribute("Status",result.status);bridge:SetAttribute("Report",Http:JSONEncode(result))
print("VERITY_FINAL_"..result.status,expected,count,failure or "")
if type(args)=="table"then task.wait(0.2);Test:EndTest(result)end
