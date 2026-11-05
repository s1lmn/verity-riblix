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
local UI={};UI.__index=UI
function UI.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),rows={},prices={}},UI)
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
   if self:Preview(id) then ctx.sound:Play("DecorTryOn") end
  end))
  self.cleanup:Add(buy.Activated:Connect(function()
   local state=ctx.net.state;if not state then return end
   if (state.CosmeticsOwned or {})[id] then
    ctx.request("EquipCosmetic",{itemId=id,equipped=(state.CosmeticsEquipped or {})[item.slot]~=id})
   else ctx.request("CosmeticPurchase",{itemId=id}) end
  end))
 end
 return self
end
function UI:Preview(id)
 local item=assert(Catalog.Items[id],"Unknown cosmetic")
 local equipped=table.clone((self.ctx.net.state or {}).CosmeticsEquipped or {})
 equipped[item.slot]=id
 CosmeticFactory.Apply(self.preview,equipped)
 self.previewId=id
 self.ctx.refs.Panels.COSMETICS.Body.CanvasPosition=Vector2.new(0,0)
 Locale.Bind(self.ctx.refs.Panels.COSMETICS.PreviewCaption,item.name)
 return self.preview:FindFirstChild("Cosmetics"):FindFirstChild(id)~=nil
end
function UI:Render()
 local state=self.ctx.net.state
 local offers={};for _,item in (state and state.CosmeticsCatalog or {}) do offers[item.id]=item end
 for id,row in self.rows do
  local item=Catalog.Items[id];local offer=offers[id]
  row.name.Text=Locale.Text(item.name)
  row.category.Text=Locale.Text(item.category)
  W.SetButton(row.tryOn,if self.previewId==id then Locale.Text("ПРИМЕРЯЕТСЯ") else Locale.Text("ПРИМЕРИТЬ"),true,false)
  local owned=state and (state.CosmeticsOwned or {})[id]
  local equipped=state and (state.CosmeticsEquipped or {})[item.slot]==id
  local busy=self.ctx.net:IsBusy()
  local available=offer and offer.available==true
  local price=offer and self.prices[offer.productId]
  if available and self.prices[offer.productId]==nil then
   self.prices[offer.productId]=false
   task.spawn(function()
    local ok,info=pcall(function()return Market:GetProductInfoAsync(offer.productId,Enum.InfoType.Product)end)
    if self.dead then return end
    if ok and type(info)=="table" and info.IsForSale~=false and type(info.PriceInRobux)=="number" then self.prices[offer.productId]=info.PriceInRobux end
    if self.ctx.refs.Panels.COSMETICS.Root.Visible then self:Render() end
   end)
  end
  local text=if owned then (if equipped then Locale.Text("REMOVE") else Locale.Text("EQUIP")) elseif available then (if price then Locale.Text("BUY · R$")..price else Locale.Text("BUY WITH ROBUX")) else Locale.Text("NOT ON SALE")
  W.SetButton(row.buy,if busy then Locale.Text("WAIT…") else text,self.ctx.net.connected and state~=nil and state.VerityUnlocked and not busy and (owned or available),busy)
  row.info.Text=if equipped then Locale.Text("Equipped · saved with your progress") elseif owned then Locale.Text("Owned") elseif available then Locale.Text("Roblox confirms the purchase") else Locale.Text("Preview available · shop item is not on sale yet")
 end
end
function UI:Destroy() self.dead=true;self.cleanup:Destroy() end
return UI
