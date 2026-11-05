"""Validate all native models and execute exact production skin-stage code. No Play."""
from pathlib import Path
import json,subprocess,tempfile,xml.etree.ElementTree as E,re
R=Path(__file__).resolve().parents[1];OUT=R/'assets/verity-elemental/all-levels';data=json.loads((OUT/'levels.json').read_text())
assert len(data['levels'])==100 and data['textureCount']==16
root=E.parse(OUT/'Verity_All_100_Models.rbxmx').getroot();folder=root.find('Item');models=folder.findall('Item');assert len(models)==100
refs=[n.get('referent') for n in root.iter('Item')];assert len(refs)==len(set(refs))
for d,m in zip(data['levels'],models):
 assert m.find("Properties/string[@name='Name']").text==d['name']
 body=next(n for n in m.findall('Item') if n.find("Properties/string[@name='Name']").text=='Body')
 assert all(float(n.text)==1.7 for n in body.findall("Properties/Vector3[@name='size']/*"))
 assert len(body.findall("Item[@class='SurfaceGui']"))==1
 mesh=body.find("Item[@class='SpecialMesh']");assert mesh is not None
 if d['texture']:assert mesh.find("Properties/Content[@name='TextureId']/url").text==d['texture']
 else:assert mesh.find("Properties/token[@name='MeshType']").text=='3'
 assert len(list((OUT/'models').glob(f'{d["name"]}.rbxmx')))==1
 meta=next(n for n in m.findall('Item') if n.find("Properties/string[@name='Name']").text=='Integration')
 emotions=next(n for n in meta.findall('Item') if n.find("Properties/string[@name='Name']").text=='Emotions')
 assert len(emotions.findall('Item'))==8
 assert 1<=d['suggestedScale']<=15
source=(R/'src/world/VerityFactory.luau').read_text();stage=source[source.index('function Factory.SetStage'):source.index('\nreturn Factory')]
visual=(R/'src/world/VerityVisualController.luau').read_text()
apply=visual[visual.index('function Controller:Apply('):visual.index('\n-- The existing model controller owns attack facing')]
assert 'p:GetAttribute("VerityTint")~=nil' in visual

h='''
local V={};V.__index=V
local function vector(x,y,z)return setmetatable({X=x,Y=y,Z=z},V)end
function V.__mul(a,b)if type(a)=='number' then a,b=b,a end;return vector(a.X*b,a.Y*b,a.Z*b)end
local Vector3={new=vector,one=vector(1,1,1)}
local Color3={new=vector,fromHex=function()return vector(.9,.7,.1)end}
local Enum={MeshType={FileMesh='file',Sphere='sphere'}}
local Skins=(function() CONFIG end)()
local Factory={Color=function()return Color3.new(1,.8,.1)end}
STAGE
local model={scale=1}
local mesh={}
local body={attrs={}}
function body:FindFirstChildOfClass()return mesh end
function body:GetAttribute(k)return self.attrs[k]end
function body:SetAttribute(k,v)self.attrs[k]=v end
function model:FindFirstChild(k)return if k=='Body' then body else nil end
function model:GetAttribute()return nil end
function model:GetScale()return self.scale end
for pass=1,2 do
 for i=1,100 do
  local level=if pass==1 then i else 101-i
  local skin=Skins.Get(level);model.scale=1+14*((level-1)/99)^.85
  Factory.SetStage(model,level)
  if level<10 then
   assert(skin==nil and mesh.MeshType=='sphere' and mesh.TextureId=='')
   assert(body:GetAttribute('VerityTint')==true and mesh.VertexColor.X==1)
  else
   assert(skin and mesh.TextureId==skin.Texture and mesh.MeshType=='file')
   assert(math.abs(mesh.Scale.X-(1.7/2.8)*model.scale)<1e-6)
   assert(body:GetAttribute('VerityTint')==false)
   assert(mesh.VertexColor.X>=.85 and mesh.VertexColor.Y>=.85 and mesh.VertexColor.Z>=.85)
  end
 end
end
for level,id in {[10]='Aqua',[25]='Frost',[50]='Magma',[75]='Cyber',[90]='Cosmic',[100]='Rainbow'} do
 local skin=Skins.Get(level);assert(skin.Id==id and skin.Tone.X==1 and skin.Tone.Y==1 and skin.Tone.Z==1,'anchor changed')
end
for _,level in {0,101,-1,.5}do assert(Skins.Get(level)==nil)end
assert(Skins.Get(75,'Cosmic').Id=='Cosmic','preview override')
-- Execute the merged Apply method: camera/aim ownership remains the team's path,
-- while the elemental Body must keep its texture-neutral color.
local CF={};CF.__index=CF;function CF.__mul()return setmetatable({},CF)end
local CFrame={new=function()return setmetatable({},CF)end,Angles=function()return setmetatable({},CF)end}
local workspace={CurrentCamera=nil}
local Controller={}
APPLY_METHOD
local previous={};local nextColor={}
local textured={Parent=true,Color=previous,GetAttribute=function()return false end}
local plain={Parent=true,Color=previous,GetAttribute=function()return true end}
local renderModel={PrimaryPart={FindFirstChild=function()return nil end}}
function renderModel:IsDescendantOf()return true end
function renderModel:GetScale()return 1 end
function renderModel:GetAttribute()return false end
function renderModel:PivotTo(p)self.pose=p end
Controller.Apply({}, {model=renderModel,origin=CFrame.new(),stageLevel=1,tints={textured,plain}},1,0,0,nextColor,1)
assert(textured.Color==previous and plain.Color==nextColor,'merge recolored texture or froze ordinary color')
print('100 native models,8 faces,16 textures,200 skin transitions and merged renderer tint protection passed; no Play')
'''.replace('CONFIG',(R/'src/shared/VerityElementalSkins.luau').read_text()).replace('STAGE',stage).replace('APPLY_METHOD',apply)
with tempfile.TemporaryDirectory(prefix='verity-all-levels-') as t:
 p=Path(t)/'check.luau';p.write_text(h);subprocess.run([str(R.parent/'luau/luau'),str(p)],check=True)
