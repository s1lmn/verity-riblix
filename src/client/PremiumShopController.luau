--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.Shared.PremiumVisualCatalog)
local Themes=require(RS.Shared.HomeStyleConfig)
local World=RS.World
local Interior=require(World.InteriorFactory)
local HouseArt=require(World.PremiumHouseArt)
local DecorArt=require(World.PremiumDecorArt)
local Verity=require(World.VerityFactory)
local Fusion=require(World.VerityFusionFactory)
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local Skin=require(script.Parent.PremiumShopSkin)
local W=require(script.Parent.UIWidgets)
local Shop={};Shop.__index=Shop

local function part(parent,name,size,frame,hex)
 return W.New("Part",{Name=name,Size=size,CFrame=frame,Color=Color3.fromHex(hex),Anchored=true,
  CanCollide=false,CanQuery=false,CanTouch=false,Material=Enum.Material.SmoothPlastic},parent)
end

function Shop.new(ctx,money,abilities)
 local self=setmetatable({ctx=ctx,money=money,abilities=abilities,cleanup=Cleanup.new(),rows={},variants={},section="boost"},Shop)
 local refs=ctx.refs.Panels.SHOP;self.refs=refs
 self.previewWorld=W.New("WorldModel",{},refs.Preview)
 self.camera=W.New("Camera",{FieldOfView=40},refs.Preview);refs.Preview.CurrentCamera=self.camera
 for section,tab in refs.Tabs do
  self.cleanup:Add(tab.Activated:Connect(function()
   self.section=section;self:ClearPreview();refs.Body.CanvasPosition=Vector2.zero;self:Render()
  end))
 end
 for index,id in Catalog.Order do
  local card=Catalog.Card(id)
  local row=Skin.Card(refs.Body,id,card,index)
  self.rows[id]=row
  self.cleanup:Add(row.Preview.Activated:Connect(function() self:Preview(id) end))
  self.cleanup:Add(row.Buy.Activated:Connect(function() self:Activate(id) end))
  if row.Variant then
   self.cleanup:Add(row.Variant.Activated:Connect(function()
    self.variants[id]=(self.variants[id] or 1)%#card.Variants+1
    if self.previewOffer==id then self:Preview(id) end
    self:Render()
   end))
  end
 end
 self.cleanup:Add(refs.HouseView.Activated:Connect(function()
  if self.previewOffer then self:Preview(self.previewOffer,not self.interior) end
 end))
 self.cleanup:Add(refs.Hide.Activated:Connect(function() self:ClearPreview() end))
 self.cleanup:Add(refs.Root:GetPropertyChangedSignal("Visible"):Connect(function()
  if refs.Root.Visible then self:Render() else self:ClearPreview() end
 end))
 return self
end

function Shop:ClearPreview()
 self.refs.Stage.Visible=false
 self.previewOffer=nil;self.interior=false
 self.previewWorld:ClearAllChildren()
end

function Shop:Variant(id)
 local bundle=Catalog.Passes[id]
 return if bundle and bundle.Variants then bundle.Variants[self.variants[id] or 1] else id
end
function Shop:Preview(offerId,interior)
 self:ClearPreview()
 self.previewOffer=offerId;self.interior=interior==true
 local id=self:Variant(offerId)
 local item=Catalog.Items[id]
 local house=item.Preview=="House"
 self.refs.HouseView.Visible=house
 self.refs.HouseView.Text=Locale.Text(if self.interior then "ФАСАД" else "ИНТЕРЬЕР")
 self.refs.Caption.Size=UDim2.new(1,if house then -170 else -72,0,39)
 local world=self.previewWorld
 local camera=self.camera
 if item.Preview=="House" then
  local theme=Themes.Themes[item.Theme]
  local house=Interior.CreateHouse(world,CFrame.identity,Color3.fromHex(theme.Color))
  HouseArt.Build(house,CFrame.identity,item.Theme)
  camera.CFrame=if self.interior then CFrame.lookAt(Vector3.new(8,7,11),Vector3.new(-12,4,2))
   else CFrame.lookAt(Vector3.new(32,24,67),Vector3.new(0,8,6))
 elseif item.Preview=="Fusion" then
  Fusion.Create(world,nil,id)
  camera.CFrame=CFrame.lookAt(Vector3.new(4,8,21),Vector3.new(0,5.4,0))
 elseif item.Preview=="Hero" then
  local pet=Verity.Create(world,CFrame.identity,{level=1,preview=true})
  pet.Body.Color=Color3.fromHex("FFCC54");pet.PrimaryPart.LevelLabel.Enabled=false
  for _,side in {-1,1} do
   local a=Vector3.new(side*.29,1.09,-.79)
   local b=Vector3.new(side*.77,1.2,-2.5)
   local beam=part(world,"HeroLaser",Vector3.new(.075,.075,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),"FF3D60")
   beam.Material=Enum.Material.Neon
  end
  camera.CFrame=CFrame.lookAt(Vector3.new(2.4,2,-5),Vector3.new(0,.95,-.75))
 elseif item.Preview=="Aura" then
  local pet=Verity.Create(world,CFrame.identity,{level=1,preview=true})
  pet.PrimaryPart.LevelLabel.Enabled=false
  DecorArt.Build(world,CFrame.identity,id,true)
  camera.CFrame=CFrame.lookAt(Vector3.new(2.2,2,-4.9),Vector3.new(0,.8,0))
 elseif item.Preview=="Decor" then
  DecorArt.Build(world,CFrame.identity,id,true)
  local y=if id=="party_disco" or id==Catalog.Gallery.id then 2.9 else 3.6
  camera.CFrame=CFrame.lookAt(Vector3.new(6,6.5,13),Vector3.new(0,y,0))
 else
  for index,stack in {2,3,5} do
   for height=1,stack do
    local coin=part(world,"Coin",Vector3.new(.19,1.15,1.15),CFrame.new((index-2)*1.34,height*.19,0)*CFrame.Angles(0,0,math.pi/2),if height%2==0 then "FFC555" else "FFDF87")
    coin.Shape=Enum.PartType.Cylinder
   end
  end
  camera.CFrame=CFrame.lookAt(Vector3.new(2,2.4,-5),Vector3.new(0,.5,0))
 end
 Locale.Bind(self.refs.Caption,item.Title)
 self.refs.Stage.Visible=true;self.refs.Body.CanvasPosition=Vector2.zero
 self.ctx.sound:Play("DecorTryOn")
