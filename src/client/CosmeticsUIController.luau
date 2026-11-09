--!nonstrict
local Locale = require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Skin=require(script.Parent.CosmeticShopSkin)
local Cleanup=require(script.Parent.Cleanup)
local Market=game:GetService("MarketplaceService")
local RS=game:GetService("ReplicatedStorage")
local World=RS.World
local Forge=require(RS.Shared.WeatherForgeConfig)
local lookOrder={"Original","Auto",table.unpack(Forge.LookOrder)}
local Factory=require(World.VerityFactory)
local CosmeticFactory=require(World.CosmeticFactory)
local Catalog=require(game:GetService("ReplicatedStorage").Shared.CosmeticCatalog)
local Rewards=require(game:GetService("ReplicatedStorage").Shared.ActivityRewards)
local UI={};UI.__index=UI
function UI.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),rows={},lookRows={},prices={},selected={},tab="Accessories"},UI)
 local panel=ctx.refs.Panels.COSMETICS
 local preview=panel.Preview
 local world=self.cleanup:Add(W.New("WorldModel",{},preview))
 local camera=self.cleanup:Add(W.New("Camera",{CFrame=CFrame.lookAt(Vector3.new(0,1.1,-4.3),Vector3.new(0,1,0)),FieldOfView=40},preview))
 preview.CurrentCamera=camera
 self.preview=Factory.Create(world,CFrame.identity,{level=1,preview=true})
 self.preview.PrimaryPart.LevelLabel.Enabled=false
 self.cleanup:Add(panel.Reset.Activated:Connect(function()
  self.previewId=nil;self.previewLook=nil;self:Render()
 end))
 for _,tab in {"Accessories","Looks"} do
  self.cleanup:Add(panel[tab].Activated:Connect(function()
   self.tab=tab;self.previewId=nil;self.previewLook=nil
   panel.Body.CanvasPosition=Vector2.zero;self:Render()
  end))
 end
 for index,id in lookOrder do
  local look=Forge.Looks[id]
  local row=Skin.LookCard(panel.Body,id,index,if look then Color3.fromHex(look.Color) else T.Blue)
  self.lookRows[id]=row
  self.cleanup:Add(row.tryOn.Activated:Connect(function()
   self.previewId=nil;self.previewLook=id
   panel.Body.CanvasPosition=Vector2.zero;self:Render();ctx.sound:Play("DecorTryOn")
  end))
  self.cleanup:Add(row.buy.Activated:Connect(function()
   local state=ctx.net.state
   if not state or not state.VerityUnlocked then return end
   if look and not (state.CosmeticsOwned or {})[look.Item] then self:GuideToForge()
   else
    self.previewLook=nil
    ctx.request("SetWeatherLook",{itemId=id});self:Render()
   end
  end))
 end
 self.cleanup:Add(RS:GetAttributeChangedSignal("VerityWeatherKind"):Connect(function()
  if panel.Root.Visible then self:Render() end
 end))
 for index,id in Catalog.Order do
  local item=Catalog.Items[id]
  local row=Skin.Card(panel.Body,item,index)
  self.rows[id]=row
  local previewButton,buy=row.tryOn,row.buy
  self.cleanup:Add(previewButton.Activated:Connect(function()
   if self:Preview(self:SelectedId(id)) then ctx.sound:Play("DecorTryOn") end
  end))
  for variantId,button in row.tones do
   self.cleanup:Add(button.Activated:Connect(function()
    self.selected[id]=variantId
    if self:Preview(variantId) then ctx.sound:Play("DecorTryOn") end
    self:Render()
   end))
  end
  self.cleanup:Add(buy.Activated:Connect(function()
   local state=ctx.net.state;if not state then return end
   local selected=self:SelectedId(id)
   if Catalog.Owns(state.CosmeticsOwned,selected) then
    ctx.request("EquipCosmetic",{itemId=selected,equipped=(state.CosmeticsEquipped or {})[item.slot]~=selected})
   elseif item.achievement and Rewards.Items[item.achievement].activity=="Secrets" and ctx.secrets then
    local id=if item.achievement=="secret_solar" then "solar" elseif item.achievement=="secret_canopy" then "canopy" else "cloud"
    ctx.secrets:Select(id)
   elseif item.achievement then ctx.notifications:Show(Locale.Text(Rewards.Items[item.achievement].condition))
   elseif item.source=="StreetDelivery" then ctx.notifications:Show(Locale.Text("Обычная награда 70% • ×2 22% • ×5 6% • украшение 2%. Все украшения собраны — компенсация ×5."))
   elseif item.source=="WeatherForge" then self:GuideToForge()
   elseif item.source=="Fusion" then ctx.notifications:Show(Locale.Text("Заверши заезд слияния, чтобы получить подвески."))
   elseif item.starter then return
   else ctx.request("CosmeticPurchase",{itemId=id}) end
  end))
 end
 return self
