"""Generate 100 native Roblox models/config from 16 shared uploaded skin images.
Original early palette and approved anchor designs remain intact.
"""
from pathlib import Path
import json,re,math,copy,xml.etree.ElementTree as E
R=Path(__file__).resolve().parents[1];BASE=R/'assets/verity-elemental';OUT=BASE/'all-levels'
(OUT/'models').mkdir(parents=True,exist_ok=True)
old=json.loads((BASE/'roblox-assets.json').read_text());new=json.loads((BASE/'progression-skins/roblox-assets.json').read_text());images={**old['textures'],**new['textures']}
colors={'Aqua':'14DDEB','Frost':'59C9FF','Magma':'FF970A','Cyber':'A337FF','Cosmic':'7930ED','Rainbow':'FF7BD9'}
ranges=[(10,14,'Aqua','Aqua'),(15,19,'AquaBloom','Aqua'),(20,24,'AquaCrest','Aqua'),(25,34,'Frost','Frost'),(35,44,'FrostPrism','Frost'),(45,49,'FrostAurora','Frost'),(50,59,'Magma','Magma'),(60,69,'MagmaBlaze','Magma'),(70,74,'MagmaCore','Magma'),(75,79,'Cyber','Cyber'),(80,84,'CyberPulse','Cyber'),(85,89,'CyberOverdrive','Cyber'),(90,94,'Cosmic','Cosmic'),(95,97,'CosmicNova','Cosmic'),(98,99,'CosmicNebula','Cosmic'),(100,100,'Rainbow','Rainbow')]
palette=re.findall(r'Name="([^"]+)",Hex="([A-F0-9]+)"',(R/'src/shared/VerityCompanionLevels.luau').read_text())[:9]
tones={'Aqua':(.06,.02,.09),'Frost':(.08,.04,0),'Magma':(0,.06,.12),'Cyber':(0,.08,.02),'Cosmic':(.04,.08,0),'Rainbow':(0,0,0)}
levels=[]
for level in range(1,101):
 if level<=9:
  name,h=palette[level-1];d={'level':level,'id':name,'family':'Basic','texture':None,'hex':h,'tone':[1,1,1]}
 else:
  start,end,id,family=next(x for x in ranges if x[0]<=level<=x[1]);p=(level-start)/max(1,end-start)
  d={'level':level,'id':id,'family':family,'texture':images[id],'hex':colors[family],'tone':[round(1-c*p,6) for c in tones[family]]}
 d['name']=f"Verity_L{level:03}_{d['id']}";d['suggestedScale']=1+14*((level-1)/99)**.85;levels.append(d)
(OUT/'levels.json').write_text(json.dumps({'mesh':old['mesh'],'meshDiameter':2.8,'baseDiameter':1.7,'textureCount':len(images),'levels':levels},indent=2))
# Runtime descriptors are cached once; no new rendering loop or random per-frame colors.
s='''--!strict
-- Full progression; all body texture IDs are real Studio upload readbacks.
local Skins={MeshId="rbxassetid://98969698787830",MeshDiameter=2.8,BodyDiameter=1.7}
Skins.Items=table.freeze({
'''
for start,end,id,family in ranges:s+=f' {id}=table.freeze({{Id="{id}",Family="{family}",Texture="{images[id]}",Hex="{colors[family]}"}}),\n'
s+='})\nSkins.Targets=table.freeze({[10]="Aqua",[25]="Frost",[50]="Magma",[75]="Cyber",[90]="Cosmic",[100]="Rainbow"})\nlocal levels={\n'
for d in levels[9:]:
 tone=','.join(map(str,d['tone']))
 s+=f' [{d["level"]}]=table.freeze({{Id="{d["id"]}",LevelKey="{d["id"]}:{d["level"]}",Family="{d["family"]}",Texture=Skins.Items.{d["id"]}.Texture,Hex="{d["hex"]}",Tone=Vector3.new({tone})}}),\n'
s+='''}
function Skins.Get(level: number,override: string?)
 if override then return Skins.Items[override] end
 return levels[level]
end
return table.freeze(Skins)
'''
(R/'src/shared/VerityElementalSkins.luau').write_text(s)
# Native library: one Root, one Body, one SpecialMesh and independent shared FaceGui.
face=next(x for x in E.parse(R/'assets/verity-ten-textured/Verity_FaceTemplates.rbxmx').getroot().iter('Item') if x.get('class')=='SurfaceGui')
face_ids=json.loads((R/'assets/verity-ten-textured/roblox-assets.json').read_text())['textures']
def item(parent,kind,name,ref):
 n=E.SubElement(parent,'Item',{'class':kind,'referent':ref});p=E.SubElement(n,'Properties');E.SubElement(p,'string',name='Name').text=name;return n,p
