from pathlib import Path
import json, math, xml.etree.ElementTree as E
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUT=Path(__file__).resolve().parents[1]
C={'grass':'58D43D','lawn':'8DE54A','road':'58668F','paving':'FFF0CF','cream':'FFFCED','white':'FFFFFF','navy':'303A79','glass':'48D8FF','wood':'D4954F','leaf':'27BF50','leaf2':'8BEC37','mint':'36E5AC','pink':'FF60B6','blue':'39BFFF','yellow':'FFDA39','lilac':'A179FF','peach':'FF984A'}
def font(size, bold=False):
    names = ['/System/Library/Fonts/Supplemental/Arial Bold.ttf' if bold else '/System/Library/Fonts/Supplemental/Arial.ttf', 'DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf']
    for name in names:
        try: return ImageFont.truetype(name, size)
        except OSError: pass
    return ImageFont.load_default()

nodes=[]
def folder(path,cls='Model'):
    if not any(n['path']==path for n in nodes): nodes.append(dict(path=path,cls=cls))
def part(path,pos,size,col,shape='Block',collide=True,alpha=0,cls='Part',upright=False):
    nodes.append(dict(path=path,cls=cls,pos=pos,size=size,color=C.get(col,col),shape=shape,collide=collide,alpha=alpha,upright=upright))
def stud(path,x,y,z,diameter,col):
    part(path,(x,y,z),(0.65,diameter,diameter),col,shape='Cylinder',collide=False,upright=True)
def tree(path,x,z,scale=1):
    folder(path)
    part(path+'/Trunk',(x,3*scale,z),(1.7*scale,6*scale,1.7*scale),'wood')
    part(path+'/Crown',(x,7.5*scale,z),(8*scale,5*scale,8*scale),'leaf',collide=False)
    part(path+'/CrownTop',(x,11*scale,z),(6*scale,3*scale,6*scale),'leaf2',collide=False)
    for dx in (-1.5,1.5):
        stud(path+f'/LeafStud{dx}',x+dx*scale,12.5*scale+0.325,z,2*scale,'leaf2')
def bench(path,x,z):
    folder(path)
    part(path+'/Seat',(x,2,z),(9,0.6,2.5),'wood')
    part(path+'/Back',(x,3.2,z+1),(9,2,0.5),'wood')
    for dx in (-3,3): part(path+f'/Leg{dx}',(x+dx,1,z),(0.6,2,2),'navy')

folder('GeneratedWorld'); folder('GeneratedWorld/Environment'); folder('GeneratedWorld/Plots'); folder('GeneratedWorld/Plaza')
env='GeneratedWorld/Environment'
part(env+'/Ground',(0,-2,0),(232,4,530),'grass')
part(env+'/Road',(0,0.08,0),(26,0.16,414),'road')
for side in (-1,1):
    part(env+f'/Sidewalk{side}',(side*18,0.25,0),(10,0.5,414),'paving')
    part(env+f'/Curb{side}',(side*13.4,0.35,0),(0.8,0.7,414),'white')
    part(env+f'/OuterGreen{side}',(side*103,0.05,0),(24,0.1,414),'grass')
for i,z in enumerate(range(-190,191,22)):
    part(env+f'/RoadDash{i}',(0,0.18,z),(0.45,0.04,8),'cream',collide=False)
for end in (-1,1):
    for i,x in enumerate(range(-10,11,4)):
        part(env+f'/Crosswalk{end}_{i}',(x,0.2,end*196),(2,0.05,7),'white',collide=False)
    part(env+f'/EndPath{end}',(0,0.12,end*225),(180,0.24,26),'paving')
    for x in (-88,-55,55,88): tree(env+f'/ParkTree{end}_{x}',x,end*246,1.2)
    for x in (-42,42): bench(env+f'/Bench{end}_{x}',x,end*228)

