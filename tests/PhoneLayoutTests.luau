local L=require("../src/client/PhoneLayout")
for _,size in {{320,568},{360,640},{390,844},{568,320},{720,360},{844,390},{1024,768},{1920,1080}} do
 local w,h=size[1],size[2]
 local p=L.Measure(w,h)
 assert(p.x>=0 and p.y>=0 and p.x+p.width<=w and p.y+p.height<=h)
 assert(p.bodyTop+p.bodyH<=p.height-48)
 assert(p.artW>0 and p.artH>=150 and p.controlsW>=100)
 assert(p.controlsY+p.controlsH<=p.contentH)
 assert(p.controlsX+p.controlsW<=p.bodyW)
 if p.landscape then assert(p.controlsX>=p.artW+8) else assert(p.controlsY>=p.artH+8) end
 assert(p.contentH>=p.bodyH)
end
print('Phone layout: 8 portrait/landscape/desktop sizes, separate art/controls, screen bounds and scrolling passed')
