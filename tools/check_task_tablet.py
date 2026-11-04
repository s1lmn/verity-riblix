"""Execute native order tablet and task controller with mocked engine services; no Play."""
from pathlib import Path
import sys,subprocess,tempfile
r=Path(__file__).resolve().parents[1]
skin=(r/'src/client/TaskTabletSkin.luau').read_text()
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
for _,name in {'Root','Title','Subtitle','Close','Body','Rows'} do assert(refs[name],name)end
assert(not refs.Root.Visible,'constructor must keep menu closed')
for _,size in {{320,568},{390,844},{568,320},{844,390},{1920,1080}} do
 local x=if size[1]<640 then 12 else 172
 local p=Skin.Layout(refs,{X=size[1],Y=size[2]},x)
 assert(p.width+x<=size[1]-12 and p.height<=size[2]-24,'safe bounds')
 assert(refs.Close.Size.Y.Offset>=44,'close target')
 assert(refs.Body.CanvasSize.Y.Offset==548,'scroll reaches third order')
 for _,id in {'PRESS_BUTTON','REACH_POINT','STAND_ON_PLATFORM'} do
  local row=refs.Rows[id]
  for _,key in {'Root','Title','Description','Reward','Status','Button'} do assert(row[key],id..key)end
  assert(row.Button.Size.Y.Offset>=44,'order touch target')
  assert(row.Button.Position.Y.Offset+row.Button.Size.Y.Offset<=row.Root.Size.Y.Offset,'card clipping')
 end
end
'''
h += "\n" + "local workspace={GetServerTimeNow=function()return 100 end}\n"
h += "local typeof=type\nlocal listeners={}\nlocal event={Connect=function(_,fn)table.insert(listeners,fn);return {} end}\n"
h += "for _,row in refs.Rows do row.Button.Activated=event end\n"
h += "local Cleanup={new=function()return {Add=function()end,Destroy=function()end}end}\n"
h += "local Locale={Text=function(s)return s end,Number=tostring}\n"
h += "local script={Parent={Locale='locale',Cleanup='cleanup',UIWidgets='widgets'}}\n"
h += "local function require(k)return ({locale=Locale,cleanup=Cleanup,widgets=Widgets})[k]end\n"
h += "local Tasks=(function()\n"+(r/'src/client/TasksUIController.luau').read_text()+"\nend)()\n"
h += """
local ctx={refs={Panels={TASKS=refs}},net={connected=true,Result={Event=event},IsBusy=function()return false end},active='TASKS'}
ctx.request=function(action,args)ctx.requested=args.taskId end
ctx.close=function()ctx.closed=true end
local controller=Tasks.new(ctx)
ctx.net.state={Tasks={{taskId='PRESS_BUTTON',reward=20,status='Ready',cooldownEndsAt=0},
 {taskId='REACH_POINT',reward=40,status='Active',cooldownEndsAt=0},
 {taskId='STAND_ON_PLATFORM',reward=25,status='Cooldown',cooldownEndsAt=110}}}
controller:Render()
assert(refs.Rows.PRESS_BUTTON.Reward.Text=='$20')
assert(refs.Rows.PRESS_BUTTON.Button.Interactable)
assert(refs.Rows.REACH_POINT.Status.Text=='Выполняется')
assert(refs.Rows.REACH_POINT.Button.Text=='ПОКАЗАТЬ ПУТЬ →')
assert(refs.Rows.STAND_ON_PLATFORM.Status.Text=='Снова через 10с')
assert(not refs.Rows.STAND_ON_PLATFORM.Button.Interactable)
ctx.net.state.Tasks[3].cooldownEndsAt=100;controller:Render()
assert(refs.Rows.STAND_ON_PLATFORM.Button.Interactable,'expired cooldown')
ctx.net.connected=false;controller:Render()
assert(not refs.Rows.PRESS_BUTTON.Button.Interactable,'offline')
ctx.net.state=nil;controller:Render()
assert(refs.Rows.PRESS_BUTTON.Reward.Text=='$—','stale reward')
listeners[#listeners]({action='TaskStart',success=true})
assert(ctx.closed,'confirmed start closes stable TASKS key')
controller:Destroy()
print('Task tablet: native constructor, 5 viewport bounds, scroll, 44px targets, server rewards, active/cooldown/offline states passed; no Studio Play')
"""
for a,b in [('THEME',theme),('LAYOUT',layout),('WIDGETS',widgets),('SKIN',skin)]:h=h.replace(a,b)
with tempfile.TemporaryDirectory(prefix='verity-phone-') as t:
 p=Path(t)/'phone.luau';p.write_text(h);subprocess.run([sys.argv[1],str(p)],check=True)
