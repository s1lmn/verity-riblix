--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Market=game:GetService("MarketplaceService")
local Input=game:GetService("UserInputService")
local Players=game:GetService("Players")
local GuiService=game:GetService("GuiService")
local Lighting=game:GetService("Lighting")
local Products=require(RS.Shared.ShopProducts)
local Catalog=require(RS.Shared.PremiumVisualCatalog)
local Bridge=require(RS.Shared.PremiumVisualBridge)
local Abilities=require(RS.Shared.AbilityCatalog)
local Packs=require(RS.Shared.CharacterPacks)
local Economy=require(RS.Shared.EconomyConfig)
local Houses=require(RS.Shared.HouseConfig)
local Config=require(RS.Shared.GameConfig)
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local Skin=require(script.Parent.PremiumShopSkin)
local Scenes=require(script.Parent.PremiumShopScenes)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Shop={};Shop.__index=Shop
local benefits={
 scarlet_sentinel="Долгий полёт над районом и усиленные лазеры против NPC",
 money_x3="Тот же заработок. В три раза больше денег.",
 premium_homes="Три узнаваемых стиля для твоего дома",
}
function Shop.new(ctx,money,abilities)
 local self=setmetatable({ctx=ctx,money=money,abilities=abilities,cleanup=Cleanup.new(),rows={},variants={},
  section="boost",scenes={},prices={},priceRequests={},priceRetry={}},Shop)
 self.refs=ctx.refs.Panels.SHOP
 self.blur=self.cleanup:Add(Instance.new("BlurEffect"))
 self.blur.Name="VerityShopBlur";self.blur.Size=10;self.blur.Enabled=false;self.blur.Parent=Lighting
 self.cleanup:Add(self.refs.Back.Activated:Connect(function() self:Back() end))
 for section,tab in self.refs.Tabs do
  self.cleanup:Add(tab.Activated:Connect(function()
   if self.section==section then return end
   self.section=section;self:ClearPreview();self.refs.Body.CanvasPosition=Vector2.zero;self:Render()
  end))
 end
 for index,id in Catalog.Order do
  local row=Skin.Card(self.refs.Parking,id,Catalog.Card(id),index);self.rows[id]=row
  self.cleanup:Add(row.Preview.Activated:Connect(function()self:Preview(id)end))
  self.cleanup:Add(row.Buy.Activated:Connect(function()self:Activate(id)end))
  self.cleanup:Add(row.Equip.Activated:Connect(function()self:Activate(id)end))
  self.cleanup:Add(row.Reset.Activated:Connect(function()self:Remove(id)end))
  if row.Variant then self.cleanup:Add(row.Variant.Activated:Connect(function()
   local card=Catalog.Card(id);self.variants[id]=(self.variants[id] or 1)%#card.Variants+1
   self:DropScene(id);self:Render()
  end)) end
  if row.HouseView then self.cleanup:Add(row.HouseView.Activated:Connect(function()
   self.interior=not self.interior;self:DropScene(id);self:Render()
  end)) end
 end
 self.cleanup:Add(self.refs.Root:GetPropertyChangedSignal("Visible"):Connect(function()
  self.refs.Backdrop.Visible=self.refs.Root.Visible
  self:UpdateBlur()
  if self.refs.Root.Visible then
   self.prices={};self:Render()
  else
   self:CloseDetail()
   self:ClearPreview()
  end
 end))
 self.cleanup:Add(self.refs.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
  self:ClearPreview();self:Render()
 end))
 self.cleanup:Add(Locale.Changed.Event:Connect(function()self:Render()end))
 self.cleanup:Add(ctx.settings.Changed.Event:Connect(function()self:UpdateBlur();self:ClearPreview();self:Render()end))
 self.cleanup:Add(Input:GetPropertyChangedSignal("PreferredInput"):Connect(function() self:UpdateBlur() end))
 self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
  if result.success then return end
  if result.action=="BuyPremiumOffer" then self.promptPassId=nil;self:Render()
  elseif result.action=="BuyShopProduct" then self.promptProductId=nil;self:Render() end
 end))
 self.cleanup:Add(ctx.net.Notification.Event:Connect(function(payload)
  if payload.code=="PURCHASE_ERROR" then self.promptPassId=nil;self.promptProductId=nil;self:Render() end
 end))
 -- Closing the platform prompt only releases UI; PremiumService alone grants ownership.
 self.cleanup:Add(Market.PromptGamePassPurchaseFinished:Connect(function(player,id)
  if player==Players.LocalPlayer and self.promptPassId==id then self.promptPassId=nil;self:Render() end
 end))
 self.cleanup:Add(Market.PromptProductPurchaseFinished:Connect(function(userId,id)
  if userId==Players.LocalPlayer.UserId and self.promptProductId==id then self.promptProductId=nil;self:Render() end
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
 self.playing=nil
end
function Shop:UpdateBlur()
 local values=self.ctx.settings.values
 self.blur.Enabled=self.refs.Root.Visible and not values.ReducedEffects and not values.LowGraphics
  and Input.PreferredInput~=Enum.PreferredInput.Touch
end
function Shop:CloseDetail()
 if not self.detailId then return nil end
 local id=self.detailId
 self.detailId=nil
 self.rows[id].Root.Parent=self.refs.Body
 self.interior=false
 return id
end
function Shop:Back()
 local id=self:CloseDetail()
 if not id then return false end
 self:ClearPreview()
 self:Render()
 self.refs.Body.CanvasPosition=self.gridScroll or Vector2.zero
 if Input.PreferredInput==Enum.PreferredInput.Gamepad then GuiService.SelectedObject=self.rows[id].Preview end
 return true
end
function Shop:Preview(id)
 if self.detailId~=id then
  self:CloseDetail()
  self.gridScroll=self.refs.Body.CanvasPosition
  self:ClearPreview()
  self.detailId=id
  self.rows[id].Root.Parent=self.refs.Detail
  self.refs.Detail.CanvasPosition=Vector2.zero
  if Input.PreferredInput==Enum.PreferredInput.Gamepad then GuiService.SelectedObject=self.refs.Back end
 end
 if not Products.Items[id] then
  self.playing=id
  self.playAt=os.clock()
  self.ctx.sound:Play("DecorTryOn")
 end
 self:Render()
 if self.refs.Detail.CanvasPosition.Y>0 then self.refs.Detail.CanvasPosition=Vector2.zero end
end
local function priceKey(id,isProduct)
 return if isProduct then "product:"..tostring(id) else id
end
function Shop:Price(id,isProduct)
 if type(id)~="number" or id<=0 then return nil end
 local key=priceKey(id,isProduct)
 local cached=self.prices[key]
 if cached then return cached end
 if not self.priceRequests[key] and os.clock()>=(self.priceRetry[key] or 0) then
  self.priceRequests[key]=true
  task.spawn(function()
   local ok,info=pcall(function()return Market:GetProductInfoAsync(id,if isProduct then Enum.InfoType.Product else Enum.InfoType.GamePass)end)
   if self.dead then return end
   self.priceRequests[key]=nil
   if ok and type(info)=="table" then self.prices[key]=info else self.priceRetry[key]=os.clock()+30 end
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
 elseif Packs.Items[id] then
  local equipped=state.AbilitiesEquipped or {}
  result.trial=state.CharacterPackTrial==id and not result.owned
  result.owned=result.owned or result.trial
  result.selected=result.owned and equipped.Attack==id and equipped.Mobility==id
 end
 local product=Products.Items[id]
 if product then
  result.productId=Products.Id(id)
  result.canPurchase=state.Premium and state.Premium.salesEnabled==true
 end
 local marketId=if product then result.productId else result.gamePassId
 local info=self:Price(marketId,product~=nil)
 local price=info and info.PriceInRobux
 result.price=if type(price)=="number" and price>=0 and price<math.huge and price%1==0 then price else nil
 result.priceKnown=info~=nil
 result.onSale=info and info.IsForSale==true
 result.loading=marketId~=nil and not info and self.priceRequests[priceKey(marketId,product~=nil)]==true
 result.canPurchase=result.canPurchase==true and result.onSale and result.price~=nil and not result.owned
 result.pending=marketId~=nil and (if product then self.promptProductId==marketId and os.clock()<(self.promptProductUntil or 0)
  else self.promptPassId==marketId and os.clock()<(self.promptUntil or 0))
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
  elseif Packs.Items[id] then self.ctx.request("EquipAbility",{itemId=id})
  else
   local v=self:Variant(id)
   self.ctx.request("EquipPremiumOffer",{itemId=id,variantId=if v~=id then v else nil})
  end
 elseif offer.canPurchase and offer.productId and net.remotes.BuyShopProduct then
  self.promptProductId=offer.productId;self.promptProductUntil=os.clock()+65
  if not self.ctx.request("BuyShopProduct",{itemId=id}) then self.promptProductId=nil end
 elseif offer.canPurchase and offer.gamePassId and net.remotes.BuyPremiumOffer then
  self.promptPassId=offer.gamePassId;self.promptUntil=os.clock()+65
  local op=self.ctx.request("BuyPremiumOffer",{itemId=id})
  if not op then self.promptPassId=nil end
 end
 self:Render()
end
function Shop:Copy(id,row,state)
 local card=Catalog.Card(id)
 local product=Products.Items[id]
 local look=Packs.Looks[Packs.AbilityForOffer(id)]
 local remaining=if product and product.Seconds then (state and state.ShopBoostExpiresAt or 0)-workspace:GetServerTimeNow() else 0
 row.Caption.Text=Locale.Text(if product and product.Cash then "ИГРОВАЯ ВАЛЮТА" elseif product then "БУСТ ДОХОДА"
  elseif id=="money_x3" then "ПОСТОЯННЫЙ БОНУС" elseif card.Variants then "3 ВАРИАНТА" elseif look then "ОБЛИК + 2 СПОСОБНОСТИ" else "НАБОР")
 row.Benefit.Text=Locale.Text(benefits[id] or card.Description)
 row.Bundle.Text=Locale.Text(if product then "МОЖНО КУПИТЬ ПОВТОРНО" elseif card.Variants then "ОДНА ПОКУПКА · ТРИ ВАРИАНТА" elseif look then "ОБЛИК · 2 СПОСОБНОСТИ · БОНУС" else "ПОСТОЯННЫЙ ПРОПУСК")
 row.Comparison.Visible=id=="money_x3"
 if row.Variant then
  row.Variant.Text=string.format(Locale.Text("Вариант %d/%d · %s ›"),self.variants[id] or 1,#card.Variants,Locale.Text(Catalog.Items[self:Variant(id)].Title))
 end
 if row.HouseView then row.HouseView.Text=Locale.Text(if self.interior then "ФАСАД" else "ИНТЕРЬЕР") end
 if product then
  if product.Cash then
   row.Details.Text="+"..Locale.Number(product.Cash).." $"
   row.Extra.Text=Locale.Text("Пакет зачисляется целиком, без множителей.")
  else
   row.Details.Text=Locale.Text("Работает вместе с постоянным ×3. Повторная покупка продлевает время.")
   row.Extra.Text=if remaining>0 then string.format("%s %d:%02d",Locale.Text("Осталось"),math.floor(remaining/60),math.floor(remaining%60))
    else Locale.Text("Отсчёт начинается после покупки и идёт, даже когда ты выходишь из игры.")
  end
 elseif id=="scarlet_sentinel" then
  local a=Abilities.Items[Catalog.HeroAbilityId]
  local controls=if Input.PreferredInput==Enum.PreferredInput.Gamepad then "L1 — полёт · R1 — лазеры"
   elseif Input.PreferredInput==Enum.PreferredInput.Touch then "Прыжок — выше · кнопка «Спуск» — ниже"
   else "F — полёт · G — лазеры"
  row.Details.Text=string.format(Locale.Text("Полёт %d с · скорость %d studs/с · повтор через %d с\nЛазеры: %d против NPC / %d против игроков · дальность %d studs\nПерезарядка лазеров: %d с\n%s"),a.FlightDuration,a.FlightSpeed,a.FlightCooldown,a.PvEDamage,a.Damage,a.Range,a.Cooldown,Locale.Text(controls))
  row.Extra.Text=Locale.Text("Свободный мир и PvE. В гонках, паркуре и слиянии силы отключены. Испытания допускают только нужную силу. Под крышей полёт ограничен; безопасные зоны защищены от урона. Направление — стик или WASD, подъём — прыжок. Для спуска нажми Ctrl на ПК или удерживай «Спуск» на телефоне. Сцена сокращена для показа.")
 elseif Packs.Items[id] then
  local pack=Packs.Items[id]
  row.Details.Text=string.format(Locale.Text("Движение: %s · повтор через %d с\nPvE: %s · повтор через %d с"),Locale.Text(pack.MobilityLabel),pack.MobilityCooldown,Locale.Text(pack.AttackLabel),pack.Cooldown)
  row.Extra.Text=Locale.Text("Боевой приём работает в активной волне PvE. В гонках, паркуре и совместном заезде способности отключены.")
 elseif id=="money_x3" then
  local level=math.clamp(state and state.VerityLevel or 1,1,100)
  local base=Economy.getIncome(level)*Houses.getIncomeMultiplier(state and state.HouseIncomeLevel or 0,state and state.HouseDoorOwned,state and state.HouseSecondFloorOwned)*(state and state.BoostMultiplier or 1)
  row.Comparison.Text=string.format(Locale.Text("БЕЗ ПРОПУСКА  $%s/с  →  С ×3  $%s/с"),Locale.Number(base),Locale.Number(base*Config.MoneyPassMultiplier))
  row.Details.Text=Locale.Text(if state and state.VerityUnlocked then "Без таймера и повторной покупки.\nПример: доход твоего уровня и дома за 1 секунду, с текущими усилениями.\nВсе 100 уровней доступны бесплатно." else "Без таймера и повторной покупки.\nПример после распаковки Verity: доход за 1 секунду.\nВсе 100 уровней доступны бесплатно.")
  row.Extra.Text=Locale.Text("×3: доход Verity и дома, свайпы и редкие карты, поручения, доставка, паркур, гонки, PvE-арена, искры, ритм, погодные испытания и события района. Материалы и украшения не умножаются. Остальные множители сохраняются. У предела кошелька начисление ограничено.")
 elseif id=="premium_homes" then
  row.Details.Text=Locale.Text("В наборе: сакура, космический дом и неоновая вилла. Фасад и интерьер.\nОформление не строит этажи и не увеличивает доход. Нужен построенный первый этап дома.")
 else row.Details.Text=Locale.Text(if id==Catalog.FusionLookId then "Достаточно пропуска у одного участника. Покупка не даёт напарнику постоянного владения." else "Оформление без изменения характеристик. Примерка не меняет профиль.") end
 if look then
  row.Bundle.Text=string.format(Locale.Text("ОБЛИК · 2 СПОСОБНОСТИ · +$%s ОДИН РАЗ"),Locale.Number(Packs.BonusCash))
  row.Extra.Text=string.format(Locale.Text("Эффект облика: %s"),Locale.Text(look.Effect)).."\n"..row.Extra.Text
 end
end
function Shop:Render()
 if self.dead or not self.refs.Root.Visible then return end
 local net=self.ctx.net
 local detail=self.detailId~=nil
 self.refs.Body.Visible=not detail
 self.refs.Detail.Visible=detail
 self.refs.Back.Visible=detail
 self.refs.Title.Position=UDim2.fromOffset(if detail then 60 else 12,5)
 for _,section in Catalog.Sections do
  local tab=self.refs.Tabs[section.id]
  tab.Visible=not detail
  local selected=self.section==section.id
  local accent=Color3.fromHex(section.color)
  local color=if selected then accent else accent:Lerp(T.White,.72)
  if tab:GetAttribute("BaseColor")~=color then tab:SetAttribute("BaseColor",color);tab.BackgroundColor3=color end
  W.SetButton(tab,Locale.Text(if self.refs.CompactHeader and section.id=="boost" then "ДЕНЬГИ" else section.title),true,false)
 end
 for id,row in self.rows do
  local visible=if detail then self.detailId==id else Catalog.Card(id).Section==self.section
  local parent=if not visible then self.refs.Parking elseif detail then self.refs.Detail else self.refs.Body
  if row.Root.Parent~=parent then row.Root.Parent=parent end
  row.Root.Visible=visible
  if not visible then self:DropScene(id);continue end
  self:Copy(id,row,net.state)
  local offer=self:Offer(id,net.state)
  local product=Products.Items[id]
  row.Illustration.Visible=not detail or product~=nil
  row.Viewport.Visible=detail and product==nil
  row.PhasePlate.Visible=row.Viewport.Visible
  row.Price.Text=if offer.owned then Locale.Text("Куплено") elseif offer.loading then Locale.Text("Загружаем цену Roblox…")
   elseif offer.onSale and offer.price then string.format(Locale.Text("Цена Roblox: %d R$"),offer.price)
   elseif not offer.priceKnown then Locale.Text("Цена временно недоступна")
   else Locale.Text("Сейчас не продаётся")
  row.Buy.Visible=offer.owned~=true and offer.onSale==true and offer.price~=nil
  if (product or Packs.Items[id]) and not offer.gamePassId and not offer.productId and not offer.owned then row.Price.Text=Locale.Text("Скоро") end
  row.Equip.Visible=offer.owned==true and not offer.selected and id~="money_x3"
  if offer.owned then row.Price.Text=Locale.Text(if offer.selected then "✓ ВЫБРАНО" else "✓ КУПЛЕНО") end
  if offer.trial then row.Price.Text=Locale.Text("Пробный доступ на эту сессию") end
  local priceLabel=if offer.pending then "…" elseif offer.price then string.format("%d R$",offer.price) else ""
  W.SetButton(row.Buy,priceLabel,row.Buy.Visible
   and net.connected and not net:IsBusy() and not offer.pending and offer.canPurchase or false,offer.pending==true)
  W.SetButton(row.Equip,Locale.Text("ВЫБРАТЬ"),row.Equip.Visible and net.connected and not net:IsBusy() and offer.canEquip or false,false)
  row.Reset.Visible=offer.selected==true and self:Binding(id)~=nil
  W.SetButton(row.Reset,Locale.Text("СНЯТЬ ОФОРМЛЕНИЕ"),net.connected and not net:IsBusy() and offer.canEquip==true,false)
  W.SetButton(row.Preview,Locale.Text(if product then "ПОДРОБНЕЕ" elseif detail and Packs.AbilityForOffer(id) then "ПОВТОРИТЬ ПОКАЗ" else "ПРИМЕРИТЬ"),true,false)
  row.Preview.Visible=not detail or product==nil
  if detail then Skin.LayoutDetail(row,self.refs.Detail.AbsoluteSize.X-12)
  else Skin.LayoutTile(row) end
 end
end
function Shop:Step(now)
 if self.dead or not self.refs.Root.Visible then return end
 if GuiService.MenuIsOpen or not self.ctx.refs.Gui.Enabled or self.ctx.presenting or self.ctx.forgeReveal or self.ctx.rewardOverlay then
  self:ClearPreview();return
 end
 if now>=(self.nextRender or 0) then self.nextRender=now+1;self:Render() end
 if self.playing and now-self.playAt>=8.6 then self.playing=nil end
 local id=self.detailId
 if not id or Products.Items[id] then return end
 if not self.scenes[id] then
  self.scenes[id]=Scenes.new(self.rows[id].Viewport,self:Variant(id),{interior=id=="premium_homes" and self.interior})
 end
 local reduced=self.ctx.settings.values.ReducedMotion or self.ctx.settings.values.ReducedEffects
 local interval=if reduced or not self.playing then 1/15 elseif self.ctx.settings.values.LowGraphics then 1/24 else 1/60
 if now<(self.nextFrame or 0) then return end;self.nextFrame=now+interval
 for id,scene in self.scenes do
  local age=if self.playing==id then now-self.playAt else 0
  self.rows[id].Phase.Text=Locale.Text(scene:Step(age,reduced or self.playing~=id))
 end
end
function Shop:Destroy() self.dead=true;self:ClearPreview();self.cleanup:Destroy() end
return Shop
