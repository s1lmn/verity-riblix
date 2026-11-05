"""Author repeatable spherical skin textures and shared low-poly GLB approval models.
No gameplay files or previously uploaded art are overwritten.
"""
from pathlib import Path
import json, math, struct, io, shutil, zipfile
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/verity-elemental'
W,H=1024,512
SPECS=[('Aqua',10),('Frost',25),('Magma',50),('Cyber',75),('Cosmic',75),('Rainbow',100)]
u,v=np.meshgrid(np.linspace(0,1,W),np.linspace(0,1,H))
t=(u-.5)*2*np.pi;p=v*np.pi
X=np.sin(p)*np.sin(t);Y=np.cos(p);Z=-np.sin(p)*np.cos(t)
P=np.stack([X,Y,Z],axis=-1)
def rgb(h):return np.array([int(h[k:k+2],16) for k in (0,2,4)],dtype=float)
def mix(a,b,t):return np.asarray(a)*(1-np.asarray(t)[...,None])+np.asarray(b)*np.asarray(t)[...,None]
def blend(c,color,mask):return mix(c,rgb(color),np.clip(mask,0,1))
def smooth(a,b,n):
 t=np.clip((n-a)/(b-a),0,1);return t*t*(3-2*t)
def base(a,b):return mix(rgb(a),rgb(b),np.broadcast_to((Y+1)/2,(H,W)))
def sphere_stamp(c,center,radius,kind,color,angle=0):
 n=np.array(center,dtype=float);n/=np.linalg.norm(n)
 right=np.cross([0,1,0],n);right/=np.linalg.norm(right);right=-right
 up=np.cross(n,right)
 # Preserve visually upright icons on the outward sphere tangent.
 if up[1]<0:up=-up
 sx=P@right/radius;sy=P@up/radius
 xx=sx*np.cos(angle)-sy*np.sin(angle);yy=sx*np.sin(angle)+sy*np.cos(angle)
 mask=Image.new('L',(512,512),0);d=ImageDraw.Draw(mask)
 if kind=='star':
  pts=[(256+235*(1 if i%2==0 else .45)*math.sin(i*math.pi/5),256-235*(1 if i%2==0 else .45)*math.cos(i*math.pi/5)) for i in range(10)]
  d.polygon(pts,fill=255)
 elif kind=='snow':
  for a in np.arange(6)*math.pi/3:
   def pt(dx,dy):return (256+dx*math.cos(a)-dy*math.sin(a),256+dx*math.sin(a)+dy*math.cos(a))
   d.line([pt(0,0),pt(0,-215)],fill=255,width=23)
   for q in (100,155):
    for side in (-1,1):d.line([pt(0,-q),pt(side*45,-q-45)],fill=255,width=20)
 elif kind=='bubble':d.ellipse((36,36,476,476),fill=255)
 ix=np.clip(((xx+1)*255.5).astype(int),0,511);iy=np.clip(((1-yy)*255.5).astype(int),0,511)
 m=np.asarray(mask)[iy,ix]/255*((np.abs(xx)<1)&(np.abs(yy)<1)&((P@n)>.2))
 return blend(c,color,m)
