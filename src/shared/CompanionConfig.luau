--!strict
local Config={IndoorMaxScale=2.25,TeleportDistance=80,Smoothing=8,RoofClearance=2,
 RayInterval=0.25,EnvelopeRadius=1.15,CameraMargin=2}
function Config.Offset(scale:number,plotId:number): (number,number,number)
 local side=if plotId%2==0 then -1 else 1
 return side*(3+scale*1.2),1.1,2+scale*0.5+(plotId%4)*0.65
end
function Config.Blend(dt:number): number
 return 1-math.exp(-Config.Smoothing*math.clamp(dt,0,0.25))
end
return table.freeze(Config)
