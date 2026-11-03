"""Build the World-owned interior template; never rebuild the exterior map."""
from pathlib import Path
import json
import xml.etree.ElementTree as E
from render_interior import preview

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/interiors'
OUT.mkdir(parents=True,exist_ok=True)
COL={'cream':'FFF6DD','white':'FFFFFF','navy':'303A79','mint':'36DDB5','pink':'FF67B8','yellow':'FFDA39','blue':'43CAFF','purple':'A179FF','leaf':'55CF53','lime':'99E63B','wood':'E1AD6D','sand':'FFDCAF','wall':'FFF9ED','tile':'E7F6EF','dark':'25345D'}
nodes=[]
def group(path):
    nodes.append(dict(path=path,cls='Folder'))
def p(path,pos,size,color,collide=True,alpha=0,studs=False,shape='Block',light=False):
    nodes.append(dict(path=path,cls='Part',pos=list(pos),size=list(size),color=COL.get(color,color),collide=collide,alpha=alpha,shape=shape,topSurface='Studs' if studs else 'Smooth',light=light))
for g in ('Geometry','Furniture','Markers'):group(g)
for g in ('Sofa','CoffeeTable','Media','Kitchen','Dining','Plants','Decor','Entry','Lamps'):group('Furniture/'+g)

# The floor's upper surface is local Y=0; the closed shell has no physical doorway.
p('Geometry/Floor',(0,-.5,0),(32,1,28),'cream',studs=True)
p('Geometry/WallBack',(0,6,-14.5),(34,12,1),'wall')
p('Geometry/WallFront',(0,6,14.5),(34,12,1),'wall')
p('Geometry/WallLeft',(-16.5,6,0),(1,12,28),'wall')
p('Geometry/WallRight',(16.5,6,0),(1,12,28),'wall')
p('Geometry/Ceiling',(0,12.5,0),(34,1,30),'white')
for name,pos,size in [('Back',(0,.5,-13.875),(32,1,.25)),('Front',(0,.5,13.875),(32,1,.25)),('Left',(-15.875,.5,0),(.25,1,28)),('Right',(15.875,.5,0),(.25,1,28))]:
    p('Geometry/Skirting'+name,pos,size,'mint',collide=False)
for y in (4,8):
    p(f'Geometry/BackSeam{y}',(0,y,-13.95),(32,.08,.1),'sand',collide=False)
    p(f'Geometry/LeftSeam{y}',(-15.95,y,0),(.1,.08,28),'sand',collide=False)

# Living area: sofa faces the screen across the central circulation space.
p('Furniture/Decor/RugBorder',(4,.09,1),(17,.18,14),'purple',collide=False)
p('Furniture/Decor/Rug',(4,.2,1),(16,.04,13),'pink',collide=False)
for z in (-4.5,6.5):p('Furniture/Decor/RugStripe'+str(z),(4,.235,z),(14,.03,.35),'yellow',collide=False)
p('Furniture/Sofa/Plinth',(10,1,1),(5,1.6,10.5),'navy')
p('Furniture/Sofa/Back',(12.125,3,1),(1.25,4.5,10.5),'mint')
for z in (-4,6):p('Furniture/Sofa/Arm'+str(z),(10,2.75,z),(5,3,1),'mint')
for j,z in enumerate((-2,1,4)):
    p(f'Furniture/Sofa/Cushion{j}',(9.5,2.125,z),(3.75,.75,2.875),'mint')
    p(f'Furniture/Sofa/Pillow{j}',(10.75,3.3,z),(1,1.75,1.875),('yellow','pink','purple')[j],collide=False)
for x in (8.5,11.5):
    for z in (-3,5):p(f'Furniture/Sofa/Foot{x}_{z}',(x,.375,z),(.65,.75,.65),'wood')

p('Furniture/CoffeeTable/Top',(3,2,1),(5,.5,6),'yellow')
for x in (1.25,4.75):
    for z in (-1,3):p(f'Furniture/CoffeeTable/Leg{x}_{z}',(x,1,z),(.5,2,.5),'wood')
