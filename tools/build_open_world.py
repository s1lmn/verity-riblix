"""Generate the shared walk-in neighbourhood; one reusable house recipe."""
from pathlib import Path
import copy, json, math, xml.etree.ElementTree as E
from build_interior import nodes as house_nodes, lua
from render_interior import preview

ROOT=Path(__file__).resolve().parents[1]
C={'grass':'58D43D','lawn':'8DE54A','road':'58668F','paving':'FFF0CF','cream':'E3D8BD','white':'FFFFFF','navy':'303A79','wood':'C69D70','leaf':'27BF50','leaf2':'8BEC37','mint':'36E5AC','pink':'FF60B6','blue':'39BFFF','yellow':'FFDA39','lilac':'A179FF','peach':'FF984A'}
nodes=[];recipe=[];plots=[]
def group(path,cls='Model',**metadata):
    n=dict(path=path,cls=cls,**metadata);nodes.append(n);recipe.append(copy.deepcopy(n))
def part(path,pos,size,color,collide=True,alpha=0,studs=False,cls='Part'):
    n=dict(path=path,cls=cls,pos=list(pos),size=list(size),color=C.get(color,color),shape='Block',collide=collide,alpha=alpha,topSurface='Studs' if studs else 'Smooth')
    nodes.append(n);recipe.append(copy.deepcopy(n))
def tree(path,x,z,scale=1):
    group(path)
    part(path+'/Trunk',(x,3*scale,z),(1.5*scale,6*scale,1.5*scale),'wood')
    part(path+'/Crown',(x,7.5*scale,z),(8*scale,5*scale,8*scale),'leaf',False,studs=True)
    part(path+'/Top',(x,11*scale,z),(6*scale,3*scale,6*scale),'leaf2',False,studs=True)
def bench(path,x,z):
    group(path)
    part(path+'/Seat',(x,1.8,z),(3,.5,8),'wood')
    part(path+'/Back',(x+1.2,3,z),(.5,2.5,8),'mint')
    for dz in (-2.5,2.5):part(path+f'/Leg{dz}',(x,.8,z+dz),(2.5,1.6,.5),'navy')

group('GeneratedWorld');group('GeneratedWorld/Environment');group('GeneratedWorld/Plots');group('GeneratedWorld/Plaza')
env='GeneratedWorld/Environment'
part(env+'/Ground',(0,-2,0),(340,4,740),'grass',studs=True)
part(env+'/Road',(0,.08,0),(26,.16,620),'road',studs=True)
for side in (-1,1):
    part(env+f'/Sidewalk{side}',(side*18,.25,0),(10,.5,620),'paving',studs=True)
    part(env+f'/Curb{side}',(side*13.4,.35,0),(.8,.7,620),'white')
for i,z in enumerate(range(-280,281,24)):part(env+f'/RoadDash{i}',(0,.18,z),(.45,.04,9),'cream',False)
for end in (-1,1):
    for i,x in enumerate(range(-10,11,4)):part(env+f'/Crosswalk{end}_{i}',(x,.2,end*300),(2,.05,7),'white',False)
    part(env+f'/EndPath{end}',(0,.12,end*326),(280,.24,26),'paving',studs=True)
    for x in (-140,-100,100,140):tree(env+f'/ParkTree{end}_{x}',x,end*351,1.2)
    for x in (-65,65):bench(env+f'/ParkBench{end}_{x}',x,end*326)