end
function UI:GuideToForge()
 local ctx=self.ctx
 ctx.notifications:Show(Locale.Text("Следуй по стрелкам к кузнице погоды."))
 if ctx.forge then ctx.forge.routeRequested=os.clock()+180 end
 ctx.close()
end
function UI:SelectedId(id)
 local state=self.ctx.net.state
 local item=Catalog.Items[id]
 local equipped=state and (state.CosmeticsEquipped or {})[item.slot]
 return self.selected[id] or (if Catalog.BaseId(equipped)==id then equipped else id)
end
function UI:Preview(id)
 self.previewId=id;self.previewLook=nil
 self:RenderPreview()
 self.ctx.refs.Panels.COSMETICS.Body.CanvasPosition=Vector2.new(0,0)
 return self.preview:FindFirstChild("Cosmetics"):FindFirstChild(id)~=nil
end
function UI:RenderPreview()
 local state=self.ctx.net.state or {}
 local level=state.VerityLevel or 1
 local weather=RS:GetAttribute("VerityWeatherKind") or "Clear"
 local look=Forge.Resolve(self.previewLook or state.WeatherLook or "Original",weather)
 local equipped=table.clone(state.CosmeticsEquipped or {})
 local item=self.previewId and Catalog.Items[self.previewId]
 if item then equipped[item.slot]=self.previewId end
 local signature=table.concat({tostring(level),look and look.Id or "",equipped.Face or "",equipped.Head or "",equipped.Ears or ""},"|")
 if signature~=self.previewSignature then
  self.previewSignature=signature
  self.preview:SetAttribute("WeatherSkinOverride",look and look.Skin or nil)
  self.preview:SetAttribute("Cosmetic_Head",equipped.Head)
  Factory.SetStage(self.preview,level)
  local body=self.preview:FindFirstChild("Body")
  if body and body:GetAttribute("VerityTint") then body.Color=Factory.Color(level) end
  CosmeticFactory.Apply(self.preview,equipped)
 end
 local caption=self.ctx.refs.Panels.COSMETICS.PreviewCaption
 if item and item.tone then Locale.Bind(caption,"%s • %s",Locale.Text(item.name),Locale.Text(Catalog.Tones[item.tone].name))
 elseif item then Locale.Bind(caption,item.name)
 elseif self.previewLook and look then Locale.Bind(caption,look.Name)
 else Locale.Bind(caption,"Уровень %d · %s",level,Locale.Text(if look then look.Name else "Облик по уровню")) end
