from pathlib import Path
import math
import numpy as np
from PIL import Image, ImageDraw, ImageFont

def font(size, bold=False):
    names = ['/System/Library/Fonts/Supplemental/Arial Bold.ttf' if bold else '/System/Library/Fonts/Supplemental/Arial.ttf', 'DejaVuSans-Bold.ttf' if bold else 'DejaVuSans.ttf']
    for name in names:
        try: return ImageFont.truetype(name, size)
        except OSError: pass
    return ImageFont.load_default()

def preview(filename, nodes, output_dir, zoom=1, focus=None):
    width,height=1800,1300; scale=2.15*zoom
    def project(x,y,z):return (width/2+(x-z*0.52)*scale,height/2+80+(x*.27+z*.47-y)*scale)
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
            faces.append((depth,ps,tuple(int(c*factor) for c in color),n.get('topSurface')=='Studs' and factor==1.0))
    pixels=np.array(canvas); depthbuffer=np.full((height,width),-np.inf,dtype=np.float32)
    for face in faces:
        _,ps,col=face[:3]
        patterned=len(face)>3 and face[3]
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
            view[mask]=dep[mask]
            target=pixels[ymin:ymax+1,xmin:xmax+1]
            if patterned:
                # Approximation of classic Roblox square studs for this software preview.
                # The exported map uses native TopSurface, not a texture or extra Parts.
                wx=w0*points[0][0]+w1*points[1][0]+w2*points[2][0]
                wz=w0*points[0][2]+w1*points[1][2]+w2*points[2][2]
                u=np.mod(wx,2)/2;v=np.mod(wz,2)/2
                inside=(u>.22)&(u<.78)&(v>.22)&(v<.78)
                light=inside&((u<.32)|(v<.32))
                shadow=inside&((u>.66)|(v>.66))
                shade=np.where(shadow,.77,np.where(light,1.12,np.where(inside,1.035,1.0)))
                colors=np.clip(np.asarray(col)[None,None,:]*shade[:,:,None],0,255).astype(np.uint8)
                target[mask]=colors[mask]
            else:
                target[mask]=col
    canvas=Image.fromarray(pixels);draw=ImageDraw.Draw(canvas)
    draw.rounded_rectangle((40,35,650,115),radius=14,fill='white')
    draw.text((65,54),'VERITY / STANDARD INTERIOR',fill='#34445D',font=font(26, True))
    draw.text((65,88),'GEOMETRY PREVIEW - NOT A STUDIO SCREENSHOT',fill='#64748B',font=font(13))
    canvas.save(output_dir/filename)