end

function Shop:Offer(id,state)
 if not state then return nil end
 if id=="money_x3" then
  return {owned=state.MoneyPassOwned,selected=state.MoneyPassOwned,price=self.money.offer and self.money.offer.PriceInRobux,
   pending=self.money.promptOpen,canPurchase=self.money.offer~=nil}
 elseif id=="scarlet_sentinel" then
  local equipment=state.AbilitiesEquipped or {}
  return {owned=state.HeroPassOwned,trial=state.HeroPassTrial,
   selected=state.HeroPassOwned and equipment.Attack==Catalog.HeroAbilityId and equipment.Mobility==Catalog.HeroAbilityId,
   price=self.abilities.offer and self.abilities.offer.PriceInRobux,pending=self.abilities.promptOpen,
   canEquip=state.VerityUnlocked,canPurchase=self.abilities.offer~=nil and state.VerityUnlocked}
 end
 local premium=state.PremiumShop
 local offers=type(premium)=="table" and premium.offers
 local offer=type(offers)=="table" and offers[id]
 if type(offer)~="table" then return nil end
 local variantId=self:Variant(id)
 if variantId==id then return offer end
 local variant=type(offer.variants)=="table" and offer.variants[variantId]
 local projected=table.clone(offer)
 projected.selected=type(variant)=="table" and variant.selected==true
 projected.canEquip=type(variant)=="table" and variant.canEquip==true
 return projected
end

function Shop:Activate(id)
 local net=self.ctx.net
 local offer=self:Offer(id,net.state)
 if not offer or not net.connected or net:IsBusy() or offer.selected or offer.pending then return end
 if id=="money_x3" then self.money:Buy()
 elseif id=="scarlet_sentinel" then self.abilities:Activate(Catalog.HeroAbilityId)
 elseif offer.owned and offer.canEquip and net.remotes.EquipPremiumOffer then
  local variantId=self:Variant(id)
  self.ctx.request("EquipPremiumOffer",{itemId=id,variantId=if variantId~=id then variantId else nil})
 elseif not offer.owned and offer.canPurchase and net.remotes.BuyPremiumOffer then
  self.ctx.request("BuyPremiumOffer",{itemId=id})
 end
 self:Render()
end

function Shop:Render()
 if not self.refs.Root.Visible then return end
 local net=self.ctx.net
 for _,section in Catalog.Sections do
  local selected=section.id==self.section
  W.SetButton(self.refs.Tabs[section.id],(if selected then "✓ " else "")..Locale.Text(section.title),true,false)
 end
 for id,row in self.rows do
  local card=Catalog.Card(id)
  row.Root.Visible=card.Section==self.section
  if not row.Root.Visible then continue end
  if row.Variant then
   row.Variant.Text=string.format(Locale.Text("Вариант %d/%d · %s ›"),self.variants[id] or 1,#card.Variants,Locale.Text(Catalog.Items[self:Variant(id)].Title))
  end
  local offer=self:Offer(id,net.state) or {}
  local planned=Catalog.Passes[id]
  local pass=id=="money_x3" or id=="scarlet_sentinel"
  local validPrice=type(offer.price)=="number" and offer.price>=0 and offer.price<math.huge and offer.price%1==0
  local buy=offer.canPurchase and validPrice and (pass or net.remotes.BuyPremiumOffer~=nil)
  local equip=offer.canEquip and (pass or net.remotes.EquipPremiumOffer~=nil)
  local label=if offer.pending then Locale.Text("ПОДТВЕРДИ ПОКУПКУ В ROBLOX")
   elseif offer.selected then Locale.Text(if offer.trial then "ВЫБРАНО · НА СЕССИЮ" else "ВЫБРАНО")
   elseif offer.owned then Locale.Text(if offer.trial then "НА СЕССИЮ · ВЫБРАТЬ" elseif equip then "КУПЛЕНО · ВЫБРАТЬ" else "КУПЛЕНО")
   elseif buy then string.format(Locale.Text("КУПИТЬ • %d R$"),offer.price)
   elseif planned then string.format(Locale.Text("СКОРО • %d R$"),planned.Price)
   else Locale.Text("СКОРО")
  W.SetButton(row.Buy,label,net.connected and not net:IsBusy() and not offer.pending and not offer.selected
   and (offer.owned and equip or not offer.owned and buy) or false,offer.pending==true)
 end
end

function Shop:Destroy() self:ClearPreview();self.cleanup:Destroy() end
return Shop
