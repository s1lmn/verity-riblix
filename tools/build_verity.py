"""Author the first ten native Roblox smile-ball variants and a review gallery."""
from pathlib import Path
import math, json, colorsys, xml.etree.ElementTree as E
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/verity';(OUT/'models').mkdir(parents=True,exist_ok=True)
DEFS=[
 ('Sunny','FFE12B','Classic','Bob',.15,1.5),
 ('Curious','19E5FF','Curious','Sway',.12,1.3),
 ('Joy','FF39C5','Happy','Hop',.24,1.7),
 ('Wink','83F025','Wink','Tilt',.16,1.4),
 ('Spark','FF8A1E','Glow','Spin',.22,1.5),
 ('Dreamy','9454FF','Sleepy','Float',.24,1.0),
 ('Confident','2F89FF','Focused','Rock',.14,1.6),
 ('Playful','FF4A76','Happy','DoubleHop',.27,1.6),
 ('Wow','17E4B5','Wow','Float',.26,1.25),
 ('Golden','FFD137','Stars','Orbit',.32,1.1),
]
R=1.4;BLACK='10141A'
def scale(level):return 1+14*((level-1)/99)**.85 # Export parity checked against shared LevelConfig.
def model_parts(level):
    parts=[]
    def ball(name,pos,size,color,**extras):parts.append(dict(name=name,shape='Ball',pos=list(pos),size=list(size),color=color,**extras))
    def front_z(x,y):return -math.sqrt(max(.01,R*R-x*x-(y-R)**2))-.045
    def line(name,points,color=BLACK,width=.065,glow=False):
        for i,(a,b) in enumerate(zip(points,points[1:])):parts.append(dict(name=f'{name}_{i}',shape='Rod',a=list(a),b=list(b),width=width,color=color,glow=glow))
        for i,point in enumerate(points):ball(f'{name}Cap{i}',point,(width,width,width),color,glow=glow)
    def stroke(name,xy,color=BLACK,width=.065,glow=False):line(name,[(x,y,front_z(x,y)) for x,y in xy],color,width,glow)
    def eye(name,x,y=1.91,sx=.21,sy=.38,glow=False):ball(name,(x,y,front_z(x,y)-.012),(sx,sy,.13),'D6FFFF' if glow else BLACK,glow=glow,eye=True)
    def closed(name,x,y=1.9):stroke(name,[(x+u,y+.12*(1-(u/.17)**2)) for u in np.linspace(-.17,.17,7)],width=.065)
    def star(name,x):
        for j,angle in enumerate((0,math.pi/2,math.pi/4,-math.pi/4)):
            dx=.2*math.cos(angle);dy=.2*math.sin(angle)
            stroke(name+str(j),[(x-dx,1.91-dy),(x+dx,1.91+dy)],'CFFFFF',.075,True)
    body=DEFS[level-1][1];expression=DEFS[level-1][2]
    ball('Body',(0,R,0),(R*2,R*2,R*2),body,body=True)
    if expression=='Happy':closed('LeftHappy',-.44);closed('RightHappy',.44)
    elif expression=='Wink':eye('LeftEye',-.44);closed('RightWink',.44)
    elif expression=='Curious':eye('LeftEye',-.44,1.96,.24,.43);eye('RightEye',.44,1.86,.19,.33)
    elif expression=='Sleepy':
        for x,name in [(-.44,'LeftSleepy'),(.44,'RightSleepy')]:stroke(name,[(x-.16,1.9),(x+.16,1.86)],width=.075)
    elif expression=='Glow':eye('LeftGlow',-.44,sx=.23,sy=.43,glow=True);eye('RightGlow',.44,sx=.23,sy=.43,glow=True)
    elif expression=='Stars':star('LeftStar',-.44);star('RightStar',.44)
    else:
        eye('LeftEye',-.44);eye('RightEye',.44)
        if expression=='Focused':
            stroke('LeftBrow',[(-.65,2.2),(-.28,2.12)],width=.07)
            stroke('RightBrow',[(.28,2.12),(.65,2.2)],width=.07)
    if expression=='Wow':stroke('WowMouth',[(.2*math.cos(t),1.04+.23*math.sin(t)) for t in np.linspace(0,2*math.pi,17)],width=.07)
    else:
        stroke('Smile',[(x,1.2-.38*(1-(x/.85)**2)) for x in np.linspace(-.85,.85,17)],width=.075 if level in (5,10) else .065)
        for x in (-.85,.85):ball('Dimple'+str(x),(x,1.2,front_z(x,1.2)),(.1,.1,.1),BLACK)
    if level in (5,10):
        count=12 if level==5 else 16
        for i in range(count):
            t=2*math.pi*i/count
            ball('Aura'+str(i),(1.55*math.cos(t),.12,1.55*math.sin(t)),(.105,.105,.105),'62F7FF' if level==5 else 'FFE778',glow=True,optional=True)
    return parts
