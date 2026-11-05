"""Real race modules against mock events/engine values; no Studio or Play."""
from pathlib import Path
import re,subprocess,tempfile
R=Path(__file__).resolve().parents[1]
h=r'''
local function signal()
 local rows={};return {Connect=function(_,fn)local r={fn=fn};table.insert(rows,r);return {Disconnect=function()r.off=true end}end,
 Fire=function(_,...)for _,r in table.clone(rows) do if not r.off then r.fn(...)end end end}
end
local V={};V.__index=function(v,k)if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end;return V[k]end
local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},V)end
function V.__sub(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
function V.__add(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
local Vector3={new=vec,zero=vec(0,0,0)};local Vector2={new=vec}
local CF={};CF.__index=function(c,k)if k=='Rotation' then return c end;return CF[k]end
local function cf(p)return setmetatable({Position=p},CF)end
function CF.__mul(a,b)return cf(a.Position+b.Position)end
local CFrame={new=function(x,y,z)return cf(if type(x)=='table' then x else vec(x or 0,y or 0,z or 0))end,Angles=function()return cf(Vector3.zero)end}
local function ctor(...)return {...}end
local Color3={fromHex=function(h)return h end};local Enum={Material={Plastic=1},SurfaceType={Studs=1,Smooth=2},Font={GothamBold=1}}
local UDim2={fromOffset=ctor,fromScale=ctor,new=ctor};local UDim={new=ctor}
local all={}
local Instance={new=function(class)
 local o={ClassName=class,attrs={},Triggered=signal(),OnServerEvent=signal(),Activated=signal()}
 function o:SetAttribute(k,v)self.attrs[k]=v end
 function o:GetAttribute(k)return self.attrs[k]end
 function o:Destroy()self.dead=true;self.Parent=nil end
 function o:FindFirstChild(name)
  for _,child in all do if rawget(child,"Parent")==self and rawget(child,"Name")==name then return child end end
 end
 setmetatable(o,{__index=function(t,k)if k=="CFrame" then return CFrame.new(rawget(t,"Position") or Vector3.zero)end;return t:FindFirstChild(k)end})
 table.insert(all,o);return o
end}
local Numeric=(function() NUMERIC_SOURCE end)()
local Income=(function()local script={Parent={Numeric='numeric'}};local function require()return Numeric end; INCOME_SOURCE end)()
local Config=(function() CONFIG_SOURCE end)()
local Levels=(function() LEVEL_SOURCE end)()
local Shared={VerityRaceConfig='config',EconomyConfig='income',Numeric='numeric',LocaleText='locale'}
local physics=signal();local playerList={}
local Players={GetPlayers=function()return playerList end,GetPlayerByUserId=function(_,id)for _,p in playerList do if p.UserId==id then return p end end end}
local now=0
local workspace=Instance.new('Workspace');function workspace:GetServerTimeNow()return now end
local game={GetService=function(_,s)return ({ReplicatedStorage={Shared=Shared},Players=Players,RunService={RenderStepped=physics},ContextActionService={},UserInputService={},GuiService={}})[s]end}
local Locale={SetWorld=function(o,k,t,...)o[k]=if select("#",...)>0 then string.format(t,...)else t end,Text=function(t)return t end}
local function require(k)return ({config=Config,income=Income,numeric=Numeric,locale=Locale})[k]end
local Builder=(function() BUILDER_SOURCE end)()
local Service=(function() SERVICE_SOURCE end)()
local island=Builder.Build(workspace);assert(Builder.Build(workspace)==island,'builder duplicated track')
local count=0
for _,o in all do if o.ClassName=='Part' then count+=1;assert(o.Anchored and not o.CanTouch);if o.Name:find('Gate')then assert(not o.CanCollide and not o.CanQuery)end end end
assert(count<130,'part budget exceeded')
assert(Config.LaneX[2]-Config.LaneX[1]>25.5 and 34>25.5,'giant100 cannot fit')
local seed=7
local function random()seed=(seed*16807)%2147483647;return seed/2147483647 end
local lowWins,equalWins=0,0
for _=1,20000 do
 local f=Config.Rank({{slot=1,level=1},{slot=2,level=100}},random);if f[1]<f[2]then lowWins+=1 end
 local e=Config.Rank({{slot=1,level=50},{slot=2,level=50}},random);if e[1]<e[2]then equalWins+=1 end
end
assert(math.abs(lowWins/20000-1/6)<.012,'weighted odds mismatch')
assert(math.abs(equalWins/20000-.5)<.012,'equal levels biased')
for phase=0,10 do
 local old=-1
 for step=0,1000 do local p=Config.Progress(step/1000*18.4,18.4,phase);assert(p>=old and p>=0 and p<=1);old=p end
 assert(Config.Progress(0,18.4,phase)==0 and Config.Progress(18.4,18.4,phase)==1)
end
for level=1,100 do
 local radius=.85*Levels.getVerityScale(level)
 local finish=Config.Position(1,16,16,0,radius)
 assert(math.abs(finish.Z+radius-Config.EndZ)<1e-6,'different sizes cross the finish at different times')
end
local profiles={};local paid=0;local notes={};local state={sessions={},Publish=function()end}
local data={Get=function(_,id)return profiles[id]end}
local economy={GetMultiplier=function()return 1 end,AddCash=function(_,id,amount)paid+=amount;return true,amount end}
local function player(id,level)
 local root={Position=vec(Config.LaneX[id],3,Config.PadZ)};local hum={Health=100}
 local char={FindFirstChild=function()return root end,FindFirstChildOfClass=function()return hum end}
 local p={UserId=id,DisplayName='Racer'..id,Character=char,attrs={},root=root,hum=hum}
 function p:SetAttribute(k,v)self.attrs[k]=v end;function p:GetAttribute(k)return self.attrs[k]end
 profiles[id]={Data={VerityUnlocked=true,VerityLevel=level,Cash=0}};state.sessions[id]={};table.insert(playerList,p);return p
end
local p1,p2,p3,p4=player(1,1),player(2,100),player(3,25),player(4,50)
local function fixture()
 paid=0;notes={};now=0
 for _,p in playerList do p.attrs={};p.hum.Health=100;p.root.Position=vec(Config.LaneX[p.UserId],3,Config.PadZ)end
 local s=Service.new(data,state,economy,Players,function()return now end,function(id,code,reward)table.insert(notes,{id=id,code=code,reward=reward})end,function()return .5 end)
 s:Bind(island);return s
end
local s=fixture();p1.root.Position=vec(0,3,0);assert(not s:Join(p1,1),'joined remotely')
now+=1;p1.root.Position=vec(0/0,3,92);assert(not s:Join(p1,1),'NaN accepted')
now+=1;p1.root.Position=vec(Config.LaneX[1],3,92);p1.attrs.VerityRiding=true;assert(not s:Join(p1,1));p1.attrs={}
now+=1;assert(s:Join(p1,1));assert(s.phase=='Waiting' and p1:GetAttribute('VerityRaceSlot')==1)
assert(not s:Join(p1,2),'duplicate queue entry')
assert(s:Join(p2,2));assert(s.phase=='Countdown' and s.deadline==now+10)
local remote=island:FindFirstChild('LeaveRaceQueue');remote.OnServerEvent:Fire(p2,'invalid');assert(s:Count()==2,'extra arguments accepted')
remote.OnServerEvent:Fire(p2);assert(s.phase=='Waiting' and not s.deadline and not p2:GetAttribute('VerityRaceSlot'))
now+=1;assert(s:Join(p2,2));assert(s:Join(p3,3));assert(s:Join(p4,4));assert(s:Count()==4)
now=s.deadline-.01;s:Tick();assert(s.phase=='Countdown' and paid==0)
now+=.01;s:Tick();assert(s.phase=='Running' and s.entries[2].finish==Config.BaseSeconds,'strongest deterministic draw should win')
assert(not s:Leave(p1),'running race left via queue cancel')
local locked=s.entries[1].level;profiles[1].Data.VerityLevel=100
assert(s.entries[1].level==locked and p1:GetAttribute('VerityRaceLevel')==locked,'race odds changed after start')
now=s.endsAt-.01;s:Tick();assert(paid==0,'paid before finish')
now=s.endsAt;s:Tick();assert(s.phase=='Results' and paid==Income.getIncome(100)*12)
local reward=paid;s:Finish(false);s:Tick();assert(paid==reward,'double payout')
for _,p in playerList do assert(not p:GetAttribute('VerityRaceSlot'),'pet remained on track')end
now=s.deadline;s:Tick();assert(s.phase=='Waiting' and s:Count()==0)
s:Destroy()
profiles[1].Data.VerityLevel=1
s=fixture();assert(s:Join(p1,1));p1.root.Position=vec(0,3,0);s:Tick();assert(s:Count()==0,'walk-away queue retained')
now+=1;p1.root.Position=vec(Config.LaneX[1],3,92);assert(s:Join(p1,1));now+=Config.QueueTimeout+1;s:Tick();assert(s:Count()==0,'solo queue never expired');s:Destroy()
s=fixture();s:Join(p1,1);s:Join(p2,2);now=s.deadline;s:Tick();p2.hum.Health=0;s:Tick()
assert(s.phase=='Running' and s:Count()==1,'forfeit cancelled remaining racer')
now=s.endsAt;s:Tick();assert(paid==Income.getIncome(1)*12,'remaining racer did not win forfeit');s:Destroy()
s=fixture();s:Join(p1,1);s:Join(p2,2);now=s.deadline;s:Tick();p1.hum.Health=0;p2.hum.Health=0;s:Tick();assert(s.phase=='Results' and paid==0);s:Destroy()
-- Placement checks use actual source map geometry.
local recipe=(function() MAP_SOURCE end)()
for _,row in recipe do
 if row.path and row.collide and row.pos and row.size and row.path~='Environment/Ground' then
  local x,y,z=table.unpack(row.pos);local sx,sy,sz=table.unpack(row.size)
  if math.abs(x+178)<(sx+40)/2 and math.abs(z-90)<(sz+12)/2 and y+sy/2>.3 then
   error('Access path collides with '..row.path)
  end
 end
end

-- Execute the actual UI constructor and race branch in the sole companion controller.
local world=Instance.new('Model');world.Name='GeneratedWorld';world.Parent=workspace;island.Parent=world
s=fixture()
Players.LocalPlayer=p1
Enum.UserInputState={Begin=1};Enum.ContextActionResult={Sink=1,Pass=2};Enum.KeyCode={Q=1,ButtonB=2}
local bindings={};local actions={BindAction=function(_,name,fn)bindings[name]=fn end,UnbindAction=function(_,name)bindings[name]=nil end}
local input={GetFocusedTextBox=function()return nil end};local gui={MenuIsOpen=false}
function game:GetService(n)return ({ReplicatedStorage={Shared=Shared},Players=Players,RunService={RenderStepped=physics},ContextActionService=actions,UserInputService=input,GuiService=gui})[n]end
local Cleanup={new=function()return {items={},Add=function(self,v)table.insert(self.items,v);return v end,Destroy=function(self)
 for _,v in self.items do if type(v)=='function' then v() elseif v.Disconnect then v:Disconnect()else v:Destroy()end end
end}end}
local W={Round=function(o)return o end,Stroke=function()end,SetButton=function(o,t,enabled)o.Text=t;o.Interactable=enabled end}
function W.Frame(parent,name,size,color)local o=Instance.new('Frame');o.Parent=parent;o.Name=name;return o end
function W.Text(parent,name,t)local o=Instance.new('TextLabel');o.Parent=parent;o.Name=name;o.Text=t;return o end
function W.Button(parent,name,t)local o=Instance.new('TextButton');o.Parent=parent;o.Name=name;o.Text=t;return o end
local script={Parent={Cleanup='cleanup',Locale='clientlocale',UIWidgets='widgets',UITheme='theme'}}
local function require(k)return ({config=Config,cleanup=Cleanup,clientlocale=Locale,widgets=W,theme={}})[k]end
local Controller=(function() CLIENT_SOURCE end)()
local ctx={refs={Safe={AbsoluteSize=vec(390,800,0)}},settings={values={ReducedMotion=false}}}
local client=Controller.new(ctx)
local remote=island:FindFirstChild('LeaveRaceQueue');function remote:FireServer(...)self.OnServerEvent:Fire(p1,...)end
assert(s:Join(p1,1));client:Tick(.1);assert(client.card.Visible and client.detail.Text:find('ждём соперника'))
assert(client:Leave() and not p1:GetAttribute('VerityRaceSlot'),'client leave not routed')
now+=1;s:Join(p1,1);s:Join(p2,2);client:Tick(.1);assert(client.title.Text:find('СТАРТ ЧЕРЕЗ'))
ctx.active='PHONE';client:Tick(.1);assert(not client.card.Visible and not client:Leave(),'menu did not hide/suspend race UI')
ctx.active=nil;now=s.deadline;s:Tick();client:Tick(.1)
assert(not client.leave.Interactable and not client:Leave(),'client left a running race')
assert(client.gates[1].part.CFrame.Position.Y<client.gates[1].base.Position.Y,'gate did not open')
local Companion={}
local Race=Config;local Follow={TeleportDistance=80}
local function visibility(record,alpha)record.visibility=alpha end
FOLLOW_SOURCE
local model=Instance.new('Model');model:SetAttribute('FollowOwner',true)
local record={owner=1,model=model,level=1,plot=1,origin=CFrame.new(0,0,0)}
Companion.Follow({},record,now,.1)
assert(record.racing and not record.riding and record.origin.Position.Z==Config.StartZ,'queued companion was duplicated or not placed on track')
now+=8;Companion.Follow({},record,now,.1);assert(record.origin.Position.Z>Config.StartZ and record.origin.Position.Z<Config.EndZ)
local base=client.gates[1].base;client:Destroy();assert(not bindings.VerityRaceLeave and client.gates[1]==nil,'client cleanup left gate/input owner')
s:Destroy()

print(string.format('Races: actual builder/service,2–4/free queue, countdown/cancel/disconnect/forfeit, frozen levels, one payout, weighted sampling %.2f%% low-level wins, monotone overtake paths and map access passed; no Play',100*lowWins/20000))
'''
for k,p in [('NUMERIC_SOURCE','src/shared/Numeric.luau'),('INCOME_SOURCE','src/shared/EconomyConfig.luau'),('LEVEL_SOURCE','src/shared/LevelConfig.luau'),('CONFIG_SOURCE','src/shared/VerityRaceConfig.luau'),('BUILDER_SOURCE','src/world/VerityRaceBuilder.luau'),('SERVICE_SOURCE','src/server/VerityRaceService.luau'),('MAP_SOURCE','src/world/MapRecipe.luau'),('CLIENT_SOURCE','src/client/VerityRaceController.luau')]:h=h.replace(k,(R/p).read_text())
follow=(R/'src/world/VerityVisualController.luau').read_text().split('function Controller:Follow(record,now,dt)',1)[1].split('function Controller:Tick(',1)[0]
h=h.replace('FOLLOW_SOURCE','function Companion:Follow(record,now,dt)'+follow)
with tempfile.TemporaryDirectory(prefix='verity-races-') as t:
 p=Path(t)/'check.luau';p.write_text(h);result=subprocess.run([str(R.parent/'luau/luau'),str(p)],capture_output=True,text=True)
 if result.returncode:
  print(result.stderr);m=re.search(r'check.luau:(\d+)',result.stderr)
  if m:
   line=int(m.group(1));print('\n'.join(f'{i+1}: {v}' for i,v in enumerate(h.splitlines())if line-3<=i<=line+1))
  raise SystemExit(result.returncode)
 print(result.stdout,end='')
