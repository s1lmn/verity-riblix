--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Market=game:GetService("MarketplaceService")
local Input=game:GetService("UserInputService")
local Players=game:GetService("Players")
local GuiService=game:GetService("GuiService")
local Catalog=require(RS.Shared.PremiumVisualCatalog)
local Bridge=require(RS.Shared.PremiumVisualBridge)
local Abilities=require(RS.Shared.AbilityCatalog)
local Economy=require(RS.Shared.EconomyConfig)
local Houses=require(RS.Shared.HouseConfig)
local Config=require(RS.Shared.GameConfig)
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local Skin=require(script.Parent.PremiumShopSkin)
local Scenes=require(script.Parent.PremiumShopScenes)
local W=require(script.Parent.UIWidgets)
local Shop={};Shop.__index=Shop
local benefits={
 scarlet_sentinel="Полёт и лазеры для свободного мира",
 money_x3="Тот же заработок. В три раза больше денег.",
 premium_homes="Три узнаваемых стиля для твоего дома",
}
function Shop.new(ctx,money,abilities)
 local self=setmetatable({ctx=ctx,money=money,abilities=abilities,cleanup=Cleanup.new(),rows={},variants={},
  expanded={},section="boost",scenes={},prices={},priceRequests={},priceRetry={}},Shop)
 self.refs=ctx.refs.Panels.SHOP
 for section,tab in self.refs.Tabs do
  self.cleanup:Add(tab.Activated:Connect(function()
   self.section=section;self:ClearPreview();self.refs.Body.CanvasPosition=Vector2.zero;self:Render()
  end))
 end
 for index,id in Catalog.Order do
  local row=Skin.Card(self.refs.Body,id,Catalog.Card(id),index);self.rows[id]=row
  self.cleanup:Add(row.Preview.Activated:Connect(function()self:Preview(id)end))
  self.cleanup:Add(row.Buy.Activated:Connect(function()self:Activate(id)end))
  self.cleanup:Add(row.Reset.Activated:Connect(function()self:Remove(id)end))
  self.cleanup:Add(row.More.Activated:Connect(function()self.expanded[id]=not self.expanded[id];self:Render()end))
  if row.Variant then self.cleanup:Add(row.Variant.Activated:Connect(function()
   local card=Catalog.Card(id);self.variants[id]=(self.variants[id] or 1)%#card.Variants+1
   self:DropScene(id);self:Render()
  end)) end
  if row.HouseView then self.cleanup:Add(row.HouseView.Activated:Connect(function()
   self.interior=not self.interior;self:DropScene(id);self:Render()
  end)) end
 end
 self.cleanup:Add(self.refs.Root:GetPropertyChangedSignal("Visible"):Connect(function()
  if self.refs.Root.Visible then self.prices={};self:Render() else self:ClearPreview() end
 end))
 self.cleanup:Add(self.refs.Body:GetPropertyChangedSignal("CanvasPosition"):Connect(function()self.nextVisibility=0 end))
 self.cleanup:Add(self.refs.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
  self:ClearPreview();self:Render()
 end))
 self.cleanup:Add(Locale.Changed.Event:Connect(function()self:Render()end))
 self.cleanup:Add(ctx.settings.Changed.Event:Connect(function()self:ClearPreview();self:Render()end))
 self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
  if result.action=="BuyPremiumOffer" and not result.success then self.promptPassId=nil;self:Render() end
 end))
 self.cleanup:Add(ctx.net.Notification.Event:Connect(function(payload)
  if payload.code=="PURCHASE_ERROR" then self.promptPassId=nil;self:Render() end
 end))
 -- Closing the platform prompt only releases UI; PremiumService alone grants ownership.
 self.cleanup:Add(Market.PromptGamePassPurchaseFinished:Connect(function(player,id)
  if player==Players.LocalPlayer and self.promptPassId==id then self.promptPassId=nil;self:Render() end
 end))
 return self
end
function Shop:Variant(id)
 local pass=Catalog.Passes[id]
 return if pass and pass.Variants then pass.Variants[self.variants[id] or 1] else id