palette=['mint','peach','blue','yellow','pink','lilac','blue','mint']
for row in range(8):
    z=(row-3.5)*72
    for side in (-1,1):
        pid=row*2+(1 if side==-1 else 2);root=f'GeneratedWorld/Plots/Plot_{pid:02}'
        group(root);group(root+'/Markers','Folder')
        part(root+'/Lawn',(side*85,.08,z),(120,.16,70),'lawn',studs=True)
        part(root+'/Path',(side*40,.2,z),(30,.4,8),'paving',studs=True)
        part(root+'/Porch',(side*51,.25,z),(6,.5,12),'cream',studs=True)
        part(root+'/VerityPlatform',(side*37,.35,z+24),(17,.7,17),'cream',studs=True)
        part(root+'/PlatformInset',(side*37,.73,z+24),(14,.06,14),palette[row],False,studs=True)
        part(root+'/UpgradeStation',(side*29,1,z+33),(3,2,2.5),palette[row])
        part(root+'/OwnerSign',(side*28,2.7,z-31),(.8,3.6,5),'cream')
        part(root+'/SignPost',(side*28,1,z-31),(.6,2,.6),'wood')
        for name,x,y,dz in [('SpawnPoint',35,3.5,0),('DeliveryPoint',36,1,-10),('VerityOrigin',37,.9,24),('HouseEntrance',50,3.5,0)]:
            part(root+'/Markers/'+name,(side*x,y,z+dz),(1,1,1),'white',False,1)
        # Actual furnished house on this plot. Full details exist in XML, while the
        # Luau map recipe references one shared InteriorRecipe through the factory.
        origin=[side*67,.5,z]
        group(root+'/House',house=True,origin=origin,yaw=-side*math.pi/2,accent=C[palette[row]])
        for source in house_nodes:
            n=copy.deepcopy(source);n['path']=root+'/House/'+source['path']
            if 'pos' in n:
                x,y,local_z=n['pos'];sx,sy,sz=n['size']
                n['pos']=[side*(67-local_z),.5+y,z+side*x];n['size']=[sz,sy,sx]
                if n.get('accent'):n['color']=C[palette[row]]
            nodes.append(n)
        for dz in (-30,30):tree(root+f'/Tree{dz}',side*134,z+dz,.85)
        bench(root+'/GardenBench',side*38,z-20)
        part(root+'/MailboxPost',(side*30,1.5,z-16),(.6,3,.6),'wood')
        part(root+'/Mailbox',(side*30,3.3,z-16),(2.5,1.5,2),palette[row])
        part(root+'/MailboxSlot',(side*28.7,3.4,z-16),(.1,.2,1.4),'navy',False)
        for j in range(3):
            part(root+f'/FlowerPot{j}',(side*47,.6,z+11+j*2.5),(1.7,1.2,1.7),'cream')
            part(root+f'/Flower{j}',(side*47,1.8,z+11+j*2.5),(1.5,1.2,1.5),('pink','yellow','lilac')[j],False)
        plots.append(dict(id=pid,minX=min(side*25,side*145),maxX=max(side*25,side*145),minZ=z-36,maxZ=z+36))
for side in (-1,1):
    for i,z in enumerate((-252,-108,36,180)):
        path=env+f'/Lamp{side}_{i}';group(path)
        part(path+'/Post',(side*21.2,6,z),(.65,12,.65),'navy')
        part(path+'/Head',(side*21.2,12.5,z),(2.8,1.5,2.8),'yellow')
        part(path+'/Cap',(side*21.2,13.4,z),(3.3,.35,3.3),'blue')
part('GeneratedWorld/Plaza/WelcomePad',(0,.35,-326),(24,.7,16),'mint',studs=True)
part('GeneratedWorld/Plaza/WelcomeSpawn',(0,.9,-326),(8,1,8),'mint',False,1,cls='SpawnLocation')

def field(parent,tag,name,value):
    q=E.SubElement(parent,tag,name=name);q.text=str(value);return q
def frame(parent,name,pos):
    q=E.SubElement(parent,'CoordinateFrame',name=name)
    for k,v in zip(('X','Y','Z'),pos):E.SubElement(q,k).text=str(v)
    for a in range(3):
        for b in range(3):E.SubElement(q,f'R{a}{b}').text='1' if a==b else '0'
def document():
    root=E.Element('roblox',version='4');E.SubElement(root,'External').text='null';E.SubElement(root,'External').text='nil';return root
def populate(parent):
    lookup={};props_lookup={}
    for i,n in enumerate(nodes):
        parentpath,_,name=n['path'].rpartition('/')
        obj=E.SubElement(lookup.get(parentpath,parent),'Item',{'class':n['cls'],'referent':f'W{i}'})
        lookup[n['path']]=obj;props=E.SubElement(obj,'Properties');props_lookup[n['path']]=props
        field(props,'string','Name',name)
        if n.get('house'):field(props,'token','ModelStreamingMode',1)
        if 'pos' not in n:continue
        for key,value in [('Anchored',True),('CanCollide',n['collide']),('CanTouch',False),('CanQuery',n['alpha']<1),('CastShadow',n['alpha']==0)]:field(props,'bool',key,str(value).lower())
        field(props,'float','Transparency',n['alpha']);field(props,'token','Material',256 if n.get('topSurface')=='Studs' else 272);field(props,'token','TopSurface',3 if n.get('topSurface')=='Studs' else 0);field(props,'token','BottomSurface',0)
        if n['cls']=='Part':field(props,'token','shape',1)
        field(props,'Color3uint8','Color3uint8',0xFF000000|int(n['color'],16))
        size=E.SubElement(props,'Vector3',name='size')
        for key,value in zip(('X','Y','Z'),n['size']):E.SubElement(size,key).text=str(value)
        frame(props,'CFrame',n['pos'])
        if n['path'].endswith('/House/Geometry/Floor'):frame(props,'PivotOffset',(0,.5,0))
        if n.get('light'):
            light=E.SubElement(obj,'Item',{'class':'PointLight','referent':f'Light{i}'})
            lp=E.SubElement(light,'Properties');field(lp,'string','Name','InteriorLight');field(lp,'float','Brightness',1.2);field(lp,'float','Range',24);field(lp,'bool','Shadows','false')
        if n['cls']=='SpawnLocation':field(props,'bool','Neutral','true');field(props,'float','Duration',0)
    for n in nodes:
        if n.get('house'):field(props_lookup[n['path']],'Ref','PrimaryPart',lookup[n['path']+'/Geometry/Floor'].get('referent'))

