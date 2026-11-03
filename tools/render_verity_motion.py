"""Animation sketch from the same motion parameters; not a Studio capture."""
from pathlib import Path
import json, math
from PIL import Image, ImageDraw, ImageFont
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/verity'
defs=json.loads((OUT/'definitions.json').read_text());poster=Image.open(OUT/'verity-first-ten.png').convert('RGB')
try:font=ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf',17)
except OSError:font=ImageFont.load_default()
icons=[]
for i in range(10):
    x=(i%5)*320;y=65+(i//5)*370
    icons.append(poster.crop((x+10,y,x+310,y+300)).resize((220,220),Image.Resampling.LANCZOS))
frames=[]
for tick in range(60):
    time=tick/20
    im=Image.new('RGB',(1200,650),'#EFF4FA');d=ImageDraw.Draw(im)
    d.text((25,15),'VERITY 01–10 / MOTION SKETCH — NOT STUDIO',font=font,fill='#263455')
    for i,definition in enumerate(defs):
        phase=time*definition['Speed']*2
        wave=(math.sin(phase)+1)/2;bob=definition['Bob']*wave;roll=math.sin(phase*.75)*.035
        motion=definition['Motion']
        if motion=='Hop':bob=definition['Bob']*max(0,math.sin(phase))**2
        if motion=='DoubleHop':bob=definition['Bob']*abs(math.sin(phase*1.5))**3
        if motion=='Tilt':roll=math.sin(phase)*.12
        if motion=='Rock':roll=math.sin(phase)*.07
        if motion=='Sway':roll=math.sin(phase)*.075
        x=(i%5)*240;y=55+(i//5)*290
        progress=max(0,min(1,(time-.35)/.75));pop=1+.14*math.sin(math.pi*progress)*math.exp(-2*progress)
        tile=icons[i].resize((round(220*pop),round(220*pop)),Image.Resampling.LANCZOS)
        tile=tile.rotate(-roll*180/math.pi,Image.Resampling.BICUBIC,expand=False,fillcolor='#EFF4FA')
        im.paste(tile,(x+120-tile.width//2,y+235-tile.height-round(bob*45)))
        if definition['Special']:
            color='#62F7FF' if i==4 else '#FFD75A'
            for j in range(12):
                a=j*math.pi/6+time*.65
                cx=x+120+93*math.cos(a);cy=y+228+12*math.sin(a)
                d.ellipse((cx-2.5,cy-2.5,cx+2.5,cy+2.5),fill=color)
        d.text((x+16,y+247),f'{i+1:02}  {definition["Name"]}',font=font,fill='#263455')
    frames.append(im)
palette=frames[0].quantize(colors=256)
frames=[frame.quantize(palette=palette,dither=Image.Dither.NONE) for frame in frames]
frames[0].save(OUT/'verity-motion-sketch.gif',save_all=True,append_images=frames[1:],duration=50,loop=0,disposal=2,optimize=False)
print('Motion sketch saved; exact engine appearance must still be checked in Studio.')