p('Furniture/CoffeeTable/Tray',(3,2.3,.75),(2.5,.1,2),'cream',collide=False)
p('Furniture/CoffeeTable/BookBlue',(2.5,2.55,.75),(1.2,.4,1.6),'blue',collide=False)
p('Furniture/CoffeeTable/BookPink',(2.5,2.8,.75),(1.1,.1,1.5),'pink',collide=False)
p('Furniture/CoffeeTable/Cup',(3.75,2.65,1.1),(.6,.6,.6),'purple',collide=False)

p('Furniture/Media/Console',(-13.5,1.8,.5),(3.5,3.2,10),'wood')
p('Furniture/Media/ConsoleTop',(-13.5,3.5,.5),(3.75,.25,10.25),'cream')
for j,z in enumerate((-2.75,.5,3.75)):
    p(f'Furniture/Media/Drawer{j}',(-11.69,1.95,z),(.125,2.25,3),'mint',collide=False)
    p(f'Furniture/Media/Handle{j}',(-11.55,2,z),(.15,.2,1),'white',collide=False)
p('Furniture/Media/TVFrame',(-15.45,7,0),(.65,5.5,9.5),'navy',collide=False)
p('Furniture/Media/TVScreen',(-15.05,7,0),(.15,4.75,8.75),'blue',collide=False)
p('Furniture/Media/TVHorizon',(-14.95,6.2,0),(.06,1.75,8.2),'mint',collide=False)
p('Furniture/Media/TVSun',(-14.9,8.1,-2.5),(.08,1.2,1.2),'yellow',collide=False)
for j,z in enumerate((-3,-1,1,3)):
    p(f'Furniture/Media/TVHill{j}',(-14.85,6.3,z),(.06,1.2+(j%2)*.6,1.8),'leaf',collide=False)

# Kitchen on the rear wall, away from the entry and living-room aisle.
for j,x in enumerate((2,6,10)):
    p(f'Furniture/Kitchen/Cabinet{j}',(x,1.9,-11.75),(3.9,3.8,3.5),'mint')
    p(f'Furniture/Kitchen/Handle{j}',(x,2.7,-9.94),(1,.2,.15),'white',collide=False)
p('Furniture/Kitchen/Counter',(6,4,-11.75),(12.25,.3,3.75),'white')
p('Furniture/Kitchen/Backsplash',(6,5.75,-13.9),(12,3,.15),'blue',collide=False)
for j,x in enumerate((2,6,10)):
    p(f'Furniture/Kitchen/Upper{j}',(x,9,-12.9),(3.9,3,2),'cream')
    p(f'Furniture/Kitchen/UpperHandle{j}',(x,8.4,-11.82),(1,.2,.15),'mint',collide=False)
p('Furniture/Kitchen/SinkRim',(2,4.2,-11.6),(2.5,.1,2.4),'navy',collide=False)
p('Furniture/Kitchen/Sink',(2,4.27,-11.6),(1.9,.05,1.8),'blue',collide=False)
p('Furniture/Kitchen/TapStem',(2,4.85,-12.7),(.25,1.25,.25),'white',collide=False)
p('Furniture/Kitchen/TapSpout',(2,5.4,-12.3),(.25,.25,1),'white',collide=False)
p('Furniture/Kitchen/Hob',(6,4.2,-11.6),(3.2,.1,2.9),'navy',collide=False)
for x in (5.2,6.8):
    for z in (-12.25,-10.9):p(f'Furniture/Kitchen/Burner{x}_{z}',(x,4.3,z),(.9,.08,.85),'dark',collide=False)
