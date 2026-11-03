from pathlib import Path
import json,base64,zipfile,shutil
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/verity-hero';dest=ROOT.parents[1]/'outputs';dest.mkdir(exist_ok=True)
v=[];n=[];uv=[];faces=[]
for line in (OUT/'VerityHero.obj').read_text().splitlines():
 s=line.split()
 if not s:continue
 if s[0]=='v':p=list(map(float,s[1:]));v+=p;n += [x/1.4 for x in p]
 if s[0]=='vt':uv+=list(map(float,s[1:]))
 if s[0]=='f':faces += [int(x.split('/')[0])-1 for x in s[1:]]
emotions=json.loads((OUT/'manifest.json').read_text())['emotions']
textures={e:'data:image/png;base64,'+base64.b64encode((OUT/'textures'/f'{e}.png').read_bytes()).decode() for e in emotions}
html='''<!doctype html><html lang="ru"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Verity — actual mesh</title><style>*{box-sizing:border-box}body{margin:0;background:#10121d;color:#faf8ee;font:16px system-ui}header{padding:22px 28px}h1{margin:0 0 5px;font-size:25px}p{margin:0;color:#b1b7ca}canvas{display:block;width:100%;height:65vh;touch-action:none}nav{display:flex;gap:9px;justify-content:center;flex-wrap:wrap;padding:15px}button{background:#25293c;color:#fff;border:1px solid #454c69;border-radius:13px;padding:12px 17px;cursor:pointer}button.active{background:#ffda21;color:#211421;border-color:#ffda21}footer{text-align:center;padding:12px;color:#a6adc2;font-size:13px}</style><header><h1>VERITY — базовая модель</h1><p>Один меш · 2 208 треугольников · 8 сменных текстур. Поверни шарик мышью или пальцем.</p></header><canvas id="view"></canvas><nav id="buttons"></nav><footer>Интерактивный просмотр фактического OBJ и его текстур. Это WebGL, не Roblox Studio.</footer><script>
const V=VERTICES,N=NORMALS,U=UVS,I=INDICES,T=TEXTURES;
const c=document.querySelector('canvas'),g=c.getContext('webgl',{antialias:true});if(!g)throw Error('WebGL unavailable');
function shader(type,src){let s=g.createShader(type);g.shaderSource(s,src);g.compileShader(s);if(!g.getShaderParameter(s,g.COMPILE_STATUS))throw Error(g.getShaderInfoLog(s));return s}
const vs=shader(g.VERTEX_SHADER,`attribute vec3 p,n;attribute vec2 uv;uniform float yaw,pitch,aspect;varying vec2 t;varying vec3 norm;vec3 turn(vec3 v){float a=cos(yaw),b=sin(yaw),d=cos(pitch),e=sin(pitch);vec3 q=vec3(a*v.x+b*v.z,v.y,-b*v.x+a*v.z);return vec3(q.x,d*q.y-e*q.z,e*q.y+d*q.z);}void main(){vec3 q=turn(p);norm=turn(n);t=uv;gl_Position=vec4(q.x/(1.8*aspect),q.y/1.8,q.z/8.,1.);}`);
const fs=shader(g.FRAGMENT_SHADER,`precision mediump float;varying vec2 t;varying vec3 norm;uniform sampler2D skin;void main(){vec3 nn=normalize(norm),l=normalize(vec3(-.4,.65,-.68)),h=normalize(l+vec3(0.,0.,-1.));vec3 col=texture2D(skin,t).rgb;col*=.72+.28*max(0.,dot(nn,l));col+=.09*pow(max(0.,dot(nn,h)),32.);gl_FragColor=vec4(col,1.);}`);
const prog=g.createProgram();g.attachShader(prog,vs);g.attachShader(prog,fs);g.linkProgram(prog);g.useProgram(prog);
function attrib(name,arr,size){let b=g.createBuffer();g.bindBuffer(g.ARRAY_BUFFER,b);g.bufferData(g.ARRAY_BUFFER,new Float32Array(arr),g.STATIC_DRAW);let a=g.getAttribLocation(prog,name);g.enableVertexAttribArray(a);g.vertexAttribPointer(a,size,g.FLOAT,false,0,0)}attrib('p',V,3);attrib('n',N,3);attrib('uv',U,2);
let ib=g.createBuffer();g.bindBuffer(g.ELEMENT_ARRAY_BUFFER,ib);g.bufferData(g.ELEMENT_ARRAY_BUFFER,new Uint16Array(I),g.STATIC_DRAW);g.enable(g.DEPTH_TEST);g.clearColor(.063,.071,.114,1);let yaw=0,pitch=0,ready=false;
let tex=g.createTexture();g.bindTexture(g.TEXTURE_2D,tex);g.texParameteri(g.TEXTURE_2D,g.TEXTURE_MIN_FILTER,g.LINEAR);g.texParameteri(g.TEXTURE_2D,g.TEXTURE_MAG_FILTER,g.LINEAR);g.texParameteri(g.TEXTURE_2D,g.TEXTURE_WRAP_S,g.CLAMP_TO_EDGE);g.texParameteri(g.TEXTURE_2D,g.TEXTURE_WRAP_T,g.CLAMP_TO_EDGE);
function draw(){if(!ready)return;const d=Math.min(devicePixelRatio,2);c.width=Math.round(c.clientWidth*d);c.height=Math.round(c.clientHeight*d);g.viewport(0,0,c.width,c.height);g.uniform1f(g.getUniformLocation(prog,'yaw'),yaw);g.uniform1f(g.getUniformLocation(prog,'pitch'),pitch);g.uniform1f(g.getUniformLocation(prog,'aspect'),c.width/c.height);g.clear(g.COLOR_BUFFER_BIT|g.DEPTH_BUFFER_BIT);g.drawElements(g.TRIANGLES,I.length,g.UNSIGNED_SHORT,0)}
let token=0;function face(name){let request=++token;const img=new Image();img.onload=()=>{if(request!==token)return;g.pixelStorei(g.UNPACK_FLIP_Y_WEBGL,true);g.texImage2D(g.TEXTURE_2D,0,g.RGBA,g.RGBA,g.UNSIGNED_BYTE,img);ready=true;draw()};img.src=T[name];document.querySelectorAll('button').forEach(b=>b.classList.toggle('active',b.dataset.face===name))}
const labels={Joy:'Радость',Love:'Любовь',Playful:'Язык',Wink:'Подмигивание',Laugh:'Смех',Surprise:'Удивление',Confident:'Уверенность',Stars:'Восторг'};for(const name of Object.keys(T)){let b=document.createElement('button');b.dataset.face=name;b.textContent=labels[name];b.onclick=()=>face(name);document.querySelector('nav').append(b)}
let last=null;c.onpointerdown=e=>{last=[e.clientX,e.clientY];c.setPointerCapture(e.pointerId)};c.onpointermove=e=>{if(!last)return;yaw+=(e.clientX-last[0])*.008;pitch=Math.max(-1.2,Math.min(1.2,pitch+(e.clientY-last[1])*.008));last=[e.clientX,e.clientY];draw()};c.onpointerup=c.onpointercancel=()=>last=null;window.onresize=draw;face('Joy');
</script></html>'''
for k,a in [('VERTICES',v),('NORMALS',n),('UVS',uv),('INDICES',faces),('TEXTURES',textures)]:html=html.replace(k,json.dumps(a,separators=(',',':')))
(OUT/'VerityHero_Review.html').write_text(html)
# Validate exact external data shape before delivery.
assert len(v)//3==len(n)//3==len(uv)//2
assert len(faces)==2208*3 and max(faces)<len(v)//3
assert len(textures)==8
for filename in ['VerityHero.glb','actual-mesh-front.png','actual-mesh-emotions.png','VerityHero_Review.html']:
 shutil.copy(OUT/filename,dest/filename)
print('Packaged actual mesh review, eight textures, OBJ and GLB. No Roblox asset IDs invented.')
