"""Software rasterize actual exported GLB triangles/UV/PNG materials. Not Studio."""
from pathlib import Path
import struct,json,io,math
import numpy as np
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/verity-elemental'
def read_glb(path):
 raw=path.read_bytes();n=struct.unpack_from('<I',raw,12)[0];j=json.loads(raw[20:20+n]);blob=raw[28+n:]
 def view(i):
  v=j['bufferViews'][i];return blob[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
 def acc(i):
  a=j['accessors'][i];dt={5126:'<f4',5123:'<u2'}[a['componentType']];k={'VEC3':3,'VEC2':2,'SCALAR':1}[a['type']]
  return np.frombuffer(view(a['bufferView']),dtype=dt,count=a['count']*k,offset=a.get('byteOffset',0)).reshape(-1,k)
 return j,view,acc

def raster(path,res=440):
 j,view,acc=read_glb(path);im=np.zeros((res,res,4));depth=np.full((res,res),np.inf)
 light=np.array([-.45,.7,-1.3]);light/=np.linalg.norm(light)
 half=light+np.array([0,0,-1]);half/=np.linalg.norm(half)
 # Draw opaque first, transparent expression last.
 for mesh in sorted(j['meshes'],key=lambda m:'Face' in m['name']):
  for prim in mesh['primitives']:
   a=prim['attributes'];pos=acc(a['POSITION']);normal=acc(a['NORMAL']);uv=acc(a['TEXCOORD_0']);tri=acc(prim['indices']).reshape(-1,3)
   mat=j['materials'][prim['material']];ti=mat['pbrMetallicRoughness']['baseColorTexture']['index'];ii=j['textures'][ti]['source']
   tex=np.asarray(Image.open(io.BytesIO(view(j['images'][ii]['bufferView']))).convert('RGBA'),dtype=float)/255
   xy=np.column_stack([(pos[:,0]+1.03)/(2.06)*(res-1),(1.88-pos[:,1])/(2.06)*(res-1)])
   for ids in tri:
    q=xy[ids];lo=np.maximum(np.floor(q.min(axis=0)).astype(int),0);hi=np.minimum(np.ceil(q.max(axis=0)).astype(int),res-1)
    if (hi<lo).any():continue
    xx,yy=np.meshgrid(np.arange(lo[0],hi[0]+1)+.5,np.arange(lo[1],hi[1]+1)+.5)
    d=(q[1,1]-q[2,1])*(q[0,0]-q[2,0])+(q[2,0]-q[1,0])*(q[0,1]-q[2,1])
    if abs(d)<1e-9:continue
    b0=((q[1,1]-q[2,1])*(xx-q[2,0])+(q[2,0]-q[1,0])*(yy-q[2,1]))/d
    b1=((q[2,1]-q[0,1])*(xx-q[2,0])+(q[0,0]-q[2,0])*(yy-q[2,1]))/d;b2=1-b0-b1
    bary=np.stack([b0,b1,b2],axis=-1)
    z=bary@pos[ids,2];ys=slice(lo[1],hi[1]+1);xs=slice(lo[0],hi[0]+1)
    inside=(bary.min(axis=-1)>=-1e-5)&(z<depth[ys,xs])
    if not inside.any():continue
    st=bary@uv[ids];tx=np.clip(st[...,0]*(tex.shape[1]-1),0,tex.shape[1]-1);ty=np.clip(st[...,1]*(tex.shape[0]-1),0,tex.shape[0]-1)
    x0=tx.astype(int);y0=ty.astype(int);x1=np.minimum(x0+1,tex.shape[1]-1);y1=np.minimum(y0+1,tex.shape[0]-1)
    fx=(tx-x0)[...,None];fy=(ty-y0)[...,None]
    rgba=(tex[y0,x0]*(1-fx)+tex[y0,x1]*fx)*(1-fy)+(tex[y1,x0]*(1-fx)+tex[y1,x1]*fx)*fy
    n=bary@normal[ids];n/=np.maximum(1e-8,np.linalg.norm(n,axis=-1))[...,None]
    shade=.45+.55*np.maximum(0,n@light);spec=.15*np.maximum(0,n@half)**50
    rgba[...,:3]=np.clip((rgba[...,:3]**2.2*shade[...,None]+spec[...,None])**(1/2.2),0,1)
    inside&=rgba[...,3]>.02
    target=im[ys,xs];alpha=rgba[...,3:4]
    target[...,:3]=np.where(inside[...,None],rgba[...,:3]*alpha+target[...,:3]*(1-alpha),target[...,:3])
    target[...,3]=np.where(inside,rgba[...,3]+target[...,3]*(1-rgba[...,3]),target[...,3]);depth[ys,xs]=np.where(inside,z,depth[ys,xs])
 return Image.fromarray((np.clip(im,0,1)*255).astype('uint8'))

def main():
 specs=json.loads((OUT/'manifest.json').read_text())['models']
 canvas=Image.new('RGB',(1440,1080),'#E9D9FC');draw=ImageDraw.Draw(canvas)
 fontpath='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
 heading=ImageFont.truetype(fontpath,43);font=ImageFont.truetype(fontpath,25);small=ImageFont.truetype(fontpath,16)
 draw.text((720,22),'VERITY / ELEMENTAL MODELS',anchor='mt',font=heading,fill='#542D8B')
 for i,s in enumerate(specs):
  x=(i%3)*480;y=90+(i//3)*470
  draw.rounded_rectangle((x+10,y,x+470,y+457),radius=28,fill='#FFF7FC')
  sprite=raster(OUT/s['file']);canvas.paste(sprite,(x+20,y-3),sprite)
  title=f"{s['skin'].upper()} / LV {s['targetLevel']}"+(' ALT' if s['alternate'] else '')
  draw.text((x+240,y+419),title,anchor='mt',font=font,fill='#542D8B')
 draw.text((720,1051),'Actual GLB mesh + UV textures / offline software render / not a Studio screenshot',anchor='mt',font=small,fill='#6D6082')
 canvas.save(OUT/'preview-render.png')
 print('Rasterized actual exported GLB triangles, UVs and embedded PNGs to preview-render.png')
if __name__=='__main__':main()
