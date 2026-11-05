--!nonstrict
local Layout=require(script.Parent.WorldLayout)
local Config={Version=3,ZOffset=Layout.EndShift,RewardSeconds=60,Cooldown=150,MinimumRunSeconds=25,MaximumRunSeconds=480,ResetBelow=4.5,MinStepSeconds=.18}
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
 if p.hazard=="Sweep" then return 2,(now*.9+index)*math.pi end
 local t=(now+index*.63)%5
 return if t<2.7 then 0 elseif t<3.7 then 1 else 2,0
end
function Config.Medal(seconds,faults)
 if seconds<=80 and faults==0 then return "ЗОЛОТО",1.5 end
 if seconds<=125 and faults<=2 then return "СЕРЕБРО",1.25 end
 return "БРОНЗА",1
end
return table.freeze(Config)