p('Furniture/Kitchen/Board',(10,4.25,-11.7),(2,.15,1.5),'wood',collide=False)
p('Furniture/Kitchen/Kettle',(10,4.85,-11.7),(.9,1.1,.8),'yellow',collide=False)
p('Furniture/Kitchen/Fridge',(-2.25,4.25,-11.5),(3.75,8.5,4),'cream')
p('Furniture/Kitchen/FridgeDivider',(-2.25,5.5,-9.45),(3.5,.12,.1),'mint',collide=False)
for y in (3.5,6.8):p('Furniture/Kitchen/FridgeHandle'+str(y),(-.9,y,-9.35),(.2,1.4,.2),'mint',collide=False)
p('Furniture/Kitchen/FridgeMagnet',(-2.5,6.5,-9.35),(.8,.8,.1),'pink',collide=False)

# Compact dining table and two decorative chairs.
p('Furniture/Dining/Top',(-10,3.4,-8.75),(5.5,.5,4.5),'yellow')
for x in (-12,-8):
    for z in (-10.25,-7.25):p(f'Furniture/Dining/Leg{x}_{z}',(x,1.6,z),(.5,3.2,.5),'wood')
for j,z in enumerate((-12,-5.5)):
    p(f'Furniture/Dining/ChairSeat{j}',(-10,1.9,z),(2.75,.4,2.5),'mint')
    backz=z+(-1.1 if j==0 else 1.1)
    p(f'Furniture/Dining/ChairBack{j}',(-10,3,backz),(2.75,2.5,.4),'mint')
    for dx in (-.9,.9):
        for dz in (-.8,.8):p(f'Furniture/Dining/ChairLeg{j}_{dx}_{dz}',(-10+dx,.85,z+dz),(.35,1.7,.35),'wood')
p('Furniture/Dining/Bowl',(-10,3.85,-8.75),(1.3,.4,1.3),'pink',collide=False)
for j,x in enumerate((-10.35,-9.65)):p(f'Furniture/Dining/Fruit{j}',(x,4.2,-8.75),(.65,.65,.65),'leaf',collide=False)

# Decorative inset window and toy block plants. No texture or external mesh IDs.
p('Furniture/Decor/WindowFrame',(-15.8,7.5,-8),(.25,5.5,5),'white',collide=False)
p('Furniture/Decor/WindowGlass',(-15.6,7.5,-8),(.1,4.75,4.25),'blue',collide=False)
p('Furniture/Decor/WindowMullion',(-15.5,7.5,-8),(.1,4.75,.25),'white',collide=False)
p('Furniture/Decor/WindowCrossbar',(-15.5,7.5,-8),(.1,.25,4.25),'white',collide=False)
for z in (-11,-5):p('Furniture/Decor/Curtain'+str(z),(-15.2,7.25,z),(.5,6,1),'yellow',collide=False)
def plant(name,x,z):
    p('Furniture/Plants/'+name+'Pot',(x,1,z),(2,2,2),'purple')
    p('Furniture/Plants/'+name+'Stem',(x,2.8,z),(.4,2,.4),'leaf',collide=False)
    p('Furniture/Plants/'+name+'LeafA',(x-.6,3.5,z),(2.25,1.1,1.7),'leaf',collide=False)
    p('Furniture/Plants/'+name+'LeafB',(x+.6,4.3,z),(1.8,1.5,1.8),'lime',collide=False)
plant('FrontLeft',-13,10)
plant('FrontRight',13,10)

p('Furniture/Entry/DoorFrame',(0,4.75,13.75),(6,9.5,.5),'mint',collide=False)
p('Furniture/Entry/Door',(0,4.5,13.4),(5,9,.25),'yellow',collide=False)
p('Furniture/Entry/DoorPanel',(0,6,13.22),(3.5,3,.1),'cream',collide=False)
p('Furniture/Entry/Handle',(1.75,4,13.15),(.3,.6,.25),'navy',collide=False)
p('Furniture/Entry/Mat',(0,.08,11),(6,.16,3),'mint',collide=False)
for x in (-2,0,2):p('Furniture/Entry/MatStripe'+str(x),(x,.18,11),(.3,.04,2.5),'cream',collide=False)
p('Furniture/Decor/WallArtFrame',(15.8,7,1),(.25,4,5),'purple',collide=False)
p('Furniture/Decor/WallArtPanel',(15.6,7,1),(.1,3.5,4.5),'cream',collide=False)
for j,(z,y) in enumerate(((-.2,7),(1,7.7),(2.2,7))):p(f'Furniture/Decor/WallArtTile{j}',(15.45,y,z),(.1,1.2,1),('mint','yellow','pink')[j],collide=False)
for j,x in enumerate((-6,7)):
    p(f'Furniture/Lamps/CeilingPlate{j}',(x,11.8,0),(4,.25,4),'mint',collide=False)
    p(f'Furniture/Lamps/Diffuser{j}',(x,11.55,0),(3.5,.25,3.5),'cream',collide=False,light=True)

