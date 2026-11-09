--!nonstrict
-- Prevent stale Rojo preview/game scripts from starting a second runtime.
if game:GetService("ReplicatedStorage"):GetAttribute("VerityRuntimeMode")=="Preview" then return end
local Players = game:GetService("Players")
-- Load after profile initialization. The player chooses a house before gameplay starts.
Players.CharacterAutoLoads = false
local ReplicatedStorage = game:GetService("ReplicatedStorage")
ReplicatedStorage:SetAttribute("VerityCoreReady",false)
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Shared = ReplicatedStorage:WaitForChild("Shared", 15)
assert(Shared, "Missing Shared folder; check Rojo mapping")
local Config = require(Shared.GameConfig)
local Protocol = require(Shared.RemotesConfig)
local LocaleText = require(Shared.LocaleText)
local Runtime = require(script.Parent.Runtime)
assert(not Runtime.Services, "Core already started")
local function clock() return workspace:GetServerTimeNow() end
local function guid() return HttpService:GenerateGUID(false) end
local usingStudioMemory = RunService:IsStudio() and Config.StudioDataMode == "Memory"
local store
if usingStudioMemory then
	local records = {}
	store = {UpdateAsync = function(_, key, transform)
		local updated = transform(records[key])
		if updated ~= nil then records[key] = updated end
		return updated
	end}
	warn("VERITY: Studio profiles are ephemeral; DataStore is NOT being tested")
else
	local name = Config.DataStoreName .. (if RunService:IsStudio() then "_Studio" else "")
	store = DataStoreService:GetDataStore(name)
end
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then remotesFolder = Instance.new("Folder"); remotesFolder.Name = "Remotes"; remotesFolder.Parent = ReplicatedStorage end
local remotes = {}
for _, names in {Protocol.Requests, Protocol.Events} do
	for _, name in names do
		local remote = remotesFolder:FindFirstChild(name)
		assert(not remote or remote:IsA("RemoteEvent"), "Remote class conflict: " .. name)
		if not remote then remote = Instance.new("RemoteEvent"); remote.Name = name; remote.Parent = remotesFolder end
		remotes[name] = remote
	end
end
local function send(userId, eventName, payload)
	local player = Players:GetPlayerByUserId(userId)
	if player then remotes[eventName]:FireClient(player, payload) end
end
local worldSignal = Instance.new("BindableEvent")
worldSignal.Name = "WorldSignal"
worldSignal.Parent = script.Parent
local function emit(event)
	remotes.WorldEvent:FireAllClients(event)
	worldSignal:Fire(event)
end
local Data = require(script.Parent.DataService).new(store, clock, task.wait, game.JobId .. ":" .. guid())
local State = require(script.Parent.PlayerStateService).new(Data, clock)
local Economy = require(script.Parent.EconomyService).new(Data, clock)
local Income = require(script.Parent.IncomeService).new(Data, State, Economy, clock)
local MoneyPass = require(script.Parent.MoneyPassService).new(Data, State, Income, MarketplaceService)
local WorldModule = require(script.Parent.WorldIntegration)
local generatedWorld
local worldModules = ReplicatedStorage:FindFirstChild("World")
if worldModules then
	generatedWorld = require(worldModules.WorldBuilder).Build(workspace, Config.PlotCount)
	local lighting = game:GetService("Lighting")
	lighting.ClockTime = 13.5; lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(158, 166, 184)
	lighting.OutdoorAmbient = Color3.fromRGB(179, 184, 194)
	lighting.GlobalShadows = true; lighting.ShadowSoftness = 0.4
end
local World
local Plots = require(script.Parent.PlotService).new(Config.PlotCount, Config.ServerCapacity,
	function(userId, plotId, pointName) return World:IsNear(userId, plotId, pointName) end,
	if generatedWorld then WorldModule.ReadLayouts(generatedWorld, Config.PlotCount) else nil)
World = WorldModule.new(workspace, Players, Plots, generatedWorld)
State.DeliveryPosition = function(userId)
 local plotId=Plots.owners[userId];local anchors=plotId and World.anchors[plotId]
 return anchors and anchors.DeliveryPoint.Position