end
function Shop:Binding(id)
 local variant=self:Variant(id)
 return Bridge.Equip(id,if variant~=id then variant else nil)
end
function Shop:DropScene(id)
 local scene=self.scenes[id];if scene then scene:Destroy();self.scenes[id]=nil end
end
function Shop:ClearPreview()
 for id in self.scenes do self:DropScene(id) end
 self.playing=nil;self.nextVisibility=0
end
function Shop:Preview(id)
 self.playing=id;self.playAt=os.clock();self:DropScene(id)
 self.ctx.sound:Play("DecorTryOn");self:Render()
 local row=self.rows[id]
 -- Keep the scene at the top of the scroll area without opening a competing panel.
 local y=row.Art.AbsolutePosition.Y-self.refs.Body.AbsolutePosition.Y+self.refs.Body.CanvasPosition.Y-6
 local maxY=math.max(0,self.refs.Body.AbsoluteCanvasSize.Y-self.refs.Body.AbsoluteWindowSize.Y)
 self.refs.Body.CanvasPosition=Vector2.new(0,math.clamp(y,0,maxY))
end
function Shop:Price(passId)
 if type(passId)~="number" or passId<=0 then return nil end
 local cached=self.prices[passId]
 if cached then return cached end
 if not self.priceRequests[passId] and os.clock()>=(self.priceRetry[passId] or 0) then
  self.priceRequests[passId]=true
  task.spawn(function()
   local ok,info=pcall(function()return Market:GetProductInfoAsync(passId,Enum.InfoType.GamePass)end)
   if self.dead then return end
   self.priceRequests[passId]=nil
   if ok and type(info)=="table" then self.prices[passId]=info else self.priceRetry[passId]=os.clock()+30 end
   self:Render()
  end)
 end
 return nil
end
function Shop:Offer(id,state)
 if not state then return {} end
 local source=state.PremiumShop and state.PremiumShop.offers and state.PremiumShop.offers[id]
 local result=if source then table.clone(source) else {}
 local variant=self:Variant(id)
 if variant~=id then
  local entry=source and source.variants and source.variants[variant]
  result.selected=entry and entry.selected==true;result.canEquip=entry and entry.canEquip==true
 end
 if id=="money_x3" then result.owned=state.MoneyPassOwned==true;result.selected=result.owned
 elseif id=="scarlet_sentinel" then
  local eq=state.AbilitiesEquipped or {}
  result.owned=state.HeroPassOwned==true;result.trial=state.HeroPassTrial==true
  result.selected=result.owned and eq.Attack==Catalog.HeroAbilityId and eq.Mobility==Catalog.HeroAbilityId
  result.canEquip=result.owned and state.VerityUnlocked==true
 end
 local info=self:Price(result.gamePassId)
 local price=info and info.PriceInRobux
 result.price=if type(price)=="number" and price>=0 and price<math.huge and price%1==0 then price else nil
 result.priceKnown=info~=nil
 result.onSale=info and info.IsForSale==true
 result.loading=result.gamePassId~=nil and not info and self.priceRequests[result.gamePassId]==true
 result.canPurchase=result.canPurchase==true and result.onSale and result.price~=nil and not result.owned
 result.pending=self.promptPassId==result.gamePassId and os.clock()<(self.promptUntil or 0)
 return result
end
function Shop:Remove(id)
 local state=self.ctx.net.state;local offer=self:Offer(id,state);local b=self:Binding(id)
 if b and offer.selected and self.ctx.net.connected and not self.ctx.net:IsBusy() then
  self.ctx.request("SetPremiumStyle",{slot=b.Slot,itemId="default"})
 end
end
function Shop:Activate(id)
 local net=self.ctx.net;local offer=self:Offer(id,net.state)
 if not net.connected or net:IsBusy() or offer.pending or offer.selected then return end
 if offer.owned and offer.canEquip then
  if id=="scarlet_sentinel" then self.abilities:Activate(Catalog.HeroAbilityId)
  else
   local v=self:Variant(id)
   self.ctx.request("EquipPremiumOffer",{itemId=id,variantId=if v~=id then v else nil})
  end
 elseif offer.canPurchase and net.remotes.BuyPremiumOffer then
  self.promptPassId=offer.gamePassId;self.promptUntil=os.clock()+65
  local op=self.ctx.request("BuyPremiumOffer",{itemId=id})
  if not op then self.promptPassId=nil end
 end
 self:Render()
