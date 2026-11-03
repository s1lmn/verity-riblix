--!nonstrict
if not game:GetService("RunService"):IsStudio() then return end
local Players=game:GetService("Players");local Test=game:GetService("StudioTestService")
local Http=game:GetService("HttpService");local args=Test:GetTestArgs()
local expected=if type(args)=="table" then args.players or 1 else 1
local bridge=Instance.new("Folder");bridge.Name="CompleteSmokeBridge"
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
		for _,p in Players:GetPlayers()do if not ready[p] or not s.DataService:Get(p.UserId)or not p.Character or not p.Character:GetAttribute("SpawnReady") or not p.Character:FindFirstChild("HumanoidRootPart")then return false end end
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
  local opened=ask(p,"request",{action="OpenBox"})
		check(opened.success,"UI transport unpacks owned Verity "..p.Name.." result="..tostring(opened.errorCode).." distance="..tostring((p.Character.HumanoidRootPart.Position-anchors.DeliveryPoint.Position).Magnitude))
		waitFor(function()return ask(p,"inspect").model end,10,"Canonical Verity did not replicate")
		ask(p,"phone",{open=true})
		local swipe=ask(p,"swipe")
		check(swipe.success and swipe.reward==2,"real phone handler receives Core reward "..p.Name)
		local last=s.PlayerStateService.sessions[p.UserId].LastSwipeAt
		check(ask(p,"replay").replayed and s.PlayerStateService.sessions[p.UserId].LastSwipeAt==last,"duplicate wire request not paid twice "..p.Name)
		ask(p,"phone",{open=false})
	end
 -- Cluster players to distinguish actual foreign following from streamed-out hidden models.
 for i,p in roster do p.Character:PivotTo(CFrame.new((i%4)*12-18,5,math.floor((i-1)/4)*12-20)) end
 task.wait(2)
 for _,p in roster do
  local seen=ask(p,"inspect").companions
  for _,owner in roster do check(seen[tostring(owner.UserId)] and seen[tostring(owner.UserId)].mode~="Hidden","replicated companion visible to "..p.Name.." for "..owner.Name) end
  local before=ask(p,"inspect").position
  p.Character:PivotTo(p.Character:GetPivot()+Vector3.new(22,0,0));task.wait(1.1)
  local after=ask(p,"inspect")
  check(after.position and (after.position-before).Magnitude>12,"companion follows owner movement "..p.Name)
  check((after.position-p.Character.HumanoidRootPart.Position).Magnitude<25,"small companion remains near owner "..p.Name)
  for _,observer in roster do
   local visible=ask(observer,"inspect").companions[tostring(p.UserId)]
   check(visible and visible.mode~="Hidden" and (visible.position-p.Character.HumanoidRootPart.Position).Magnitude<25,"foreign companion follows for "..observer.Name.." owner "..p.Name)
  end
 end
 local first=roster[1];local id=first.UserId;local profile=s.DataService:Get(id)
 if expected==1 then
  local anchors=s.WorldIntegration.anchors[s.PlotService.owners[id]]
  local house=workspace.GeneratedWorld.Plots[string.format("Plot_%02d",s.PlotService.owners[id])].House
  first.Character:PivotTo(anchors.HouseEntrance.CFrame)
  ask(first,"walk",{position=house.Markers.EntryPoint.Position});task.wait(.5)
  local follow=ask(first,"inspect")
  check(follow.mode=="Following" and (follow.position-first.Character.HumanoidRootPart.Position).Magnitude<25,"small companion follows into a walk-in house")
 end
	for _,taskId in {"PRESS_BUTTON","REACH_POINT","STAND_ON_PLATFORM"}do
		check(ask(first,"request",{action="TaskStart",args={taskId=taskId}}).success,"UI starts "..taskId)
		local target=s.WorldIntegration.targets[taskId]
		first.Character:PivotTo(target.CFrame+Vector3.new(0,3,0));task.wait(0.15)
		if taskId=="PRESS_BUTTON"then ask(first,"prompt")end
		waitFor(function()return not s.PlayerStateService.sessions[id].Tasks[taskId].Active end,5,"Task failed "..taskId)
		check(s.PlayerStateService.sessions[id].Tasks[taskId].CooldownUntil>workspace:GetServerTimeNow(),"physical server task completion "..taskId)
	end
 check(ask(first,"preview",{itemId="round_glasses"}).success,"shop preview uses cosmetic model")
 check(not ask(first,"request",{action="EquipCosmetic",args={itemId="round_glasses",equipped=true}}).success,"server refuses unowned accessory")
 check(not ask(first,"request",{action="CosmeticPurchase",args={itemId="round_glasses"}}).success,"unconfigured Robux item is not sold")
 local products=s.CosmeticService.products;s.CosmeticService.products={[101]="round_glasses"}
 check(s.CosmeticService:ProcessReceiptAsync(id,"synthetic-studio-receipt",101),"synthetic receipt and entitlement saved atomically")
 check(s.CosmeticService:ProcessReceiptAsync(id,"synthetic-studio-receipt",101),"synthetic receipt replay does not grant twice")
 s.CosmeticService.products=products
 check(ask(first,"request",{action="EquipCosmetic",args={itemId="round_glasses",equipped=true}}).success,"UI equips server-owned accessory")
 task.wait(.5)
 for _,p in roster do
  local info=ask(p,"inspect").companions[tostring(id)]
  check(info.face=="round_glasses" and info.cosmeticModel,"equipped accessory replicated to "..p.Name)
 end
 s.EconomyService:AddCash(id,1e14);s.PlayerStateService:Publish(id,true)
	if expected==1 then
		local result=ask(first,"grow",nil,210)
		check(result.purchases==99 and result.level==100,"99 actual UI/Core purchases reach100")
		check(math.abs(result.scale-15)<1e-5 and result.completed==99,"99 canonical animations settle at15x")
		check(string.find(result.label,"15×",1,true)~=nil,"final UI shows15x")
		check(not ask(first,"request",{action="UpgradeVerity"}).success,"UI/Core reject level101")
	else
		check(ask(first,"request",{action="UpgradeVerity"}).success,"first player upgrades through real UI")
		for _,p in roster do if p~=first then check(s.DataService:Get(p.UserId).Data.VerityLevel==1,"independent guest progress "..p.Name)end end
	end
 if expected==1 then
  local house=workspace.GeneratedWorld.Plots[string.format("Plot_%02d",s.PlotService.owners[id])].House
  first.Character:PivotTo(house.Markers.EntryPoint.CFrame+Vector3.new(0,3,0));task.wait(1.5)
  local full=ask(first,"inspect")
  check(full.mode=="RoofHover" and full.scale==15 and full.position.Y>30,"full 15x companion stays outside above house roof")
  local presentation=ask(first,"presentation")
  check(presentation.auraOutside,"high-level aura surrounds full-size sphere")
  check(presentation.hiddenOwner,"missing owner-root simulation hides companion")
  check(presentation.cameraFade,"full-size companion fades locally when camera is inside")
  check(presentation.reducedEffects,"Reduced Effects suppresses active effects")
 end
 local savedLevel=profile.Data.VerityLevel
 local savedCooldown=profile.Data.TaskCooldowns.PRESS_BUTTON
 s.PlayerLifecycle.Detach(first);s.PlayerLifecycle.Attach(first)
 check(s.DataService:Get(id).Data.VerityLevel==savedLevel and s.DataService:Get(id).Data.VerityUnlocked,"production profile reattach restores unlocked level")
 check(s.DataService:Get(id).Data.CosmeticsEquipped.Face=="round_glasses","production profile reattach restores equipped cosmetics")
 check(s.DataService:Get(id).Data.TaskCooldowns.PRESS_BUTTON==savedCooldown,"production profile reattach preserves task cooldown")
 check(ask(first,"reload").success,"UI reload re-synchronizes numeric operations")
	local inspection=ask(first,"inspect")
	check(inspection.guiCount==1 and inspection.prototypeCount==0,"one UI and no art-gallery collision after reload")
 check(ask(first,"inspect").companions[tostring(id)].cosmeticModel,"restored companion wears saved cosmetic")
 local old=first.Character;old:FindFirstChildOfClass("Humanoid").Health=0
	waitFor(function()return first.Character~=old and first.Character and first.Character:FindFirstChild("HumanoidRootPart")end,20,"Respawn failed")
 task.wait(1)
 local respawn=ask(first,"inspect")
 check(respawn.guiCount==1,"respawn keeps one UI")
 check(respawn.mode~="Hidden" and respawn.position~=nil,"respawn restores following companion")
	if expected>1 then
		local leaving=roster[#roster];local plotId=s.PlotService.owners[leaving.UserId]
		local house=workspace.GeneratedWorld.Plots[string.format("Plot_%02d",plotId)].House
  leaving.Character:FindFirstChildOfClass("Humanoid").Health=0;task.wait(.3)
		command:FireClient(leaving,Http:GenerateGUID(false),"leave",{})
		waitFor(function()return s.DataService.profiles[leaving.UserId]==nil and s.PlotService.owners[leaving.UserId]==nil end,15,"Leave cleanup failed")
		check(house.Parent~=nil,"leaving preserves physical shared house")
  task.wait(.3)
  check(ask(first,"inspect").visualRecords==expected-1,"leaving while hidden cleans visual controller and model")
	end
end)
local result={status=if ok then "PASS"else "FAIL",players=expected,assertions=count,checks=checks,
	error=if ok then nil else tostring(failure),kind="15x flying companion / UI / Core / cosmetics end-to-end",syntheticCosmeticReceipt=true,profileReattach="production lifecycle; not network reconnect",maxScale=15,
	dataMode="Studio Memory",seededTestMoney=true}
bridge:SetAttribute("Status",result.status);bridge:SetAttribute("Report",Http:JSONEncode(result))
print("VERITY_FINAL_"..result.status,expected,count,failure or "")
if type(args)=="table"then task.wait(0.2);Test:EndTest(result)end