end
local Verity = require(script.Parent.VerityService).new(Data, State, guid, emit)
local Delivery = require(script.Parent.DeliveryService).new(Data, State, Plots, Income, Verity, clock, Config.DeliveryDelay)
local Upgrade = require(script.Parent.UpgradeService).new(Data, State, Economy, Income, Verity)
local Phone = require(script.Parent.PhoneService).new(Data, State, Economy, clock)
local Tasks = require(script.Parent.TaskService).new(Data, State, Economy, clock,
	function(userId,taskId,step) return World:IsNearTask(userId,taskId,step) end,
 function(userId)
  local player=Players:GetPlayerByUserId(userId)
  if not player or not World:GetCharacter(userId) then return false end
  for _,name in {"VerityRiding","VerityRaceSlot","VerityParkourStep","VerityBattleActive","VerityFusionSlot","VerityDiversionKind"} do
   if player:GetAttribute(name) then return false end
  end
  return true
 end)
local Cosmetics = require(script.Parent.CosmeticService).new(Data, State, require(script.Parent.CosmeticProducts), clock)
Delivery.onUnlocked=function(id) Cosmetics:GrantStarter(id) end
State.CosmeticsCatalog = function() return Cosmetics:Catalog(not usingStudioMemory) end
local ActivityRewards=require(script.Parent.ActivityRewardService).new(Data,State,function(id,rewardId,itemId)
 send(id,"NotificationEvent",{protocolVersion=1,code="ACTIVITY_REWARD_UNLOCKED",source="ActivityReward",achievementId=rewardId,itemId=itemId,eventId=guid()})
end)
local Album=require(script.Parent.AlbumService).new(Data,State,ActivityRewards,function(id,code)
 send(id,"NotificationEvent",{protocolVersion=1,code=code,source="Album",eventId=guid()})
end)
Phone.onCollectionChanged=function(id) Album:CheckMaster(id) end
local Boost = require(script.Parent.BoostService).new(Data, State, Income, clock)
Tasks.onReward = function(id, reward, taskId)
	World:React(id,"Confident",2)
	send(id, "NotificationEvent", {protocolVersion=1,code="TASK_REWARD",reward=reward,eventId=guid(),source="Task",taskId=taskId})
end
if generatedWorld then require(script.Parent.GameplayInteractions).Start(workspace, World, Tasks, State) end
local AbilityShop = require(script.Parent.AbilityShopService).new(Data,State,Economy,MarketplaceService)
local Premium=require(script.Parent.PremiumService).new(Data,State,Income,AbilityShop,MarketplaceService,Players,clock,not usingStudioMemory,function(id,code)
 send(id,"NotificationEvent",{protocolVersion=1,code=code,source="Premium",eventId=guid()})
end)
MoneyPass.premium=Premium;AbilityShop.premium=Premium
local Receipts=require(script.Parent.PurchaseReceiptService).new(Data,State,{Cosmetics,Boost},not usingStudioMemory)
State.PremiumProjection=function(id)return Premium:Projection(id)end
State.PremiumPublic=function(id)return Premium:PublicStyles(id)end
Delivery.onUnlocked=function(id)Cosmetics:GrantStarter(id);Premium:OnUnlocked(id)end

local CombatTargets = require(script.Parent.CombatTargets).new(Data,State,Economy,function(id,reward)
 send(id,"NotificationEvent",{protocolVersion=1,code="COMBAT_REWARD",reward=reward,eventId=guid(),source="Combat"})
end)
local Abilities = require(script.Parent.VerityAbilityService).new(Data, State, World, CombatTargets)
State.AbilitySlots=function(id)
 local player=Players:GetPlayerByUserId(id);return if player then Abilities:SlotSnapshot(player) else {}
