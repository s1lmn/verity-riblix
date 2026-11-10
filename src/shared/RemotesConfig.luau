--!strict
local Numeric = require(script.Parent.Numeric)
local Drops = require(script.Parent.FeedDrops)
local Tasks = require(script.Parent.TaskConfig)
local Album=require(script.Parent.AlbumConfig)
local Forge=require(script.Parent.WeatherForgeConfig)
local Premium=require(script.Parent.PremiumCatalog)
local Bridge=require(script.Parent.PremiumVisualBridge)
local ShopProducts=require(script.Parent.ShopProducts)
local RemotesConfig = {}
RemotesConfig.Requests = table.freeze({
	"RequestClaimDailyReward", "RequestStoryGuide", "RequestBuyShopProduct", "RequestBuyPremiumOffer", "RequestEquipPremiumOffer", "RequestPremiumPurchase", "RequestPremiumRefresh", "RequestSetPremiumStyle", "RequestBuyAbility", "RequestEquipAbility", "RequestUpgradeHouse", "RequestHouseDoor", "RequestOpenBox", "RequestUpgradeVerity", "RequestUpgradeSwipe", "RequestPhoneSession",
	"RequestCraftWeatherItem", "RequestSetWeatherLook", "RequestClaimAlbumSet", "RequestEquipCosmetic", "RequestCosmeticPurchase", "RequestSwipe", "RequestTaskStart", "RequestTaskComplete", "RequestSetShowcaseCard", "RequestSync",
})
RemotesConfig.Events = table.freeze({"PlayerStateUpdated", "ActionResult", "WorldEvent", "NotificationEvent"})
function RemotesConfig.isOperationId(value: any): boolean
	return type(value) == "string" and #value >= 1 and #value <= 16
		and string.match(value, "^[1-9]%d*$") ~= nil
		and (tonumber(value) or math.huge) <= 1e15
end
function RemotesConfig.validateRequest(name: string, payload: any): (boolean, string?)
	if type(payload) ~= "table" then return false, "INVALID_PAYLOAD" end
	if not RemotesConfig.isOperationId(payload.operationId) then
		return false, "INVALID_OPERATION_ID"
	end
	local allowed = {operationId = true}
	if name=="RequestStoryGuide" then
  allowed.enabled=true
  if type(payload.enabled)~="boolean" then return false,"INVALID_BOOLEAN" end
 elseif name=="RequestBuyShopProduct" then
  allowed.itemId=true
  if type(payload.itemId)~="string" or not ShopProducts.Items[payload.itemId] then return false,"INVALID_ITEM" end
 elseif name=="RequestBuyPremiumOffer" or name=="RequestEquipPremiumOffer" then
  allowed.itemId=true
  local binding=type(payload.itemId)=="string" and Bridge.Offers[payload.itemId]
  if not binding then return false,"INVALID_ITEM" end
  if name=="RequestEquipPremiumOffer" then
   allowed.variantId=true
   if not Bridge.Equip(payload.itemId,payload.variantId) then return false,"INVALID_ITEM" end
  end
 elseif name=="RequestPremiumPurchase" or name=="RequestPremiumRefresh" then
  allowed.itemId=true
  if type(payload.itemId)~="string" or not Premium.Items[payload.itemId] then return false,"INVALID_ITEM" end
 elseif name=="RequestSetPremiumStyle" then
  allowed.itemId=true;allowed.slot=true
  if type(payload.slot)~="string" or type(payload.itemId)~="string" or not Premium.Choice(payload.slot,payload.itemId) then return false,"INVALID_ITEM" end
 elseif name=="RequestCraftWeatherItem" or name=="RequestSetWeatherLook" then
  allowed.itemId=true
  if type(payload.itemId)~="string" then return false,"INVALID_ITEM" end
  if name=="RequestCraftWeatherItem" then
   if not Forge.Recipes[payload.itemId] then return false,"INVALID_ITEM" end
  elseif payload.itemId~="Auto" and payload.itemId~="Original" and not Forge.Looks[payload.itemId] then return false,"INVALID_ITEM" end
 elseif name=="RequestClaimAlbumSet" then
  allowed.itemId=true
  if type(payload.itemId)~="string" or not Album.Sets[payload.itemId] then return false,"INVALID_ITEM" end
 elseif name == "RequestHouseDoor" then
		allowed.locked = true
		if type(payload.locked) ~= "boolean" then return false, "INVALID_OPEN" end
	elseif name == "RequestSetShowcaseCard" then
		allowed.slot = true
		allowed.cardId = true
		if not Numeric.isInteger(payload.slot, 1, Drops.ShowcaseSlots)
			or not Numeric.isInteger(payload.cardId, 0, Drops.CardCount) then return false, "INVALID_CARD" end
	elseif name == "RequestPhoneSession" then
		allowed.open = true
		if type(payload.open) ~= "boolean" then return false, "INVALID_OPEN" end
	elseif name == "RequestEquipCosmetic" or name == "RequestCosmeticPurchase" or name == "RequestBuyAbility" or name == "RequestEquipAbility" then
  allowed.itemId = true
  if type(payload.itemId)~="string" or #payload.itemId<1 or #payload.itemId>64 or not string.match(payload.itemId,"^[%w_%-]+$") then return false,"INVALID_ITEM" end
  if name == "RequestEquipAbility" then
   allowed.slot=true
   if payload.slot~=nil and payload.slot~="Mobility" and payload.slot~="Attack" then return false,"INVALID_EQUIPMENT" end
  end
  if name == "RequestEquipCosmetic" then
   allowed.equipped=true
   if type(payload.equipped)~="boolean" then return false,"INVALID_EQUIPMENT" end
  end
 elseif name == "RequestTaskStart" or name == "RequestTaskComplete" then
		allowed.taskId = true
		if type(payload.taskId) ~= "string" or not Tasks[payload.taskId] then return false, "INVALID_TASK" end
	end
	for key in payload do
		if not allowed[key] then return false, "UNEXPECTED_FIELD" end
	end
	return true, nil
end
return table.freeze(RemotesConfig)
