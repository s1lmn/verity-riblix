"""Execute actual ability service and client against mocked engine values; no Play."""
from pathlib import Path
import tempfile,subprocess,sys
R=Path(__file__).resolve().parents[1]
h='''
local now=100;local delayed={}
local function signal()
 local callbacks={}
 return {Connect=function(_,fn)local r={fn=fn};table.insert(callbacks,r);return {Disconnect=function()r.off=true end}end,Fire=function(_,...)for _,r in table.clone(callbacks) do if not r.off then r.fn(...)end end end}
end
local V={}
function V.__index(v,k)
 if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
 if k=='Unit' then return v/v.Magnitude end
 return V[k]
end
local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},V)end
function V.__add(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
function V.__sub(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
function V.__mul(a,b)if type(a)=='number' then a,b=b,a end;return vec(a.X*b,a.Y*b,a.Z*b)end
function V.__div(a,b)return vec(a.X/b,a.Y/b,a.Z/b)end
function V:Dot(b)return self.X*b.X+self.Y*b.Y+self.Z*b.Z end
local Vector3={new=vec,one=vec(1,1,1),zero=vec(0,0,0),xAxis=vec(1,0,0),yAxis=vec(0,1,0),zAxis=vec(0,0,1)}
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local function typeof(v)return if getmetatable(v)==V then 'Vector3' else type(v)end
local task={delay=function(t,fn)table.insert(delayed,{at=now+t,fn=fn})end}
local function advance(t)
 now+=t
 for i=#delayed,1,-1 do if delayed[i].at<=now then local r=table.remove(delayed,i);r.fn()end end
end
local workspace={GetServerTimeNow=function()return now end}
function workspace:Blockcast(cf,size,delta,params)self.cast={cf=cf,size=size,delta=delta,params=params};return self.hit end
local Enum={RaycastFilterType={Exclude=1,Include=2},ActuatorRelativeTo={World=1},VelocityConstraintMode={Plane='plane',Vector='vector'},HumanoidStateType={Jumping=1,Freefall=2}}
local RaycastParams={new=function()return {}end}
local Instance={new=function(class)
 local o={ClassName=class,OnServerEvent=signal()}
 function o:Destroy()self.destroyed=true end
 return o
end}
local Catalog=(function() CATALOG end)()
local Forms=(function() FORMS end)()
local Numeric=(function() NUMERIC end)()
local Levels=(function() LEVELCONFIG end)()
local Ride=(function() RIDECONFIG end)()
local RS={Shared={VerityAbilities='forms',AbilityCatalog='catalog',Numeric='numeric',LevelConfig='levels',VerityRideConfig='ride'}}
local PlayerList={}
local ServerPlayers={GetPlayers=function()return PlayerList end}
local physicsHeart=signal()
local game={GetService=function(_,n)return if n=='ReplicatedStorage' then RS elseif n=='Players' then ServerPlayers elseif n=='RunService' then {Heartbeat=physicsHeart} else {}end}
local function require(k)return ({forms=Forms,catalog=Catalog,numeric=Numeric,levels=Levels,ride=Ride})[k]end
local CF={}
function CF.__index(c,k)if k=='Rotation' then return c end return CF[k]end
function CF.__add(c,v)return setmetatable({Position=c.Position+v},CF)end
function CF.__mul(a,b)return setmetatable({Position=a.Position+b.Position},CF)end
local CFrame={new=function(a,b,c)return setmetatable({Position=if type(a)=='table' then a else vec(a or 0,b or 0,c or 0)},CF)end}
local OverlapParams={new=function()return {}end}
Enum.PartType={Ball=1}
function workspace:GetPartBoundsInRadius()return self.overlaps or {}end
function workspace:GetPartBoundsInBox()return self.overlaps or {}end

local Service=(function() SERVICE end)()
local function fixture(id)
 now=100;delayed={};workspace.hit=nil;workspace.solidHit=nil;workspace.bodyHit=nil
 local root={Position=vec(0,3,0),Size=vec(2,2,1),CFrame={LookVector=vec(0,0,-1)},AssemblyMass=10,AssemblyLinearVelocity=Vector3.zero,Parent=workspace}
 function root:IsDescendantOf(w)return self.Parent==w end
 function root:CanSetNetworkOwnership()return not self.denyOwner end
 function root:SetNetworkOwner(v)self.serverOwned=v==nil end
 function root:SetNetworkOwnershipAuto()self.restored=true end
 function root:ApplyImpulse(v)self.impulse=v end
 local hum={Health=100,WalkSpeed=32,MoveDirection=vec(0,0,-1)}
 function hum:ChangeState(s)self.state=s end
 local char={}
 function char:FindFirstChild(n)return if n=='HumanoidRootPart' then root else nil end
 function char:FindFirstChildOfClass(n)return if n=='Humanoid' then hum else nil end
 local player={UserId=1,Character=char,attrs={}}
 function player:SetAttribute(k,v)self.attrs[k]=v end
 function player:GetAttribute(k)return self.attrs[k]end
 local profile={Data={VerityUnlocked=true,VerityLevel=100,AbilitiesOwned={[id]=true},AbilitiesEquipped={Mobility=id}},HeroPassOwned=id=='homelander'}
 PlayerList={player}
 local data={Get=function(_,uid)return if uid==1 then profile else nil end}
 local s=Service.new(data,{sessions={[1]={}}},{anchors={}},{records={}})
 s.remote.FireAllClients=function(_,e)s.event=e end
 s.remote.FireClient=function(_,_,e)s.blocked=e end
 return s,player,root,hum,profile
end
local s,p,r,h=fixture('dash');s:Activate(p,'Mobility')
assert(s.active[p] and s.active[p].velocity.VelocityConstraintMode=='plane' and r.serverOwned,'dash ownership was not transferred')
assert(s.active[p].velocity.PlaneVelocity.Y==-65 and not r.impulse,'dash still depends on one impulse')
assert(workspace.cast.params.RespectCanCollide and math.abs(workspace.cast.delta.Magnitude-19.5)<1e-6)
advance(.3);assert(not s.active[p] and h.WalkSpeed==32)
s,p,r,h=fixture('dash');workspace.hit={Distance=8};s:Activate(p,'Mobility')
assert(s.active[p] and math.abs(s.active[p].speed-(8-.4)/.3)<1e-6,'nearby wall cancelled whole dash')
s,p=fixture('dash');workspace.hit={Distance=.2};s:Activate(p,'Mobility')
assert(not s.active[p] and s.blocked.code=='OBSTACLE' and not p:GetAttribute('VerityAbilityReadyAt'),'blocked dash consumed cooldown')
s,p,r,h=fixture('flight');s:Activate(p,'Mobility');local current=s.active[p]
assert(current and current.untilTime==112 and p:GetAttribute('VerityAbilityReadyAt')==118)
advance(.36);assert(current.velocity.VectorVelocity.Magnitude==0,'initial flight drift never timed out')
s:Activate(p,'Steer',vec(1,0,0));assert(current.velocity.VectorVelocity.X==34)
advance(.1);s:Activate(p,'Steer',vec(0,1,0));assert(current.velocity.VectorVelocity.Y==22,'10Hz steering throttled')
local before=current.velocity.VectorVelocity;s:Activate(p,'Steer',vec(0/0,0,0));assert(current.velocity.VectorVelocity==before)
advance(.36);assert(current.velocity.VectorVelocity.Magnitude==0,'stale steering retained movement')
r.Position=vec(0,81,0);s:Activate(p,'Steer',vec(0,1,0));assert(current.velocity.VectorVelocity.Y==0,'altitude cap bypassed')
advance(10);assert(s.active[p],'flight ended before12s')
advance(2);assert(not s.active[p] and current.attachment.destroyed and r.restored)
s,p=fixture('homelander');s:Activate(p,'Mobility');assert(s.active[p].untilTime==118 and p:GetAttribute('VerityAbilityReadyAt')==124)
s,p,r=fixture('flight');r.denyOwner=true;s:Activate(p,'Mobility');assert(not s.active[p] and not p:GetAttribute('VerityAbilityReadyAt'))
s,p,r,h,profile=fixture('dash');profile.Data.AbilitiesOwned={};s:Activate(p,'Mobility');assert(not s.active[p],'unowned action allowed')
s,p,r,h=fixture('dash');s:Activate(p,'Mobility');local active=s.active[p];s:Activate(p,'Steer',vec(1,0,0));assert(active.velocity.VectorVelocity==nil,'steer hijacked dash')
s,p,r,h=fixture('leap');s:Activate(p,'Mobility');assert(r.serverOwned and r.AssemblyLinearVelocity.Y==68,'team leap fix lost')
function workspace:Raycast(origin,delta,params)
 if params.RespectCanCollide then return self.solidHit else return self.bodyHit end
end
local function shoot(covered)
 local service,player,root,hum,profile=fixture('dash')
 profile.Data.AbilitiesOwned.repulsor=true;profile.Data.AbilitiesEquipped.Attack='repulsor'
 local target={Parent=workspace,Position=vec(0,5,-30)}
 service.targets.records[target]={health=100}
 service.targets.Damage=function(_,part,damage)assert(part==target);return damage end
 if covered then
  workspace.solidHit={Instance={},Distance=8,Position=vec(0,5,-8)}
  workspace.bodyHit={Instance=target,Distance=30,Position=target.Position}
 else
  workspace.solidHit={Instance=target,Distance=30,Position=target.Position}
 end
 service:Activate(player,'Attack',vec(0,0,-1));advance(.2)
 assert(service.blocked and service.blocked.kind=='CombatResult')
 return service.blocked.damage
end
assert(shoot(false)==18,'actual team attack/result path failed')
assert(shoot(true)==0,'attack damaged through cover after merge')
local function rideFixture(level)
 local service,player,root,hum,profile=fixture('dash')
 profile.Data.VerityLevel=level;profile.Data.AbilitiesOwned={}
 root.CFrame=CFrame.new(root.Position);hum.HipHeight=2
 workspace.overlaps=nil
 workspace.Raycast=function()return {Position=vec(0,0,0),Normal=Vector3.yAxis}end
 return service,player,root,hum,profile
end
s,p,r,h,profile=rideFixture(49);s:Activate(p,'Ride');assert(not s.active[p],'ride unlocked too early')
s,p,r,h,profile=rideFixture(50);p:SetAttribute('VerityParkourStep',1);s:Activate(p,'Ride');assert(not s.active[p],'mounted during course')
s,p,r,h,profile=rideFixture(50);workspace.hit={Distance=4};s:Activate(p,'Ride');assert(not s.active[p],'mounted into ceiling')
s,p,r,h,profile=rideFixture(50);workspace.overlaps={{}};s:Activate(p,'Ride');assert(not s.active[p],'mounted inside wall')
s,p,r,h,profile=rideFixture(50);s:Activate(p,'Ride')
assert(s.active[p].phase=='Takeoff' and not s.active[p].hull.CanCollide,'takeoff did not gate collision/input')
assert(s.active[p].ride and p:GetAttribute('VerityRiding') and r.serverOwned,'unpaid progression ride failed')
local mounted=s.active[p];assert(mounted.hull.Size.X>10 and mounted.hull.Massless)
s:Refresh(p,p.Character,profile.Data);assert(s.active[p]==mounted and h.WalkSpeed==0,'snapshot cancelled takeoff')
s:Activate(p,'Steer',vec(1,0,0));assert(mounted.velocity.VectorVelocity.Magnitude==0,'takeoff steering bypassed')
r.Position=mounted.launch+vec(0,mounted.hull.Size.X+Ride.SeatOffset,0);physicsHeart:Fire(.1)
assert(not mounted.phase and mounted.hull.CanCollide and p:GetAttribute('VerityRidePhase')=='Cruise','takeoff did not finish')
advance(.2);s:Activate(p,'Steer',vec(1,0,0));assert(mounted.velocity.VectorVelocity.X==36)
advance(.36);assert(mounted.velocity.VectorVelocity.Magnitude==0,'stale rider input kept moving')
local hull=mounted.hull
s:Activate(p,'Ride');assert(mounted.phase=='Landing' and not mounted.hull and hull.destroyed,'dismount did not start smooth landing')
r.Position=vec(0,3,0);physicsHeart:Fire(.1)
assert(not s.active[p] and not p:GetAttribute('VerityRiding') and r.restored,'dismount leaked hull/ownership')
s,p,r,h,profile=rideFixture(50);s:Activate(p,'Ride');mounted=s.active[p]
r.Position=mounted.launch+vec(0,mounted.hull.Size.X+Ride.SeatOffset,0);physicsHeart:Fire(.1)
advance(60);assert(mounted.phase=='Landing','timer skipped smooth landing')
r.Position=vec(0,3,0);physicsHeart:Fire(.1)
assert(not s.active[p] and mounted.attachment.destroyed,'timed ride leaked')
s,p,r,h,profile=rideFixture(50);s:Activate(p,'Ride');mounted=s.active[p]
s:Stop(p);physicsHeart:Fire(.1);assert(not s.active[p] and mounted.transition==nil,'cancelled transition survived Stop')
s,p,r,h,profile=rideFixture(50);s:Activate(p,'Ride');mounted=s.active[p]
r.Position=mounted.launch+vec(0,mounted.hull.Size.X+Ride.SeatOffset,0);physicsHeart:Fire(.1)
workspace.Raycast=function()return nil end
s:Dismount(p,mounted);local queued=#delayed;s:Dismount(p,mounted)
assert(#delayed==queued and mounted.landingRetry and s.active[p]==mounted,'missing ground created retry flood or dropped rider')
assert(mounted.untilTime>now,'missing ground expired steering')
s:Stop(p)
s,p,r,h,profile=rideFixture(50);s:Activate(p,'Ride');mounted=s.active[p]
advance(7);physicsHeart:Fire(.1)
assert(not s.active[p] and mounted.transition==nil and mounted.hull.destroyed,'stalled takeoff leaked transition')
s,p=fixture('dash');p:SetAttribute('VerityRaceSlot',1)
s:Activate(p,'Mobility');assert(not s.active[p] and s:IsSafe(p,{}),'queued racer can attack/move or be targeted')
print('Ride: level/session gate, no purchase, parkour/ceiling/wall guards, snapshot, steering watchdog and timed/dismount cleanup passed; mocked geometry only')
print('Ability server: dash/ownership, leap,12/18s flight, steering/cleanup and real attack feedback/cover passed; no Play')
'''
h += "\n" + r'''
-- Actual client constructor/heartbeat: latch short jump inputs and show active time.
s,p,r,h,profile=fixture('flight');s:Activate(p,'Mobility')
local heart=signal();local jump=signal();local held={};local sent={}
local clientRemote={FireServer=function(_,slot,direction)table.insert(sent,{slot=slot,direction=direction})end}
function RS:WaitForChild()return clientRemote end
Enum.KeyCode={F='F',G='G',ButtonL1='L1',ButtonR1='R1',ButtonL3='L3',R='R',LeftControl='Ctrl',Space='Space'}
Enum.PreferredInput={KeyboardAndMouse=1,Touch=2,Gamepad=3}
Enum.UserInputState={Begin=1};Enum.ContextActionResult={Sink=1,Pass=2};Enum.TextXAlignment={Center=1}
local Input={PreferredInput=1,JumpRequest=jump,GetFocusedTextBox=function()return nil end,IsKeyDown=function(_,key)return held[key]==true end}
local Gui={MenuIsOpen=false}
local bindings={}
local Actions={BindAction=function(_,name,fn,_,a,b)bindings[name]={fn=fn,a=a,b=b}end,UnbindAction=function()end}
local PlayerService={LocalPlayer=p}
local game={GetService=function(_,name)return ({Players=PlayerService,ReplicatedStorage=RS,UserInputService=Input,ContextActionService=Actions,GuiService=Gui,RunService={Heartbeat=heart}})[name]end}
local Color3={fromHex=function()return {}end}
local UDim2={fromScale=function()return {}end,fromOffset=function()return {}end}
local W={Text=function()return {Destroy=function()end}end,SetButton=function(b,text,enabled)b.Text=text;b.Interactable=enabled end}
local Cleanup={new=function()return {Add=function(_,v)return v end,Destroy=function()end}end}
local script={Parent={Cleanup='cleanup',Locale='locale',UIWidgets='widgets'}}
local function require(k)return ({catalog=Catalog,ride=Ride,cleanup=Cleanup,locale={Text=function(t)return t end},widgets=W})[k]end
local Client=(function() CLIENT end)()
local state=profile.Data
local ctx={refs={Safe={},AbilityButton={Activated=signal()},AttackButton={Activated=signal()},RideButton={Activated=signal()}},net={state=state,connected=true}}
local client=Client.new(ctx)
assert(bindings.VerityRide.b=='L3','ride conflicts with Y menu binding')
assert(ctx.refs.AbilityButton.Visible and ctx.refs.AbilityButton.Text=='ПОЛЁТ • 12 с')
jump:Fire();heart:Fire(.1)
assert(#sent==1 and sent[1].slot=='Steer' and sent[1].direction.Y>.7,'short jump was lost')
now+=.31;heart:Fire(.1);assert(sent[#sent].direction.Y==0,'idle flight climbs without input')
ctx.active='PHONE';held.Space=true;heart:Fire(.1);assert(sent[#sent].direction.Magnitude==0,'menu did not suspend steering')
ctx.active=nil;held.Space=false;Gui.MenuIsOpen=true;heart:Fire(.1);assert(sent[#sent].direction.Magnitude==0)
Gui.MenuIsOpen=false;now=104;client:Render();assert(ctx.refs.AbilityButton.Text=='ПОЛЁТ • 8 с','button shows cooldown instead of flight time')
profile.Data.AbilitiesOwned={};profile.Data.AbilitiesEquipped.Mobility=nil
p:SetAttribute('VerityRiding',true);p:SetAttribute('VerityMobilityUntil',now+60)
heart:Fire(.1)
assert(not ctx.refs.AbilityButton.Visible and ctx.refs.RideButton.Visible,'riding requires a purchased flight')
assert(sent[#sent].slot=='Steer','unpaid rider steering was skipped')
client:Activate('Ride',true);assert(sent[#sent].slot=='Ride','dismount button did not route to server')
p:SetAttribute('VerityRidePhase','Takeoff');client:Render()
assert(not ctx.refs.RideButton.Interactable and ctx.refs.RideButton.Text:find('Взлетаем!'),'takeoff button did not lock/show phase')
client:Destroy()
print('Ability client: actual constructor,10Hz steering, short jump latch, hover/menu guards and active12s countdown passed; no Play')
'''
for a,p in [('LEVELCONFIG','src/shared/LevelConfig.luau'),('RIDECONFIG','src/shared/VerityRideConfig.luau'),('CATALOG','src/shared/AbilityCatalog.luau'),('FORMS','src/shared/VerityAbilities.luau'),('NUMERIC','src/shared/Numeric.luau'),('SERVICE','src/server/VerityAbilityService.luau'),('CLIENT','src/client/AbilityController.luau')]:h=h.replace(a,(R/p).read_text())
with tempfile.TemporaryDirectory(prefix='verity-abilities-') as t:
 p=Path(t)/'check.luau';p.write_text(h);subprocess.run([sys.argv[1],str(p)],check=True)