def val(p,kind,name,value):E.SubElement(p,kind,name=name).text=str(value)
def vec(p,name,xyz):
 n=E.SubElement(p,'Vector3',name=name)
 for k,v in zip('XYZ',xyz):E.SubElement(n,k).text=str(v)
def frame(p,y):
 n=E.SubElement(p,'CoordinateFrame',name='CFrame')
 for k,v in zip(['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],[0,y,0,1,0,0,0,1,0,0,0,1]):E.SubElement(n,k).text=str(v)
def content(p,key,uri):E.SubElement(E.SubElement(p,'Content',name=key),'url').text=uri
library=E.Element('roblox',{'version':'4'});folder,_=item(library,'Folder','VerityElementalModels','AllLevels')
for d in levels:
 ref=f'L{d["level"]:03}';model,mp=item(folder,'Model',d['name'],ref);val(mp,'Ref','PrimaryPart',ref+'Root')
 for y,size,suffix in [(0,.04,'Root'),(.85,1.7,'Body')]:
  part,p=item(model,'Part',suffix,ref+suffix);vec(p,'size',[size]*3);frame(p,y)
  for flag in ['Anchored','CanCollide','CanTouch','CanQuery','CastShadow']:val(p,'bool',flag,'true' if flag=='Anchored' else 'false')
  val(p,'Color3uint8','Color3uint8',0xffffffff if suffix=='Root' or d['texture'] else 0xff000000|int(d['hex'],16));val(p,'token','Material',272)
  if suffix=='Root':val(p,'float','Transparency',1);continue
  mesh,sp=item(part,'SpecialMesh','Mesh',ref+'Mesh');val(sp,'token','MeshType',5 if d['texture'] else 3)
  vec(sp,'Scale',[1.7/2.8]*3 if d['texture'] else [1]*3);vec(sp,'VertexColor',d['tone'])
  if d['texture']:content(sp,'MeshId',old['mesh']);content(sp,'TextureId',d['texture'])
  gui=copy.deepcopy(face);mapping={}
  for i,n in enumerate(gui.iter('Item')):mapping[n.get('referent')]=ref+f'Face{i}';n.set('referent',ref+f'Face{i}')
  for n in gui.iter('Ref'):
   if n.text in mapping:n.text=mapping[n.text]
  props=gui.find('Properties');oldref=props.find("Ref[@name='Adornee']")
  if oldref is not None:props.remove(oldref)
  val(props,'Ref','Adornee',ref+'Body');part.append(gui)
 meta,mp=item(model,'Configuration','Integration',ref+'Integration')
 for kind,key,value in [('IntValue','Level',d['level']),('StringValue','SkinId',d['id']),('StringValue','Family',d['family']),('NumberValue','BaseDiameter',1.7),('NumberValue','SuggestedScale',d['suggestedScale']),('BoolValue','AlreadyScaled','false')]:
  _,p=item(meta,kind,key,ref+key);val(p,{'IntValue':'int64','StringValue':'string','NumberValue':'double','BoolValue':'bool'}[kind],'Value',value)
 emotions,_=item(meta,'Configuration','Emotions',ref+'Emotions')
 for name,uri in face_ids.items():_,p=item(emotions,'StringValue',name,ref+name);val(p,'string','Value',uri)
 single=E.Element('roblox',{'version':'4'});single.append(copy.deepcopy(model));E.indent(single);E.ElementTree(single).write(OUT/'models'/f'{d["name"]}.rbxmx',encoding='utf-8',xml_declaration=True)
E.indent(library);E.ElementTree(library).write(OUT/'Verity_All_100_Models.rbxmx',encoding='utf-8',xml_declaration=True)
p=R/'default.project.json';j=json.loads(p.read_text());j['tree']['ReplicatedStorage'].pop('VerityElementalModels',None);j['tree'].setdefault('ServerStorage',{'$className':'ServerStorage'})['VerityElementalModels']={'$path':'assets/verity-elemental/all-levels/Verity_All_100_Models.rbxmx'};p.write_text(json.dumps(j,indent=2)+'\n')
print('Built100 native models and cached runtime descriptors;16 shared textures; original1–9 palette; normalized size and8 independent emotions.')