RECIPES=[model_parts(i) for i in range(1,11)]
def lua(v):
    if isinstance(v,str):return json.dumps(v)
    if isinstance(v,bool):return str(v).lower()
    if isinstance(v,(int,float,np.floating)):return str(float(v)) if isinstance(v,np.floating) else str(v)
    if isinstance(v,(list,tuple)):return '{'+','.join(lua(x) for x in v)+'}'
    return '{'+','.join(k+'='+lua(x) for k,x in v.items())+'}'
(ROOT/'src/world/VerityRecipe.luau').write_text('-- Generated native Parts; first 10 only.\nreturn '+lua(RECIPES)+'\n')
definitions=[dict(Name=d[0],Color=d[1],Expression=d[2],Motion=d[3],Bob=d[4],Speed=d[5],Special=i in (5,10)) for i,d in enumerate(DEFS,1)]
(OUT/'definitions.json').write_text(json.dumps(definitions,indent=2))
(ROOT/'src/world/VerityDefinitions.luau').write_text('-- First ten approved-for-review variants; no economy.\nreturn '+lua(definitions)+'\n')

def field(parent,tag,name,value):q=E.SubElement(parent,tag,name=name);q.text=str(value);return q
def item(parent,cls,name,ref):
    q=E.SubElement(parent,'Item',{'class':cls,'referent':ref});p=E.SubElement(q,'Properties');field(p,'string','Name',name);return q,p
def frame(parent,pos,matrix=None,name='CFrame'):
    q=E.SubElement(parent,'CoordinateFrame',name=name)
    for k,v in zip(('X','Y','Z'),pos):E.SubElement(q,k).text=str(v)
    m=np.eye(3) if matrix is None else matrix
    for a in range(3):
        for b in range(3):E.SubElement(q,f'R{a}{b}').text=str(m[a,b])
def doc():
    r=E.Element('roblox',version='4');E.SubElement(r,'External').text='null';E.SubElement(r,'External').text='nil';return r
def make_part(parent,n,ref,origin=(0,0,0),s=1):
    q,p=item(parent,'Part',n['name'],ref)
    if n['shape']=='Rod':
        a=np.array(n['a']);b=np.array(n['b']);x=(b-a)/np.linalg.norm(b-a)
        up=np.array([0.,1.,0.]) if abs(x[1])<.9 else np.array([0.,0.,1.]);z=np.cross(x,up);z/=np.linalg.norm(z);y=np.cross(z,x)
        rotation=np.column_stack((x,y,z));pos=(a+b)/2;size=(np.linalg.norm(b-a),n['width'],n['width']);shape=2
    else:pos=np.array(n['pos']);size=n['size'];shape=0;rotation=None
    field(p,'token','shape',shape);field(p,'token','Material',288 if n.get('glow') else 272)
    field(p,'float','Reflectance',.045 if n.get('body') else 0)
    for name,value in [('Anchored',True),('CanCollide',False),('CanTouch',False),('CanQuery',False),('CastShadow',bool(n.get('body')))]:field(p,'bool',name,str(value).lower())
    field(p,'Color3uint8','Color3uint8',0xFF000000|int(n['color'],16))
    v=E.SubElement(p,'Vector3',name='size')
    for k,val in zip(('X','Y','Z'),size):E.SubElement(v,k).text=str(val*s)
    frame(p,np.array(origin)+pos*s,rotation)
    return q,p
def append_model(parent,level,origin=(0,0,0),prefix='V'):
    q,p=item(parent,'Model',f'Verity_{level:02}',prefix+'Model');field(p,'Ref','PrimaryPart',prefix+'Root');field(p,'token','ModelStreamingMode',1)
    root,rp=item(q,'Part','Root',prefix+'Root')
    for name,value in [('Anchored',True),('CanCollide',False),('CanTouch',False),('CanQuery',False)]:field(rp,'bool',name,str(value).lower())
    field(rp,'float','Transparency',1);v=E.SubElement(rp,'Vector3',name='size')
    for axis in 'XYZ':E.SubElement(v,axis).text='.1'
    frame(rp,origin)
    appearance,ap=item(q,'Model','Appearance',prefix+'Appearance');field(ap,'Ref','PrimaryPart',prefix+'P0')
    for i,n in enumerate(RECIPES[level-1]):
        _,pp=make_part(appearance,n,prefix+f'P{i}',origin,scale(level))
        if i==0:frame(pp,(0,-R*scale(level),0),name='PivotOffset')
    return q
