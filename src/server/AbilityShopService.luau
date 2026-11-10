--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Catalog=require(Shared.AbilityCatalog)
local Packs=require(Shared.CharacterPacks)
local Config=require(Shared.GameConfig)
local AdminAccess=require(script.Parent.AdminAccess)
local Shop={};Shop.__index=Shop
function Shop.new(data,state,economy,market)
	return setmetatable({data=data,state=state,economy=economy,market=market,passId=Config.HeroPassId},Shop)
end
function Shop:Equip(userId,id,slot)
	local profile=self.data:Get(userId)
	local item=Catalog.Items[id]
	if not profile or not self.state.sessions[userId] then return "NOT_READY" end
	if not item then return "INVALID_ITEM" end
	local data=profile.Data
	if not data.VerityUnlocked then return "BOX_NOT_OPENED" end
	if data.VerityLevel<item.Level then return "ABILITY_LEVEL_REQUIRED" end
	if not Catalog.Owns(data,id,Catalog.HeroAccess(profile),profile.AdminHeroSlots) then return "ABILITY_NOT_OWNED" end
	if slot~=nil and slot~=item.Slot and not (slot=="Mobility" and item.MobilityAction) then return "INVALID_EQUIPMENT" end
 local slots=if not slot and item.MobilityAction then {"Attack","Mobility"} else {slot or item.Slot}
 local temporary=profile.AdminHeroSlots
 local paid=if item.Pack then Packs.Owns(data,id) else profile.HeroPassOwned==true
 if item.Premium and temporary and not paid then
  for _,key in slots do temporary[key]=id end
 else
  for _,key in slots do
   if temporary then temporary[key]=nil end
   data.AbilitiesEquipped[key]=id
  end
  self.data:Touch(profile)
 end
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
function Shop:GrantHeroForSession(userId)
 if not AdminAccess.IsAllowed(userId) then return "DENIED" end
 local profile=self.data:Get(userId)
 if not profile or not self.state.sessions[userId] then return "NOT_READY" end
 if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
 if not profile.HeroPassOwned then profile.AdminHeroSlots={Attack="homelander",Mobility="homelander"} end
 return self:Equip(userId,"homelander")
end
function Shop:GrantPackForSession(userId,id)
 if not AdminAccess.IsAllowed(userId) or not Packs.Items[id] then return "DENIED" end
 local profile=self.data:Get(userId)
 if not profile or not self.state.sessions[userId] then return "NOT_READY" end
 if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
 profile.AdminHeroSlots={Attack=id,Mobility=id}
 return "OK"
end
function Shop:RefreshPassAsync(userId,equipOnPurchase)
 if self.premium then return self.premium:RefreshAsync(userId,"hero_kit",equipOnPurchase) end
	if not self.passId then return "NOT_CONFIGURED" end
	local profile=self.data:Get(userId)
	if not profile then return "NOT_READY" end
	local ok,owned=pcall(function() return self.market:UserOwnsGamePassAsync(userId,self.passId) end)
	if self.data:Get(userId)~=profile then return "NOT_READY" end
	if not ok then return "UNAVAILABLE" end
 if owned then
  local changed=not profile.HeroPassOwned
  profile.HeroPassOwned=true
  if equipOnPurchase then self:Equip(userId,"homelander") end
  if changed or equipOnPurchase then self.state:Publish(userId,true) end
 end
	return if owned then "OWNED" else "UNOWNED"
end
return Shop