palette=['mint','peach','blue','yellow','pink','lilac','blue','mint']
plots=[]
for row in range(8):
    z=(row-3.5)*48
    for side in (-1,1):
        pid=row*2+(1 if side==-1 else 2)
        root=f'GeneratedWorld/Plots/Plot_{pid:02}'
        folder(root); folder(root+'/House'); folder(root+'/Markers','Folder')
        def local(name,v,y,u,sv,sy,su,col,**kw):
            part(root+'/'+name,(side*(25+v),y,z+u),(sv,sy,su),col,**kw)
        local('Lawn',32,0.08,0,64,0.16,46,'lawn')
        local('Path',13,0.2,-10,26,0.4,6,'paving')
        # Solid shell: interiors intentionally postponed. Front faces the street.
        local('House/Foundation',41,0.7,0,29,1.4,32,'cream')
        # Oversized construction blocks with visible recessed joints.
        for layer in range(3):
            widths=[10,10,10] if layer%2==0 else [5,10,10,5]
            start=-15
            for brick,width in enumerate(widths):
                local(f'House/Brick_{layer}_{brick}',41,4+layer*6,start+width/2,28,5.85,width-0.15,palette[row])
                start+=width
        local('House/Roof',41,19.6,0,30,1.2,32,'navy')
        local('House/RoofCap',41,20.35,0,28,0.3,30,palette[row])
        for a in range(4):
            for b in range(4):
                stud(root+f'/House/RoofStud{a}_{b}',side*(25+30.5+a*7),20.825,z-10.5+b*7,3.2,palette[row])
        local('House/FrontBand',26.75,17.8,0,0.5,1.6,30,'cream')
        for u in (-14.3,14.3): local(f'House/Corner{u}',26.65,9.9,u,0.7,17,1.1,'cream')
        local('House/DoorFrame',26.5,5,-9,0.9,9.5,5.7,'white')
        local('House/Door',25.95,4.8,-9,0.3,8.5,4.5,palette[(row+3)%8])
        local('House/DoorInset',25.75,6,-9,0.15,3.2,3.2,'glass',collide=False)
        local('House/DoorHandle',25.5,4.3,-7.5,0.25,0.5,0.3,'yellow',collide=False)
        local('House/Canopy',24.6,10.3,-9,5,0.5,8,'cream')
        local('House/CanopyAccent',22.05,10.3,-9,0.2,0.55,8,palette[(row+3)%8])
        local('House/Step',24.8,0.6,-9,4,0.8,7,'cream')
        for j,(u,y,w,h) in enumerate([(5,6.7,11,7),(-8,14,7,4.6),(5,14,11,4.6)]):
            local(f'House/WindowFrame{j}',26.5,y,u,0.7,h+0.8,w+0.8,'white')
            local(f'House/WindowGlass{j}',26.05,y,u,0.2,h,w,'glass',collide=False)
            local(f'House/WindowMullion{j}',25.9,y,u,0.2,h,0.35,'white',collide=False)
        # Side window and simple rear trim give the shell a finished silhouette.
        for u in (-15.12,15.12):
            local(f'House/SideFrame{u}',42,10,u,8,6,0.4,'white')
            local(f'House/SideGlass{u}',42,10,u*1.015,7,5,0.2,'glass',collide=False)
        local('VerityPlatform',12,0.35,9,17,0.7,17,'cream')
        local('PlatformInset',12,0.73,9,14,0.06,14,palette[row],collide=False)
        # Border studs keep the central Verity anchor flat and free for future placement.
        for a,b in [(-6,-6),(0,-6),(6,-6),(-6,6),(0,6),(6,6),(-6,0),(6,0)]:
            stud(root+f'/PlatformStud{a}_{b}',side*(37+a),1.085,z+9+b,1.7,palette[row])
        local('UpgradeStation',5,1,19,3,2,2.5,palette[row])
        local('OwnerSign',2,2.7,-19,0.8,3.6,5,'cream')
        local('SignPost',2,1,-19,0.6,2,0.6,'wood')
        # Invisible integration anchors. No per-lot SpawnLocation until Core assigns ownership.
        for name,v,y,u in [('DeliveryPoint',8,1,-15),('SpawnPoint',5,3,-9),('VerityOrigin',12,0.8,9)]:
            local('Markers/'+name,v,y,u,1,1,1,'white',collide=False,alpha=1)
        for u in (-20,20):
            tree(root+f'/Tree{u}',side*85,z+u,0.72)
        for u in (-19,19):
            local(f'Hedge{u}',40,1.5,u,18,3,3,'leaf',collide=False)
        # Chunky flowers add color without external meshes or textures.
        local('FlowerBed',23,0.6,18,8,1.2,3,'cream')
        for j in range(3):
            local(f'FlowerStem{j}',20.5+j*2.5,1.7,18,0.3,1.6,0.3,'leaf',collide=False)
            local(f'Flower{j}',20.5+j*2.5,2.6,18,1.6,1.6,1.6,('pink','yellow','lilac')[j],collide=False)
        plots.append(dict(id=pid,x=side*57,z=z,minX=min(side*25,side*89),maxX=max(side*25,side*89),minZ=z-24,maxZ=z+24))

