"""Build the World-owned interior template; never rebuild the exterior map."""
from pathlib import Path
import json
import xml.etree.ElementTree as E
from render_interior import preview

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/interiors'
OUT.mkdir(parents=True,exist_ok=True)
COL={'cream':'D5C8AE','white':'FFFFFF','navy':'303A79','mint':'36DDB5','pink':'FF67B8','yellow':'FFDA39','blue':'43CAFF','purple':'A179FF','leaf':'55CF53','lime':'99E63B','wood':'C69D70','sand':'8396A8','wall':'728AA2','tile':'B2BFCB','dark':'25345D','upperwall':'779C94'}
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

# v2: preserve the first room's entrance contract, enlarge the house behind it.
# Its kitchen rotates onto the right-hand wall so the back passage stays clear.
kept=[]
living=[]
for n in nodes:
    path=n['path']
    if 'pos' not in n:
        kept.append(n);continue
    if path in ('Geometry/WallBack','Geometry/BackSeam4','Geometry/BackSeam8') or path.startswith(('Furniture/Lamps/','Furniture/Decor/WallArt')):
        continue
    if path.startswith(('Furniture/Sofa/','Furniture/CoffeeTable/','Furniture/Media/','Furniture/Decor/Rug')):
        n['pos'][2]-=33
        if path.startswith('Furniture/Media/'):n['pos'][0]-=8
        living.append(n);continue
    if path.startswith('Furniture/Kitchen/'):
        x,y,z=n['pos'];sx,sy,sz=n['size']
        n['pos']=[-z+2,y,x-4];n['size']=[sz,sy,sx]
    if path=='Geometry/Ceiling':
        n['color']=COL['tile']
        n['pos'][2]=.5;n['size'][2]=29 # Ends at passage wall, not inside it.
    kept.append(n)
nodes=kept+living
group('Geometry/Stairs');group('Furniture/Gallery');group('Furniture/Upper')

p('Geometry/LivingFloor',(0,-.5,-34),(48,1,40),'cream',studs=True)
p('Geometry/LivingBack',(0,15,-54.5),(50,30,1),'wall')
p('Geometry/LivingLeft',(-24.5,15,-34),(1,30,40),'wall')
p('Geometry/LivingRight',(24.5,15,-34),(1,30,40),'wall')
# Wide, genuinely open 11 x 9 stud passage from the original room.
for side in (-1,1):
    p(f'Geometry/PassageWall{side}',(side*15.25,7.5,-14.5),(19.5,15,1),'wall')
    p(f'Geometry/PassageFrame{side}',(side*5.625,4.5,-14.25),(.4,9,1.7),'navy',collide=False)
p('Geometry/PassageLintel',(0,12,-14.5),(11,6,1),'wall')
p('Geometry/PassageFrameTop',(0,9.125,-14.25),(11.5,.25,1.7),'navy',collide=False)
p('Geometry/UpperFront',(0,23,-14.5),(50,14,1),'upperwall')
p('Geometry/UpperBackLining',(0,23,-53.9),(48,14,.2),'upperwall',collide=False)
p('Geometry/UpperLeftLining',(-23.9,23,-34),(.2,14,40),'upperwall',collide=False)
p('Geometry/UpperRightLining',(23.9,23,-34),(.2,14,40),'upperwall',collide=False)
p('Geometry/UpperFloorMain',(-5,15.5,-34),(38,1,40),'cream',studs=True)
p('Geometry/UpperFloorFront',(19,15.5,-19.5),(10,1,11),'cream',studs=True)
p('Geometry/UpperLanding',(19,15.5,-52),(10,1,4),'cream',studs=True)
p('Geometry/UpperCeiling',(0,30.5,-34),(50,1,42),'tile')
# 32 half-stud risers, .75 stud treads. Full opening above the entire flight.
for i in range(32):
    top=(i+1)*.5;z=-26-(i+.5)*.75
    p(f'Geometry/Stairs/Step{i:02}',(19,top/2,z),(8,top,.75),'wood')
    p(f'Geometry/Stairs/Nosing{i:02}',(19,top+.025,z+.275),(8,.05,.2),'mint',collide=False)
    for x in (14.75,23.25):
        p(f'Geometry/Stairs/Handrail{i:02}_{x}',(x,top+3,z),(.3,.3,.85),'navy')
        if i%4==0 or i==31:
            p(f'Geometry/Stairs/Post{i:02}_{x}',(x,top+1.5,z),(.3,3,.3),'mint')
p('Geometry/UpperOpeningRail',(13.75,18,-37.5),(.3,.3,25),'navy')
p('Geometry/UpperOpeningFrontRail',(19,18,-24.75),(10,.3,.3),'navy')
for z in (-49,-45,-41,-37,-33,-29,-25):
    p('Geometry/UpperOpeningPost'+str(z),(13.75,17,z),(.3,2,.3),'mint')