def make_skin(name):
 if name=='Aqua':
  c=base('005DF5','17F4E8')
  # Broad water/foam sweep, repeating continuously around the back.
  boundary=-.48+.18*np.sin(2*t+.5)+.07*np.sin(3*t-.4)
  c=blend(c,'0865F2',1-smooth(boundary-.02,boundary+.02,Y))
  c=blend(c,'E5FFFC',(1-smooth(.025,.08,np.abs(Y-boundary))))
  c=blend(c,'27A7FF',1-smooth(boundary-.16,boundary-.12,Y))
  for center,r in [((-.74,.03,-.8),.12),((.68,.65,-.8),.13),((.82,.27,-.8),.07),((-.5,.65,.8),.13)]:
   c=sphere_stamp(c,center,r,'bubble','9BFDF7')
   n=np.asarray(center);n=n/np.linalg.norm(n);c=blend(c,'F4FFFF',1-smooth(.004,.009,1-P@n))
 elif name=='Magma':
  c=base('FF7900','FFCD10')
  centers=[(-.82,.58,-.65),(.85,.05,-.64),(-.60,-.68,-.5),(.57,-.71,-.6),(.2,.8,.65),(-.8,.0,.6),(.55,-.55,.8)]
  for i,n in enumerate(centers):
   n=np.asarray(n,dtype=float);n/=np.linalg.norm(n)
   dist=np.arccos(np.clip(P@n,-1,1))
   irregular=.04*np.sin(X*13+Y*9+i)+.025*np.cos(Y*17-Z*9)
   radius=.32+(i%3)*.025
   c=blend(c,'FFF044',1-smooth(radius+.045,radius+.10,dist+irregular))
   c=blend(c,'F04520',1-smooth(radius-.015,radius+.025,dist+irregular))
   c=blend(c,'A93440',1-smooth(radius-.08,radius-.03,dist+irregular))
 elif name=='Cyber':
  c=base('7430F3','B43EFF')
  border=.62+.12*np.abs(np.sin(t*1.5+.3))
  c=blend(c,'153266',smooth(border-.015,border+.015,np.abs(Y)))
  line=1-smooth(.014,.035,np.abs(np.abs(Y)-border))
  c=blend(c,'83FF32',line*(Y>0));c=blend(c,'23F3FF',line*(Y<0))
  # One large painted pixel insignia, leaving the middle face area quiet.
  ix=(X>.49)&(X<.78)&(Y>.16)&(Y<.57)
  iy=((X>.40)&(X<.67)&(Y>.31)&(Y<.44))
  c=blend(c,'FF47D7',(ix|iy).astype(float))
 elif name=='Frost':
  c=base('0472F8','72E3FF')
  edge=.68+.08*(4*np.abs(((t*3/(2*np.pi))%1)-.5)-1)
  c=blend(c,'808DF4',smooth(edge-.09,edge-.07,np.abs(Y)))
  c=blend(c,'C9ECFF',smooth(edge-.05,edge-.03,np.abs(Y)))
  c=blend(c,'F2FDFF',smooth(edge-.015,edge+.015,np.abs(Y)))
  for center,r in [((.85,.52,-.55),.21),((-.78,-.35,-.65),.22),((.1,.2,.98),.25)]:c=sphere_stamp(c,center,r,'snow','F5FFFF')
 elif name=='Cosmic':
  c=base('4620B6','6A32F5')
  for i,(n,col) in enumerate([((-.65,.58,-.7),'ED3EFF'),((.7,-.5,-.6),'1CDAFF'),((-.8,-.3,.5),'F151FF'),((.35,.2,.9),'246CFF')]):
   n=np.asarray(n);n/=np.linalg.norm(n);field=P@n+.07*np.sin(X*13+Z*8)*np.cos(Y*10)
   c=blend(c,col,smooth(.80,.92,field)*.95)
  for n in [( .57,.65,-.7),(-.70,-.18,-.7),(.54,-.65,-.7),(-.3,.6,.8)]:c=sphere_stamp(c,n,.21,'star','FFE955')
 else:
  c=base('FFF4B8','FFFCEC')
  for i,(n,col) in enumerate([((-.62,-.15,-.8),'FF51C0'),((.38,.76,-.6),'1BE5F2'),((.82,-.2,-.5),'FFDC25'),((.05,-.85,-.5),'B156FF'),((-.3,.4,.8),'29D9FF'),((.4,-.6,.7),'FF80C8')]):
   n=np.asarray(n);n/=np.linalg.norm(n)
   field=P@n+.07*np.sin(X*17+Y*14)*np.cos(Y*11+Z*9)
   c=blend(c,col,smooth(.77,.86,field))
  for n in [(.61,.62,-.7),(-.7,.0,-.7),(.50,-.64,-.7),(-.4,.3,.9)]:c=sphere_stamp(c,n,.22,'star','FFD52B')
 # Explicitly close the UV seam; no baked lighting or facial art in the skin.
 c=np.clip(c,0,255).astype('uint8');c[:,-1]=c[:,0];c[0]=np.mean(c[0],axis=0).astype('uint8');c[-1]=np.mean(c[-1],axis=0).astype('uint8')
 Image.fromarray(c).save(OUT/'skins'/f'{name}.png')

def sphere():
 verts=[];normals=[];uvs=[];tris=[]
 for j in range(25):
  phi=np.pi*j/24
  for i in range(49):
   theta=(i/48-.5)*2*np.pi;n=(math.sin(phi)*math.sin(theta),math.cos(phi),-math.sin(phi)*math.cos(theta))
   verts.append((n[0]*.85,n[1]*.85+.85,n[2]*.85));normals.append(n);uvs.append((i/48,j/24))
 for j in range(24):
  for i in range(48):
   a=j*49+i;b=a+1;c=a+50;d=a+49
   if j>0:tris.extend((a,b,c))
   if j<23:tris.extend((a,c,d))
 return verts,normals,uvs,tris