end
local Parkour=require(script.Parent.ParkourService).new(Data,State,Economy,clock,function(id,code,reward)
 send(id,"NotificationEvent",{protocolVersion=1,code=code,source="Parkour",reward=reward,eventId=guid()})
end,function(player)Abilities:Stop(player)end)
if generatedWorld and generatedWorld:FindFirstChild("VerityParkour") then Parkour:Bind(generatedWorld.VerityParkour,Players) end
local StreetDelivery=require(script.Parent.StreetDeliveryService).new(Data,State,Economy,Players,clock,function(id,code,reward,result)
 send(id,"NotificationEvent",{protocolVersion=1,code=code,source="StreetDelivery",reward=reward,deliveryReward=result,eventId=guid()})
end,workspace)
local Race=require(script.Parent.VerityRaceService).new(Data,State,Economy,Players,clock,function(id,code,reward)
 if code=="RACE_WIN" then World:React(id,"Stars",4)end
 send(id,"NotificationEvent",{protocolVersion=1,code=code,source="VerityRace",reward=reward,eventId=guid()})
end)
if generatedWorld and generatedWorld:FindFirstChild("VerityRaceTrack") then Race:Bind(generatedWorld.VerityRaceTrack)end
local BattleModel=require(ReplicatedStorage.World.VerityBattleBuilder).Build(generatedWorld or workspace)
local Battle=require(script.Parent.VerityBattleService).new(BattleModel,Data,State,Economy,Players,clock,CombatTargets,Abilities,function(id,code,reward)
 send(id,"NotificationEvent",{protocolVersion=1,code=code,source="VerityBattle",reward=reward,eventId=guid()})
end)
Parkour.onCompleted=function(id) ActivityRewards:Grant(id,"parkour_clear") end
Race.onWinner=function(id) ActivityRewards:Grant(id,"race_champion") end
Battle.onCompleted=function(id) ActivityRewards:Grant(id,"titan_victory") end
Abilities.arena=Battle
local Fusion
if generatedWorld then
 local model
 local ok, result=pcall(function()
  model=require(ReplicatedStorage.World.VerityFusionBuilder).Build(generatedWorld)
  return require(script.Parent.VerityFusionService).new(model,Data,State,Players,clock,
   function(player) Abilities:Stop(player) end,function(id,code)
    send(id,"NotificationEvent",{protocolVersion=1,code=code,source="Fusion",reward=0,eventId=guid()})
   end)
 end)
 if ok then
  Fusion=result
 else
  if model then model:Destroy() end
  warn("[Verity Fusion] Initialization failed",result)
 end
end
local DiversionsModel=require(ReplicatedStorage.World.DiversionsBuilder).Build(generatedWorld or workspace)
local Diversions=require(script.Parent.DiversionsService).new(DiversionsModel,Data,State,Economy,Players,clock,
 function(player) Abilities:Stop(player) end,function(id,code,reward)
  send(id,"NotificationEvent",{protocolVersion=1,code=code,source="Diversions",reward=reward,eventId=guid()})
 end)
local Bond=require(script.Parent.VerityBondService).new(World,Data,State,Players,clock)
 Tasks.onStage=function(id,taskId,prop) Bond:Stage(id,taskId,prop) end
 local HomeStyles
 local CommunityModel=require(ReplicatedStorage.World.CommunityBuilder).Build(generatedWorld or workspace)
 local Community=require(script.Parent.CommunityService).new(CommunityModel,Data,State,Economy,Players,clock,
  function(p) Abilities:Stop(p) end,function(id,code,reward)
   send(id,"NotificationEvent",{protocolVersion=1,code=code,source="Community",reward=reward,eventId=guid()})
  end,function(id,emotion,seconds) Bond:React(id,emotion,"Helping",seconds) end)
local activitiesRemote=Instance.new("RemoteEvent");activitiesRemote.Name="VerityActivities";activitiesRemote.Parent=ReplicatedStorage
local activityLimits={}
activitiesRemote.OnServerEvent:Connect(function(player,action,...)
 if select("#",...)>0 or player.Parent~=Players or not Data:Get(player.UserId) or not (Battle.members[player] or Parkour.runs[player]) or clock()-(activityLimits[player] or -math.huge)<.5 then return end
 activityLimits[player]=clock()
 if action=="LeaveBattle" and Battle.members[player] then Battle:Remove(player,true)
 elseif action=="LeaveParkour" and Parkour.runs[player] then Parkour:Return(player,true) end
end)
if Fusion then Fusion.premium=Premium end
Premium.onChanged=function(userId,itemId)
 if Fusion and Fusion:Find(Players:GetPlayerByUserId(userId)) and (itemId=="fusion_pack" or itemId=="style:FusionStyle") then Fusion:RefreshPremiumStyle() end
end
local abilityShopRemote=Instance.new("RemoteEvent")
abilityShopRemote.Name="VerityAbilityShop";abilityShopRemote.Parent=ReplicatedStorage
if generatedWorld then
	require(script.Parent.AbilityStands).Build(generatedWorld,function(player,id) abilityShopRemote:FireClient(player,id) end)
