--!nonstrict
local Locale = require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local Skin=require(script.Parent.CosmeticShopSkin)
local Cleanup=require(script.Parent.Cleanup)
local Market=game:GetService("MarketplaceService")
local World=game:GetService("ReplicatedStorage").World
local Factory=require(World.VerityFactory)
local CosmeticFactory=require(World.CosmeticFactory)
local Catalog=require(game:GetService("ReplicatedStorage").Shared.CosmeticCatalog)
local Rewards=require(game:GetService("ReplicatedStorage").Shared.ActivityRewards)
local UI={};UI.__index=UI
function UI.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),rows={},prices={},selected={}},UI)
 local panel=ctx.refs.Panels.COSMETICS
 local preview=panel.Preview
 local world=self.cleanup:Add(W.New("WorldModel",{},preview))
 local camera=self.cleanup:Add(W.New("Camera",{CFrame=CFrame.lookAt(Vector3.new(0,1.1,-4.3),Vector3.new(0,1,0)),FieldOfView=40},preview))
 preview.CurrentCamera=camera
 self.preview=Factory.Create(world,CFrame.identity,{level=1,preview=true})
 Locale.Bind(self.preview.PrimaryPart.LevelLabel.Title,"VERITY • LVL %d",1)
 self.cleanup:Add(panel.Reset.Activated:Connect(function()
  CosmeticFactory.Apply(self.preview,(ctx.net.state or {}).CosmeticsEquipped or {})
  self.previewId=nil;Locale.Bind(panel.PreviewCaption,"ТВОЙ ТЕКУЩИЙ ОБРАЗ")
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
   elseif item.source=="WeatherForge" then ctx.notifications:Show("Создай венец за погодные материалы в кузнице погоды.");if ctx.forge then ctx.forge.routeRequested=os.clock()+180 end;ctx.close()
   elseif item.source=="Fusion" then ctx.notifications:Show(Locale.Text("Заверши заезд слияния, чтобы получить подвески."))
   elseif item.starter then return
   else ctx.request("CosmeticPurchase",{itemId=id}) end
  end))
 end
 return self
end
function UI:SelectedId(id)
 local state=self.ctx.net.state
 local item=Catalog.Items[id]
 local equipped=state and (state.CosmeticsEquipped or {})[item.slot]
 return self.selected[id] or (if Catalog.BaseId(equipped)==id then equipped else id)
end
function UI:Preview(id)
 local item=assert(Catalog.Items[id],"Unknown cosmetic")
 local equipped=table.clone((self.ctx.net.state or {}).CosmeticsEquipped or {})
 equipped[item.slot]=id
 CosmeticFactory.Apply(self.preview,equipped)
 self.previewId=id
 self.ctx.refs.Panels.COSMETICS.Body.CanvasPosition=Vector2.new(0,0)
 local caption=self.ctx.refs.Panels.COSMETICS.PreviewCaption
 if item.tone then Locale.Bind(caption,"%s • %s",Locale.Text(item.name),Locale.Text(Catalog.Tones[item.tone].name))
 else Locale.Bind(caption,item.name) end
 return self.preview:FindFirstChild("Cosmetics"):FindFirstChild(id)~=nil
end
function UI:Render()
 local state=self.ctx.net.state
 local offers={};for _,item in (state and state.CosmeticsCatalog or {}) do offers[item.id]=item end
 for id,row in self.rows do
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
