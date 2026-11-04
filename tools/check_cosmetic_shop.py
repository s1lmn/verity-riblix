"""Execute native cosmetic shop/controller with mocked services. Not a Studio render."""
from pathlib import Path
import sys,subprocess,tempfile
r=Path(__file__).resolve().parents[1]
skin=(r/'src/client/CosmeticShopSkin.luau').read_text()
widgets=(r/'src/client/UIWidgets.luau').read_text()
layout=(r/'src/client/PhoneLayout.luau').read_text()
theme=(r/'src/client/UITheme.luau').read_text()
h='''
local function color()local c={};function c:Lerp()return color()end;return c end
local Color3={fromHex=function()return color()end,new=function()return color()end,fromRGB=function()return color()end}
local ColorSequence={new=function()return {}end}
local UDim={new=function(s,o)return {Scale=s,Offset=o}end}
local UDim2={new=function(xs,xo,ys,yo)return {X={Scale=xs or 0,Offset=xo or 0},Y={Scale=ys or 0,Offset=yo or 0}}end}
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
local Vector3={new=function(...)return {...}end}
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local Enum={Font={Gotham=1,GothamBold=2},TextXAlignment={Left=1,Center=2},ApplyStrokeMode={Border=1},SortOrder={LayoutOrder=1},FillDirection={Horizontal=1,Vertical=2},SelectionBehavior={Stop=1},AutomaticSize={None=1,Y=2},ScrollingDirection={Y=1}}
local instances={}
local Instance={new=function(class)
 local o={ClassName=class}
 o.Activated={callbacks={}}
 function o.Activated:Connect(fn)table.insert(self.callbacks,fn);return {Disconnect=function()end}end
 function o.Activated:Fire()for _,fn in self.callbacks do fn()end end
 function o:SetAttribute(k,v)self[k]=v end
 table.insert(instances,o);return o
end}
local script={Parent={Locale='locale',UITheme='theme',UIWidgets='widgets',PhoneLayout='layout'}}
local Theme=(function() THEME end)()
local Layout=(function() LAYOUT end)()
local Widgets
local function require(k)return ({locale={BindStatic=function(o)return o end},theme=Theme,layout=Layout,widgets=Widgets})[k] end
Widgets=(function() WIDGETS end)()
local exports=table.pack((function() SKIN end)())
assert(exports.n==1 and type(exports[1].Build)=='function','skin module export')
local Skin=exports[1];local refs=Skin.Build({})
for _,name in {'Root','Title','Close','Body','Preview','Reset','PreviewCaption'} do assert(refs[name],name)end
assert(not refs.Root.Visible)
local Catalog=(function() CATALOG end)()
for _,size in {{320,568},{390,844},{568,320},{844,390},{1920,1080}} do
 local x=if size[1]<640 then 12 else 172
 local p=Skin.Layout(refs,{X=size[1],Y=size[2]},x)
 assert(p.width+x<=size[1]-12 and p.height+24<=size[2],'safe bounds')
 for _,name in {'Close','Reset'} do assert(refs[name].Size.Y.Offset>=44,name)end
 for i,id in Catalog.Order do
  local row=Skin.Card(refs.Body,Catalog.Items[id],i)
  for _,name in {'buy','tryOn'} do
   local b=row[name];local w=p.width-32-6
   assert(b.Size.X.Scale*w+b.Size.X.Offset>=44,'button too narrow')
   assert(b.Size.Y.Offset>=44,'button too short')
   assert(b.Position.Y.Offset+b.Size.Y.Offset<=row.Root.Size.Y.Offset,'card clip')
  end
 end
end
local Cleanup={new=function()return {Add=function(_,v)return v end,Destroy=function()end}end}
local Locale={Text=function(s)return s end,Bind=function()end}
local mockModel={PrimaryPart={LevelLabel={Title={}}}}
function mockModel:FindFirstChild()return {FindFirstChild=function(_,id)return self.equipped and self.equipped[Catalog.Items[id].slot]==id end}end
local factory={Create=function()return mockModel end}
local cosmetic={Apply=function(model,equipped)model.equipped=table.clone(equipped)end}
local RS={World={VerityFactory='factory',CosmeticFactory='cosmetic'},Shared={CosmeticCatalog='catalog'}}
local game={GetService=function(_,name)return if name=='ReplicatedStorage' then RS else {} end}
local CFrame={identity={},lookAt=function()return {}end}
local script={Parent={Locale='locale',UIWidgets='widgets',CosmeticShopSkin='skin',Cleanup='cleanup'}}
local function require(k)return ({locale=Locale,widgets=Widgets,skin=Skin,cleanup=Cleanup,factory=factory,cosmetic=cosmetic,catalog=Catalog})[k]end
local UI=(function() CONTROLLER end)()
assert(type(UI.new)=='function','controller export')
local requests={}
local ctx={refs={Panels={COSMETICS=refs}},net={connected=true,IsBusy=function()return false end},
 request=function(a,v)table.insert(requests,{action=a,args=v})end,sound={Play=function()end}}
local controller=UI.new(ctx)
ctx.net.state={VerityUnlocked=true,CosmeticsOwned={round_glasses=true},CosmeticsEquipped={Face='round_glasses'},CosmeticsCatalog={}}
controller:Render()
assert(controller.rows.round_glasses.buy.Text=='REMOVE')
assert(controller.rows.round_glasses.buy.Interactable)
assert(not controller.rows.party_hat.buy.Interactable,'unconfigured sale')
controller.rows.party_hat.tryOn.Activated:Fire();controller:Render()
assert(controller.previewId=='party_hat' and #requests==0,'try-on issued purchase')
assert(mockModel.equipped.Face=='round_glasses' and mockModel.equipped.Head=='party_hat')
refs.Reset.Activated:Fire()
assert(mockModel.equipped.Head==nil and controller.previewId==nil,'reset did not restore real equipped state')
controller.rows.round_glasses.buy.Activated:Fire()
assert(requests[1].action=='EquipCosmetic' and requests[1].args.equipped==false)
ctx.net.state.CosmeticsEquipped={};controller:Render()
assert(controller.rows.round_glasses.buy.Text=='EQUIP')
ctx.net.state.CosmeticsCatalog={{id='party_hat',available=true,productId=101}}
controller.prices[101]=79;controller:Render()
assert(controller.rows.party_hat.buy.Text=='BUY · R$79')
assert(controller.rows.party_hat.buy.Interactable)
controller.rows.party_hat.buy.Activated:Fire()
assert(requests[2].action=='CosmeticPurchase' and requests[2].args.itemId=='party_hat')
assert(not ctx.net.state.CosmeticsOwned.party_hat,'local receipt fabricated')
ctx.net.IsBusy=function()return true end;controller:Render()
assert(not controller.rows.party_hat.buy.Interactable,'busy purchase enabled')
ctx.net.IsBusy=function()return false end
ctx.net.connected=false;controller:Render()
assert(not controller.rows.round_glasses.buy.Interactable,'offline purchase enabled')
ctx.net.state=nil;controller:Render()
assert(not controller.rows.round_glasses.buy.Interactable)
assert(controller:Preview('star_earrings'),'offline preview failed')
controller:Destroy()
print('Cosmetic shop: actual skin/controller constructors, 5 viewport bounds, touch targets, ownership/equip/offline states, local try-on and reset passed; no Studio Play')
'''
for a,b in [('THEME',theme),('LAYOUT',layout),('WIDGETS',widgets),('SKIN',skin),('CATALOG',(r/'src/shared/CosmeticCatalog.luau').read_text()),('CONTROLLER',(r/'src/client/CosmeticsUIController.luau').read_text())]:h=h.replace(a,b)
with tempfile.TemporaryDirectory(prefix='verity-phone-') as t:
 p=Path(t)/'phone.luau';p.write_text(h);subprocess.run([sys.argv[1],str(p)],check=True)