end
State.send = function(userId, snapshot)
	local player = Players:GetPlayerByUserId(userId)
	if player then Abilities:Refresh(player, player.Character, snapshot) end
	World:UpdatePlot(userId, snapshot)
	send(userId, "PlayerStateUpdated", snapshot)
end
local Remote = require(script.Parent.RemoteService).new(Data, State, clock,
	function(userId, result) send(userId, "ActionResult", result) end)
Remote:Register("RequestPremiumPurchase",function(id,payload)return Premium:PreparePurchase(id,payload.itemId)end)
Remote:Register("RequestPremiumRefresh",function(id,payload)return Premium:RequestRefresh(id,payload.itemId)end)
Remote:Register("RequestSetPremiumStyle",function(id,payload)return Premium:Select(id,payload.slot,payload.itemId)end)
Remote:Register("RequestBuyAbility",function(id,payload) return AbilityShop:Buy(id,payload.itemId) end)
Remote:Register("RequestEquipAbility",function(id,payload) return AbilityShop:Equip(id,payload.itemId,payload.slot) end)
Remote:Register("RequestUpgradeHouse",function(id)
 local plotId=Plots.owners[id]
 if not plotId or not World:IsNearWorkshop(id,plotId) then return "TOO_FAR" end
 local status=Upgrade:UpgradeHouse(id)
 return if status=="HOUSE_UPGRADED" then "OK" else status
end)
Remote:Register("RequestEquipCosmetic", function(id,payload) return Cosmetics:Equip(id,payload.itemId,payload.equipped) end)
Remote:Register("RequestCosmeticPurchase", function(id,payload)
 if usingStudioMemory then return "PRODUCT_UNAVAILABLE" end
 local status,product=Cosmetics:PreparePurchase(id,payload.itemId)
 if status=="OK" then task.defer(function()
  local player=Players:GetPlayerByUserId(id)
  if not player then return end
  local ok=pcall(function() MarketplaceService:PromptProductPurchase(player,product) end)
  if not ok then Cosmetics:ClosePrompt(id,product);send(id,"NotificationEvent",{protocolVersion=1,code="PURCHASE_ERROR"}) end
 end) end
 return status
end)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(id,product,_purchased)
 -- Closes prompt only. Never grants an entitlement from this event.
 Cosmetics:ClosePrompt(id,product)
end)
World.houseProgression = require(script.Parent.HouseProgression).new(World, Players, function(player, feature, doorOwnerId)
	if feature == "DoorExit" then
		local session=State.sessions[doorOwnerId]
  local locked=false
  if player.UserId==doorOwnerId and session then locked=not session.HouseDoorLocked end
  if Upgrade:SetHouseDoor(doorOwnerId, locked) == "OK" then State:Publish(doorOwnerId, true) end
		return
	end
	local id = player.UserId
	local plotId = Plots.owners[id]
	if not plotId then return end
	local status
	if feature == "Door" and Data:Get(id) and Data:Get(id).Data.HouseDoorOwned then
		status = Upgrade:SetHouseDoor(id, not State.sessions[id].HouseDoorLocked)
	else
		status = Upgrade:BuyHouseFeature(id, feature)
	end
	State:Publish(id, true)
	send(id, "NotificationEvent", {protocolVersion=1,code=status,source="HouseFeature"})
end)
 World.houseProgression.stopMovement=function(player) Abilities:Stop(player) end
 HomeStyles=require(script.Parent.HomeStyleService).new(World,Data,State,Economy,clock,function(id,code)
  send(id,"NotificationEvent",{protocolVersion=1,code=code,source="HomeStyle",eventId=guid()})
  if code=="HOME_STYLE_APPLIED" or code=="HOME_DECOR_PURCHASED" then Bond:React(id,"Love","Home",2.5) end
 end)
local Arcade=require(script.Parent.ArcadeService).new(World,Data,State,Players,clock,Abilities,function(id,code)
  send(id,"NotificationEvent",{protocolVersion=1,code=code,source="Arcade",eventId=guid()})
 end)
local SecretsModel=require(ReplicatedStorage.World.SecretsBuilder).Build(generatedWorld or workspace)
 local Secrets=require(script.Parent.SecretsService).new(SecretsModel,Data,State,Players,clock,Abilities,ActivityRewards,
  function(id,code) send(id,"NotificationEvent",{protocolVersion=1,code=code,source="Secrets",eventId=guid()}) end,
  function(id,emotion,seconds) Bond:React(id,emotion,"Helping",seconds) end)
 Abilities.secrets=Secrets