for level in range(1,11):
    r=doc();append_model(r,level);E.ElementTree(r).write(OUT/'models'/f'Verity_{level:02}.rbxmx',encoding='utf-8',xml_declaration=True)

# Smooth analytic preview of the exact sphere/rod recipe, not an AI illustration.
def render_ball(level,edge=400):
    factor=3;w=h=edge*factor;image=np.zeros((h,w,3),dtype=np.float64);image[:]=[239,244,250]
    depth=np.full((h,w),np.inf);pix=R*2.7/w
    xx=(np.arange(w)-w/2)*pix;yy=R+(h/2-np.arange(h))*pix
    X,Y=np.meshgrid(xx,yy);light=np.array([-.38,.65,-.66]);light/=np.linalg.norm(light)
    glow=Image.new('RGBA',(w,h),(0,0,0,0));gd=ImageDraw.Draw(glow)
    for n in RECIPES[level-1]:
        if n.get('optional'):continue
        color=np.array([int(n['color'][k:k+2],16) for k in (0,2,4)],float)
        if n['shape']=='Ball':
            cx,cy,cz=n['pos'];sx,sy,sz=np.array(n['size'])/2
            ux=(X-cx)/sx;uy=(Y-cy)/sy;rr=1-ux*ux-uy*uy;valid=rr>=0
            zz=cz-sz*np.sqrt(np.maximum(0,rr));mask=valid&(zz<depth)
            nx=ux/sx;ny=uy/sy;nz=-np.sqrt(np.maximum(0,rr))/sz
            norm=np.sqrt(nx*nx+ny*ny+nz*nz);norm=np.maximum(norm,1e-8)
            lam=np.maximum(0,(nx*light[0]+ny*light[1]+nz*light[2])/norm)
            shading=.65+.35*lam
            rgb=np.clip(color[None,None,:]*shading[:,:,None],0,255)
            if n.get('body'):
                spec=np.maximum(0,(nx*(-.18)+ny*.35-nz*.92)/norm)**48
                rgb=np.clip(rgb+spec[:,:,None]*35,0,255)
            image[mask]=rgb[mask];depth[mask]=zz[mask]
        else:
            a=np.array(n['a']);b=np.array(n['b']);ax=(a[0]/pix+w/2);ay=h/2-(a[1]-R)/pix;bx=b[0]/pix+w/2;by=h/2-(b[1]-R)/pix
            overlay=Image.new('RGBA',(w,h),(0,0,0,0));d=ImageDraw.Draw(overlay)
            col=tuple(int(c) for c in color)+(255,);d.line((ax,ay,bx,by),fill=col,width=max(1,round(n['width']/pix)))
            arr=np.array(overlay);mask=arr[:,:,3]>0;image[mask]=arr[:,:,:3][mask]
            if n.get('glow'):gd.line((ax,ay,bx,by),fill=col,width=max(1,round(n['width']*2/pix)))
    base=Image.fromarray(np.clip(image,0,255).astype('uint8')).convert('RGBA')
    if level in (5,10):base=Image.alpha_composite(base,glow.filter(ImageFilter.GaussianBlur(5)))
    return base.convert('RGB').resize((edge,edge),Image.Resampling.LANCZOS)
