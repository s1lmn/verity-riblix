--!strict
local Layout=require(script.Parent.WorldLayout)
local Config={FirstDelay=45,Interval=240,DriveSeconds=24,ThrowSeconds=.8,PickupSeconds=35,RewardSeconds=15,Reach=8,
 RoadX=6,StartZ=-302-Layout.EndShift,EndZ=302+Layout.EndShift,SidewalkX=20,ParcelY=1.65,DropZ={-144,0,144},Colors={"FFB72D","55DCC9","AE7AF5"}}
function Config.Round(cycle:number,started:number)
 local z=Config.DropZ[(cycle-1)%#Config.DropZ+1]
 local side=if cycle%2==1 then 1 else -1
 local throwAt=started+(z-Config.StartZ)/(Config.EndZ-Config.StartZ)*Config.DriveSeconds
 return {cycle=cycle,started=started,x=side*Config.SidewalkX,z=z,throwAt=throwAt,readyAt=throwAt+Config.ThrowSeconds,
  expiresAt=throwAt+Config.ThrowSeconds+Config.PickupSeconds,color=Config.Colors[(cycle-1)%#Config.Colors+1]}
end
function Config.Sample(round,now:number)
 local drive=math.clamp((now-round.started)/Config.DriveSeconds,0,1)
 local toss=math.clamp((now-round.throwAt)/Config.ThrowSeconds,0,1)
 return {truckZ=Config.StartZ+(Config.EndZ-Config.StartZ)*drive,truckVisible=now>=round.started and now<round.started+Config.DriveSeconds,
  toss=toss,parcelVisible=now>=round.throwAt and now<round.expiresAt,ready=now>=round.readyAt and now<round.expiresAt,
  remaining=math.max(0,math.ceil(round.expiresAt-now))}
end
return table.freeze(Config)