local AdventureModel=require(ReplicatedStorage.World.AdventureBuilder).Build(generatedWorld,World.houseProgression.plots)
local Adventures=require(script.Parent.AdventureService).new(World,AdventureModel,Data,State,Economy,Players,clock,Abilities,Arcade,function(id,code,cash)
 send(id,"NotificationEvent",{protocolVersion=1,code=code,source="Adventure",reward=cash or 0,eventId=guid()})
end)
Abilities.adventures=Adventures;Arcade.adventures=Adventures
local ForgeModel=require(ReplicatedStorage.World.WeatherForgeBuilder).Build(generatedWorld)
local Forge=require(script.Parent.WeatherForgeService).new(ForgeModel,Data,State,Players,clock,guid,function(id,code)
 send(id,"NotificationEvent",{protocolVersion=1,code=code,source="WeatherForge",eventId=guid()})
end)
Adventures.forge=Forge
Remote:Register("RequestCraftWeatherItem",function(id,payload)return Forge:Craft(id,payload.itemId)end)
Remote:Register("RequestSetWeatherLook",function(id,payload)return Forge:SelectLook(id,payload.itemId)end)
Remote:Register("RequestHouseDoor", function(id, payload)
	if not Plots.owners[id] then return "NOT_READY" end
	return Upgrade:SetHouseDoor(id,payload.locked)
end)
Remote:Register("RequestOpenBox", function(id) return Delivery:Open(id) end)
Remote:Register("RequestUpgradeVerity", function(id)
	local status=Upgrade:UpgradeVerity(id)
	if status=="OK" then World:React(id,"Stars",2) end
	return status
end)
Remote:Register("RequestUpgradeSwipe", function(id) return Upgrade:UpgradeSwipe(id) end)
Remote:Register("RequestPhoneSession", function(id, payload) return Phone:SetOpen(id, payload.open) end)
Remote:Register("RequestClaimAlbumSet",function(id,payload)return Album:Claim(id,payload.itemId)end)
Remote:Register("RequestSetShowcaseCard", function(id, payload)
	return Phone:SetShowcaseCard(id, payload.slot, payload.cardId)
end)
Remote:Register("RequestSwipe", function(id)
	local status,reward,cardId,isNewCard=Phone:Swipe(id)
	if status=="OK" then World:React(id,"Love",2) end
	return status,reward,cardId,isNewCard
end)
Remote:Register("RequestTaskStart", function(id, payload) return Tasks:Start(id, payload.taskId) end)
Remote:Register("RequestTaskComplete", function(id, payload) return Tasks:Complete(id, payload.taskId) end)
Remote:Register("RequestSync", function(id)
	local plots = {}
	for owner in State.sessions do
		local state = State:PublicPlotSnapshot(owner)
		if state then table.insert(plots, state) end
	end
	send(id, "WorldEvent", {protocolVersion = 1, type = "WorldSnapshot", eventId = guid(),
		plots = plots, presentation = false})
	return "OK"
end)
for _, name in Protocol.Requests do
	remotes[name].OnServerEvent:Connect(function(player, payload, ...)
		if select("#", ...) > 0 then return end
		Remote:Handle(player.UserId, name, payload)
	end)
end
for plotId, anchors in World.anchors do
	anchors.WorkshopPrompt.Triggered:Connect(function(player)
		local id = player.UserId
		if Plots.owners[id] ~= plotId or not World:IsNearWorkshop(id, plotId) then return end
		local status = Upgrade:UpgradeHouse(id)
		State:Publish(id, true)
		send(id, "NotificationEvent", {protocolVersion = 1, code = status, source = "Workshop"})
	end)
	local box = anchors.Model:FindFirstChild("CoreDeliveryBox")
	if box then
		box.OpenBox.Triggered:Connect(function(player)
			-- Same ownership, distance and state checks as the remote path.
			local status = Delivery:Open(player.UserId)
			State:Publish(player.UserId, true)
			send(player.UserId, "NotificationEvent", {protocolVersion = 1, code = status, source = "Delivery"})
		end)
	end
