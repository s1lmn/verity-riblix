"""Execute companion/workshop skins and controllers with mocked engine values. Not a Studio render."""
from pathlib import Path
import sys,subprocess,tempfile
r=Path(__file__).resolve().parents[1]
skin=(r/'src/client/GrowthPanelsSkin.luau').read_text()
widgets=(r/'src/client/UIWidgets.luau').read_text()
layout=(r/'src/client/PhoneLayout.luau').read_text()
theme=(r/'src/client/UITheme.luau').read_text()
h='''
local function color()local c={};function c:Lerp()return color()end;return c end
local Color3={fromHex=function()return color()end,new=function()return color()end}
local ColorSequence={new=function()return {}end}
local UDim={new=function(s,o)return {Scale=s,Offset=o}end}
local UDim2={new=function(xs,xo,ys,yo)return {X={Scale=xs or 0,Offset=xo or 0},Y={Scale=ys or 0,Offset=yo or 0}}end}
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local Enum={Font={Gotham=1,GothamBold=2},TextXAlignment={Left=1,Center=2},ApplyStrokeMode={Border=1},SortOrder={LayoutOrder=1},FillDirection={Horizontal=1,Vertical=2},SelectionBehavior={Stop=1},AutomaticSize={None=1,Y=2},ScrollingDirection={Y=1}}
local function signal()
 local callbacks={}
 return {Connect=function(_,fn)table.insert(callbacks,fn);return {Disconnect=function()end}end,Fire=function(_,...)for _,fn in callbacks do fn(...)end end}
end
local instances={}
local Instance={new=function(class)
 local o={ClassName=class,Activated=signal(),Event=signal()}
 function o:Fire(...)self.Event:Fire(...)end
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
assert(exports.n==1 and type(exports[1].BuildVerity)=='function','skin module export')
local Skin=exports[1];local refs=Skin.BuildVerity({})
for _,name in {'Root','Title','Subtitle','Body','Close','Level','Income','Scale','House','Progress','Milestone','Buy','Note','Boost','Ability','MoneyPass','MoneyPassHint'} do assert(refs[name],name)end
assert(not refs.Root.Visible)
local workshop=Skin.BuildWorkshop({})
for _,size in {{320,568},{390,844},{568,320},{844,390},{1920,1080}} do
 local x=if size[1]<640 then 12 else 172
 for _,panel in {refs,workshop} do
  local p=Skin.Layout(panel,{X=size[1],Y=size[2]},x)
  assert(p.width+x<=size[1]-12 and p.height+24<=size[2],'safe bounds')
  assert(panel.Close.Size.Y.Offset>=44)
 end
 assert(refs.Buy.Size.Y.Offset>=44 and refs.MoneyPass.Size.Y.Offset>=44)
end
local Cleanup={new=function()return {Add=function(_,x)return x end,Destroy=function()end}end}
local Locale={Text=function(s)return s end,Number=tostring}
local Levels=(function() LEVELS end)()
local Numeric=(function() NUMERIC end)()
local Model=(function() MODEL end)()
local Abilities=(function() ABILITIES end)()
local script={Parent={Numeric='numeric',Locale='locale',UIModel='model',UIWidgets='widgets',UITheme='theme',Cleanup='cleanup',GrowthPanelsSkin='skin'}}
local function require(k)return ({numeric=Numeric,locale=Locale,model=Model,widgets=Widgets,theme=Theme,cleanup=Cleanup,skin=Skin,abilities=Abilities,houses=Houses})[k]end
local Houses=(function() HOUSES end)()
local game={GetService=function()return {Shared={HouseConfig='houses',VerityAbilities='abilities'}}end}
local function require(k)return ({locale=Locale,model=Model,widgets=Widgets,theme=Theme,cleanup=Cleanup,skin=Skin,abilities=Abilities,houses=Houses})[k]end
local workspace={GetServerTimeNow=function()return 100 end}
local Verity=(function() VERITY_CONTROLLER end)()
local Workshop=(function() WORKSHOP_CONTROLLER end)()
local requests={}
local busy=false
local ctx={refs={Panels={VERITY=refs,WORKSHOP=workshop}},net={connected=true,IsBusy=function()return busy end},request=function(a,v)table.insert(requests,{action=a,args=v})end}
local verity=Verity.new(ctx);local house=Workshop.new(ctx)
verity:Render();house:Render();assert(not refs.Buy.Interactable)
local state={VerityLevel=1,VerityUnlocked=true,Cash=1000,NextVerityUpgradeCost=25,IncomePerSecond=1,NextIncomePerSecond=2,HouseTier=1,HouseIncomeLevel=0,HouseDoorOwned=true,HouseDoorLocked=false}
ctx.net.state=state
for level=1,100 do
 state.VerityLevel=level;state.HouseTier=Houses.getHouseTier(level)
 verity:Render()
 assert(refs.Progress.Size.X.Scale==(level-1)/99)
 assert(refs.Buy.Interactable==(level<100),'upgrade eligibility')
 assert(refs.Scale.Text~='' and refs.Ability.Text~='')
end
assert(refs.Level.Text=='MAX LEVEL 100 • GIANT FINAL FORM')
state.VerityLevel=1;state.VerityUnlocked=false;verity:Render();assert(not refs.Buy.Interactable)
state.VerityUnlocked=true;state.Cash=0;verity:Render();assert(not refs.Buy.Interactable)
state.Cash=1000;busy=true;verity:Render();assert(not refs.Buy.Interactable)
busy=false;ctx.net.connected=false;verity:Render();assert(not refs.Buy.Interactable)
ctx.net.connected=true;verity:Render();refs.Buy.Activated:Fire();assert(requests[1].action=='UpgradeVerity')
assert(#house.rows==#Houses.IncomeUpgrades)
for count=0,#Houses.IncomeUpgrades do
 state.HouseIncomeLevel=count;state.VerityLevel=100;house:Render()
 assert(house.fill.Size.X.Scale==count/#Houses.IncomeUpgrades)
end
house.lock.Activated:Fire();assert(requests[2].action=='HouseDoor' and requests[2].args.locked==true)
state.HouseDoorOwned=false;house:Render();assert(not house.lock.Visible)
state.Boost={multiplier=2,endsAt=110};verity:Render();assert(refs.Boost.Visible)
state.Boost.endsAt=99;verity:Render();assert(not refs.Boost.Visible)
verity:Destroy();house:Destroy()
print('Growth panels: real skin and two controller constructors, five viewport bounds, 100 companion levels, workshop progression, lock/upgrade requests and eligibility passed; no Studio Play')
'''
model=(r/'src/client/UIModel.luau').read_text()
model='\n'.join('local LevelConfig=Levels' if line.startswith('local LevelConfig = ') else line for line in model.splitlines())
for a,b in [('THEME',theme),('LAYOUT',layout),('WIDGETS',widgets),('SKIN',skin),('LEVELS',(r/'src/shared/LevelConfig.luau').read_text()),('NUMERIC',(r/'src/shared/Numeric.luau').read_text()),('MODEL',model),('ABILITIES',(r/'src/shared/VerityAbilities.luau').read_text()),('HOUSES',(r/'src/shared/HouseConfig.luau').read_text()),('VERITY_CONTROLLER',(r/'src/client/VerityUIController.luau').read_text()),('WORKSHOP_CONTROLLER',(r/'src/client/WorkshopUIController.luau').read_text())]:h=h.replace(a,b)
with tempfile.TemporaryDirectory(prefix='verity-phone-') as t:
 p=Path(t)/'phone.luau';p.write_text(h);subprocess.run([sys.argv[1],str(p)],check=True)
