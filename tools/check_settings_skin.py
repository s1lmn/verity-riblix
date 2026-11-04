"""Execute native settings skin/controller with mocked engine values. Not a Studio render."""
from pathlib import Path
import sys,subprocess,tempfile
r=Path(__file__).resolve().parents[1]
skin=(r/'src/client/SettingsSkin.luau').read_text()
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
assert(exports.n==1 and type(exports[1].Build)=='function','skin module export')
local Skin=exports[1];local refs=Skin.Build({})
for _,name in {'Root','Title','Close','Body','Language','Sound','Volume','Minus','Plus','Motion','Effects','VolumeFill','ToggleKnobs'} do assert(refs[name],name)end
assert(not refs.Root.Visible)
for _,size in {{320,568},{390,844},{568,320},{844,390},{1920,1080}} do
 local x=if size[1]<640 then 12 else 172
 local p=Skin.Layout(refs,{X=size[1],Y=size[2]},x)
 assert(p.width+x<=size[1]-12 and p.height+24<=size[2],'safe bounds')
 for _,name in {'Close','Language','Sound','Minus','Plus','Motion','Effects'} do
  assert(refs[name].Size.Y.Offset>=44,name..' touch height')
 end
end
local gui={};function gui:SetAttribute(k,v)self[k]=v end
function refs.Root:FindFirstAncestorOfClass()return gui end
local Locale={Changed={Event=signal()},language='ru',Text=function(s)return s end}
function Locale.GetLanguage()return Locale.language end
function Locale.SetLanguage(l)Locale.language=l;Locale.Changed.Event:Fire()end
local Cleanup={new=function()return {Add=function(_,x)return x end,Destroy=function()end}end}
local script={Parent={Locale='locale',Cleanup='cleanup'}}
local function require(k)return ({locale=Locale,cleanup=Cleanup})[k]end
local exports=table.pack((function() CONTROLLER end)())
assert(exports.n==1 and type(exports[1].new)=='function','controller module export')
local settings=exports[1].new(refs)
assert(gui.UISounds and gui.UIVolume==.6)
local changes=0;settings.Changed.Event:Connect(function()changes+=1 end)
for _,pair in {{'Sound','UISounds'},{'Motion','ReducedMotion'},{'Effects','ReducedEffects'}} do
 local b,k=pair[1],pair[2];local before=settings.values[k]
 refs[b].Activated:Fire();assert(settings.values[k]~=before and gui[k]==settings.values[k])
 assert(refs.ToggleKnobs[b].Position.X.Offset==(if settings.values[k] then 27 else 3))
 refs[b].Activated:Fire();assert(settings.values[k]==before)
end
for i=1,20 do refs.Plus.Activated:Fire()end
assert(settings.values.Volume==1 and refs.VolumeFill.Size.X.Scale==1)
for i=1,20 do refs.Minus.Activated:Fire()end
assert(settings.values.Volume==0 and refs.VolumeFill.Size.X.Scale==0)
local oldChanges=changes
refs.Language.Activated:Fire();assert(Locale.language=='en' and changes==oldChanges,'locale changed audio settings')
refs.Language.Activated:Fire();assert(Locale.language=='ru')
settings:Destroy()
print('Settings: real skin/controller constructors, five viewport bounds, 44px controls, three toggles, attributes, volume clamp/meter and language passed; no Studio Play')
'''
for a,b in [('THEME',theme),('LAYOUT',layout),('WIDGETS',widgets),('SKIN',skin),('CONTROLLER',(r/'src/client/SettingsController.luau').read_text())]:h=h.replace(a,b)
with tempfile.TemporaryDirectory(prefix='verity-phone-') as t:
 p=Path(t)/'phone.luau';p.write_text(h);subprocess.run([sys.argv[1],str(p)],check=True)
