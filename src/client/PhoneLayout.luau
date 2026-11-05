--!strict
-- Native pixel layout, no UIScale shrinking of touch targets.
local Layout={}
function Layout.Measure(width: number,height: number)
 local landscape=width>height and height<500
 local w=math.min(if landscape then 580 else 350,width-24)
 local h=math.min(650,height-24)
 local hardware=if landscape then 20 else 34
 local header=if landscape then 56 else 74
 local bodyTop=hardware+header+8
 local bodyH=math.max(70,h-bodyTop-54)
 local bodyW=w-36
 local controlsH=218
 local artH=if landscape then math.max(bodyH,controlsH) else math.max(150,bodyH-controlsH-8)
 local contentH=if landscape then math.max(artH,controlsH) else artH+8+controlsH
 return {width=w,height=h,x=math.floor((width-w)/2),y=math.floor((height-h)/2),
  landscape=landscape,hardware=hardware,bodyTop=bodyTop,bodyH=bodyH,bodyW=bodyW,
  artH=artH,contentH=contentH,controlsH=controlsH,
  artW=if landscape then math.floor((bodyW-12)*.53) else bodyW,
  controlsX=if landscape then math.floor((bodyW-12)*.53)+12 else 0,
  controlsY=if landscape then 0 else artH+8,
  controlsW=if landscape then bodyW-math.floor((bodyW-12)*.53)-12 else bodyW}
end
return Layout