p('Markers/EntryPoint',(0,3,8.5),(1,1,1),'white',False,1)
p('Markers/ExitPoint',(0,2.5,11.5),(1,1,1),'white',False,1)

def lua(v):
    if isinstance(v,str):return json.dumps(v)
    if isinstance(v,bool):return str(v).lower()
    if isinstance(v,(int,float)):return str(v)
    if isinstance(v,list):return '{'+','.join(lua(x) for x in v)+'}'
    return '{'+','.join(k+'='+lua(x) for k,x in v.items())+'}'
(ROOT/'src/world/InteriorRecipe.luau').write_text('-- Generated by tools/build_interior.py.\nreturn '+lua(nodes)+'\n')

def field(parent,tag,name,value):
    q=E.SubElement(parent,tag,name=name);q.text=str(value);return q
def cf(parent,name,pos):
    q=E.SubElement(parent,'CoordinateFrame',name=name)
    for k,v in zip(('X','Y','Z'),pos):E.SubElement(q,k).text=str(v)
    for a in range(3):
        for b in range(3):E.SubElement(q,f'R{a}{b}').text='1' if a==b else '0'
def model_xml():
    doc=E.Element('roblox',version='4');E.SubElement(doc,'External').text='null';E.SubElement(doc,'External').text='nil'
    root=E.SubElement(doc,'Item',{'class':'Model','referent':'InteriorRoot'})
    props=E.SubElement(root,'Properties');field(props,'string','Name','StandardInterior');field(props,'token','ModelStreamingMode',1);field(props,'Ref','PrimaryPart','InteriorFloor')
    lookup={'':root}
    for i,n in enumerate(nodes):
        parent,_,name=n['path'].rpartition('/')
        q=E.SubElement(lookup[parent],'Item',{'class':n['cls'],'referent':'InteriorFloor' if n['path']=='Geometry/Floor' else f'I{i}'})
        props=E.SubElement(q,'Properties');field(props,'string','Name',name);lookup[n['path']]=q
        if 'pos' not in n:continue
        for key,val in [('Anchored',True),('CanCollide',n['collide']),('CanTouch',False),('CanQuery',n['alpha']<1),('CastShadow',n['alpha']<1)]:field(props,'bool',key,str(val).lower())
        field(props,'float','Transparency',n['alpha']);field(props,'token','Material',272);field(props,'token','TopSurface',3 if n['topSurface']=='Studs' else 0);field(props,'token','BottomSurface',0);field(props,'token','shape',1)
        field(props,'Color3uint8','Color3uint8',0xFF000000|int(n['color'],16))
        size=E.SubElement(props,'Vector3',name='size')
        for key,val in zip(('X','Y','Z'),n['size']):E.SubElement(size,key).text=str(val)
        cf(props,'CFrame',n['pos'])
        if n['path']=='Geometry/Floor':cf(props,'PivotOffset',(0,.5,0))
        if n['light']:
            light=E.SubElement(q,'Item',{'class':'PointLight','referent':f'L{i}'})
            lp=E.SubElement(light,'Properties');field(lp,'string','Name','InteriorLight');field(lp,'float','Brightness',1.2);field(lp,'float','Range',24);field(lp,'bool','Shadows','false')
    return doc,root
