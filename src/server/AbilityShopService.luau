--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Catalog=require(Shared.AbilityCatalog)
local Config=require(Shared.GameConfig)
local Shop={};Shop.__index=Shop
function Shop.new(data,state,economy,market)
	return setmetatable({data=data,state=state,economy=economy,market=market,passId=Config.HeroPassId},Shop)
end
function Shop:Equip(userId,id)
	local profile=self.data:Get(userId)
	local item=Catalog.Items[id]
	if not profile or not self.state.sessions[userId] then return "NOT_READY" end
	if not item then return "INVALID_ITEM" end
	local data=profile.Data
	if not data.VerityUnlocked then return "BOX_NOT_OPENED" end
	if data.VerityLevel<item.Level then return "ABILITY_LEVEL_REQUIRED" end
	if not Catalog.Owns(data,id,profile.HeroPassOwned) then return "ABILITY_NOT_OWNED" end
	data.AbilitiesEquipped[item.Slot]=id
	if item.MobilityAction then data.AbilitiesEquipped.Mobility=id end
	self.data:Touch(profile)
	return "OK"
end
function Shop:Buy(userId,id)
	local profile=self.data:Get(userId)
	local item=Catalog.Items[id]
	if not profile or not self.state.sessions[userId] then return "NOT_READY" end
	if not item then return "INVALID_ITEM" end
	if item.Premium then return "PRODUCT_UNAVAILABLE" end
	if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
	if profile.Data.VerityLevel<item.Level then return "ABILITY_LEVEL_REQUIRED" end
	if profile.Data.AbilitiesOwned[id] then return self:Equip(userId,id) end
	if not self.economy:TrySpendCash(userId,item.Cost) then return "INSUFFICIENT_CASH" end
	profile.Data.AbilitiesOwned[id]=true
	return self:Equip(userId,id)
end
function Shop:RefreshPassAsync(userId)
	if not self.passId then return "NOT_CONFIGURED" end
	local profile=self.data:Get(userId)
	if not profile then return "NOT_READY" end
	local ok,owned=pcall(function() return self.market:UserOwnsGamePassAsync(userId,self.passId) end)
	if self.data:Get(userId)~=profile then return "NOT_READY" end
	if not ok then return "UNAVAILABLE" end
	if owned and not profile.HeroPassOwned then
		profile.HeroPassOwned=true
		-- Rejoin verifies ownership again. Stored equipment is only a preference.
		self.data:Touch(profile)
		self.state:Publish(userId,true)
	end
	return if owned then "OWNED" else "UNOWNED"
end
return Shop
