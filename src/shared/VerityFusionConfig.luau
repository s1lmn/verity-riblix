--!nonstrict
-- Shared course and display coordinates. Only FusionService advances a run.
local Layout=require(script.Parent.WorldLayout)
local C={Version=1,Hub=Vector3.new(-110,.55,333+Layout.EndShift),TrackX=-440,TrackY=18,
 StartZ=-120,EndZ=420,HalfWidth=21,Radius=5.65,Speed=9,BoostSpeed=14,BoostSeconds=1.1,BoostCooldown=6,
 JumpSpeed=22,Gravity=44,JoinReach=9,QueueReach=22,QueueSeconds=45,MergeSeconds=2.6,RunSeconds=95,
 RetrySeconds=1.25,MaxFaults=5,ResultSeconds=4,InputTimeout=.35,PublishInterval=.08,Reward="fusion_charms"}
C.Obstacles=table.freeze({
 table.freeze({kind="Gate",z=-58,half=1.4,opening=-8.5}),
 table.freeze({kind="Gap",z=-4,half=2.75}),
 table.freeze({kind="Bar",z=58,half=1.2,height=2.2}),
 table.freeze({kind="Gate",z=118,half=1.4,opening=8.5}),
 table.freeze({kind="Bumper",z=184,half=3.4,height=3.3}),
 table.freeze({kind="Gap",z=242,half=3.3}),
 table.freeze({kind="Gate",z=305,half=1.4,opening=-8.5}),
 table.freeze({kind="Bar",z=368,half=1.2,height=2.6}),
})
C.OpeningHalf=10
function C.BumperX(now) return math.sin(now*1.45)*11 end
function C.Pose(x,z,y,yaw)
 return CFrame.new(C.TrackX+x,C.TrackY+y,z)*CFrame.Angles(0,math.pi+yaw,0)
end
function C.Seat(slot,solo)
 return CFrame.new(if solo then 0 else (slot-1.5)*4.3,9.25,0)
end
function C.MergePose() return CFrame.new(C.Hub+Vector3.new(0,.35,0))*CFrame.Angles(0,math.pi,0) end
function C.ObstacleHit(o,x,z,y,now)
 local distance=math.abs(z-o.z)
 if o.kind=="Gap" then return distance<=o.half and y<.22 end
 if distance>o.half+1.15 then return false end
 if o.kind=="Gate" then return math.abs(x-o.opening)>C.OpeningHalf-C.Radius end
 if o.kind=="Bumper" then return y<o.height and math.abs(x-C.BumperX(now))<C.Radius+2.4 end
 return y<o.height
end
return table.freeze(C)
