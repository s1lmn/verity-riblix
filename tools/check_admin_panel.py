"""Admin module/constructor and local preview checks with fake services. No Studio."""
from pathlib import Path
import subprocess,sys,tempfile
r=Path(__file__).resolve().parents[1]
source=(r/'src/client/AdminPanelController.luau').read_text()
access=(r/'src/server/AdminAccess.luau').read_text()
visual=(r/'src/world/VerityVisualController.luau').read_text()
api=visual[visual.index('function Controller:AdminRecord()'):visual.index('function Controller:BeginSpawn(event)')]
finish=visual[visual.index('function Controller:Finish(record,now)'):visual.index('visibility=function(record,alpha)')]
cleanup=(r/'src/client/Cleanup.luau').read_text()
h='''
local links={}
local function signal() return {Connect=function(_,f) local c={kind='link',f=f};function c:Disconnect()self.off=true end;table.insert(links,c);return c end} end
local function typeof(v) return if type(v)=='table' and v.kind=='object' then 'Instance' elseif type(v)=='table' and v.kind=='link' then 'RBXScriptConnection' else type(v) end
local Cleanup=(function() CLEANUP end)()
local AdminAccess=(function() ACCESS end)()
assert(AdminAccess.IsAllowed(1371278087,0,false))
assert(AdminAccess.IsAllowed(10,10,true))
assert(not AdminAccess.IsAllowed(10,10,false))
assert(not AdminAccess.IsAllowed(20,10,true))
local function object(props)
 local o=props or {};o.kind='object';o.Activated=signal();o.AbsoluteSize={X=800,Y=700}
 function o:GetPropertyChangedSignal()return signal()end
 function o:Destroy()self.destroyed=true end
 return o
end
local W={}
function W.New(_,props,parent) local o=object(props);o.Parent=parent;return o end
function W.Frame(parent,name,size,color)return W.New('Frame',{Name=name,Size=size,Color=color},parent)end
function W.Button(parent,name,text,color)return W.New('Button',{Name=name,Text=text},parent)end
function W.Line(parent,name,text)return W.New('Text',{Name=name,Text=text},parent)end
function W.Round(o)return o end
function W.Stroke()end;function W.List()end
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local UDim2={new=function(...)return {...}end,fromOffset=function(...)return {...}end}
local Theme={Gold=1,Paper=2,Purple=3,Soft=4,Ink=5,Bold=6}
local Enum={AutomaticSize={Y=1},ScrollingDirection={Y=1},KeyCode={F8=1},CreatorType={User='user'}}
local player={UserId=1371278087,CharacterRemoving=signal(),admin=true}
function player:GetAttribute(n)return if n=='VerityAdmin' then self.admin else 1 end
function player:GetAttributeChangedSignal()return signal()end
local Client=player
local Levels=(function() LEVELS end)()
local Profile={Aura=function(level)return {fire=level>=10,trails=if level>=100 then 3 else 0}end}
local Abilities={Get=function()return {name='Form'}end}
local shared={LevelConfig='levels',VerityAbilities='abilities',VerityAnimationProfile='profile'}
local RS={Shared=shared,World={AudioConfig='audio'}}
local game={GetService=function(_,n)if n=='Players' then return {LocalPlayer=player} elseif n=='UserInputService' then return {InputBegan=signal(),GetFocusedTextBox=function()return nil end} else return RS end end}
local script={Parent={UIWidgets='widgets',UITheme='theme',Cleanup='cleanup'}}
local function require(k)return ({levels=Levels,abilities=Abilities,profile=Profile,widgets=W,theme=Theme,cleanup=Cleanup,audio={UI={Reward={}}}})[k] end
local exports=table.pack((function() PANEL end)())
assert(exports.n==1 and type(exports[1].new)=='function','admin export')
local Controller={};local Factory={Color=function(n)return n end}
local function integer(v,a,b)return type(v)=='number' and v==v and v%1==0 and v>=a and v<=b end
API
FINISH
local record={owner=player.UserId,level=7,revision=4,model={GetPivot=function()return {}end},baseYaw=0,plot=1,lastYaw=0,lastLift=0}
local visuals=setmetatable({records={record},spawn={},effects={CancelUpgrade=function()end,HideGrowth=function()end,BeginUpgrade=function()end}}, {__index=Controller})
function visuals:Apply()end
local settings={Changed={Event=signal()}}
local ctx={refs={Safe=object(),Panels={PHONE={Root=object()}}},settings=settings,close=function()end,sound={Stop=function()end,StopUpgrade=function()end}}
local panel=exports[1].new(ctx,visuals)
assert(panel.toggle.Visible and not panel.panel.Visible)
panel:Toggle();assert(panel.panel.Visible)
for level=1,100 do assert(panel:SetLevel(level));assert(record.adminLevel==level and record.level==7 and record.revision==4) end
for _,level in {0,101,-1,.5,math.huge,0/0} do assert(not panel:SetLevel(level)) end
local e=visuals:AdminLevel(100,true);assert(e.preview and record.level==7)
visuals:Finish(record,1);assert(record.level==7 and record.adminLevel==100,'preview changed progression')
record.active={event={preview=false}};assert(not visuals:AdminLevel(20,false),'interrupted real upgrade');record.active=nil
player.admin=false
assert(not panel:SetLevel(10));assert(not visuals:AdminEmotion('Joy'))
panel:Close();assert(record.adminLevel==nil and record.level==7,'failed restore after revoke')
panel:Destroy()
for _,c in links do assert(c.off,'connection leak') end
print('Admin: permission policy, real constructor/export, 100 levels, invalid inputs, local-only progression, cancel/revoke and cleanup passed')
'''
for a,b in [('CLEANUP',cleanup),('ACCESS',access),('LEVELS',(r/'src/shared/LevelConfig.luau').read_text()),('PANEL',source),('API',api),('FINISH',finish)]:h=h.replace(a,b)
with tempfile.TemporaryDirectory(prefix='verity-admin-') as t:
 p=Path(t)/'check.luau';p.write_text(h);subprocess.run([sys.argv[1],str(p)],check=True)