for x in (16,20,23):p('Geometry/UpperFrontPost'+str(x),(x,17,-24.75),(.3,2,.3),'mint')

# Minimal upper room: one plant, a window and a portrait; no invented use yet.
plant('UpperCorner',-20,-20)
for n in nodes:
    if n['path'].startswith('Furniture/Plants/UpperCorner'):n['pos'][1]+=16
p('Furniture/Upper/WindowFrame',(-12,23,-53.7),(12,7,.3),'navy',collide=False)
p('Furniture/Upper/WindowGlass',(-12,23,-53.45),(11.25,6.25,.15),'blue',collide=False)
p('Furniture/Upper/WindowMullion',(-12,23,-53.3),(.35,6.25,.15),'tile',collide=False)
p('Furniture/Upper/WindowCrossbar',(-12,23,-53.3),(11.25,.35,.15),'tile',collide=False)

# Asset-free framed Verity portraits made from shallow toy-block shapes.
# This stylised mascot is replaceable once the final Verity reference is supplied.
def portrait(name,x,y,z,face='back',body='pink',crown=False):
    prefix='Furniture/Gallery/'+name
    group(prefix)
    def art(partname,u,v,w,h,color,depth=.06,layer=0):
        if face=='back':p(prefix+'/'+partname,(x+u,y+v,z+layer),(w,h,depth),color,collide=False)
        else:p(prefix+'/'+partname,(x+layer,y+v,z+u),(depth,h,w),color,collide=False)
    art('Frame',0,0,7.5,7,'navy',.35)
    art('Canvas',0,0,6.8,6.3,'blue',.1,.25)
    art('Ground',0,-2.4,6.3,.8,'mint',.06,.35)
    art('Body',0,-.5,3.8,3.1,body,.08,.4)
    art('Head',0,.4,4.3,2.8,body,.08,.45)
    art('EarL',-1.4,2,1,1.3,body,.08,.45)
    art('EarR',1.4,2,1,1.3,body,.08,.45)
    for side in (-1,1):
        art('EyeWhite'+str(side),side*.9,.6,.9,1.15,'white',.06,.55)
        art('Pupil'+str(side),side*.85,.5,.45,.7,'navy',.06,.65)
        art('Cheek'+str(side),side*1.5,-.4,.55,.3,'yellow',.06,.6)
    art('Smile',0,-.6,.9,.25,'navy',.06,.6)
    if crown:
        art('CrownBand',0,2.25,2.8,.5,'yellow',.08,.65)
        for j,u in enumerate((-1,0,1)):art('CrownTip'+str(j),u,2.7,.55,.65,'yellow',.08,.65)
portrait('VerityWelcome',-15.7,7,1,face='left',body='pink')
portrait('VerityCrown',-10,7,-53.8,body='mint',crown=True)
portrait('VerityUpstairs',7,23,-53.8,body='purple',crown=True)
for j,(x,y,z) in enumerate(((-5,11.5,-1),(-10,14.5,-35),(8,14.5,-44),(-10,29.5,-30),(8,29.5,-44))):
    p(f'Furniture/Lamps/CeilingPlate{j}',(x,y+.25,z),(4,.25,4),'navy',collide=False)
    p(f'Furniture/Lamps/Diffuser{j}',(x,y,z),(3.5,.25,3.5),'tile',collide=False,light=True)
p('Markers/LivingRoomEntry',(0,3,-19),(1,1,1),'white',False,1)
p('Markers/StairBottom',(19,3,-23.5),(1,1,1),'white',False,1)
p('Markers/UpstairsPoint',(10,19,-52),(1,1,1),'white',False,1)

# v3: a walk-in house, integrated on each real plot. Replace solid facade panels
# with actual doorway/window openings; no character teleport or separate room.
remove={'Geometry/WallFront','Geometry/LivingLeft','Geometry/LivingRight','Geometry/UpperFront','Geometry/UpperLeftLining','Geometry/UpperRightLining'}
nodes=[n for n in nodes if n['path'] not in remove and not n['path'].startswith(('Furniture/Entry/Door','Furniture/Entry/Handle'))]
for n in nodes:
    if n['path'] in ('Geometry/Floor','Geometry/LivingFloor','Geometry/UpperFloorMain','Geometry/UpperFloorFront','Geometry/UpperLanding'):
        n['color']='86A9BF';n['topSurface']='Studs'
