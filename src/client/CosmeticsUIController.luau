--!nonstrict
local Locale = require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
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
 local preview=W.New("ViewportFrame",{Name="Preview",Size=UDim2.new(1,-4,0,190),BackgroundColor3=T.Soft,
  BorderSizePixel=0,Ambient=Color3.fromRGB(210,210,210),LightColor=Color3.new(1,1,1),LightDirection=Vector3.new(-1,-1,-1)},panel.Body)
 W.Round(preview,12)
 local world=W.New("WorldModel",{},preview)
 local camera=W.New("Camera",{CFrame=CFrame.lookAt(Vector3.new(0,1.1,-4.3),Vector3.new(0,1,0)),FieldOfView=40},preview)
 preview.CurrentCamera=camera
 self.preview=Factory.Create(world,CFrame.identity,{level=1,preview=true})
 Locale.Bind(self.preview.PrimaryPart.LevelLabel.Title,"VERITY • LVL %d",1)
 W.Line(panel.Body,"CosmeticNotice","Cosmetics only. No income or growth bonuses. Preview does not grant ownership.",42,12,false,T.Muted)
 for _,id in Catalog.Order do
  local item=Catalog.Items[id]
  local row=W.Block(panel.Body,id,128)
  local name=W.Text(row,"Name","",15,true)
  local previewButton=W.Button(row,"Preview","PREVIEW",T.Blue)
  previewButton.Position,previewButton.Size=UDim2.fromOffset(0,34),UDim2.new(.43,-4,0,44)
  local buy=W.Button(row,"EquipOrBuy","LOADING…",T.Mint)
  buy.Position,buy.Size=UDim2.new(.43,4,0,34),UDim2.new(.57,-4,0,44)
  local info=W.Text(row,"Status","Waiting for inventory",11,false,T.Muted)
  info.Position,info.Size=UDim2.fromOffset(0,84),UDim2.new(1,0,0,22)
  self.rows[id]={buy=buy,info=info,name=name}
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
 return self.preview:FindFirstChild("Cosmetics"):FindFirstChild(id)~=nil
end
function UI:Render()
 local state=self.ctx.net.state
 local offers={};for _,item in (state and state.CosmeticsCatalog or {}) do offers[item.id]=item end
 for id,row in self.rows do
  local item=Catalog.Items[id];local offer=offers[id]
  row.name.Text=Locale.Text(item.name).." · "..Locale.Text(item.category)
  local owned=state and (state.CosmeticsOwned or {})[id]
  local equipped=state and (state.CosmeticsEquipped or {})[item.slot]==id
  local busy=self.ctx.net:IsBusy()
  local available=offer and offer.available==true
  local price=offer and self.prices[offer.productId]
  if available and self.prices[offer.productId]==nil then
   self.prices[offer.productId]=false
   task.spawn(function()
    local ok,info=pcall(function()return Market:GetProductInfoAsync(offer.productId,Enum.InfoType.Product)end)
    if ok and info.IsForSale~=false and type(info.PriceInRobux)=="number" then self.prices[offer.productId]=info.PriceInRobux end
   end)
  end
  local text=if owned then (if equipped then Locale.Text("REMOVE") else Locale.Text("EQUIP")) elseif available then (if price then Locale.Text("BUY · R$")..price else Locale.Text("BUY WITH ROBUX")) else Locale.Text("NOT ON SALE")
  W.SetButton(row.buy,if busy then Locale.Text("WAIT…") else text,state~=nil and state.VerityUnlocked and not busy and (owned or available),busy)
  row.info.Text=if equipped then Locale.Text("Equipped · saved with your progress") elseif owned then Locale.Text("Owned") elseif available then Locale.Text("Roblox confirms the purchase") else Locale.Text("Preview available · shop item is not on sale yet")
 end
end
function UI:Destroy() self.cleanup:Destroy() end
return UI
