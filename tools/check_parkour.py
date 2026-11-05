"""Execute actual parkour geometry/service with mocked Roblox; optional native visual export."""
from pathlib import Path
import subprocess,tempfile,sys,math,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1]
h='''
local V={}
function V.__index(v,k)if k=='Magnitude' then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)end;return V[k]end
local function vec(x,y,z)return setmetatable({X=x,Y=y,Z=z},V)end
function V.__add(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
function V.__sub(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
local Vector3={new=vec,zero=vec(0,0,0)}
local CFrame={new=vec}
local Numeric=(function() NUMERIC end)()
local script={Parent={Numeric='numeric'}}
local function require(k)assert(k=='numeric');return Numeric end
local Income=(function() INCOME end)()
local Config=(function() CONFIG end)()
-- Check free-route geometry using the weakest existing form, before powers.
for i=2,#Config.Pads do
 local a,b=Config.Pads[i-1],Config.Pads[i]
 local gap=if a.x~=b.x then math.abs(a.x-b.x)-(a.w+b.w)/2 else math.abs(a.z-b.z)-(a.d+b.d)/2
 assert(gap<=3.5 and b.y-a.y<=1.5,'base jump gap/height')
 assert(Config.Contains(b.x,b.z),'outside island')
end
local game={GetService=function()return {Shared={ParkourConfig='config',EconomyConfig='income',LocaleText='locale'}}end}
local function require(k)return ({config=Config,income=Income,locale={SetWorld=function(o,k,v)o[k]=v end}})[k]end
local Service=(function() SERVICE end)()
local now=100;local rewards=0;local publishes=0;local notes={};local stops=0
local root={Position=vec(0,3,0)}
local hum={Health=100}
local char={}
function char:FindFirstChild(n)return if n=='HumanoidRootPart' then root else nil end
function char:FindFirstChildOfClass(n)return if n=='Humanoid' then hum else nil end
function char:PivotTo(cf)root.Position=cf end
local player={UserId=1,Character=char,attrs={}}
function player:SetAttribute(k,v)self.attrs[k]=v end
local profile={Data={VerityUnlocked=true,VerityLevel=1}}
local data={Get=function(_,id)return if id==1 then profile else nil end}
local state={sessions={[1]={}},Publish=function()publishes+=1 end}
local economy={GetMultiplier=function()return 1 end,AddCash=function(_,id,amount)assert(id==1);rewards+=amount;return true,amount end}
local s=Service.new(data,state,economy,function()return now end,function(_,code,amount)table.insert(notes,{code=code,amount=amount})end,function()stops+=1 end)
local function pad(i)local p=Config.Pads[i];root.Position=vec(p.x,p.y+3.5,p.z)end
pad(13);assert(not s:Touch(player,13) and rewards==0,'finish without run')
pad(1);assert(s:Touch(player,1));pad(3);assert(not s:Touch(player,3),'skipped pad')
for i=2,7 do now+=.5;pad(i);assert(s:Touch(player,i))end
assert(s.runs[player].checkpoint==7)
root.Position=vec(260,3,300);s:Tick();assert(stops==1 and root.Position.Y==Config.Pads[7].y+4)
assert(s.runs[player].index==7,'fall did not restore checkpoint')
for i=8,13 do now+=.5;pad(i);assert(s:Touch(player,i))end
assert(rewards==Income.getIncome(1)*20 and publishes==1 and not s.runs[player])
assert(not s:Touch(player,13),'duplicate finish')
local paid=rewards
pad(1);assert(s:Touch(player,1))
for i=2,13 do now+=.5;pad(i);assert(s:Touch(player,i))end
assert(rewards==paid and notes[#notes].code=='PARKOUR_PRACTICE','cooldown paid twice')
now+=Config.Cooldown;pad(1);assert(s:Touch(player,1))
for i=2,13 do now+=.5;pad(i);assert(s:Touch(player,i))end
assert(rewards==paid*2 and publishes==2)
pad(1);assert(s:Touch(player,1));hum.Health=0;s:Tick();assert(not s.runs[player]);hum.Health=100
pad(1);root.Position=vec(0,3,0);assert(not s:Touch(player,1),'remote-position completion')
pad(1);profile.Data.VerityUnlocked=false;assert(not s:Touch(player,1));profile.Data.VerityUnlocked=true
assert(s:Touch(player,1));s:Return(player,true);assert(not s.runs[player] and root.Position.X==164)
s:Remove(player);assert(s.ready[player]==nil)
-- Execute the actual builder, capture its native geometry, check idempotence.
local instances={}
local Instance={new=function(class)
 local o={ClassName=class,attrs={},id=#instances+1}
 function o:SetAttribute(k,v)self.attrs[k]=v end
 function o:GetAttribute(k)return self.attrs[k]end
 function o:FindFirstChild(name,recursive)
  for _,n in instances do if n.Parent==self then if n.Name==name then return n end;if recursive then local found=n:FindFirstChild(name,true);if found then return found end end end end
 end
 table.insert(instances,o);return o
end}
local Color3={fromHex=function(s)return s end}
local UDim2={fromOffset=function(x,y)return {X=x,Y=y}end,fromScale=function(x,y)return {X=x,Y=y}end}
local Enum={Material={Plastic=1},SurfaceType={Studs=3,Smooth=0},Font={GothamBold=20}}
local Builder=(function() BUILDER end)()
local parent=Instance.new('Model');local course=Builder.Build(parent);local count=#instances
assert(Builder.Build(parent)==course and #instances==count,'duplicate course on reused v5')
local padCount=0;local parts=0
for _,p in instances do
 if p.ClassName=='Part' then
  parts+=1;assert(p.Anchored,'loose part')
  if p.attrs.ParkourIndex then padCount+=1;assert(p.CanTouch and p.CanCollide,'pad cannot be reached')end
  print(string.format('PART|%d|%s|%f,%f,%f|%f,%f,%f|%s|%s|%s',p.id,p.Name,p.Position.X,p.Position.Y,p.Position.Z,p.Size.X,p.Size.Y,p.Size.Z,p.Color,tostring(p.CanCollide),tostring(p.CanTouch)))
 elseif p.ClassName=='TextLabel' and p.Parent and p.Parent.ClassName=='BillboardGui' then
  local g=p.Parent
  print(string.format('LABEL|%d|%s|%f|%f',g.Parent.id,p.Text,g.Size.X,g.StudsOffsetWorldSpace.Y))
 end
end
assert(padCount==13 and parts<140,'course part budget/route')
print('Parkour: actual builder/service, base jump bounds,13 ordered pads, checkpoint reset, reward deduplication/cooldown/practice, death/exit/position guards passed; no Play')
'''
for a,p in [('NUMERIC','src/shared/Numeric.luau'),('INCOME','src/shared/EconomyConfig.luau'),('CONFIG','src/shared/ParkourConfig.luau'),('SERVICE','src/server/ParkourService.luau'),('BUILDER','src/world/ParkourBuilder.luau')]:h=h.replace(a,(R/p).read_text())
with tempfile.TemporaryDirectory(prefix='verity-parkour-') as t:
 p=Path(t)/'check.luau';p.write_text(h);result=subprocess.run([str(R.parent/'luau/luau'),str(p)],check=True,capture_output=True,text=True)