end
function UI:Render()
 local state=self.ctx.net.state
 local panel=self.ctx.refs.Panels.COSMETICS
 local skins=self.tab=="Looks"
 W.SetButton(panel.Accessories,Locale.Text("АКСЕССУАРЫ"),skins,false)
 W.SetButton(panel.Looks,Locale.Text("СКИНЫ"),not skins,false)
 panel.Notice.Text=Locale.Text(if skins then "Уровень определяет базовый облик. Постоянные скины открываются в кузнице." else "Украшения меняют только внешний вид. Примерка бесплатная.")
 local selection=state and state.WeatherLook or "Original"
 local ready=state and state.VerityUnlocked and self.ctx.net.connected and not self.ctx.net:IsBusy()
 for id,row in self.lookRows do
  row.Root.Visible=skins
  if not skins then continue end
  local look=Forge.Looks[id]
  local owned=not look or (state and (state.CosmeticsOwned or {})[look.Item]==true)
  local selected=selection==id
  row.name.Text=Locale.Text(if look then look.Name elseif id=="Auto" then "Облик по погоде" else "Облик по уровню")
  row.info.Text=Locale.Text(if id=="Auto" then "Временно меняет облик во время особой погоды." elseif id=="Original" then "Меняется по мере роста Verity." elseif owned then "Скин открыт" else "Открывается в кузнице погоды")
  W.SetButton(row.tryOn,Locale.Text(if self.previewLook==id then "ПРИМЕРЯЕТСЯ" else "ПРИМЕРИТЬ"),true,false)
  W.SetButton(row.buy,Locale.Text(if selected then "ВЫБРАНО" elseif owned then "ВЫБРАТЬ" else "К КУЗНИЦЕ"),ready and not selected,false)
 end
 self:RenderPreview()
 local offers={};for _,item in (state and state.CosmeticsCatalog or {}) do offers[item.id]=item end
 for id,row in self.rows do
  row.Root.Visible=not skins
  if skins then continue end
  local item=Catalog.Items[id];local offer=offers[id]
  row.name.Text=Locale.Text(item.name)
  row.category.Text=Locale.Text(item.category)
  local selected=self:SelectedId(id)
  for variantId,button in row.tones do
   local tone=Catalog.Tones[Catalog.Items[variantId].tone]
   W.SetButton(button,(if selected==variantId then "✓ " else "")..Locale.Text(tone.name),true,false)
  end
  W.SetButton(row.tryOn,if self.previewId==selected then Locale.Text("ПРИМЕРЯЕТСЯ") else Locale.Text("ПРИМЕРИТЬ"),true,false)
  local owned=state and Catalog.Owns(state.CosmeticsOwned,selected)
  local equipped=state and (state.CosmeticsEquipped or {})[item.slot]==selected
  local busy=self.ctx.net:IsBusy()
  local available=offer and offer.available==true
  local price=offer and offer.productId and self.prices[offer.productId]
  if available and self.prices[offer.productId]==nil then
   self.prices[offer.productId]=false
   task.spawn(function()
    local ok,info=pcall(function()return Market:GetProductInfoAsync(offer.productId,Enum.InfoType.Product)end)
    if self.dead then return end
    if ok and type(info)=="table" and info.IsForSale~=false and type(info.PriceInRobux)=="number" then self.prices[offer.productId]=info.PriceInRobux end
    if self.ctx.refs.Panels.COSMETICS.Root.Visible then self:Render() end
   end)
  end
  local achievement=item.achievement and Rewards.Items[item.achievement]
  local text=if owned then (if equipped then Locale.Text("REMOVE") else Locale.Text("EQUIP")) elseif achievement or item.exclusive then Locale.Text("КАК ПОЛУЧИТЬ") elseif item.starter then Locale.Text("ОТКРОЙ VERITY") elseif available then (if price then Locale.Text("BUY · R$")..price else Locale.Text("BUY WITH ROBUX")) else Locale.Text("NOT ON SALE")
  W.SetButton(row.buy,if busy then Locale.Text("WAIT…") else text,self.ctx.net.connected and state~=nil and state.VerityUnlocked and not busy and (owned or available or achievement~=nil or item.exclusive),busy)
  if achievement then
   if row.progress then row.progress.Size=UDim2.fromScale(if owned then 1 else 0,1) end
   local progress=string.format(Locale.Text(achievement.progress),if owned then 1 else 0)
   row.info.Text=if owned then Locale.Text("Награда получена").." • "..progress else Locale.Text(achievement.condition).." "..progress
  elseif item.source=="StreetDelivery" then
   row.info.Text=if owned then Locale.Text("Награда получена") else Locale.Text("Бесплатная доставка • шанс украшения 2%")
  elseif item.source=="WeatherForge" then
   row.info.Text=if owned then Locale.Text("Награда получена") else Locale.Text("Создай венец за погодные материалы в кузнице погоды.")
  elseif item.source=="Fusion" then
   row.info.Text=if owned then Locale.Text("Награда получена") else Locale.Text("Заверши заезд слияния, чтобы получить подвески.")
  elseif item.starter then
   row.info.Text=if equipped then Locale.Text("Equipped · saved with your progress") else Locale.Text("Бесплатно после открытия Verity. Выбери цвет и надень!")
  else
  row.info.Text=if equipped then Locale.Text("Equipped · saved with your progress") elseif owned then Locale.Text("Owned") elseif available then Locale.Text("Roblox confirms the purchase") else Locale.Text("Preview available · shop item is not on sale yet")
  end
 end
end
function UI:Destroy() self.dead=true;self.cleanup:Destroy() end
return UI
