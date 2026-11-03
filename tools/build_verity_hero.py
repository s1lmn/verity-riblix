"""Vector-authored UV faces, one lightweight sphere. No gameplay."""
from pathlib import Path
import math,json
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/verity-hero';(OUT/'textures').mkdir(parents=True,exist_ok=True)
W,H=2048,1024;S=2;BG='#FFDA21';INK='#211421';PINK='#FF5C78'
EMOTIONS=['Joy','Love','Playful','Wink','Laugh','Surprise','Confident','Stars']
class Art:
 def __init__(self):self.im=Image.new('RGB',(W*S,H*S),BG);self.d=ImageDraw.Draw(self.im)
 def poly(self,pts,fill):self.d.polygon([(round(x*S),round(y*S)) for x,y in pts],fill=fill)
 def ellipse(self,x,y,rx,ry,fill=INK):self.d.ellipse(((x-rx)*S,(y-ry)*S,(x+rx)*S,(y+ry)*S),fill=fill)
 def path(self,start,segments,fill):
  pts=[start];a=start
  for b,c,d in segments:
   for k in range(1,41):
    t=k/40;q=1-t;pts.append((q**3*a[0]+3*q*q*t*b[0]+3*q*t*t*c[0]+t**3*d[0],q**3*a[1]+3*q*q*t*b[1]+3*q*t*t*c[1]+t**3*d[1]))
   a=d
  self.poly(pts,fill)
 def stroke(self,pts,width,fill=INK):
  p=[(x*S,y*S) for x,y in pts];self.d.line(p,fill=fill,width=round(width*S),joint='curve')
  for x,y in [pts[0],pts[-1]]:self.ellipse(x,y,width/2,width/2,fill)
 def arch(self,x,y):self.stroke([(x+u,y-24*(1-(u/38)**2)) for u in range(-38,39,2)],15)
 def heart(self,x,y):
  self.path((x,y+40),[((x-110,y-18),(x-24,y-90),(x,y-35)),((x+24,y-90),(x+110,y-18),(x,y+40))],'#FF3472')
 def star(self,x,y):self.poly([(x+(47 if i%2==0 else 22)*math.sin(i*math.pi/5),y-(47 if i%2==0 else 22)*math.cos(i*math.pi/5)) for i in range(10)],INK)
 def mouth(self):
  self.path((860,535),[((945,564),(1103,564),(1188,535)),((1170,718),(878,718),(860,535))],INK)
  # tongue intentionally inside the mouth bowl, not floating or occluded
  self.path((943,648),[((965,615),(1087,615),(1109,648)),((1060,682),(985,682),(943,648))],PINK)
for emotion in EMOTIONS:
 a=Art()
 for x in [920,1128]:
  if emotion=='Love':a.heart(x,424)
  elif emotion=='Stars':a.star(x,424)
  elif emotion=='Laugh' or (emotion in ['Wink','Playful'] and x>1024):a.arch(x,430)
  else:a.ellipse(x,423,27,48)
 if emotion=='Surprise':a.ellipse(1024,596,52,65)
 else:a.mouth()
 if emotion=='Playful':
  a.path((1030,625),[((1055,628),(1086,628),(1106,617)),((1113,738),(1020,738),(1030,625))],PINK)
  a.stroke([(1069,643),(1069,680)],5,'#C32D55')
 if emotion=='Confident':
  a.stroke([(873,348),(955,371)],15);a.stroke([(1093,371),(1175,348)],15)
 if emotion=='Love':
  a.ellipse(835,505,28,15,'#FFA16D');a.ellipse(1213,505,28,15,'#FFA16D')
 a.im.resize((W,H),Image.Resampling.LANCZOS).save(OUT/'textures'/f'{emotion}.png')
# UV sphere: y up, forward -z, seam on back. 2208 triangles, shared single mesh.
verts=[];uvs=[];faces=[];SEG=48;RINGS=24
for j in range(RINGS+1):
 phi=math.pi*j/RINGS
 for i in range(SEG+1):
  u=i/SEG;theta=(u-.5)*2*math.pi
  verts.append((1.4*math.sin(phi)*math.sin(theta),1.4*math.cos(phi),-1.4*math.sin(phi)*math.cos(theta)));uvs.append((u,1-j/RINGS))
for j in range(RINGS):
 for i in range(SEG):
  a=j*(SEG+1)+i;b=a+1;c=a+SEG+2;d=a+SEG+1
  if j>0:faces.append((a,b,c))
  if j<RINGS-1:faces.append((a,c,d))
lines=['mtllib VerityHero.mtl','o VerityHero']
for p in verts:lines.append('v '+' '.join(f'{x:.7f}' for x in p))
for p in uvs:lines.append('vt '+' '.join(f'{x:.7f}' for x in p))
lines+=['usemtl VerityJoy','s 1']
for f in faces:lines.append('f '+' '.join(f'{x+1}/{x+1}' for x in f))
(OUT/'VerityHero.obj').write_text('\n'.join(lines)+'\n')
(OUT/'VerityHero.mtl').write_text('newmtl VerityJoy\nKd 1 1 1\nKa 0 0 0\nKs 0 0 0\nd 1\nmap_Kd textures/Joy.png\n')
(OUT/'manifest.json').write_text(json.dumps({'triangles':len(faces),'verticesWithUVSeam':len(verts),'diameterStuds':2.8,'forward':'-Z','emotions':EMOTIONS,'textureSize':[W,H],'parts':1},indent=2))
print('Created one UV sphere and eight vector-authored expression textures:',len(faces),'triangles')