end
function Shop:Copy(id,row,state)
 local card=Catalog.Card(id)
 row.Benefit.Text=Locale.Text(benefits[id] or card.Description)
 row.Bundle.Text=Locale.Text(if card.Variants then "ОДНА ПОКУПКА · ТРИ ВАРИАНТА" elseif id=="scarlet_sentinel" then "ПОСТОЯННЫЙ ПРОПУСК · ДВЕ СПОСОБНОСТИ" else "ПОСТОЯННЫЙ ПРОПУСК")
 row.Comparison.Visible=id=="money_x3"
 if row.Variant then
  row.Variant.Text=string.format(Locale.Text("Вариант %d/%d · %s ›"),self.variants[id] or 1,#card.Variants,Locale.Text(Catalog.Items[self:Variant(id)].Title))
 end
 if row.HouseView then row.HouseView.Text=Locale.Text(if self.interior then "ПОКАЗАТЬ ФАСАД" else "ПОКАЗАТЬ ИНТЕРЬЕР") end
 if id=="scarlet_sentinel" then
  local a=Abilities.Items[Catalog.HeroAbilityId]
  local controls=if Input.PreferredInput==Enum.PreferredInput.Gamepad then "L1 — полёт · R1 — лазеры"
   elseif Input.PreferredInput==Enum.PreferredInput.Touch then "Кнопки полёта и атаки на экране"
   else "F — полёт · G — лазеры"
  row.Details.Text=string.format(Locale.Text("Полёт %d с · повтор через %d с\nЛазеры: %d урона · дальность %d studs\nПерезарядка лазеров: %d с\n%s"),a.FlightDuration,a.FlightCooldown,a.Damage,a.Range,a.Cooldown,Locale.Text(controls))
  row.Extra.Text=Locale.Text("Свободный мир и PvE. В гонках, паркуре и слиянии силы отключены. Испытания допускают только нужную силу. Под крышей полёт ограничен; безопасные зоны защищены от урона. Направление — стик или WASD, подъём — прыжок; на ПК Ctrl опускает вниз. Сцена сокращена для показа.")
 elseif id=="money_x3" then
  local level=math.clamp(state and state.VerityLevel or 1,1,100)
  local base=Economy.getIncome(level)*Houses.getIncomeMultiplier(state and state.HouseIncomeLevel or 0,state and state.HouseDoorOwned,state and state.HouseSecondFloorOwned)*(state and state.BoostMultiplier or 1)
  row.Comparison.Text=string.format(Locale.Text("БЕЗ ПРОПУСКА  $%s/с  →  С ×3  $%s/с"),Locale.Number(base),Locale.Number(base*Config.MoneyPassMultiplier))
  row.Details.Text=Locale.Text(if state and state.VerityUnlocked then "Без таймера и повторной покупки.\nПример: доход твоего уровня и дома за 1 секунду, с текущими усилениями.\nВсе 100 уровней доступны бесплатно." else "Без таймера и повторной покупки.\nПример после распаковки Verity: доход за 1 секунду.\nВсе 100 уровней доступны бесплатно.")
  row.Extra.Text=Locale.Text("×3: доход Verity и дома, свайпы и редкие карты, поручения, доставка, паркур, гонки, PvE-арена, искры, ритм, погодные испытания и события района. Материалы и украшения не умножаются. Остальные множители сохраняются. У предела кошелька начисление ограничено.")
 elseif id=="premium_homes" then
  row.Details.Text=Locale.Text("В наборе: сакура, космический дом и неоновая вилла. Фасад и интерьер.\nОформление не строит этажи и не увеличивает доход. Нужен построенный первый этап дома.")
 else row.Details.Text=Locale.Text(if id==Catalog.FusionLookId then "Достаточно пропуска у одного участника. Покупка не даёт напарнику постоянного владения." else "Оформление без изменения характеристик. Примерка не меняет профиль.") end
 row.More.Text=Locale.Text(if self.expanded[id] then "СКРЫТЬ ПОДРОБНОСТИ" else "ГДЕ РАБОТАЕТ И КАК ПОЛЬЗОВАТЬСЯ")
end
function Shop:Render()
 if self.dead or not self.refs.Root.Visible then return end
 local net=self.ctx.net
 for _,section in Catalog.Sections do W.SetButton(self.refs.Tabs[section.id],(if self.section==section.id then "● " else "")..Locale.Text(section.title),true,false) end
 for id,row in self.rows do
  row.Root.Visible=Catalog.Card(id).Section==self.section
  if not row.Root.Visible then self:DropScene(id);continue end
  self:Copy(id,row,net.state)
  local offer=self:Offer(id,net.state)
  row.Price.Text=if offer.loading then Locale.Text("Загружаем цену Roblox…")
   elseif offer.onSale and offer.price then string.format(Locale.Text("Цена Roblox: %d R$"),offer.price)
   elseif not offer.priceKnown then Locale.Text("Цена временно недоступна")
   else Locale.Text("Сейчас не продаётся")
  local label=if offer.pending then "ПОДТВЕРДИ В ROBLOX" elseif offer.selected then "ВЫБРАНО" elseif offer.owned then "ВЫБРАТЬ" else "КУПИТЬ"
  if offer.trial then row.Price.Text=Locale.Text("Пробный доступ на эту сессию") end
  W.SetButton(row.Buy,Locale.Text(label),net.connected and not net:IsBusy() and not offer.pending and not offer.selected
   and (offer.owned and offer.canEquip or not offer.owned and offer.canPurchase) or false,offer.pending==true)
  row.Reset.Visible=offer.selected==true and self:Binding(id)~=nil
  W.SetButton(row.Reset,Locale.Text("СНЯТЬ ОФОРМЛЕНИЕ"),net.connected and not net:IsBusy() and offer.canEquip==true,false)
  W.SetButton(row.Preview,Locale.Text("ПРИМЕРИТЬ"),true,false)
  Skin.LayoutCard(row,self.refs.Body.AbsoluteSize.X-12,self.expanded[id])
 end
 self.nextVisibility=0
end
function Shop:Step(now)
 if self.dead or not self.refs.Root.Visible then return end
 if GuiService.MenuIsOpen or not self.ctx.refs.Gui.Enabled or self.ctx.presenting or self.ctx.forgeReveal or self.ctx.rewardOverlay then
  self:ClearPreview();return
 end
 if now>=(self.nextRender or 0) then self.nextRender=now+1;self:Render() end
 if self.playing and now-self.playAt>=8 then self.playing=nil end
 if now>=(self.nextVisibility or 0) then
  self.nextVisibility=now+.2
  local body=self.refs.Body;local top=body.AbsolutePosition.Y;local bottom=top+body.AbsoluteWindowSize.Y
  local count=0;local maxScenes=if self.ctx.settings.values.LowGraphics then 1 else 2
  for _,id in Catalog.Order do
   local row=self.rows[id];local y=row.Art.AbsolutePosition.Y
   local visible=row.Root.Visible and y+row.Art.AbsoluteSize.Y>top+4 and y<bottom-4 and count<maxScenes
   if visible then
    count+=1
    if not self.scenes[id] then
     self.scenes[id]=Scenes.new(row.Viewport,self:Variant(id),{interior=id=="premium_homes" and self.interior})
    end
   else self:DropScene(id) end
  end
 end
 local reduced=self.ctx.settings.values.ReducedMotion or self.ctx.settings.values.ReducedEffects
 local interval=if self.ctx.settings.values.LowGraphics then 1/20 else 1/30
 if now<(self.nextFrame or 0) then return end;self.nextFrame=now+interval
 for id,scene in self.scenes do
  local age=if self.playing==id then now-self.playAt else 0
  self.rows[id].Phase.Text=Locale.Text(scene:Step(age,reduced or self.playing~=id))
 end
end
function Shop:Destroy() self.dead=true;self:ClearPreview();self.cleanup:Destroy() end
return Shop
