"""Build a native Roblox model library from verified uploaded asset IDs."""
from pathlib import Path
import xml.etree.ElementTree as E,copy,json
R=Path(__file__).resolve().parents[1];OUT=R/'assets/verity-elemental'
a=json.loads((OUT/'roblox-assets.json').read_text())
templates=E.parse(R/'assets/verity-ten-textured/Verity_FaceTemplates.rbxmx').getroot()
face=next(x for x in templates.iter('Item') if x.get('class')=='SurfaceGui')
root=E.Element('roblox',{'version':'4'})
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
folder,_=item(root,'Folder','VerityElementalModels','Elementals')
for s in json.loads((OUT/'manifest.json').read_text())['models']:
 name=s['skin'];ref='Elemental'+name;model,p=item(folder,'Model',f"Verity_{s['targetLevel']}_{name}",ref)
 val(p,'Ref','PrimaryPart',ref+'Root')
 for kind,y,size,suffix in [('Part',0,.04,'Root'),('Part',.85,1.7,'Body')]:
  part,pp=item(model,kind,suffix,ref+suffix);vec(pp,'size',[size]*3);frame(pp,y)
  for flag,v in [('Anchored',True),('CanCollide',False),('CanTouch',False),('CanQuery',False),('CastShadow',False)]:val(pp,'bool',flag,str(v).lower())
  val(pp,'Color3uint8','Color3uint8',4294967295);val(pp,'token','Material',272)
  if suffix=='Root':val(pp,'float','Transparency',1)
  else:
   mesh,mp=item(part,'SpecialMesh','Mesh',ref+'Mesh');val(mp,'token','MeshType',5)
   vec(mp,'Scale',[1.7/2.8]*3);content(mp,'MeshId',a['mesh']);content(mp,'TextureId',a['textures'][name])
   gui=copy.deepcopy(face);mapping={}
   for i,x in enumerate(gui.iter('Item')):
    mapping[x.get('referent')]=f'{ref}Face{i}';x.set('referent',f'{ref}Face{i}')
   for x in gui.iter('Ref'):
    if x.text in mapping:x.text=mapping[x.text]
   props=gui.find('Properties');old=props.find("Ref[@name='Adornee']")
   if old is not None:props.remove(old)
   val(props,'Ref','Adornee',ref+'Body');part.append(gui)
 meta,mp=item(model,'Configuration','Integration',ref+'Meta')
 for kind,key,value in [('StringValue','SkinId',name),('IntValue','TargetLevel',s['targetLevel']),('NumberValue','BaseDiameter',1.7),('BoolValue','ApprovalOnly','true')]:
  _,p=item(meta,kind,key,ref+key);val(p,{'StringValue':'string','IntValue':'int64','NumberValue':'double','BoolValue':'bool'}[kind],'Value',value)
E.indent(root);E.ElementTree(root).write(OUT/'Verity_Elemental_Models.rbxmx',encoding='utf-8',xml_declaration=True)
p=R/'default.project.json';j=json.loads(p.read_text());j['tree']['ReplicatedStorage']['VerityElementalModels']={'$path':'assets/verity-elemental/Verity_Elemental_Models.rbxmx'};p.write_text(json.dumps(j,indent=2)+'\n')
print('Native model library with6models and real mesh/texture/face IDs; default Rojo project includes library.')