for side in (-1,1):
    p(f'Geometry/FrontSill{side}',(side*10.5,1,14.5),(13,2,1),'wall')
    for x,width in ((side*16,2),(side*4.5,1)):
        p(f'Geometry/FrontPier{side}_{x}',(x,6,14.5),(width,8,1),'mint')
    p(f'Geometry/FrontGlass{side}',(side*10,6,14.5),(10,8,.15),'blue',alpha=.72)
    p(f'Geometry/OpenDoorPost{side}',(side*4.125,4.5,14.5),(.4,9,1.4),'navy',collide=False)
p('Geometry/FrontHeader',(0,11,14.5),(34,2,1),'mint')
p('Geometry/OpenDoorLintel',(0,9.5,14.5),(8,1,1),'mint')
# Side glazing opens views of the living room and the upper floor to neighbours.
for side in (-1,1):
    x=side*24.5
    for name,y,h in (('Sill',1,2),('FloorBand',15.5,3),('RoofBand',29,2)):
        p(f'Geometry/Side{name}{side}',(x,y,-34.5),(1,h,39),'wall')
    # Piers meet the floor band instead of sharing its entire coloured face.
    for z in (-53,-40,-27,-15):
        center,length=(-15.5,1) if z==-15 else (z,2)
        for tier,y,h in (('Lower',8,12),('Upper',22.5,11)):
            p(f'Geometry/SidePier{side}_{z}{tier}',(x,y,center),(1,h,length),'mint')
    for j,(z,length) in enumerate(((-46.5,11),(-33.5,11),(-21,10))):
        p(f'Geometry/LivingGlass{side}_{j}',(x,8,z),(.15,12,length),'blue',alpha=.78)
        p(f'Geometry/UpperGlass{side}_{j}',(x,22.5,z),(.15,11,length),'blue',alpha=.78)
p('Geometry/UpperFrontSill',(0,17,-14.5),(50,2,1),'upperwall')
p('Geometry/UpperFrontHeader',(0,29,-14.5),(50,2,1),'mint')
for x in (-24,-10,3,16,24):p('Geometry/UpperFacadePier'+str(x),(x,23,-14.5),(1,10,1),'mint')
for j,(x,width) in enumerate(((-17,13),(-3.5,12),(9.5,12),(20,7))):
    p(f'Geometry/UpperFrontGlass{j}',(x,23,-14.5),(width,10,.15),'blue',alpha=.78)
# Visible plastic roof caps with the same fine stud surface as the map.
for name,pos,size in [('Lobby',(0,13.1,.5),(34,.2,29)),('Upper',(0,31.1,-34),(50,.2,42))]:
    p('Geometry/RoofCap'+name,pos,size,'mint',studs=True)
for n in nodes:
    if n['path'].startswith(('Geometry/FrontPier','Geometry/FrontHeader','Geometry/OpenDoorLintel','Geometry/SidePier','Geometry/UpperFacadePier','Geometry/UpperFrontHeader','Geometry/RoofCap')):
        n['accent']=True
# Extra decoration downstairs; upstairs intentionally stays sparse.
p('Furniture/Decor/BookcaseBack',(-14.75,2.75,-3.25),(.25,5.5,3.5),'wood')
for y in (.4,2.6,5.3):p('Furniture/Decor/Bookshelf'+str(y),(-13.75,y,-3.25),(2.25,.25,3.5),'wood')
for j,z in enumerate((-4.5,-3.7,-2.9,-2.1)):
    p(f'Furniture/Decor/Book{j}',(-13.7,1.4,z),(1.5,1.5,.55),('blue','pink','yellow','purple')[j],collide=False)
plant('LivingCorner',-20,-48)
p('Furniture/Decor/FloorLampBase',(-18,.25,-21),(2.5,.5,2.5),'navy')
p('Furniture/Decor/FloorLampStem',(-18,3.5,-21),(.35,6,.35),'wood',collide=False)
p('Furniture/Decor/FloorLampShade',(-18,6.5,-21),(3,1.5,3),'yellow',collide=False)
p('Furniture/Media/Speaker',(-21,4.4,4),(1.1,1.5,1.1),'navy',collide=False)
p('Furniture/Media/SpeakerInset',(-20.4,4.4,4),(.1,.8,.8),'mint',collide=False)

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
        field(props,'float','Transparency',n['alpha']);field(props,'token','Material',256 if n['topSurface']=='Studs' else 272);field(props,'token','TopSurface',3 if n['topSurface']=='Studs' else 0);field(props,'token','BottomSurface',0);field(props,'token','shape',1)
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
field(lp,'token','Technology',1)
ambient=E.SubElement(lp,'Color3',name='Ambient')
for key,value in zip(('R','G','B'),(.6,.63,.7)):E.SubElement(ambient,key).text=str(value)
E.ElementTree(doc).write(OUT/'InteriorPreview.rbxlx',encoding='utf-8',xml_declaration=True)