def glb(path,specs,include_faces):
 blob=bytearray();views=[];access=[]
 def data(raw,target=None):
  blob.extend(b'\0'*(-len(blob)%4));idx=len(views);view={'buffer':0,'byteOffset':len(blob),'byteLength':len(raw)}
  if target:view['target']=target
  views.append(view);blob.extend(raw);return idx
 def acc(values,dtype,kind,target):
  ar=np.asarray(values,dtype=dtype);component=5126 if dtype=='<f4' else 5123
  obj={'bufferView':data(ar.tobytes(),target),'componentType':component,'count':len(ar),'type':kind}
  if kind=='VEC3':obj.update(min=ar.min(axis=0).tolist(),max=ar.max(axis=0).tolist())
  access.append(obj);return len(access)-1
 verts,normals,uvs,tris=sphere()
 pos=acc(verts,'<f4','VEC3',34962);normal=acc(normals,'<f4','VEC3',34962);uv=acc(uvs,'<f4','VEC2',34962);ix=acc(tris,'<u2','SCALAR',34963)
 images=[];textures=[];mats=[];meshes=[];nodes=[]
 def material(name,image,alpha=False):
  images.append({'bufferView':data(image.read_bytes()),'mimeType':'image/png'});textures.append({'source':len(images)-1,'sampler':0})
  mat={'name':name,'pbrMetallicRoughness':{'baseColorTexture':{'index':len(textures)-1},'metallicFactor':0,'roughnessFactor':.65},'doubleSided':False}
  if alpha:mat.update(alphaMode='BLEND',doubleSided=True)
  mats.append(mat);return len(mats)-1
 face_mat=material('Face_Joy_Replaceable',ROOT/'assets/verity-ten-textured/faces/Joy.png',True) if include_faces else None
 if include_faces:
  # Flat layer previews the same front SurfaceGui artwork without baking it into body.
  fp=[(-.527,.374,-.866),(.527,.374,-.866),(.527,1.462,-.866),(-.527,1.462,-.866)]
  fa=acc(fp,'<f4','VEC3',34962);fn=acc([(0,0,-1)]*4,'<f4','VEC3',34962)
  ft=acc([(.375,.78125),(.625,.78125),(.625,.28125),(.375,.28125)],'<f4','VEC2',34962)
  fi=acc([0,2,1,0,3,2],'<u2','SCALAR',34963)
  meshes.append({'name':'FacePreview','primitives':[{'attributes':{'POSITION':fa,'NORMAL':fn,'TEXCOORD_0':ft},'indices':fi,'material':face_mat}]})
 for i,(name,level) in enumerate(specs):
  mat=material('Skin_'+name,OUT/'skins'/f'{name}.png')
  meshes.append({'name':name+'_Body','primitives':[{'attributes':{'POSITION':pos,'NORMAL':normal,'TEXCOORD_0':uv},'indices':ix,'material':mat}]})
  body_index=len(nodes);nodes.append({'name':'Body','mesh':len(meshes)-1})
  children=[body_index]
  if include_faces:children.append(len(nodes));nodes.append({'name':'FacePreview','mesh':0})
  nodes.append({'name':f'Verity_L{level:03}_{name}','children':children,'translation':[(i%3-1)*2.6,(1-i//3)*2.8,0] if len(specs)>1 else [0,0,0],
   'extras':{'SkinId':name,'PreviewTargetLevel':level,'BaseDiameter':1.7,'EmotionCount':8,'ApprovalOnly':True}})
 roots=[i for i,n in enumerate(nodes) if 'children' in n]
 doc={'asset':{'version':'2.0','generator':'Verity local procedural skin authoring'},'scene':0,'scenes':[{'nodes':roots}],
  'nodes':nodes,'meshes':meshes,'materials':mats,'images':images,'textures':textures,'samplers':[{'magFilter':9729,'minFilter':9987,'wrapS':10497,'wrapT':33071}],
  'bufferViews':views,'accessors':access,'buffers':[{'byteLength':len(blob)}]}
 text=json.dumps(doc,separators=(',',':')).encode();text+=b' '*(-len(text)%4);blob+=b'\0'*(-len(blob)%4)
 path.write_bytes(struct.pack('<III',0x46546C67,2,28+len(text)+len(blob))+struct.pack('<II',len(text),0x4e4f534a)+text+struct.pack('<II',len(blob),0x004e4942)+blob)

def main():
 for folder in ['skins','models','faces']: (OUT/folder).mkdir(parents=True,exist_ok=True)
 for name,level in SPECS:
  make_skin(name);glb(OUT/'models'/f'Verity_L{level:03}_{name}.glb',[(name,level)],True)
 for f in (ROOT/'assets/verity-ten-textured/faces').glob('*.png'):shutil.copy2(f,OUT/'faces'/f.name)
 glb(OUT/'Verity_Elemental_Gallery.glb',SPECS,True)
 glb(OUT/'Verity_Elemental_Bodies_Import.glb',SPECS,False)
 manifest={'status':'approval assets; not uploaded or wired into live renderer','baseDiameter':1.7,'pivot':[0,0,0],'bodyCenter':[0,.85,0],
  'forward':'-Z','scale':'unscaled; game uses Shared.LevelConfig only','trianglesPerBody':2208,'trianglesPerPreviewFace':2,
  'textureSize':[1024,512],'faceLayer':'independent existing normalized SurfaceGui in Roblox; GLB face plane for preview only',
  'emotions':['Joy','Love','Playful','Wink','Laugh','Surprise','Confident','Stars'],
  'models':[{'skin':name,'targetLevel':level,'file':f'models/Verity_L{level:03}_{name}.glb','alternate':name=='Cosmic'} for name,level in SPECS]}
 (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2))
 print('Created 6 approval models, shared 2208-triangle body geometry, six skin textures, eight existing independent faces, bodies-only import and GLB gallery.')
if __name__=='__main__':main()