end
Runtime.Services = {DataService = Data, PlayerStateService = State, EconomyService = Economy,
	IncomeService = Income, PlotService = Plots, WorldIntegration = World, DeliveryService = Delivery,
	VerityService = Verity, UpgradeService = Upgrade, PhoneService = Phone, TaskService = Tasks,
	CosmeticService = Cosmetics, BoostService = Boost, MoneyPassService = MoneyPass, PremiumService=Premium, PurchaseReceiptService=Receipts, AbilityShopService = AbilityShop, VerityAbilityService = Abilities, CombatTargets = CombatTargets, VerityBattleService=Battle, ParkourService=Parkour, StreetDeliveryService=StreetDelivery, VerityRaceService=Race, ActivityRewardService=ActivityRewards, VerityFusionService=Fusion, DiversionsService=Diversions, HomeStyleService=HomeStyles, CommunityService=Community, VerityBondService=Bond, SecretsService=Secrets, AlbumService=Album, ArcadeService=Arcade, AdventureService=Adventures, WeatherForgeService=Forge, WorldSignal = worldSignal.Event}
script.Parent:SetAttribute("CoreReady", true)
ReplicatedStorage:SetAttribute("VerityCoreReady",true)
local playerConnections, closing = {}, false
local AdminAccess = require(script.Parent.AdminAccess)
local AdminAbilities = require(Shared.AbilityCatalog)
local AdminHouses = require(Shared.HouseConfig)
local AdminNumbers = require(Shared.Numeric)
local nextAdminRequest = 0
local adminRemote = Instance.new("RemoteFunction")
adminRemote.Name = "VerityAdminCommand"
adminRemote.OnServerInvoke = function(player, action, value, ...)
 local id = player.UserId
 if not AdminAccess.IsAllowed(id) or player.Parent ~= Players or closing or select("#", ...) ~= 0 then return "DENIED" end
 local now = clock()
 if now < nextAdminRequest then return "WAIT" end
 nextAdminRequest = now + .3
 local profile = Data:Get(id)
 if not profile or not State.sessions[id] then return "NOT_READY" end
 local data = profile.Data
 if not data.VerityUnlocked then return "BOX_NOT_OPENED" end
 for _, attr in {"VerityDiversionKind","VerityFusionSlot","VerityRaceSlot","VerityParkourStep","VerityBattleActive","VerityRiding"} do
  if player:GetAttribute(attr) then return "IN_ACTIVITY" end
 end
 if action == "SetLevel" then
  if not AdminNumbers.isInteger(value, 1, 100) then return "INVALID_LEVEL" end
  local house = AdminHouses.IncomeUpgrades[data.HouseIncomeLevel]
  if house and value < house.Level then return "HOUSE_LEVEL", house.Level end
  if data.VerityLevel == value then return "OK" end
  Income:Settle(id)
  Abilities:Stop(player)
  data.VerityLevel = value
  Data:Touch(profile)
  Verity:Event(id, "VerityLevelSet", {newLevel = value, presentation = false})
 elseif action == "GrantAbility" then
  local item = type(value) == "string" and AdminAbilities.Items[value]
  if not item or item.Premium then return "INVALID_ABILITY" end
  if data.VerityLevel < item.Level then return "ABILITY_LEVEL", item.Level end
  data.AbilitiesOwned[value] = true
  AbilityShop:Equip(id, value, item.Slot)
 elseif action == "GrantHero" and value == "homelander" then
  local status=AbilityShop:GrantHeroForSession(id)
  if status~="OK" then return status end
 else
  return "DENIED"
 end
 State:Publish(id, true)
 return "OK"
end
adminRemote.Parent = ReplicatedStorage
local languages = {}
local languagePreference = Instance.new("RemoteEvent")
languagePreference.Name = "VerityLanguagePreference"
languagePreference.OnServerEvent:Connect(function(player, language)
	if language == "ru" or language == "en" then languages[player] = language end
end)
languagePreference.Parent = ReplicatedStorage
local function kick(player, message)
	player:Kick(LocaleText.Get(languages[player] or "ru", message))
end
local roadSpawn = generatedWorld and generatedWorld.Plaza.WelcomeSpawn
local spawning = {}
local function spawnPlayer(player)
	local id = player.UserId
	if closing or player.Parent ~= Players or not Data:Get(id) then return end
	if spawning[id] then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health <= 0 then task.delay(0.5, function() spawnPlayer(player) end) end
		return
	end
	spawning[id] = true
	local ok, reason = pcall(function() player:LoadCharacterAsync() end)
	spawning[id] = nil
	if not ok then
		warn("Character load failed", id, reason)
		if player.Parent == Players and not (player.Character and player.Character:GetAttribute("SpawnReady")) then
			kick(player, "Character unavailable. Please rejoin.")
		end
		return
	end
	-- Position as soon as the rig exists in onCharacter. Appearance loading may
	-- finish much later; never teleport a player back after they started moving.
