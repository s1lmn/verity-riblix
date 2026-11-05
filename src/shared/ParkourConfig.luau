--!nonstrict
local Layout=require(script.Parent.WorldLayout)
local Config={Version=4,ZOffset=Layout.EndShift,RewardSeconds=60,Cooldown=150,MinimumRunSeconds=25,MaximumRunSeconds=480,ResetBelow=4.5,MinStepSeconds=.18}
Config.Sections={"Сад прыжков","Радужный зигзаг","Лазерный ритм","Неоновые маятники","Острова точности","Звёздный подъём"}
local pads={}
for row=0,5 do
 for column=0,7 do
  local i=row*8+column+1
  local x=184+(if row%2==0 then column else 7-column)*16
  local z=300-row*20+Layout.EndShift
  if row==1 and column>0 and column<7 then z+=(if column%2==0 then 2 else -2) end
  local edge=column==0 or column==7
  local p={x=x,y=2.5+(i-1)*.4,z=z,w=if edge then 14 elseif row==4 then 10 else 12,d=if edge then 16 else 12,
   section=row+1,checkpoint=(column==7 or i==1),finish=i==48}
  if row==2 and column>0 and column<7 and column%2==1 then p.hazard="Pulse" end
  if row==3 and column>0 and column<7 and column%2==0 then p.hazard="Sweep" end
  if row==4 and (column==2 or column==5) then p.hazard="Sweep" end
  if row==5 and column>0 and column<7 then p.hazard=if column%2==0 then "Sweep" else "Pulse" end
  table.insert(pads,table.freeze(p))
 end
end
Config.Pads=table.freeze(pads);Config.Sections=table.freeze(Config.Sections)
Config.ExitPosition=Vector3.new(164,4,300+Layout.EndShift)
function Config.Contains(x,z)
 return x>=170 and x<=314 and z>=190+Layout.EndShift and z<=312+Layout.EndShift
end
function Config.Hazard(index,now)
 local p=Config.Pads[index]
 if not p or not p.hazard then return 0,0 end
 local cycle=if p.section>=5 then 6 else 6.8
 local t=(now+index*.63)%cycle
 local warning=if p.section>=5 then 1.2 else 1.4
 local safe=if p.section>=5 then 2.4 else 3.2
 local phase=if t<safe then 0 elseif t<safe+warning then 1 else 2
 -- Sweep stays still during the warning, then turns from that exact angle.
 local activeTime=math.max(0,t-safe-warning)
 local angle=if p.hazard=="Sweep" then index*.73+activeTime*(if p.section>=5 then 1.4 else 1.05) else 0
 return phase,angle
end
-- The visible blade/patch and the server check use the same box.
function Config.HazardGeometry(index,now)
 local p=Config.Pads[index];local phase,angle=Config.Hazard(index,now)
 local frame=CFrame.new(p.x,p.y+1.25,p.z)*CFrame.Angles(0,-angle,0)
 local size=Vector3.new(p.w-.5,.16,if p.hazard=="Pulse" then p.d-.5 else .6)
 return frame,size,phase
end
function Config.HazardHits(index,position,now)
 local frame,size,phase=Config.HazardGeometry(index,now)
 if phase~=2 then return false end
 local localPos=frame:PointToObjectSpace(position)
 -- Approximate normal avatar body, not an invisible full-platform danger zone.
 return math.abs(localPos.X)<=size.X/2+.8 and math.abs(localPos.Z)<=size.Z/2+.8 and math.abs(localPos.Y)<=2.5
end
function Config.Medal(seconds,faults)
 if seconds<=80 and faults==0 then return "ЗОЛОТО",1.5 end
 if seconds<=125 and faults<=2 then return "СЕРЕБРО",1.25 end
 return "БРОНЗА",1
end
return table.freeze(Config)
