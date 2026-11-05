--!strict
local Layout=require(script.Parent.WorldLayout)
local Config={Version=2,ZOffset=Layout.EndShift,RewardSeconds=20,Cooldown=90,MinimumRunSeconds=2,MaximumRunSeconds=180,ResetBelow=4.5}
-- Centres are platform centres; top surfaces are +0.5. Adjacent free edge gaps<=3.5.
Config.Pads=table.freeze({
 {x=184,y=2.5,z=300,w=12,d=12,checkpoint=true},
 {x=198,y=4,z=300,w=10,d=10}, {x=211,y=5.5,z=300,w=10,d=10},
 {x=224,y=7,z=300,w=12,d=12,checkpoint=true},
 {x=237,y=8.5,z=300,w=10,d=10}, {x=250,y=10,z=300,w=10,d=10},
 {x=263,y=11.5,z=300,w=12,d=12,checkpoint=true},
 {x=263,y=13,z=314,w=10,d=10}, {x=250,y=14.5,z=314,w=10,d=10},
 {x=237,y=16,z=314,w=12,d=12,checkpoint=true},
 {x=224,y=17.5,z=314,w=10,d=10}, {x=211,y=19,z=314,w=10,d=10},
 {x=198,y=20.5,z=314,w=14,d=14,finish=true},
})
for _,pad in Config.Pads do pad.z+=Config.ZOffset end
function Config.Contains(x: number,z: number): boolean
 return x>=170 and x<=282 and z>=230+Config.ZOffset and z<=370+Config.ZOffset
end
return table.freeze(Config)
