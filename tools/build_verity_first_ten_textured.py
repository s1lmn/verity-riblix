"""Shared transparent faces and one import batch; same approved vector artwork."""
from pathlib import Path
from PIL import Image,ImageDraw
import ast,math,json,struct,copy
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/verity-ten-textured';(OUT/'faces').mkdir(parents=True,exist_ok=True)
# Reuse the vector authoring recipe, without running the original asset exporter.
source=(ROOT/'tools/build_verity_hero.py').read_text();recipe=source[source.index('class Art:'):source.index('# UV sphere:')]
recipe=recipe.replace("Image.new('RGB',(W*S,H*S),BG)","Image.new('RGBA',(W*S,H*S),(0,0,0,0))")
ns=dict(Image=Image,ImageDraw=ImageDraw,math=math,W=2048,H=1024,S=2,BG='#FFDA21',INK='#211421',PINK='#FF5C78',OUT=OUT,EMOTIONS=['Joy','Love','Playful','Wink','Laugh','Surprise','Confident','Stars'])
recipe=recipe.replace("OUT/'textures'","OUT/'faces'");exec(compile(recipe,'<shared-vector-faces>','exec'),ns)
base=(ROOT/'assets/verity-hero/VerityHero.glb').read_bytes();size=struct.unpack_from('<I',base,12)[0];j=json.loads(base[20:20+size]);oldbin=base[28+size:];cut=j['bufferViews'][j['images'][0]['bufferView']]['byteOffset'];blob=bytearray(oldbin[:cut]);j['bufferViews']=j['bufferViews'][:-1];j['images']=[];j['textures']=[];j['materials']=[];j['meshes']=[];j['nodes']=[]
original=json.loads(base[20:20+size])['meshes'][0]
for i,e in enumerate(ns['EMOTIONS']):
 while len(blob)%4:blob.append(0)
 png=(OUT/'faces'/f'{e}.png').read_bytes();vi=len(j['bufferViews']);j['bufferViews'].append({'buffer':0,'byteOffset':len(blob),'byteLength':len(png)});blob.extend(png)
 j['images'].append({'bufferView':vi,'mimeType':'image/png'});j['textures'].append({'source':i})
 j['materials'].append({'name':'Face_'+e,'alphaMode':'BLEND','pbrMetallicRoughness':{'baseColorTexture':{'index':i},'metallicFactor':0,'roughnessFactor':.6}})
 mesh=copy.deepcopy(original);mesh['primitives'][0]['material']=i;j['meshes'].append(mesh);j['nodes'].append({'name':'VerityFace_'+e,'mesh':i,'translation':[(i%4)*3.5,(i//4)*3.5,0]})
j['scenes']=[{'nodes':list(range(8))}];j['buffers'][0]['byteLength']=len(blob)
text=json.dumps(j,separators=(',',':')).encode();text+=b' '*((-len(text))%4);blob+=b'\0'*((-len(blob))%4)
(OUT/'Verity_Shared_Faces_Import.glb').write_bytes(struct.pack('<III',0x46546c67,2,28+len(text)+len(blob))+struct.pack('<II',len(text),0x4e4f534a)+text+struct.pack('<II',len(blob),0x004e4942)+blob)
print('Built 8 shared transparent faces and one GLB import. No mesh generation or playtest.')

# Static Studio models use the same palette and scale as the runtime module.
from xml.etree import ElementTree as ET
palette_source=(ROOT/'src/shared/VerityCompanionLevels.luau').read_text()
import re
palettes=re.findall(r'Name="([^"]+)",Hex="([A-F0-9]+)"',palette_source)
asset_file=OUT/'roblox-assets.json'
if asset_file.exists():
 assets=json.loads(asset_file.read_text())
 def item(parent,kind,name,ref):
  node=ET.SubElement(parent,'Item',{'class':kind,'referent':ref})
  props=ET.SubElement(node,'Properties');ET.SubElement(props,'string',name='Name').text=name
  return node,props
 def val(props,kind,name,value):ET.SubElement(props,kind,name=name).text=str(value)
 def vector(props,name,xyz):
  node=ET.SubElement(props,'Vector3',name=name)
  for axis,value in zip('XYZ',xyz):ET.SubElement(node,axis).text=str(value)
 def frame(props,xyz):
  node=ET.SubElement(props,'CoordinateFrame',name='CFrame')
  for key,value in zip(['X','Y','Z','R00','R01','R02','R10','R11','R12','R20','R21','R22'],[*xyz,1,0,0,0,1,0,0,0,1]):ET.SubElement(node,key).text=str(value)
 def content(props,name,value):ET.SubElement(ET.SubElement(props,'Content',name=name),'url').text=value
 def model(parent,level,name,hexcode,xyz):
  # Mirrors LevelConfig.getVerityScale; assert the formula before exporting.
  config=(ROOT/'src/shared/LevelConfig.luau').read_text()
  assert re.search(r'return\s+1\s*\+\s*14\s*\*\s*\(\(level\s*-\s*1\)\s*/\s*99\)\s*\^\s*0\.85',config), 'Update export scale to match shared LevelConfig'
  scale=1+14*((level-1)/99)**.85;diameter=2.8*scale
  node,props=item(parent,'Model',f'Verity_{level:02}_{name}',f'Model{level}')
  val(props,'Ref','PrimaryPart',f'Body{level}')
  for partname,color in [('Body',hexcode),('Face','FFFFFF')]:
   part,p=item(node,'Part',partname,f'{partname}{level}')
   for flag,value in [('Anchored',True),('CanCollide',False),('CanTouch',False),('CanQuery',False),('CastShadow',False)]:val(p,'bool',flag,str(value).lower())
   val(p,'token','shape',0);val(p,'token','Material',272)
   val(p,'Color3uint8','Color3uint8',0xff000000|int(color,16))
   vector(p,'size',[diameter]*3);frame(p,xyz)
   if partname=='Face':
    mesh,mp=item(part,'SpecialMesh','SharedFace',f'Mesh{level}')
    val(mp,'token','MeshType',5);content(mp,'MeshId',assets['mesh']);content(mp,'TextureId',assets['textures']['Joy'])
    vector(mp,'Scale',[scale*1.004]*3)
  meta,mp=item(node,'Configuration','Integration',f'Metadata{level}')
  for kind,key,value in [('IntValue','Level',level),('NumberValue','AppliedScale',scale),('BoolValue','AlreadyScaled','true')]:
   _,p=item(meta,kind,key,f'{key}{level}');val(p,'bool' if kind=='BoolValue' else 'int64' if kind=='IntValue' else 'double','Value',value)
  for emotion,url in assets['textures'].items():
   _,p=item(meta,'StringValue',emotion,f'{emotion}{level}');val(p,'string','Value',url)
  return scale
 def document():return ET.Element('roblox',{'version':'4'})
 (OUT/'models').mkdir(exist_ok=True)
 pack=document();folder,_=item(pack,'Folder','Verity_FirstTen_Textured','FirstTen');records=[]
 for level,(name,hexcode) in enumerate(palettes,1):
  single=document();scale=model(single,level,name,hexcode,[0,0,0])
  ET.ElementTree(single).write(OUT/'models'/f'Verity_{level:02}_{name}.rbxmx',encoding='utf-8',xml_declaration=True)
  model(folder,level,name,hexcode,[(level-1)%5*18,4,(level-1)//5*18])
  records.append(dict(level=level,name=name,color='#'+hexcode,scale=scale,diameter=2.8*scale))
 ET.ElementTree(pack).write(OUT/'Verity_FirstTen_Textured.rbxmx',encoding='utf-8',xml_declaration=True)
 (OUT/'levels.json').write_text(json.dumps(records,indent=2)+'\n')
 print('Exported ten static models and a combined Studio pack with real cloud IDs.')