for side in (-1,1):
    for i,z in enumerate((-168,-72,24,120)):
        p=env+f'/Lamp{side}_{i}';folder(p)
        part(p+'/Post',(side*21.2,6,z),(0.65,12,0.65),'navy')
        part(p+'/Head',(side*21.2,12.5,z),(2.8,1.5,2.8),'yellow')
        part(p+'/Cap',(side*21.2,13.4,z),(3.3,0.35,3.3),'blue')

part('GeneratedWorld/Plaza/WelcomePad',(0,0.35,-227),(24,0.7,16),'mint')
part('GeneratedWorld/Plaza/WelcomeSpawn',(0,0.9,-227),(8,1,8),'mint',alpha=1,cls='SpawnLocation')
part('GeneratedWorld/Plaza/SignPostLeft',(-10,6,-238),(0.7,12,0.7),'wood')
part('GeneratedWorld/Plaza/SignPostRight',(10,6,-238),(0.7,12,0.7),'wood')
part('GeneratedWorld/Plaza/WelcomeSign',(0,11,-238),(23,5,0.8),'cream')

# Roblox XML serialization: the model and place use exactly the same geometry as the builder.
refs=0
def prop(parent,tag,name,value):
    q=E.SubElement(parent,tag,name=name);q.text=str(value);return q
def xmlmodel():
    global refs
    root=E.Element('roblox',version='4'); E.SubElement(root,'External').text='null'; E.SubElement(root,'External').text='nil'
    return root
def item(parent,cls,name):
    global refs
    refs+=1; q=E.SubElement(parent,'Item',{'class':cls,'referent':f'RBX{refs}'}); p=E.SubElement(q,'Properties');prop(p,'string','Name',name);return q,p
def populate(root):
    lookup={}
    for n in nodes:
        parpath,_,name=n['path'].rpartition('/')
        q,p=item(lookup.get(parpath,root),n['cls'],name);lookup[n['path']]=q
        if 'pos' not in n: continue
        for k,v in [('Anchored',True),('CanCollide',n['collide']),('CanTouch',False),('CanQuery',n['alpha']<1),('CastShadow',n['alpha']<1)]: prop(p,'bool',k,str(v).lower())
        prop(p,'float','Transparency',n['alpha']);prop(p,'float','Reflectance',0)
        prop(p,'token','Material',256);prop(p,'token','TopSurface',0);prop(p,'token','BottomSurface',0)
        if n['cls']=='Part':prop(p,'token','shape',{'Ball':0,'Block':1,'Cylinder':2}[n['shape']])
        prop(p,'Color3uint8','Color3uint8',0xFF000000 | int(n['color'],16))
        size=E.SubElement(p,'Vector3',name='size')
        for k,v in zip(('X','Y','Z'),n['size']):E.SubElement(size,k).text=str(v)
        cf=E.SubElement(p,'CoordinateFrame',name='CFrame')
        for k,v in zip(('X','Y','Z'),n['pos']):E.SubElement(cf,k).text=str(v)
        rotation=((0,-1,0),(1,0,0),(0,0,1)) if n.get('upright') else ((1,0,0),(0,1,0),(0,0,1))
        for a in range(3):
            for b in range(3):E.SubElement(cf,f'R{a}{b}').text=str(rotation[a][b])
        if n['cls']=='SpawnLocation':
            prop(p,'bool','Neutral','true');prop(p,'float','Duration',0);prop(p,'bool','AllowTeamChangeOnTouch','false')
    return lookup

model=xmlmodel();populate(model);E.ElementTree(model).write(OUT/'VerityNeighborhood.rbxmx',encoding='utf-8',xml_declaration=True)
place=xmlmodel();ws,p=item(place,'Workspace','Workspace');prop(p,'bool','StreamingEnabled','true');populate(ws)
lighting,p=item(place,'Lighting','Lighting');prop(p,'float','ClockTime',13.5);prop(p,'float','Brightness',2);prop(p,'bool','GlobalShadows','true');prop(p,'float','ShadowSoftness',0.4)
for name,values in [('Ambient',(0.62,0.65,0.72)),('OutdoorAmbient',(0.7,0.72,0.76))]:
    v=E.SubElement(p,'Color3',name=name)
    for k,x in zip(('R','G','B'),values):E.SubElement(v,k).text=str(x)
