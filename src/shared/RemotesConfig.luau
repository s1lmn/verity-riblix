--!strict
local RemotesConfig = {}
RemotesConfig.Requests = table.freeze({
	"RequestBuyAbility", "RequestEquipAbility", "RequestUpgradeHouse", "RequestHouseDoor", "RequestOpenBox", "RequestUpgradeVerity", "RequestUpgradeSwipe", "RequestPhoneSession",
	"RequestEquipCosmetic", "RequestCosmeticPurchase", "RequestSwipe", "RequestTaskStart", "RequestTaskComplete", "RequestSync",
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
	if name == "RequestHouseDoor" then
		allowed.locked = true
		if type(payload.locked) ~= "boolean" then return false, "INVALID_OPEN" end
	elseif name == "RequestPhoneSession" then
		allowed.open = true
		if type(payload.open) ~= "boolean" then return false, "INVALID_OPEN" end
	elseif name == "RequestEquipCosmetic" or name == "RequestCosmeticPurchase" or name == "RequestBuyAbility" or name == "RequestEquipAbility" then
  allowed.itemId = true
  if type(payload.itemId)~="string" or #payload.itemId<1 or #payload.itemId>64 or not string.match(payload.itemId,"^[%w_%-]+$") then return false,"INVALID_ITEM" end
  if name == "RequestEquipCosmetic" then
   allowed.equipped=true
   if type(payload.equipped)~="boolean" then return false,"INVALID_EQUIPMENT" end
  end
 elseif name == "RequestTaskStart" or name == "RequestTaskComplete" then
		allowed.taskId = true
		if payload.taskId ~= "PRESS_BUTTON" and payload.taskId ~= "REACH_POINT"
			and payload.taskId ~= "STAND_ON_PLATFORM" then return false, "INVALID_TASK" end
	end
	for key in payload do
		if not allowed[key] then return false, "UNEXPECTED_FIELD" end
	end
	return true, nil
end
return table.freeze(RemotesConfig)
