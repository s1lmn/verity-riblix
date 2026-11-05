"""Execute the real ride presentation lifecycle with minimal engine mocks; no Studio/Play."""
from pathlib import Path
import subprocess,tempfile
R=Path(__file__).resolve().parents[1]
h=r'''
local function signal()
 local rows={};return {Connect=function(_,f)local r={f=f};table.insert(rows,r);return {Disconnect=function()r.off=true end}end,
 Fire=function(_,...)for _,r in rows do if not r.off then r.f(...)end end end}
end
local V={};V.__index=function(v,k)if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end;return V[k]end
local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},V)end
function V.__sub(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
local Vector3={new=vec};local Vector2={new=vec}
local CF={};CF.__index=function(c,k)if k=='Rotation' then return setmetatable({Position=vec(0,0,0),angle=c.angle},CF)end;return CF[k]end
function CF.__mul(a,b)return setmetatable({Position=a.Position,angle=(a.angle or 0)+(b.angle or 0)},CF)end
local CFrame={new=function(v)return setmetatable({Position=v},CF)end,Angles=function(x)return setmetatable({Position=vec(0,0,0),angle=x},CF)end}
local function ctor(...)return {...}end
local NumberRange={new=ctor};local NumberSequence={new=ctor};local NumberSequenceKeypoint={new=ctor};local ColorSequence={new=ctor}
local Color3={new=ctor,fromHex=function(s)return s end}
local objects={}
local Instance={new=function(kind)local o={ClassName=kind}
 function o:Destroy()self.dead=true end
 function o:Emit(n)self.emitted=(self.emitted or 0)+n end
 function o:Clear()self.cleared=true end
 table.insert(objects,o);return o
end}
local Cleanup={new=function()return {items={},Add=function(self,v)table.insert(self.items,v)end,Destroy=function(self)for _,v in self.items do if v.Disconnect then v:Disconnect()else v:Destroy()end end end}end}
local pre=signal();local Players={list={}};function Players:GetPlayers()return self.list end
local workspace={CurrentCamera={CFrame={Position=vec(0,20,0)}}}
local Shared={VerityElementalSkins='skins'};local game={GetService=function(_,s)return ({Players=Players,RunService={PreSimulation=pre},ReplicatedStorage={Shared=Shared}})[s]end}
local script={Parent={Cleanup='cleanup'}}
local function require(k)return if k=='cleanup' then Cleanup else {Get=function()return {Hex='FFAA22'}end}end
local Presentation=(function() PRESENTATION end)()
local root={Position=vec(0,20,0),AssemblyLinearVelocity=vec(10,0,0)}
local hum={Health=100}
local function motor(name)return {Name=name,Parent=true,C0=CFrame.new(vec(0,0,0)),IsA=function(_,s)return s=='Motor6D'end}end
local hip,knee,r6= motor('LeftHip'),motor('LeftKnee'),motor('Right Hip')
local base=hip.C0;local char={}
function char:GetDescendants()return {hip,knee,r6}end
function char:FindFirstChild()return root end
function char:FindFirstChildOfClass()return hum end
local player={UserId=1,Character=char,attrs={VerityRiding=true,VerityRidePhase='Takeoff'}}
function player:GetAttribute(k)return self.attrs[k]end
Players.list={player}
local ctx={settings={values={ReducedMotion=false,ReducedEffects=false}}}
local p=Presentation.new(ctx,{})
pre:Fire(.1)
local r=p.records[player];assert(r and #r.joints==3 and r.emitter.emitted==24,'takeoff pose/burst missing')
assert(hip.C0.angle<0 and knee.C0.angle>0 and r6.C0.angle<0,'R6/R15 seated legs missing')
player.attrs.VerityRidePhase='Cruise';pre:Fire(.1);assert(r.trail.Enabled and r.emitter.emitted==34)
ctx.settings.values.ReducedEffects=true;pre:Fire(.1)
assert(not r.emitter.Enabled and not r.trail.Enabled and not r.light.Enabled and r.emitter.cleared and r.trail.cleared,'ReducedEffects left effects alive')
ctx.settings.values.ReducedEffects=false;ctx.settings.values.ReducedMotion=true;pre:Fire(.1);assert(not r.trail.Enabled,'ReducedMotion left ribbon alive')
player.attrs.VerityRidePhase='Landing';pre:Fire(.1);assert(r.emitter.emitted==52,'landing burst missing')
player.attrs.VerityRiding=nil;for _=1,12 do pre:Fire(.1)end
assert(not p.records[player] and hip.C0==base,'unmount failed to restore exact joints')
player.attrs.VerityRiding=true;pre:Fire(.1);r=p.records[player]
hum.Health=0;pre:Fire(.1);assert(not p.records[player] and r.emitter.Parent.dead,'death leaked presentation')
hum.Health=100;pre:Fire(.1);r=p.records[player];workspace.CurrentCamera.CFrame.Position=vec(1000,0,0)
pre:Fire(.1);assert(not p.records[player],'distance culling leaked pose')
workspace.CurrentCamera.CFrame.Position=vec(0,20,0);pre:Fire(.1);r=p.records[player]
p:Destroy();pre:Fire(.1);assert(not next(p.records),'UI teardown leaked presentation')
print('Ride presentation: real constructor, R6/R15 pose,3 phase bursts, reduced settings, unmount/death/distance/teardown cleanup passed; mocked engine only')
'''.replace('PRESENTATION',(R/'src/client/RidePresentation.luau').read_text())
with tempfile.TemporaryDirectory(prefix='verity-ride-presentation-') as t:
 p=Path(t)/'check.luau';p.write_text(h);subprocess.run([str(R.parent/'luau/luau'),str(p)],check=True)
