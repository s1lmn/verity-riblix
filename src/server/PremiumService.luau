--!nonstrict
-- One production owner of pass lookups and benefits. No client-supplied ownership or price.
local Catalog=require(game:GetService("ReplicatedStorage").Shared.PremiumCatalog)
local Service={};Service.__index=Service
function Service.new(data,state,income,abilityShop,market,players,clock,salesEnabled,notify)
 local self=setmetatable({data=data,state=state,income=income,shop=abilityShop,market=market,players=players,clock=clock,
  enabled=salesEnabled==true,notify=notify,records={},byPass={},dead=false},Service)
 for _,id in Catalog.Order do
  local item=Catalog.Items[id]
  if item.PassId~=nil then
   assert(Catalog.ValidId(item.PassId),"Invalid configured pass ID: "..id)
   assert(not self.byPass[item.PassId],"Duplicate configured pass ID")
   self.byPass[item.PassId]=id
  end
 end
 self.link=market.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
  local id=self.byPass[passId];local r=self.records[player.UserId]
  if not id or not r or player.Parent~=players or not self.enabled then return end
  if r.promptPass==passId then r.promptUntil=nil;r.promptPass=nil end
  if not purchased then return end
  -- Invalidate a lookup started before the purchase; it must not overwrite the new result.
  r.epochs[id]=(r.epochs[id] or 0)+1;r.inflight[id]=nil
  self:SpawnRefresh(player.UserId,id,true)
 end)
 return self
end
function Service:Record(userId)
 local p=self.data:Get(userId);local r=self.records[userId]
 return p,r and r.profile==p and r or nil
end
function Service:Apply(userId,profile,equipHero)
 local money=Catalog.Owned(profile.Data,"money_x3");local hero=Catalog.Owned(profile.Data,"hero_kit")
 local changed=false
 if (profile.MoneyPassOwned==true)~=money then self.income:Settle(userId);profile.MoneyPassOwned=money;changed=true end
 if (profile.HeroPassOwned==true)~=hero then profile.HeroPassOwned=hero;changed=true end
 local r=self.records[userId]
 if equipHero and hero and r then r.equipHero=true end
 if hero and r and r.equipHero and self.state.sessions[userId] and profile.Data.VerityUnlocked then
  if self.shop:Equip(userId,"homelander")=="OK" then r.equipHero=nil;changed=true end
 end
 if changed then self.data:Touch(profile) end
end
function Service:Attach(player)
 local userId=player.UserId;local profile=self.data:Get(userId)
 if not profile or self.dead then return end
 local old=self.records[userId];if old and old.profile==profile then return end
 self.records[userId]={profile=profile,epochs={},inflight={},statuses={},refreshAt=0}
 self:Apply(userId,profile,false)
 for _,id in Catalog.Order do if Catalog.Items[id].PassId then self:SpawnRefresh(userId,id,false) end end
end
function Service:OnUnlocked(userId)
 local profile,r=self:Record(userId);if not profile or not r then return end
 self:Apply(userId,profile,false)
end
function Service:RefreshAsync(userId,id,equipHero)
 local item=Catalog.Items[id];if not item then return "INVALID_ITEM" end
 if not Catalog.ValidId(item.PassId) then return "NOT_CONFIGURED" end
 if not self.enabled or self.dead then return "DISABLED" end
 local profile,r=self:Record(userId);if not profile or not r then return "NOT_READY" end
 if r.inflight[id] then return "PENDING" end
 local epoch=r.epochs[id] or 0;r.inflight[id]=epoch;r.statuses[id]="Checking"
 local ok,owned=pcall(function()return self.market:UserOwnsGamePassAsync(userId,item.PassId)end)
 local current,record=self:Record(userId)
 if self.dead or current~=profile or record~=r or (r.epochs[id] or 0)~=epoch then return "STALE" end
 r.inflight[id]=nil
 if not ok or type(owned)~="boolean" then
  r.statuses[id]="Unknown";self.state:Publish(userId,true);return "UNAVAILABLE"
 end
 r.statuses[id]=if owned then "Owned" else "Unowned"
 local changed=false
 if owned then
  if profile.Data.PremiumGrants[id]~=item.PassId then profile.Data.PremiumGrants[id]=item.PassId;changed=true end
 else
  if profile.Data.PremiumGrants[id]~=nil then profile.Data.PremiumGrants[id]=nil;changed=true end
  for _,slot in Catalog.Slots do
   local choice=Catalog.Options[slot][profile.Data.PremiumLoadout[slot]]
   if choice and choice.Item==id then profile.Data.PremiumLoadout[slot]="default";changed=true end
  end
 end
 if changed then self.data:Touch(profile) end
 self:Apply(userId,profile,equipHero and id=="hero_kit" and owned)
 self.state:Publish(userId,true)
 if self.onChanged then self.onChanged(userId,id) end
 return if owned then "OWNED" else "UNOWNED"