model=document();populate(model);E.ElementTree(model).write(ROOT/'VerityNeighborhood.rbxmx',encoding='utf-8',xml_declaration=True)
place=document();ws=E.SubElement(place,'Item',{'class':'Workspace','referent':'Workspace'});wp=E.SubElement(ws,'Properties');field(wp,'string','Name','Workspace');field(wp,'bool','StreamingEnabled','true');populate(ws)
lighting=E.SubElement(place,'Item',{'class':'Lighting','referent':'Lighting'});lp=E.SubElement(lighting,'Properties');field(lp,'string','Name','Lighting');field(lp,'float','ClockTime',13.5);field(lp,'float','Brightness',2);field(lp,'bool','GlobalShadows','true');field(lp,'float','ShadowSoftness',.4)
field(lp,'token','Technology',1)
for key,color in [('Ambient',(.62,.65,.72)),('OutdoorAmbient',(.7,.72,.76))]:
    q=E.SubElement(lp,'Color3',name=key)
    for channel,value in zip(('R','G','B'),color):E.SubElement(q,channel).text=str(value)
E.ElementTree(place).write(ROOT/'VerityNeighborhood.rbxlx',encoding='utf-8',xml_declaration=True)

for n in recipe:n['path']=n['path'].removeprefix('GeneratedWorld').lstrip('/')
(ROOT/'src/world/MapRecipe.luau').write_text('-- Generated outdoor layout; house details use shared InteriorRecipe.\nreturn '+lua(recipe)+'\n')
assert len(plots)==16
for i,a in enumerate(plots):
    for b in plots[i+1:]:assert not(a['minX']<b['maxX'] and b['minX']<a['maxX'] and a['minZ']<b['maxZ'] and b['minZ']<a['maxZ'])
for plot in plots:
    prefix=f"GeneratedWorld/Plots/Plot_{plot['id']:02}/"
    for n in nodes:
        if n['path'].startswith(prefix) and 'pos' in n:
            x,y,z=n['pos'];sx,sy,sz=n['size']
            assert x-sx/2>=plot['minX'] and x+sx/2<=plot['maxX'],n['path']
            assert z-sz/2>=plot['minZ'] and z+sz/2<=plot['maxZ'],n['path']
    # Outside pathway has no blocking decorative/structural part through the entrance.
    side=-1 if plot['id']%2 else 1;row_z=(plot['minZ']+plot['maxZ'])/2
    for distance in range(24,62):
        for n in nodes:
            if not n['path'].startswith(prefix) or 'pos' not in n or not n['collide']:continue
            x,y,z=n['pos'];sx,sy,sz=n['size']
            if y+sy/2<=.6 or y-sy/2>=6:continue
            assert not(abs(side*distance-x)<sx/2+1.5 and abs(row_z-z)<sz/2+1.5),('entrance blocked',n['path'],distance)
for path in ('VerityNeighborhood.rbxlx','VerityNeighborhood.rbxmx'):E.parse(ROOT/path)
report=dict(version=5,plots=16,walkInHouses=16,parts=sum('pos'in n for n in nodes),rowSpacing=72,plotFootprint=[120,72],houseFootprint=[70,50],entry='physical doorways; all players may visit',glass='transparency .72-.78; collision enabled',floor='muted blue 86A9BF with native fine Studs',checks=['lot bounds do not overlap','all lot objects fit their lot','outside path and 16 entrances have static clearance','house internal route/stair tests run in build_interior','XML parsed'],pointLights=80,studioPlaytest='not run',mobileFPS='not measured')
(ROOT/'validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
preview('map-overview.png',nodes,ROOT,zoom=.95,title='VERITY / OPEN NEIGHBOURHOOD')
preview('house-front.png',house_nodes,ROOT,zoom=6,focus=(0,0,-20),title='VERITY / WALK-IN HOUSE')