E.ElementTree(place).write(OUT/'VerityNeighborhood.rbxlx',encoding='utf-8',xml_declaration=True)

# Compact recipe and configurable Luau generator. It translates plot pairs into new rows.
recipe=[]
for n in nodes:
    m=n.copy();m['path']=m['path'].removeprefix('GeneratedWorld').lstrip('/');recipe.append(m)
def lua(v):
    if isinstance(v,str):return json.dumps(v)
    if isinstance(v,bool):return str(v).lower()
    if isinstance(v,(int,float)):return str(v)
    if isinstance(v,(list,tuple)):return '{'+','.join(lua(x) for x in v)+'}'
    return '{'+','.join(k+'='+lua(x) for k,x in v.items())+'}'
(OUT/'src/world/MapRecipe.luau').write_text('-- Generated geometry recipe; no external assets.\nreturn '+lua(recipe)+'\n')
(OUT/'src/world/WorldBuilder.luau').write_text('''--!strict
local Recipe = require(script.Parent.MapRecipe)
local WorldBuilder = {}
local VERSION = "brick-neighborhood-3"

function WorldBuilder.Build(parent: Instance?, plotCount: number?): Model
    local target = parent or workspace
    local count = plotCount or 16
    assert(count >= 16 and count <= 128 and count % 2 == 0, "PlotCount must be even, 16..128")
    local existing = target:FindFirstChild("GeneratedWorld")
    if existing then
        assert(existing:IsA("Model"), "GeneratedWorld name is occupied")
        if existing:GetAttribute("BuilderVersion") == VERSION and existing:GetAttribute("PlotCount") == count then
            return existing
        end
        error("GeneratedWorld already exists; preserve it or remove it explicitly before building")
    end
    local root = Instance.new("Model")
    root.Name = "GeneratedWorld"
    root:SetAttribute("BuilderVersion", VERSION)
    root:SetAttribute("PlotCount", count)
    local objects: {[string]: Instance} = {[""] = root}
    local function create(n: any, path: string, offset: Vector3?)
        local parentPath = path:match("^(.*)/[^/]+$") or ""
        local obj = Instance.new(n.cls) :: any
        obj.Name = path:match("[^/]+$") or "GeneratedWorld"
        if n.pos then
            obj.Anchored = true
            obj.CanCollide = n.collide
            obj.CanTouch = false
            obj.CanQuery = n.alpha < 1
            obj.CastShadow = n.alpha < 1
            obj.Material = Enum.Material.SmoothPlastic
            obj.TopSurface = Enum.SurfaceType.Smooth
            obj.BottomSurface = Enum.SurfaceType.Smooth
            obj.Size = Vector3.new(n.size[1], n.size[2], n.size[3])
            obj.CFrame = CFrame.new(Vector3.new(n.pos[1], n.pos[2], n.pos[3]) + (offset or Vector3.zero))
            if n.upright then obj.CFrame *= CFrame.Angles(0, 0, math.pi/2) end
            obj.Color = Color3.fromHex(n.color)
            obj.Transparency = n.alpha
            if obj:IsA("Part") then obj.Shape = Enum.PartType[n.shape] end
            if obj:IsA("SpawnLocation") then obj.Neutral = true; obj.Duration = 0 end
        end
        obj.Parent = assert(objects[parentPath], "Missing parent " .. parentPath)
        objects[path] = obj
        return obj
    end
    -- Environment adapts to the chosen number of pairs. Recipe positions represent 8 pairs.
    local extra = (count / 2 - 8) * 48
    for _, n in Recipe do
        if n.path ~= "" and not n.path:match("^Plots/Plot_") then
            local obj = create(n, n.path)
            if obj:IsA("BasePart") then
                if n.path == "Environment/Ground" then obj.Size += Vector3.new(0, 0, extra)
                elseif n.path:match("^Environment/Sidewalk") or n.path:match("^Environment/Curb") or n.path:match("^Environment/OuterGreen") or n.path == "Environment/Road" then
                    obj.Size += Vector3.new(0, 0, extra)
                elseif n.path:match("^Plaza/") or n.path:match("^Environment/EndPath") or n.path:match("^Environment/ParkTree") or n.path:match("^Environment/Bench") or n.path:match("^Environment/Crosswalk") then
                    local sign = if obj.Position.Z < 0 then -1 else 1
                    obj.CFrame += Vector3.new(0,0,sign*extra/2)
                elseif (n.path:match("RoadDash") or n.path:match("Lamp")) and math.abs(obj.Position.Z) > 192 + extra/2 then
                    obj:Destroy()
                end
            end
        end
    end
    for id = 1, count do
        local templateId = ((id - 1) % 16) + 1
        local sourcePrefix = string.format("Plots/Plot_%02d", templateId)
        local destination = string.format("Plots/Plot_%02d", id)
        local sourceRow = math.floor((templateId-1)/2)
        local row = math.floor((id-1)/2)
        local offset = Vector3.new(0,0,(row-(count/2-1)/2)*48 - (sourceRow-3.5)*48)
        for _, n in Recipe do
            if n.path == sourcePrefix or n.path:sub(1,#sourcePrefix+1) == sourcePrefix .. "/" then
                local obj = create(n, destination .. n.path:sub(#sourcePrefix+1), offset)
                if n.path == sourcePrefix then obj:SetAttribute("PlotId", id) end
            end
        end
    end
    root.Parent = target
    return root
end

return WorldBuilder
''')
(OUT/'src/server/MapBootstrap.server.luau').write_text('''-- Standalone map preview. Integrators can call WorldBuilder.Build themselves.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local WorldBuilder = require(ReplicatedStorage:WaitForChild("World"):WaitForChild("WorldBuilder"))
WorldBuilder.Build(workspace, 16)
Lighting.ClockTime = 13.5
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(158, 166, 184)
Lighting.OutdoorAmbient = Color3.fromRGB(179, 184, 194)
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.4
''')
(OUT/'default.project.json').write_text(json.dumps({'name':'VerityNeighborhood','tree':{'$className':'DataModel','ReplicatedStorage':{'World':{'$path':'src/world'}},'ServerScriptService':{'MapBootstrap':{'$path':'src/server/MapBootstrap.server.luau'}},'Workspace':{'$properties':{'StreamingEnabled':True}}}},indent=2))