end
function Service:SpawnRefresh(userId,id,equipHero)
 local profile,r=self:Record(userId);if not profile or not r then return end
 task.spawn(function()
  for attempt=1,3 do
   local current,record=self:Record(userId);if self.dead or current~=profile or record~=r then return end
   local status=self:RefreshAsync(userId,id,equipHero)
   if status~="UNAVAILABLE" then
    if equipHero and status=="OWNED" then self.notify(userId,"PREMIUM_CONFIRMED") end
    return
   end
   task.wait(attempt*2)
  end
 end)
end
function Service:Busy(player)
 for _,attr in {"VerityFusionSlot","VerityDiversionKind","VerityRaceSlot","VerityParkourStep","VerityBattleActive","VerityRiding"} do if player:GetAttribute(attr) then return true end end
 return false
end
function Service:PreparePurchase(userId,id)
 local item=Catalog.Items[id];local profile,r=self:Record(userId);local player=self.players:GetPlayerByUserId(userId)
 if not item then return "INVALID_ITEM" end
 if not profile or not r or not player or not self.state.sessions[userId] then return "NOT_READY" end
 if not self.enabled or not Catalog.ValidId(item.PassId) or not item.PresentationReady then return "PRODUCT_UNAVAILABLE" end
 if Catalog.Owned(profile.Data,id) then return "ALREADY_OWNED" end
 if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
 if self:Busy(player) or r.inflight[id] or r.promptUntil and self.clock()<r.promptUntil then return "BUSY" end
 r.promptUntil=self.clock()+60;r.promptPass=item.PassId
 task.defer(function()
  local current,record=self:Record(userId)
  if self.dead or current~=profile or record~=r or player.Parent~=self.players or r.promptPass~=item.PassId then return end
  local ok=pcall(function()self.market:PromptGamePassPurchase(player,item.PassId)end)
  if not ok and self.records[userId]==r then
   r.promptUntil=nil;r.promptPass=nil;self.notify(userId,"PURCHASE_ERROR")
  end
 end)
 return "OK"
end
function Service:RequestRefresh(userId,id)
 local item=Catalog.Items[id];local profile,r=self:Record(userId)
 if not item then return "INVALID_ITEM" end
 if not profile or not r then return "NOT_READY" end
 if not self.enabled or not Catalog.ValidId(item.PassId) then return "PRODUCT_UNAVAILABLE" end
 if self.clock()<r.refreshAt or r.inflight[id] then return "COOLDOWN" end
 r.refreshAt=self.clock()+10
 self:SpawnRefresh(userId,id,false);return "OK"
end
function Service:Select(userId,slot,id)
 if not Catalog.Choice(slot,id) then return "INVALID_ITEM" end
 local profile,r=self:Record(userId);local player=self.players:GetPlayerByUserId(userId)
 if not profile or not r or not player or not self.state.sessions[userId] then return "NOT_READY" end
 if self:Busy(player) then return "BUSY" end
 if id~="default" then
  local option=Catalog.Options[slot][id];local item=Catalog.Items[option.Item]
  if not Catalog.Owned(profile.Data,option.Item) then return "NOT_OWNED" end
  if not item.PresentationReady then return "PRODUCT_UNAVAILABLE" end
  if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
 end
 if profile.Data.PremiumLoadout[slot]~=id then
  profile.Data.PremiumLoadout[slot]=id;self.data:Touch(profile)
  if self.onChanged then self.onChanged(userId,"style:"..slot) end
 end
 return "OK"
end
function Service:Projection(userId)
 local profile,r=self:Record(userId);if not profile then return nil end
 local player=self.players:GetPlayerByUserId(userId);local blocked=not player or self:Busy(player)
 local items={}
 for _,id in Catalog.Order do
  local item=Catalog.Items[id];local owned=Catalog.Owned(profile.Data,id)
  table.insert(items,{id=id,
   gamePassId=item.PassId,configured=Catalog.ValidId(item.PassId),presentationReady=item.PresentationReady,
   owned=owned,
   ownershipState=if not item.PassId then "NotConfigured" elseif r and r.statuses[id] then r.statuses[id] elseif owned then "Saved" else "Unchecked",
   canPurchase=self.enabled and not blocked and r~=nil and not r.inflight[id] and (not r.promptUntil or self.clock()>=r.promptUntil) and Catalog.ValidId(item.PassId) and item.PresentationReady and not owned and profile.Data.VerityUnlocked==true})
 end
 return {version=Catalog.Version,items=items,loadout=Catalog.Public(profile.Data),savedLoadout=table.clone(profile.Data.PremiumLoadout),salesEnabled=self.enabled}
end
function Service:PublicStyles(userId)
 local profile=self.data:Get(userId);return if profile then Catalog.Public(profile.Data) else table.clone(Catalog.Defaults)
end
function Service:FusionStyle(entries)
 for slot=1,2 do
  local entry=entries[slot];local profile=entry and self.data:Get(entry.player.UserId)
  local styles=profile and Catalog.Public(profile.Data)
  if styles and styles.FusionStyle~="default" then return {id=styles.FusionStyle,ownerUserId=entry.player.UserId,shared=entries[2]~=nil} end
 end
 return {id="default",ownerUserId=0,shared=false}
end
function Service:Remove(player) self.records[player.UserId]=nil end
function Service:Destroy() self.dead=true;self.link:Disconnect();table.clear(self.records) end
return Service