fontpath='/System/Library/Fonts/Supplemental/Arial Bold.ttf'
try:font=ImageFont.truetype(fontpath,23)
except OSError:font=ImageFont.load_default()
sheet=Image.new('RGB',(1600,820),'#EFF4FA');draw=ImageDraw.Draw(sheet)
draw.text((35,20),'VERITY 01–10 / MODEL PREVIEW',fill='#263455',font=font)
for level in range(1,11):
    x=((level-1)%5)*320;y=65+((level-1)//5)*370
    sheet.paste(render_ball(level,300),(x+10,y))
    draw.text((x+20,y+303),f'{level:02}  {DEFS[level-1][0]}',fill='#263455',font=font)
    draw.text((x+20,y+334),DEFS[level-1][2],fill='#65718A',font=font)
sheet.save(OUT/'verity-first-ten.png')
render_ball(1,800).save(OUT/'verity-classic.png')
validation=dict(levels=10,reference='plain smile ball; no ears or limbs',specialLevels=[5,10],sharedGrowth='src/shared/LevelConfig.luau',maxFirstTenScale=scale(10),maxFirstTenBodyDiameter=2*R*scale(10),maxFirstTenAuraDiameter=3.21*scale(10),platformSize=17,partCounts=[len(p)+1 for p in RECIPES],studioPlaytest='not run')
assert all(2*R*scale(i)<17 for i in range(1,11))
assert len(set(d[1] for d in DEFS))==10
for p in (OUT/'models').glob('*.rbxmx'):E.parse(p)
(OUT/'validation.json').write_text(json.dumps(validation,indent=2));print(json.dumps(validation,indent=2))

# Self-contained Studio file: authored models in Edit, regenerated with tags in Play.
gallery=doc();ws,wp=item(gallery,'Workspace','Workspace','Workspace')
field(wp,'bool','StreamingEnabled','true')
scene,_=item(ws,'Folder','VerityGallery','Gallery')
floor,fp=item(scene,'Part','Floor','Floor');field(fp,'bool','Anchored','true')
field(fp,'token','Material',272);field(fp,'Color3uint8','Color3uint8',0xFF2C3554)
v=E.SubElement(fp,'Vector3',name='size')
for k,val in zip(('X','Y','Z'),(112,1,80)):E.SubElement(v,k).text=str(val)
frame(fp,(-6,-.5,8))
for level in range(1,11):
    x=((level-1)%5-2)*16;z=((level-1)//5)*24
    append_model(scene,level,(x,.5,z),f'Gallery{level}')
    q,pp=item(scene,'Part',f'Pad{level}',f'Pad{level}');field(pp,'bool','Anchored','true');field(pp,'Color3uint8','Color3uint8',0xFF000000|int(DEFS[level-1][1],16))
    size=E.SubElement(pp,'Vector3',name='size')
    for axis,val in zip(('X','Y','Z'),(11,.5,11)):E.SubElement(size,axis).text=str(val)
    frame(pp,(x,.25,z))
spawn,sp=item(scene,'SpawnLocation','GallerySpawn','GallerySpawn')
field(sp,'bool','Anchored','true');field(sp,'bool','Neutral','true');field(sp,'bool','CanCollide','false');field(sp,'float','Transparency',1);field(sp,'float','Duration',0)
v=E.SubElement(sp,'Vector3',name='size')
for axis,val in zip(('X','Y','Z'),(6,1,6)):E.SubElement(v,axis).text=str(val)
frame(sp,(0,.5,-24),np.diag([-1,1,-1]))
rs,_=item(gallery,'ReplicatedStorage','ReplicatedStorage','RS');world,_=item(rs,'Folder','World','World');shared,_=item(rs,'Folder','Shared','Shared')
module_names=['VerityDefinitions','VerityRecipe','VerityVisualConfig','VerityMotion','VerityPrototypeFactory','VerityVisualService']
for name in module_names:
    q,p=item(world,'ModuleScript',name,'Module'+name);field(p,'ProtectedString','Source',(ROOT/'src/world'/f'{name}.luau').read_text())
q,p=item(shared,'ModuleScript','LevelConfig','SharedLevel');field(p,'ProtectedString','Source',(ROOT/'src/shared/LevelConfig.luau').read_text())
ss,_=item(gallery,'ServerScriptService','ServerScriptService','SS');q,p=item(ss,'Script','GalleryBootstrap','ServerBootstrap');field(p,'ProtectedString','Source',(ROOT/'examples/verity/GalleryBootstrap.server.luau').read_text())
starter,_=item(gallery,'StarterPlayer','StarterPlayer','Starter');scripts,_=item(starter,'StarterPlayerScripts','StarterPlayerScripts','StarterScripts');q,p=item(scripts,'LocalScript','VerityVisualBootstrap','LocalBootstrap');field(p,'ProtectedString','Source',(ROOT/'src/world-client/VerityVisualBootstrap.client.luau').read_text())
lighting,lp=item(gallery,'Lighting','Lighting','Lighting');field(lp,'token','Technology',1);field(lp,'float','ClockTime',13.5);field(lp,'float','Brightness',2)
E.ElementTree(gallery).write(OUT/'Verity_First10_Preview.rbxlx',encoding='utf-8',xml_declaration=True)
E.parse(OUT/'Verity_First10_Preview.rbxlx')
