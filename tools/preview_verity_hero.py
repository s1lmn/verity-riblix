"""Render actual OBJ triangles with their exported UVs; no generated concept imagery."""
from pathlib import Path
import numpy as np,math,json,base64,struct
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/verity-hero'
verts=[];uv=[];faces=[]
for line in (OUT/'VerityHero.obj').read_text().splitlines():
 s=line.split()
 if not s:continue
 if s[0]=='v':verts.append(list(map(float,s[1:])))
 if s[0]=='vt':uv.append(list(map(float,s[1:])))
 if s[0]=='f':faces.append([int(v.split('/')[0])-1 for v in s[1:]])
v=np.array(verts);uv=np.array(uv);f=np.array(faces);norm=v/1.4
# GLB export of the actual shared mesh with a default embedded Joy texture.
blob=bytearray();views=[];accessors=[]
def put(data,target=None):
 while len(blob)%4:blob.append(0)
 off=len(blob);blob.extend(data);d={'buffer':0,'byteOffset':off,'byteLength':len(data)}
 if target:d['target']=target
 views.append(d);return len(views)-1
def acc(arr,typ,component,target):
 a=np.asarray(arr,dtype=np.float32 if component==5126 else np.uint16);vi=put(a.tobytes(),target)
 d={'bufferView':vi,'componentType':component,'count':len(a),'type':typ}
 if typ=='VEC3':d.update(min=a.min(axis=0).tolist(),max=a.max(axis=0).tolist())
 accessors.append(d);return len(accessors)-1
pa=acc(v,'VEC3',5126,34962);na=acc(norm,'VEC3',5126,34962)
# glTF v axis points down; OBJ uses up.
guv=uv.copy();guv[:,1]=1-guv[:,1];ua=acc(guv,'VEC2',5126,34962);ia=acc(f.reshape(-1),'SCALAR',5123,34963)
imageview=put((OUT/'textures/Joy.png').read_bytes())
gltf={'asset':{'version':'2.0','generator':'Verity vector-face UV prototype'},'scene':0,'scenes':[{'nodes':[0]}],'nodes':[{'mesh':0,'name':'VerityHero'}],'meshes':[{'primitives':[{'attributes':{'POSITION':pa,'NORMAL':na,'TEXCOORD_0':ua},'indices':ia,'material':0}]}],'materials':[{'name':'VerityJoy','pbrMetallicRoughness':{'baseColorTexture':{'index':0},'metallicFactor':0,'roughnessFactor':.5}}],'textures':[{'source':0}],'images':[{'bufferView':imageview,'mimeType':'image/png'}],'buffers':[{'byteLength':len(blob)}],'bufferViews':views,'accessors':accessors}
j=json.dumps(gltf,separators=(',',':')).encode();j+=b' '*((-len(j))%4);blob+=b'\0'*((-len(blob))%4)
(OUT/'VerityHero.glb').write_bytes(struct.pack('<III',0x46546c67,2,12+8+len(j)+8+len(blob))+struct.pack('<II',len(j),0x4e4f534a)+j+struct.pack('<II',len(blob),0x004e4942)+blob)
def render(emotion,N=600,yaw=0):
 tex=np.asarray(Image.open(OUT/'textures'/f'{emotion}.png').convert('RGB'),dtype=float)/255
 rot=np.array([[math.cos(yaw),0,math.sin(yaw)],[0,1,0],[-math.sin(yaw),0,math.cos(yaw)]])
 p=v@rot.T;n=norm@rot.T;screen=np.stack([N/2+p[:,0]*N/3.35,N/2-p[:,1]*N/3.35],axis=-1)
 bg=np.zeros((N,N,3))+[.055,.065,.105];depth=np.full((N,N),np.inf)
 light=np.array([-.4,.65,-.68]);light/=np.linalg.norm(light)
 for tri in f:
  ps=screen[tri];mn=np.maximum(0,np.floor(ps.min(axis=0)).astype(int));mx=np.minimum(N-1,np.ceil(ps.max(axis=0)).astype(int))
  if np.any(mx<mn):continue
  xx,yy=np.meshgrid(np.arange(mn[0],mx[0]+1)+.5,np.arange(mn[1],mx[1]+1)+.5)
  a,b,c=ps;den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
  if abs(den)<1e-9:continue
  w0=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den;w1=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den;w2=1-w0-w1
  weights=np.stack([w0,w1,w2],axis=-1);z=weights@p[tri,2]
  dest=depth[mn[1]:mx[1]+1,mn[0]:mx[0]+1];mask=(weights.min(axis=-1)>=-1e-6)&(z<dest)
  if not mask.any():continue
  tuv=weights@uv[tri];tx=np.clip((tuv[:,:,0]*(tex.shape[1]-1)).astype(int),0,tex.shape[1]-1);ty=np.clip(((1-tuv[:,:,1])*(tex.shape[0]-1)).astype(int),0,tex.shape[0]-1)
  nn=weights@n[tri];nn/=np.maximum(1e-9,np.linalg.norm(nn,axis=-1,keepdims=True))
  shade=.66+.34*np.maximum(0,nn@light);half=light+np.array([0,0,-1]);half/=np.linalg.norm(half)
  spec=.12*np.maximum(0,nn@half)**32
  color=tex[ty,tx]*shade[:,:,None]+spec[:,:,None]
  view=bg[mn[1]:mx[1]+1,mn[0]:mx[0]+1];view[mask]=color[mask];dest[mask]=z[mask]
 return Image.fromarray(np.uint8(np.clip(bg*255,0,255)))
render('Joy',800).save(OUT/'actual-mesh-front.png');render('Joy',800,.38).save(OUT/'actual-mesh-angle.png')
emotions=['Joy','Love','Playful','Wink','Laugh','Surprise','Confident','Stars'];sheet=Image.new('RGB',(1200,650),(14,17,27));d=ImageDraw.Draw(sheet)
for i,e in enumerate(emotions):
 x=i%4*300;y=i//4*325;sheet.paste(render(e,300),(x,y));d.text((x+110,y+300),e,fill='white')
sheet.save(OUT/'actual-mesh-emotions.png')
print('Rendered actual OBJ triangles, exported GLB:',len(f),'triangles')
