"""Actual door construction/pair exclusions, lifecycle and permission paths; no Studio/Play."""
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
function V.__add(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
function V.__sub(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
local Vector3={new=vec}
local CF={};CF.__index=CF
local function cf(p)return setmetatable({Position=p},CF)end
function CF.__mul(a,b)return cf(a.Position+b.Position)end
function CF:PointToObjectSpace(p)return p-self.Position end
local CFrame={new=function(x,y,z)return cf(if type(x)=='table' then x else vec(x or 0,y or 0,z or 0))end,Angles=function()return cf(vec(0,0,0))end,identity=cf(vec(0,0,0))}
local Color3={fromHex=function(h)return h end};local Enum={Material={SmoothPlastic=1},PartType={Cylinder=1}}
local all={}
local Instance={new=function(class)
 local o={ClassName=class,Destroying=signal()}
 function o:IsA(c)return self.ClassName==c or c=='BasePart' and (self.ClassName=='Part' or self.ClassName=='MeshPart')end
 function o:Destroy()self.Destroying:Fire();self.dead=true;self.Parent=nil end
 function o:PivotTo(target)
  local delta=target.Position-(self.pivot or CFrame.identity).Position
  for _,p in all do if p.Parent==self and p:IsA('BasePart') then p.CFrame=cf(p.CFrame.Position+delta)end end
  self.pivot=target
 end
 table.insert(all,o);return o
end}
local heart=signal();local Players={list={},PlayerAdded=signal()}
function Players:GetPlayers()return self.list end
function Players:GetPlayerByUserId(id)for _,p in self.list do if p.UserId==id then return p end end end
local RS={Shared={},World={PurchasePadFactory='pads'}}
local game={GetService=function(_,s)return ({RunService={Heartbeat=heart},Players=Players,ReplicatedStorage=RS})[s]end}
local Door=(function() DOOR_SOURCE end)()
local function character()
 local c={parts={},DescendantAdded=signal(),DescendantRemoving=signal()}
 for _,kind in {'Part','MeshPart','Folder'} do table.insert(c.parts,Instance.new(kind))end
 c.root={Position=vec(0,3,13)};c.hum={Health=100}
 function c:GetDescendants()return self.parts end
 function c:FindFirstChild()return self.root end
 function c:FindFirstChildOfClass()return self.hum end
 return c
end
local function player(id)return {UserId=id,Character=character(),CharacterAdded=signal(),CharacterRemoving=signal()}end
local owner,guest=player(1),player(2);Players.list={owner,guest}
local d=Door.new({},CFrame.identity)
d:Set(true,true,false,1)
assert(d.leaf.CanCollide and d.leaf.CanQuery,'closed door no longer solid/queryable')
local count=0
for part,c in d.passage do count+=1;assert(c.Part0==d.leaf and c.Part1==part and c.Parent==d.leaf)end
assert(count==2 and not d.passage[guest.Character.parts[1]],'exception granted to guest or nonphysical object')
local extra=Instance.new('Part');owner.Character.DescendantAdded:Fire(extra);assert(d.passage[extra],'new accessory/tool not covered')
local c=d.passage[extra];owner.Character.DescendantRemoving:Fire(extra);assert(c.dead and not d.passage[extra])
local old=owner.Character;local oldConstraint=d.passage[old.parts[1]]
owner.CharacterRemoving:Fire(old);assert(not next(d.passage) and oldConstraint.dead)
owner.Character=character();owner.CharacterAdded:Fire(owner.Character)
assert(d.passage[owner.Character.parts[1]] and not d.passage[old.parts[1]],'respawn retained old character exceptions')
local previous=d.passage[owner.Character.parts[1]]
d:Set(true,true,false,2);assert(previous.dead and d.passage[guest.Character.parts[1]] and not d.passage[owner.Character.parts[1]],'owner reassignment leaked passage')
local stale=Instance.new('Part');old.DescendantAdded:Fire(stale);assert(not d.passage[stale],'old character listener remained')
owner.CharacterAdded:Fire(character());assert(d.character==guest.Character,'previous owner respawn took over door')
d:Set(false,true,false,2);assert(not next(d.passage) and not d.leaf.CanCollide and not d.model.Parent)
d:Set(true,false,false,1);Players.list={owner};owner.Character.root.Position=d.leaf.CFrame.Position
local from=d.angle;d:Set(true,true,true,1);heart:Fire(.1);assert(d.angle<from,'owner stalled closing animation')
Players.list={owner,guest};guest.Character.root.Position=d.leaf.CFrame.Position
local angle=d.angle;heart:Fire(.1);assert(d.angle==angle,'door crushed guest instead of pausing')
guest.Character.root.Position=vec(100,3,100);for _=1,30 do heart:Fire(.1)end
assert(d.angle==0 and not d.motion and d.leaf.CanCollide)
local active=d.passage[owner.Character.parts[1]];d.model:Destroy();assert(active.dead and not next(d.passage),'model destruction leaked passage')
-- A delayed player join is supported if ownership is assigned before the Player exists.
Players.list={};d=Door.new({},CFrame.identity);d:Set(true,true,false,3)
local late=player(3);Players.PlayerAdded:Fire(late);assert(d.passage[late.Character.parts[1]])
d.model:Destroy()
local script={Parent={HouseConstruction='construction',HouseDoor='door'}}
local function require(k)return if k=='door' then Door else {}end
local Progression=(function() PROGRESSION_SOURCE end)()
local root=owner.Character.root;root.Position=vec(0,3,13)
local record={state={VerityUnlocked=true,HouseDoorOwned=true,HouseDoorLocked=true,ownerUserId=1},pivot=CFrame.identity,
 doorPrompt={Parent={Position=vec(0,3,17.5)},MaxActivationDistance=8},exitPrompt={Parent={Position=vec(0,3,11.5)},MaxActivationDistance=6},insideGuests={}}
local p=setmetatable({plots={[1]=record}},Progression)
assert(p:CanUseDoor(1,owner,true),'owner cannot open from inside')
record.state.HouseDoorLocked=false;assert(p:CanUseDoor(1,owner,true),'owner cannot close from inside')
guest.Character.root.Position=vec(0,3,13);record.insideGuests[2]=guest.Character
assert(not p:CanUseDoor(1,guest,true),'guest can close open door')
record.state.HouseDoorLocked=true;assert(p:CanUseDoor(1,guest,true),'trapped guest cannot exit')
record.insideGuests={};assert(not p:CanUseDoor(1,guest,true),'unregistered guest can unlock from inside')
root.Position=vec(0,3,19);assert(p:CanUseDoor(1,owner,false));guest.Character.root.Position=root.Position
assert(not p:CanUseDoor(1,guest,false),'guest can operate exterior owner control')
local State={sessions={[1]={HouseDoorLocked=true}},Publish=function()end}
local Upgrade={SetHouseDoor=function(_,id,locked)State.sessions[id].HouseDoorLocked=locked;return 'OK'end}
local activate=ACTIVATION_SOURCE
activate(owner,'DoorExit',1);assert(not State.sessions[1].HouseDoorLocked)
activate(owner,'DoorExit',1);assert(State.sessions[1].HouseDoorLocked)
activate(guest,'DoorExit',1);assert(not State.sessions[1].HouseDoorLocked,'guest exit locked the owner in')
print('Door: actual model, owner-only pair exclusions, accessories/respawn/reassignment/removal, guest blocking, swing guards and inside/outside permissions passed; no Play')
'''
source=(R/'src/server/ServerBootstrap.server.luau').read_text()
fn=re.search(r'houseProgression = require\(script.Parent.HouseProgression\).new\(World, Players, (function\(player, feature, doorOwnerId\).*?\nend)\)',source,re.S).group(1)
for key,value in [('DOOR_SOURCE',(R/'src/server/HouseDoor.luau').read_text()),('PROGRESSION_SOURCE',(R/'src/server/HouseProgression.luau').read_text()),('ACTIVATION_SOURCE',fn)]:h=h.replace(key,value)
with tempfile.TemporaryDirectory(prefix='verity-owner-door-') as t:
 p=Path(t)/'check.luau';p.write_text(h);subprocess.run([str(R.parent/'luau/luau'),str(p)],check=True)
