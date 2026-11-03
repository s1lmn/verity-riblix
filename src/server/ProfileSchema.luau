--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Numeric = require(Shared.Numeric)
local Schema = {}
function Schema.new()
	return {DataVersion = 1, Cash = 0, TotalEarned = 0, VerityLevel = 1, VerityUnlocked = false,
		DeliveryState = "NotDelivered", SwipeUpgradeLevel = 0, TutorialStep = 1,
		TutorialCompleted = false, BoostExpiresAt = 0, Receipts = {}}
end
-- Missing v1 fields are reconciled. Corrupt/future profiles fail closed, not reset.
function Schema.validate(raw)
	if raw == nil then return Schema.new(), nil end
	if type(raw) ~= "table" then return nil, "CORRUPT_PROFILE" end
	if raw.DataVersion ~= nil and raw.DataVersion ~= 1 then return nil, "UNSUPPORTED_VERSION" end
	local data = Schema.new()
	for key, fallback in data do
		if raw[key] ~= nil then data[key] = raw[key] else data[key] = fallback end
	end
	for _, key in {"Cash", "TotalEarned", "BoostExpiresAt"} do
		if not Numeric.isFinite(data[key]) or data[key] < 0 or data[key] > Config.MaxMoney then
			return nil, "INVALID_" .. key
		end
	end
	if data.TotalEarned < data.Cash then return nil, "INVALID_TOTAL_EARNED" end
	if not Numeric.isInteger(data.VerityLevel, 1, 100)
		or not Numeric.isInteger(data.SwipeUpgradeLevel, 0, 40)
		or not Numeric.isInteger(data.TutorialStep, 1, 7) then return nil, "INVALID_LEVEL" end
	if type(data.VerityUnlocked) ~= "boolean" or type(data.TutorialCompleted) ~= "boolean" then
		return nil, "INVALID_BOOLEAN"
	end
	if data.DeliveryState ~= "NotDelivered" and data.DeliveryState ~= "Delivered"
		and data.DeliveryState ~= "Opened" then return nil, "INVALID_DELIVERY" end
	if data.VerityUnlocked ~= (data.DeliveryState == "Opened") then return nil, "INCONSISTENT_DELIVERY" end
	if not data.VerityUnlocked and data.VerityLevel ~= 1 then return nil, "LOCKED_LEVEL" end
	if data.TutorialCompleted ~= (data.TutorialStep == 7) then return nil, "INVALID_TUTORIAL" end
	if type(data.Receipts) ~= "table" then return nil, "INVALID_RECEIPTS" end
	local receipts, count = {}, 0
	for id, granted in data.Receipts do
		count += 1
		if type(id) ~= "string" or #id < 1 or #id > 128 or granted ~= true
			or count > Config.ReceiptLimit then return nil, "INVALID_RECEIPTS" end
		receipts[id] = true
	end
	data.Receipts = receipts
	return data, nil
end
function Schema.copy(data)
	local copy = table.clone(data)
	copy.Receipts = table.clone(data.Receipts)
	return copy
end
return Schema