# Cutaways are review views only; the exported model remains fully enclosed.
hidden={'Geometry/WallFront','Geometry/WallRight','Geometry/Ceiling','Geometry/SkirtingFront','Geometry/SkirtingRight','Geometry/LivingRight','Geometry/LivingBack','Geometry/LivingLeft','Geometry/UpperCeiling','Geometry/UpperFront','Geometry/UpperBackLining','Geometry/UpperLeftLining','Geometry/UpperRightLining','Geometry/UpperFloorMain','Geometry/UpperFloorFront','Geometry/UpperLanding'}
# Keep the first-floor halves of the distant living-room walls in the cutaway.
cutaway=[dict(n) for n in nodes if n['path'] not in hidden and not n['path'].startswith(('Geometry/RoofCap','Geometry/PassageWall','Geometry/PassageLintel','Furniture/Entry/Door','Furniture/Entry/Handle','Furniture/Lamps/','Geometry/Upper','Furniture/Upper/','Furniture/Plants/UpperCorner','Furniture/Gallery/VerityUpstairs'))]
for name,pos,size in [('CutawayBack',(0,7.5,-54.5),(50,15,1)),('CutawayLeft',(-24.5,7.5,-34),(1,15,40))]:
    cutaway.append(dict(path=name,cls='Part',pos=pos,size=size,color=COL['wall'],alpha=0,shape='Block'))
preview('interior-cutaway.png',cutaway,OUT,zoom=6.5,focus=(0,0,-20))
upper=[dict(n) for n in nodes if n['path'].startswith(('Geometry/UpperFloor','Geometry/UpperLanding','Geometry/UpperOpening','Geometry/UpperFrontPost','Furniture/Upper/','Furniture/Plants/UpperCorner','Furniture/Gallery/VerityUpstairs'))]
for n in upper:
    if 'pos'in n:n['pos']=list(n['pos']);n['pos'][1]-=16
for name,pos,size in [('UpperViewBack',(0,7,-54.5),(50,14,1)),('UpperViewLeft',(-24.5,7,-34),(1,14,40))]:
    upper.append(dict(path=name,cls='Part',pos=pos,size=size,color=COL['upperwall'],alpha=0,shape='Block'))
preview('upstairs-cutaway.png',upper,OUT,zoom=8,focus=(0,0,-34))

# Clearance check for a 2-stud-radius character in the central circulation lane.
def blocked(x,z,feet=0,radius=1.5,step_allowance=.1):
    for n in nodes:
        if 'pos' not in n or not n['collide'] or n['path'].startswith('Geometry/Stairs/Step'):continue
        px,py,pz=n['pos'];sx,sy,sz=n['size']
        if py+sy/2<=feet+step_allowance or py-sy/2>=feet+5.5:continue
        if abs(x-px)<sx/2+radius and abs(z-pz)<sz/2+radius:return True
    return False
for z in range(-22,10):assert not blocked(0,z),('entrance passage',z)
for x in range(20):assert not blocked(x,-22),('stair approach',x)
for i in range(32):assert not blocked(19,-26-(i+.5)*.75,(i+1)*.5,step_allowance=.55),('stair headroom',i)
for x in range(20):assert not blocked(x,-52,16),('upstairs landing',x)
for z in range(-52,-18):assert not blocked(0,z,16),('upstairs room',z)
for marker in ('Markers/EntryPoint','Markers/ExitPoint'):
    n=next(n for n in nodes if n['path']==marker);assert not blocked(n['pos'][0],n['pos'][2])
for n in nodes:
    if 'pos' not in n:continue
    if n['path'].startswith('Furniture/'):
        x,y,z=n['pos'];sx,sy,sz=n['size']
        assert abs(x)+sx/2<=24.001,n['path']
        assert z-sz/2>=-54.001 and z+sz/2<=14.001,n['path']
        assert y-sy/2>=0 and y+sy/2<=30,n['path']
for path in (OUT/'StandardInterior.rbxmx',OUT/'InteriorPreview.rbxlx'):E.parse(path)
report=dict(version=3,parts=sum('pos'in n for n in nodes),lobbySize=[32,12,28],livingRoomSize=[48,15,40],upperFloorLevel=16,upperRoomSize=[48,14,40],shellBounds=[50,32.2,70],pivot=[0,0,0],streaming='Atomic',pointLights=5,stairSteps=32,stairRise=.5,stairTread=.75,stairWidth=8,portraitCount=3,clearanceRadius=1.5,centralAisle='static clearance passed',stairHeadroom='static clearance passed',upperLanding='static clearance passed',entryExit='static clearance passed',furnitureBounds='passed',externalAssets=0,studioPlaytest='not run',entryMode='physical doorway; no teleports')
(OUT/'validation.json').write_text(json.dumps(report,indent=2));print(json.dumps(report,indent=2))
