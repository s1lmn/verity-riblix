--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Numeric = require(Shared.Numeric)
local Houses = require(Shared.HouseConfig)
local Catalog = require(Shared.CosmeticCatalog)
local Drops = require(Shared.FeedDrops)
local Abilities = require(Shared.AbilityCatalog)
local Tasks = require(Shared.TaskConfig)
local Schema = {}
function Schema.new()
	return {DataVersion = 2, Cash = 0, TotalEarned = 0, VerityLevel = 1, VerityUnlocked = false,
		DeliveryState = "NotDelivered", SwipeUpgradeLevel = 0, HouseIncomeLevel = 0, HouseDoorOwned = false, HouseSecondFloorOwned = false, TutorialStep = 1,
		TutorialCompleted = false, FirstActivityCompleted = false, BoostExpiresAt = 0, Receipts = {}, FeedCollection = {}, ShowcaseCards = {}, AbilitiesOwned = {}, AbilitiesEquipped = {}, CosmeticsOwned = {}, CosmeticsEquipped = {}, TaskCooldowns = {}, NeighborhoodTaskCooldowns = {}}
end
-- Missing v1 fields are reconciled. Corrupt/future profiles fail closed, not reset.
function Schema.validate(raw)
	if raw == nil then return Schema.new(), nil end
	if type(raw) ~= "table" then return nil, "CORRUPT_PROFILE" end
	if raw.DataVersion ~= nil and raw.DataVersion ~= 1 and raw.DataVersion ~= 2 then return nil, "UNSUPPORTED_VERSION" end
	local data = Schema.new()
	for key, fallback in data do
		if raw[key] ~= nil then data[key] = raw[key] else data[key] = fallback end
	end
	data.DataVersion = 2 -- Explicit non-destructive v1 -> v2 migration.
	for _, key in {"Cash", "TotalEarned", "BoostExpiresAt"} do
		if not Numeric.isFinite(data[key]) or data[key] < 0 or data[key] > Config.MaxMoney then
			return nil, "INVALID_" .. key
		end
	end
	if data.TotalEarned < data.Cash then return nil, "INVALID_TOTAL_EARNED" end
	if not Numeric.isInteger(data.VerityLevel, 1, 100)
		or not Numeric.isInteger(data.SwipeUpgradeLevel, 0, 40)
		or not Numeric.isInteger(data.HouseIncomeLevel, 0, #Houses.IncomeUpgrades)
		or not Numeric.isInteger(data.TutorialStep, 1, 7) then return nil, "INVALID_LEVEL" end
	if type(data.FirstActivityCompleted) ~= "boolean" then return nil, "INVALID_FIRST_ACTIVITY" end
	if type(data.VerityUnlocked) ~= "boolean" or type(data.TutorialCompleted) ~= "boolean"
		or type(data.HouseDoorOwned) ~= "boolean" or type(data.HouseSecondFloorOwned) ~= "boolean" then
		return nil, "INVALID_BOOLEAN"
	end
	if data.DeliveryState ~= "NotDelivered" and data.DeliveryState ~= "Delivered"
		and data.DeliveryState ~= "Opened" then return nil, "INVALID_DELIVERY" end
	if data.VerityUnlocked ~= (data.DeliveryState == "Opened") then return nil, "INCONSISTENT_DELIVERY" end
	if not data.VerityUnlocked and data.VerityLevel ~= 1 then return nil, "LOCKED_LEVEL" end
	local houseUpgrade = Houses.IncomeUpgrades[data.HouseIncomeLevel]
	if houseUpgrade and (not data.VerityUnlocked or data.VerityLevel < houseUpgrade.Level) then
		return nil, "INVALID_HOUSE_UPGRADE"
	end
	if data.TutorialCompleted ~= (data.TutorialStep == 7) then return nil, "INVALID_TUTORIAL" end
	if type(data.Receipts) ~= "table" then return nil, "INVALID_RECEIPTS" end
	local receipts, count = {}, 0
	for id, granted in data.Receipts do
		count += 1
		if type(id) ~= "string" or #id < 1 or #id > 128 or granted ~= true
			or count > Config.ReceiptLimit then return nil, "INVALID_RECEIPTS" end
		receipts[id] = true
	end

 for _,key in {"CosmeticsOwned","CosmeticsEquipped","TaskCooldowns","NeighborhoodTaskCooldowns","FeedCollection","AbilitiesOwned","AbilitiesEquipped"} do
  if type(data[key])~="table" then return nil,"INVALID_"..key end
  data[key]=table.clone(data[key])
 end
 local countOwned=0
 for id,owned in data.CosmeticsOwned do
  countOwned+=1
  if type(id)~="string" or #id>64 or not id:match("^[%w_%-]+$") or owned~=true or countOwned>1000 then return nil,"INVALID_INVENTORY" end
 end
 for slot,id in data.CosmeticsEquipped do
  if not Catalog.Slots[slot] or not Catalog.Items[id] or Catalog.Items[id].slot~=slot or not data.CosmeticsOwned[id] then return nil,"INVALID_EQUIPMENT" end
 end
 for _,field in {"TaskCooldowns","NeighborhoodTaskCooldowns"} do
  for id,endsAt in data[field] do
   local definition=if type(id)=="string" then Tasks[id] else nil
   if not definition or definition.CooldownField~=field or not Numeric.isFinite(endsAt) or endsAt<0 or endsAt>Config.MaxMoney then return nil,"INVALID_COOLDOWN" end
  end
 end
 for cardId,count in data.FeedCollection do
  local index=if type(cardId)=="string" then tonumber(cardId) else nil
  if not index or tostring(index)~=cardId or not Drops.Get(index)
   or not Numeric.isInteger(count,1,1000000) then return nil,"INVALID_FEED_COLLECTION" end
 end
 -- Reconcile display preferences independently of inventory and progression.
 local showcase, used = {}, {}
 if type(data.ShowcaseCards) == "table" then
  for slot = 1, Drops.ShowcaseSlots do
   local key = tostring(slot)
   local cardId = data.ShowcaseCards[key]
   if Numeric.isInteger(cardId, 1, Drops.CardCount) and data.FeedCollection[tostring(cardId)] and not used[cardId] then
    showcase[key], used[cardId] = cardId, true
   end
  end
 end
 data.ShowcaseCards = showcase
 local abilityCount=0
 for id,owned in data.AbilitiesOwned do
  abilityCount+=1
  local item=Abilities.Items[id]
  if not item or item.Premium or owned~=true or abilityCount>#Abilities.Order then return nil,"INVALID_ABILITIES" end
 end
 for slot,id in data.AbilitiesEquipped do
  local item=Abilities.Items[id]
  if (slot~="Mobility" and slot~="Attack") or not item
   or (item.Slot~=slot and not (slot=="Mobility" and item.MobilityAction))
   or (not item.Premium and not data.AbilitiesOwned[id]) then return nil,"INVALID_ABILITY_EQUIPMENT" end
 end
 data.Receipts = receipts
	return data, nil
end
function Schema.copy(data)
	local copy = table.clone(data)
	for _,key in {"Receipts","CosmeticsOwned","CosmeticsEquipped","TaskCooldowns","NeighborhoodTaskCooldowns","FeedCollection","AbilitiesOwned","AbilitiesEquipped"} do copy[key]=table.clone(data[key]) end
	copy.ShowcaseCards = table.clone(data.ShowcaseCards or {})
	return copy
end
return Schema
