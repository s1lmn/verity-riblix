--!nonstrict
-- Shared course and display coordinates. Only FusionService advances a run.
local Layout=require(script.Parent.WorldLayout)
local C={Version=2,Hub=Vector3.new(-110,.55,333+Layout.EndShift),TrackX=-620,TrackY=0,
 StartZ=-140,EndZ=900,HalfWidth=23,Radius=5.65,Speed=12,BoostSpeed=18,BoostSeconds=1.1,BoostCooldown=6,
 JumpSpeed=25,Gravity=46,JoinReach=9,QueueReach=22,QueueSeconds=45,MergeSeconds=3.8,RunSeconds=165,
 RetrySeconds=1.25,MaxFaults=8,ResultSeconds=4,InputTimeout=.35,PublishInterval=.08,Reward="fusion_charms"}
C.Sections={{Name="Синхронизация",Z=-140,Color="7CE5CE"},{Name="Звёздный каньон",Z=110,Color="9CCBFF"},{Name="Сад импульсов",Z=375,Color="D6ADFF"},{Name="Финальный разгон",Z=645,Color="FFD98A"}}
C.Obstacles=table.freeze({
 {kind="Gate",z=-80,half=1.4,opening=-9}, {kind="Bar",z=-28,half=1.1,height=1.8},
 {kind="Gap",z=35,half=2.8}, {kind="Gate",z=91,half=1.4,opening=9},
 {kind="Bumper",z=150,half=2.5,height=2.7,phase=0}, {kind="Gap",z=211,half=3.6},
 {kind="Gate",z=264,half=1.4,opening=-9}, {kind="Bar",z=320,half=1.2,height=2.8},
 {kind="Bumper",z=390,half=2.5,height=3.1,phase=1.7}, {kind="Gate",z=445,half=1.4,opening=9},
 {kind="Gap",z=505,half=4.1}, {kind="Bar",z=565,half=1.2,height=3.0},
 {kind="Gate",z=624,half=1.4,opening=-9}, {kind="Bumper",z=684,half=2.5,height=3.2,phase=3.2},
 {kind="Gap",z=745,half=3.9}, {kind="Gate",z=803,half=1.4,opening=9},
 {kind="Bar",z=855,half=1.2,height=3.1},
})
for _,obstacle in C.Obstacles do table.freeze(obstacle) end
C.OpeningHalf=10.8
function C.BumperX(now,o) return math.sin(now*1.05+(o and o.phase or 0))*12 end
function C.IsGap(z,margin)
 for _,o in C.Obstacles do if o.kind=="Gap" and math.abs(z-o.z)<o.half+(margin or 0) then return true end end
 return false
end
function C.Section(z)
 local section=C.Sections[1];for _,v in C.Sections do if z>=v.Z then section=v end end;return section
end
function C.Pose(x,z,y,yaw)
 return CFrame.new(C.TrackX+x,C.TrackY+y,z)*CFrame.Angles(0,math.pi+yaw,0)
end
function C.Seat(slot,solo)
 return CFrame.new(if solo then 0 else (slot-1.5)*4.3,13.1,0)
end
function C.MergePose() return CFrame.new(C.Hub+Vector3.new(0,.35,0))*CFrame.Angles(0,math.pi,0) end
function C.ObstacleHit(o,x,z,y,now)
 local distance=math.abs(z-o.z)
 if o.kind=="Gap" then return distance<=o.half and y<.22 end
 if distance>o.half+1.15 then return false end
 if o.kind=="Gate" then return math.abs(x-o.opening)>C.OpeningHalf-C.Radius end
 if o.kind=="Bumper" then return y<o.height and math.abs(x-C.BumperX(now,o))<C.Radius+2.4 end
 return y<o.height
end
return table.freeze(C)