end
local function disconnectPlayer(userId)
	for _, connection in playerConnections[userId] or {} do connection:Disconnect() end
	playerConnections[userId] = nil
end
local function onCharacter(player, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not root or not humanoid or player.Parent ~= Players or player.Character ~= character then return end
	character:PivotTo(if roadSpawn then roadSpawn.CFrame + Vector3.yAxis * 3.5 else CFrame.new(0,4,0))
	Abilities:Refresh(player, character, State:Snapshot(player.UserId))
	character:SetAttribute("SpawnReady", true)
	player:SetAttribute("VerityProtectedUntil", clock()+8)
	local death = humanoid.Died:Connect(function()
		Abilities:Stop(player)
  Parkour:SetRun(player,nil)
  Battle:Remove(player,false)
  Race:Remove(player)
  if Fusion then Fusion:Remove(player) end
  Diversions:End(player,false)
  Forge:Remove(player);Adventures:Remove(player);Arcade:Remove(player);Community:Remove(player);Bond:Remove(player);Secrets:Remove(player)
		Tasks:OnDeath(player.UserId)
		task.delay(Players.RespawnTime, function()
			if player.Character == character then spawnPlayer(player) end
		end)
	end)
	local connections = playerConnections[player.UserId]
	if connections then
		-- Keep only the current character death connection across respawns.
		if connections[2] then connections[2]:Disconnect() end
		connections[2] = death
	else death:Disconnect() end
end
local function onPlayer(player)
 AdminAccess.Apply(player)
	if closing then return end
	local profile, reason = Data:LoadAsync(player.UserId)
	if not profile then if player.Parent == Players then warn("Profile unavailable", player.UserId, reason); kick(player, "Profile unavailable. Please rejoin.") end; return end
	if closing or player.Parent ~= Players then Data:ReleaseAsync(player.UserId); return end
 Premium:Attach(player)
	playerConnections[player.UserId] = {player.CharacterAdded:Connect(function(character) onCharacter(player, character) end)}
	player.RespawnLocation = roadSpawn
	player:SetAttribute("HouseSelectionReady", true)
	if player.Character then task.spawn(onCharacter, player, player.Character)
	else task.spawn(spawnPlayer, player) end
end

local function claimHouse(player, requestedPlot)
	local userId = player.UserId
	if closing or player.Parent ~= Players or not player:GetAttribute("HouseSelectionReady") or not Data:Get(userId) then
		return "NOT_READY"
	end
	local anchors = World.anchors[requestedPlot]
	if not anchors then return "INVALID_PLOT" end
	if Plots.owners[userId] then return "ALREADY_CLAIMED" end
	if not World:IsNear(userId, requestedPlot, "ClaimPoint") then return "TOO_FAR" end
	local plotId, reason = Plots:Assign(userId, requestedPlot)
	if not plotId then return reason end

	State:Attach(userId, plotId)
 Premium:OnUnlocked(userId)
 Cosmetics:GrantStarter(userId)
 Album:CheckMaster(userId)
 Forge:SeedLegacy(userId)
	anchors.ClaimPrompt.Enabled = false
	player:SetAttribute("HousePlotId", plotId)
	State:Publish(userId, true)
	Verity:Event(userId, "PlotAssigned", {state = State:PublicPlotSnapshot(userId), presentation = false})
	Delivery:Begin(userId)
	return "OK"
end

for plotId, anchors in World.anchors do
	anchors.ClaimPrompt.Triggered:Connect(function(player)
		claimHouse(player, plotId)
	end)
end
local function removePlayer(player)
 Premium:Remove(player);Forge:Remove(player);Adventures:Remove(player);Arcade:Remove(player);Community:Remove(player);Bond:Remove(player);HomeStyles:Remove(player);Secrets:Remove(player)
 Diversions:Remove(player)
 if Fusion then Fusion:Remove(player,true) end
 Battle:Forget(player);activityLimits[player]=nil
 Parkour:Remove(player)
 Race:Remove(player,true)
	Abilities:Remove(player)
	languages[player] = nil
	local id = player.UserId
	player:SetAttribute("HouseSelectionReady", nil)
	player:SetAttribute("HousePlotId", nil)
	Income:Settle(id)
	disconnectPlayer(id)
	Delivery:Remove(id)
	Remote:Remove(id)
	player.RespawnLocation = nil
	local plotId = Plots:Release(id)
	State:Remove(id)
	if plotId then
		World:ClearPlot(plotId)
		emit({protocolVersion = 1, type = "PlotReleased", eventId = guid(), ownerUserId = id, plotId = plotId})
	end
	if not Data:ReleaseAsync(id) then warn("Profile release did not complete", id) end
end
Runtime.Services.PlayerLifecycle = {Attach = onPlayer, Detach = removePlayer, ClaimHouse = claimHouse}
Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(removePlayer)
for _, player in Players:GetPlayers() do task.spawn(onPlayer, player) end
local incomeElapsed, stateElapsed, taskElapsed, houseElapsed = 0, 0, 0, 0
RunService.Heartbeat:Connect(function(dt)
	if closing then return end
	-- Single server mover every Heartbeat; target decisions remain on the shared .15s tick.
 Battle:UpdateMotion(clock())
 Parkour:UpdateMotion(clock())
 Parkour:Tick()
 incomeElapsed += dt; stateElapsed += dt; taskElapsed += dt; houseElapsed += dt
	if houseElapsed >= .15 then local interval=houseElapsed;houseElapsed=0;World.houseProgression:Tick();StreetDelivery:Tick();Race:Tick();Battle:Tick(interval);Diversions:Tick();Community:Tick();Bond:Tick();Secrets:Tick();Arcade:Tick();Adventures:Tick() end
	if incomeElapsed >= Config.IncomeInterval then incomeElapsed = 0; Income:Tick(); Delivery:Tick() end
	if taskElapsed >= Config.TaskPollInterval then taskElapsed = 0; Tasks:Tick() end
	if stateElapsed >= Config.SnapshotInterval then
		stateElapsed = 0
		for id in State.sessions do
			if not Data:Get(id) then
				local player = Players:GetPlayerByUserId(id)
				if player then kick(player, "Profile session expired. Please rejoin.") end
			else State:Publish(id, false) end
		end
	end
 if Fusion then Fusion:Tick(dt) end
end)
task.spawn(function()
	while not closing do
		task.wait(Config.SaveInterval)
		if closing then break end
		for id, profile in Data.profiles do
			task.spawn(function()
				if profile.Closing then
					if not Data:ReleaseAsync(id) then warn("Profile release retry failed", id) end
				else
					local ok, reason = Data:SaveAsync(id, false)
					if not ok then warn("Autosave failed", id, reason) end
				end
			end)
		end
	end
end)
-- Disabled until real owned product IDs are configured; no placeholder IDs.
MarketplaceService.ProcessReceipt = function(receipt) return Receipts:Process(receipt) end
game:BindToClose(function()
	closing = true
 Premium:Destroy();Forge:Destroy();Adventures:Destroy();Arcade:Destroy();Secrets:Destroy();Community:Destroy();HomeStyles:Destroy();Bond:Destroy()
 if Fusion then Fusion:Destroy() end
	Data.closed = true
	for id in State.sessions do Income:Settle(id) end
	local deadline=clock()+25
	local flushing,retryAt={},{}
	-- Stop mutations after final income settlement, including while an autosave yields.
	for _,profile in Data.profiles do profile.Closing=true end
	while clock()<deadline and (next(flushing)~=nil or next(Data.loading)~=nil or next(Data.profiles)~=nil) do
		for id,profile in Data.profiles do
			if flushing[id] or profile.Saving or profile.Releasing or clock()<(retryAt[id] or 0) then continue end
			flushing[id]=true
			task.spawn(function()
				local ok,result=pcall(function() return Data:ReleaseAsync(id) end)
				flushing[id]=nil;retryAt[id]=clock()+1
				if not ok then warn("Shutdown profile release failed",id,result) end
			end)
		end
		task.wait(.1)
	end
	if next(Data.profiles)~=nil or next(Data.loading)~=nil then warn("Shutdown persistence deadline reached; some profiles remain unconfirmed") end
end)
print("VERITY Core ready", Config.PlotCount, "plots; protocol v1")
