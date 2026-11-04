"""Run native phone skin builder/layout with fake engine values. Not a Studio render."""
from pathlib import Path
import sys,subprocess,tempfile
r=Path(__file__).resolve().parents[1]
skin=(r/'src/client/PhoneSkin.luau').read_text()
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
local Enum={Font={Gotham=1,GothamBold=2},TextXAlignment={Left=1,Center=2},ApplyStrokeMode={Border=1},SortOrder={LayoutOrder=1},FillDirection={Horizontal=1,Vertical=2},SelectionBehavior={Stop=1},AutomaticSize={None=1},ScrollingDirection={Y=1}}
local instances={}
local Instance={new=function(class)
 local o={ClassName=class}
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
for _,name in {'Root','Title','Close','Body','Viewport','Controls','Reward','Next','Power','Grow','Session','CollectionButton','Cash','Home','Caption','PowerHint','Subtitle'} do assert(refs[name],name)end
for _,size in {{320,568},{390,844},{568,320},{844,390},{1920,1080}} do
 local p=Skin.Layout(refs,{X=size[1],Y=size[2]})
 for _,name in {'Close','Home','Next','Power','Grow','CollectionButton'} do
  local b=refs[name];local ph=if name=='Power' or name=='Grow' or name=='Next' or name=='CollectionButton' then p.controlsH else p.height
  assert(b.Size.Y.Scale*ph+b.Size.Y.Offset>=44,name..' tap height')
 end
 assert(refs.Body.CanvasSize.Y.Offset==p.contentH)
end
assert(not refs.Root.Visible,'phone opened by constructor')
print('Phone skin: real native widget constructor/export, controller refs, 44px controls and responsive application passed')
'''
for a,b in [('THEME',theme),('LAYOUT',layout),('WIDGETS',widgets),('SKIN',skin)]:h=h.replace(a,b)
with tempfile.TemporaryDirectory(prefix='verity-phone-') as t:
 p=Path(t)/'phone.luau';p.write_text(h);subprocess.run([sys.argv[1],str(p)],check=True)