doc,_=model_xml();E.ElementTree(doc).write(OUT/'StandardInterior.rbxmx',encoding='utf-8',xml_declaration=True)

# An isolated Studio place for walk-through review; not a multiplayer implementation.
doc,root=model_xml();doc.remove(root)
ws=E.SubElement(doc,'Item',{'class':'Workspace','referent':'Workspace'});wp=E.SubElement(ws,'Properties');field(wp,'string','Name','Workspace');ws.append(root)
spawn=E.SubElement(ws,'Item',{'class':'SpawnLocation','referent':'PreviewSpawn'});sp=E.SubElement(spawn,'Properties')
field(sp,'string','Name','PreviewSpawn');field(sp,'bool','Anchored','true');field(sp,'bool','Neutral','true');field(sp,'bool','CanCollide','false');field(sp,'float','Transparency',1);field(sp,'float','Duration',0);cf(sp,'CFrame',(0,.5,8.5))
sz=E.SubElement(sp,'Vector3',name='size')
for key,value in zip(('X','Y','Z'),(4,1,3)):E.SubElement(sz,key).text=str(value)
lighting=E.SubElement(doc,'Item',{'class':'Lighting','referent':'Lighting'});lp=E.SubElement(lighting,'Properties');field(lp,'string','Name','Lighting');field(lp,'float','ClockTime',13.5);field(lp,'float','Brightness',2)
ambient=E.SubElement(lp,'Color3',name='Ambient')
for key,value in zip(('R','G','B'),(.6,.63,.7)):E.SubElement(ambient,key).text=str(value)
E.ElementTree(doc).write(OUT/'InteriorPreview.rbxlx',encoding='utf-8',xml_declaration=True)

# Cutaway for review only: the actual model always retains all walls and ceiling.
hidden={'Geometry/WallFront','Geometry/WallRight','Geometry/Ceiling','Geometry/SkirtingFront','Geometry/SkirtingRight'}
cutaway=[n for n in nodes if n['path'] not in hidden and not n['path'].startswith(('Furniture/Entry/Door','Furniture/Entry/Handle','Furniture/Decor/WallArt','Furniture/Lamps/'))]
preview('interior-cutaway.png',cutaway,OUT,zoom=11.4,focus=(0,0,0))

# Clearance check for a 2-stud-radius character in the central circulation lane.
def blocked(x,z,radius=2):
    for n in nodes:
        if 'pos' not in n or not n['collide'] or n['path']=='Geometry/Floor':continue
        px,py,pz=n['pos'];sx,sy,sz=n['size']
        if py+sy/2<=.3 or py-sy/2>=6:continue
        if abs(x-px)<sx/2+radius and abs(z-pz)<sz/2+radius:return True
    return False
for z in (8.5,7,5,3,1,-1,-3,-5,-6):assert not blocked(-3.5,z),z
for marker in ('Markers/EntryPoint','Markers/ExitPoint'):
    n=next(n for n in nodes if n['path']==marker);assert not blocked(n['pos'][0],n['pos'][2])
for n in nodes:
    if 'pos' not in n:continue
    if n['path'].startswith('Furniture/'):
        x,y,z=n['pos'];sx,sy,sz=n['size']
        assert abs(x)+sx/2<=16.001,n['path']
        assert abs(z)+sz/2<=14.001,n['path']
        assert y-sy/2>=0 and y+sy/2<=12,n['path']
for path in (OUT/'StandardInterior.rbxmx',OUT/'InteriorPreview.rbxlx'):E.parse(path)
report=dict(parts=sum('pos'in n for n in nodes),innerSizeStuds=[32,12,28],pivot=[0,0,0],streaming='Atomic',pointLights=2,clearanceRadius=2,centralAisle='static clearance passed',entryExit='static clearance passed',furnitureBounds='passed',shell='four full walls, floor and ceiling',externalAssets=0,studioPlaytest='not run',multiplayerTransitions='not implemented; Core task')
(OUT/'validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