rows=result.stdout.splitlines();print('\n'.join(x for x in rows if not x.startswith(('PART|','LABEL|'))))
if '--export' in sys.argv:
 out=R/'assets/parkour';out.mkdir(parents=True,exist_ok=True)
 doc=E.Element('roblox',{'version':'4'});model=E.SubElement(doc,'Item',{'class':'Model','referent':'ParkourPreview'});props=E.SubElement(model,'Properties');E.SubElement(props,'string',name='Name').text='Parkour_Visual_Preview'
 def val(p,k,n,v):E.SubElement(p,k,name=n).text=str(v)
 def vec(p,n,xyz):
  e=E.SubElement(p,'Vector3',name=n)
  for k,v in zip('XYZ',xyz):E.SubElement(e,k).text=str(v)
 parts={}
 for row in rows:
  a=row.split('|')
  if a[0]!='PART':continue
  _,id,name,pos,size,color,collide,touch=a
  node=E.SubElement(model,'Item',{'class':'Part','referent':'P'+id});p=E.SubElement(node,'Properties');val(p,'string','Name',name);vec(p,'size',map(float,size.split(',')))
  cf=E.SubElement(p,'CoordinateFrame',name='CFrame')
  for k,v in zip(['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],[*map(float,pos.split(',')),1,0,0,0,1,0,0,0,1]):
   E.SubElement(cf,k).text=str(v)
  for k,v in [('Anchored','true'),('CanCollide',collide),('CanTouch','false'),('CanQuery',collide)]:val(p,'bool',k,v)
  val(p,'Color3uint8','Color3uint8',0xff000000|int(color,16));val(p,'token','Material',256);val(p,'token','TopSurface',3);parts[id]=node
 for row in rows:
  a=row.split('|')
  if a[0]!='LABEL':continue
  _,id,text,width,offset=a
  gui=E.SubElement(parts[id],'Item',{'class':'BillboardGui','referent':'G'+id});p=E.SubElement(gui,'Properties');val(p,'string','Name','Sign');val(p,'Ref','Adornee','P'+id);val(p,'float','MaxDistance',500);vec(p,'StudsOffsetWorldSpace',[0,float(offset),0])
  d=E.SubElement(p,'UDim2',name='Size')
  for k,v in [('XS',0),('XO',width),('YS',0),('YO',48)]:E.SubElement(d,k).text=str(v)
  label=E.SubElement(gui,'Item',{'class':'TextLabel','referent':'T'+id});p=E.SubElement(label,'Properties');val(p,'string','Text',text);val(p,'float','TextSize',15);val(p,'bool','TextWrapped','true');val(p,'Color3uint8','BackgroundColor3uint8',0xff403064);val(p,'Color3uint8','TextColor3uint8',0xfffff6ed)
  d=E.SubElement(p,'UDim2',name='Size')
  for k,v in [('XS',1),('XO',0),('YS',1),('YO',0)]:E.SubElement(d,k).text=str(v)
 E.indent(doc);E.ElementTree(doc).write(out/'Verity_Parkour_Visual_v1.rbxmx',encoding='utf-8',xml_declaration=True)
 print('Exported visual-only native parkour model from actual builder geometry (no scripts/rewards in asset).')