# Meaningful static spatial checks: house/yard reservation fits, neighbors do not overlap.
assert len(plots)==16
for i,a in enumerate(plots):
    for b in plots[i+1:]:
        assert not (a['minX']<b['maxX'] and b['minX']<a['maxX'] and a['minZ']<b['maxZ'] and b['minZ']<a['maxZ'])
for p in plots:
    prefix=f"GeneratedWorld/Plots/Plot_{p['id']:02}/"
    for name in ('House','VerityPlatform','UpgradeStation','OwnerSign','Markers/SpawnPoint','Markers/DeliveryPoint'):
        assert any(n['path']==prefix+name for n in nodes)
    for n in nodes:
        if n['path'].startswith(prefix) and 'pos' in n:
            x,y,z=n['pos'];sx,sy,sz=n['size']
            if n.get('upright'):sx,sy=sy,sx
            assert x-sx/2>=p['minX']-0.01 and x+sx/2<=p['maxX']+0.01, n['path']
            assert z-sz/2>=p['minZ']-0.01 and z+sz/2<=p['maxZ']+0.01,n['path']

# Isometric geometry preview; not a Roblox Studio screenshot.
def preview(filename,zoom=1,focus=None):
    width,height=1800,1300; scale=2.15*zoom
    def project(x,y,z):return (width/2+(x-z*0.52)*scale,height/2+(x*.27+z*.47-y)*scale)
    canvas=Image.new('RGB',(width,height),'#E9F0F5');draw=ImageDraw.Draw(canvas)
    faces=[]
    for n in nodes:
        if 'pos' not in n or n['alpha']>=1:continue
        x,y,z=n['pos'];sx,sy,sz=n['size']
        if focus:
            if sz<130 and (abs(z-focus[2])>65 or abs(x-focus[0])>100):continue
            x-=focus[0];z-=focus[2]
        color=tuple(int(n['color'][i:i+2],16) for i in (0,2,4))
        if n['shape']=='Cylinder':
            # Upright studs: polygon rings match the real cylinder bounds.
            rings=[[(x+sy/2*math.cos(k*math.pi/6),y+dy,z+sz/2*math.sin(k*math.pi/6)) for k in range(12)] for dy in (-sx/2,sx/2)]
            for k in range(12):
                ps=[rings[0][k],rings[0][(k+1)%12],rings[1][(k+1)%12],rings[1][k]]
                faces.append((0,ps,tuple(int(c*.83) for c in color)))
                faces.append((0,[rings[1][k],rings[1][(k+1)%12],(x,y+sx/2,z)],color))
            continue
        if n['shape']=='Ball':
            # Low-poly ellipsoid matches the simple rounded foliage intention.
            verts=[]
            for j in range(1,5):
                lat=-math.pi/2+j*math.pi/5
                verts.append([(x+sx/2*math.cos(lat)*math.cos(k*math.pi/4),y+sy/2*math.sin(lat),z+sz/2*math.cos(lat)*math.sin(k*math.pi/4)) for k in range(8)])
            for j in range(3):
                for k in range(8):
                    ps=[verts[j][k],verts[j][(k+1)%8],verts[j+1][(k+1)%8],verts[j+1][k]]
                    faces.append((sum(p[0]+p[2] for p in ps)/4,ps,tuple(int(c*(.82+j*.055)) for c in color)))
            for ring,yy in [(verts[0],y-sy/2),(verts[-1],y+sy/2)]:
                for k in range(8):
                    ps=[ring[k],ring[(k+1)%8],(x,yy,z)];faces.append((sum(p[0]+p[2] for p in ps)/3,ps,color))
            continue
        # Visible top and front faces for an orthographic view from negative X/Z.
        x0,x1=x-sx/2,x+sx/2;y0,y1=y-sy/2,y+sy/2;z0,z1=z-sz/2,z+sz/2
        for ps,factor in [([(x0,y1,z0),(x1,y1,z0),(x1,y1,z1),(x0,y1,z1)],1.0), ([(x0,y0,z1),(x1,y0,z1),(x1,y1,z1),(x0,y1,z1)],.81), ([(x1,y0,z0),(x1,y0,z1),(x1,y1,z1),(x1,y1,z0)],.9)]:
            depth=sum(p[0]+p[2]+p[1]*.02 for p in ps)/4
            faces.append((depth,ps,tuple(int(c*factor) for c in color)))
    pixels=np.array(canvas); depthbuffer=np.full((height,width),-np.inf,dtype=np.float32)
    for _,ps,col in faces:
        for k in range(1,len(ps)-1):
            points=[ps[0],ps[k],ps[k+1]]; uv=np.array([project(*p) for p in points]); depths=np.array([.52*p[0]+.6104*p[1]+p[2] for p in points])
            xmin=max(0,int(np.floor(uv[:,0].min())));xmax=min(width-1,int(np.ceil(uv[:,0].max())))
            ymin=max(0,int(np.floor(uv[:,1].min())));ymax=min(height-1,int(np.ceil(uv[:,1].max())))
            if xmax<xmin or ymax<ymin:continue
            a,b,c=uv;den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
            if abs(den)<1e-8:continue
            xx,yy=np.meshgrid(np.arange(xmin,xmax+1)+.5,np.arange(ymin,ymax+1)+.5)
            w0=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den
            w1=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den;w2=1-w0-w1
            dep=w0*depths[0]+w1*depths[1]+w2*depths[2]
            view=depthbuffer[ymin:ymax+1,xmin:xmax+1];mask=(w0>=-1e-6)&(w1>=-1e-6)&(w2>=-1e-6)&(dep>view)
            view[mask]=dep[mask];pixels[ymin:ymax+1,xmin:xmax+1][mask]=col
    canvas=Image.fromarray(pixels);draw=ImageDraw.Draw(canvas)
    draw.rounded_rectangle((40,35,650,115),radius=14,fill='white')
    draw.text((65,54),'VERITY / BRICK NEIGHBORHOOD',fill='#34445D',font=font(26, True))
    draw.text((65,88),'GEOMETRY PREVIEW - NOT A STUDIO SCREENSHOT',fill='#64748B',font=font(13))
    canvas.save(OUT/filename)
preview('map-overview.png')
preview('houses-preview.png',1.8,(0,0,-120))
for path in (OUT/'VerityNeighborhood.rbxmx',OUT/'VerityNeighborhood.rbxlx'):
    E.parse(path)
(OUT/'validation.json').write_text(json.dumps({'plots':16,'parts':sum('pos'in n for n in nodes),'plotFootprint':[64,48],'houseFootprint':[28,30],'reservedVerityPad':[17,17],'checks':['16 unique plots','non-overlapping lot bounds','all lot geometry within bounds','required integration anchors present','XML parses'],'studioPlaytest':'not run'},indent=2))
print((OUT/'validation.json').read_text())
