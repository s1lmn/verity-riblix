--!nonstrict
-- Energy Factory: one route climbs seven distinct workshops around the reactor.
local Layout=require(script.Parent.WorldLayout)
local Config={Version=7,WalkSpeed=18,JumpPower=55,ZOffset=Layout.EndShift,RewardSeconds=60,Cooldown=150,
 MinimumRunSeconds=45,MaximumRunSeconds=1200,ResetBelow=4.5,FloorHeight=22}
Config.Sections=table.freeze({"Конвейерная","Вращающиеся механизмы","Энергетический цех","Подъём к ядру","Плавильный цех","Реакторные мосты","Финальный запуск"})
local ring={}
for x=184,310,18 do table.insert(ring,{x=x,z=300}) end
for z=282,210,-18 do table.insert(ring,{x=310,z=z}) end
for x=292,184,-18 do table.insert(ring,{x=x,z=210}) end
for z=228,282,18 do table.insert(ring,{x=184,z=z}) end
local pads={}
Config.SectionCount=#Config.Sections
for section=1,Config.SectionCount do
 for station,point in ring do
  local index=#pads+1
  local checkpoint=station==1 or station==8 or station==16
  local corner=station==1 or station==8 or station==13 or station==20
  local nextPoint=ring[station%#ring+1]
  local direction=Vector3.new(nextPoint.x-point.x,0,nextPoint.z-point.z).Unit
  local p={x=point.x,y=6+(section-1)*Config.FloorHeight+(station-1)*.32,z=point.z+Layout.EndShift,
   w=12,d=12,section=section,station=station,checkpoint=checkpoint,direction=direction}
  if section==1 then
   p.w=if math.abs(direction.X)>.5 then 15 else 7
   p.d=if math.abs(direction.Z)>.5 then 15 else 7
   if not checkpoint and not corner then p.belt=if station%3==0 then -9 else 7 end
   if station==4 or station==10 or station==15 or station==22 then p.hazard="Press" end
  elseif section==2 then
   p.w=if math.abs(direction.X)>.5 then 13 else 4.5
   p.d=if math.abs(direction.Z)>.5 then 13 else 4.5
   if station==5 or station==10 or station==15 or station==18 or station==22 then p.hazard="Sweep" end
  elseif section==3 then
   p.w=if math.abs(direction.X)>.5 then 14 else 6.5
   p.d=if math.abs(direction.Z)>.5 then 14 else 6.5
   if not checkpoint and not corner and station%3~=0 then p.hazard="Laser" end
  elseif section==4 then
   p.w=10;p.d=10
   if not checkpoint and not corner and station%2==0 then p.motion="Shuttle" end
  elseif section==5 then
   p.w=10;p.d=10
   if not checkpoint and not corner then
    p.hazard="HotFloor"
    if station%3==0 then
     p.belt=-7
     -- The reverse belt shortens the available jump. Give the launch edge
     -- more length without making the landing wider across the route.
     if math.abs(direction.X)>.5 then p.w=15 else p.d=15 end
    end
   end
  elseif section==6 then
   p.w=if math.abs(direction.X)>.5 then 13 else 4.5
   p.d=if math.abs(direction.Z)>.5 then 13 else 4.5
   if not checkpoint and not corner then
    if station%2==0 then p.motion="Shuttle" else p.hazard="Sweep" end
   end
  else
   p.w=if math.abs(direction.X)>.5 then 13 else 5.5
   p.d=if math.abs(direction.Z)>.5 then 13 else 5.5
   if not checkpoint and not corner then
    if station%4==0 then p.motion="Shuttle"
    elseif station%3==0 then
     p.belt=-9;p.hazard="Press"
     if math.abs(direction.X)>.5 then p.w=15 else p.d=15 end
    elseif station%2==0 then p.hazard="Laser"
    else p.hazard="Sweep" end
   end
  end
  if corner or checkpoint then p.w=12;p.d=12;p.hazard=nil;p.belt=nil;p.motion=nil end
  if station==#ring and section<Config.SectionCount then p.motion="Lift";p.rise=Config.FloorHeight-(#ring-1)*.32;p.w=12;p.d=12;p.hazard=nil;p.belt=nil;p.gate=true end
  table.insert(pads,table.freeze(p))
 end
end
-- The last bridge reaches the actual reactor console, not a floating finish label.
for i,point in {{200,275},{216,268},{232,261},{247,255}} do
 table.insert(pads,table.freeze({x=point[1],y=6+(Config.SectionCount-1)*Config.FloorHeight+23*.32+i*.45,z=point[2]+Layout.EndShift,
  w=if i==4 then 16 else 8,d=if i==4 then 16 else 8,section=Config.SectionCount,station=24+i,checkpoint=i==4,finish=i==4,
  direction=Vector3.new(1,0,-.4).Unit}))
end
Config.Pads=table.freeze(pads)
Config.ExitPosition=Vector3.new(164,4,300+Layout.EndShift)
function Config.Contains(x,z)
 return x>=170 and x<=322 and z>=198+Layout.EndShift and z<=312+Layout.EndShift
end
function Config.PadFrame(index,now)
 local p=Config.Pads[index];local pos=Vector3.new(p.x,p.y,p.z)
 if p.motion=="Lift" then
  local t=now%16
  local alpha=if t<3 then 0 elseif t<8 then (t-3)/5 elseif t<11 then 1 else 1-(t-11)/5
  pos+=Vector3.yAxis*p.rise*alpha
 elseif p.motion=="Shuttle" then
  local sideways=Vector3.new(-p.direction.Z,0,p.direction.X)
  pos+=sideways*(math.sin(now*.8+index)*2.5)
 end
 return CFrame.new(pos)
end
function Config.Hazard(index,now)
 local p=Config.Pads[index]
 if not p or not p.hazard then return 0,0 end
 local safe=if p.hazard=="Laser" then 1.6 elseif p.hazard=="HotFloor" then 2 else 2.4
 local warning=1.1
 local active=if p.section>=5 then 3.6 else 3
 local t=(now+index*.73)%(safe+warning+active)
 local phase=if t<safe then 0 elseif t<safe+warning then 1 else 2
 local turn=math.max(0,t-safe-warning)
 return phase,if p.hazard=="Sweep" then index*.7+turn*1.4 else 0
end
function Config.HazardGeometry(index,now,platformFrame)
 local p=Config.Pads[index];local phase,angle=Config.Hazard(index,now)
 local base=platformFrame or Config.PadFrame(index,now)
 local pos=base.Position
 local frame=CFrame.lookAt(pos,pos+p.direction)
 local width=if math.abs(p.direction.X)>.5 then p.d else p.w
 if p.hazard=="Press" then
  return frame*CFrame.new(0,if phase==2 then 3 else 10,0),Vector3.new(width-.5,5,4),phase
 elseif p.hazard=="Laser" then
  return frame*CFrame.new(0,4,0),Vector3.new(width,7,.4),phase
 elseif p.hazard=="HotFloor" then
  return base*CFrame.new(0,.62,0),Vector3.new(p.w,.16,p.d),phase
 end
 return CFrame.new(pos+Vector3.new(0,1.3,0))*CFrame.Angles(0,-angle,0),Vector3.new(16,.3,.65),phase
end
-- Sweep the avatar body through the active visible box. This catches crossing
-- thin lasers between frames and includes feet on red floor panels.
function Config.HazardCrosses(index,from,to,now,platformFrame,feetOffset)
 local frame,size,phase=Config.HazardGeometry(index,now,platformFrame)
 if phase~=2 then return false end
 local feet=feetOffset or 3
 local shift=Vector3.new(0,(2-feet)/2,0)
 local a=frame:PointToObjectSpace(from+shift)
 local b=frame:PointToObjectSpace(to+shift)
 local delta=b-a
 local half=size/2+Vector3.new(.85,(feet+2)/2,.85)
 local low,high=0,1
 for _,axis in {"X","Y","Z"} do
  if math.abs(delta[axis])<.0001 then
   if math.abs(a[axis])>half[axis] then return false end
  else
   local first=(-half[axis]-a[axis])/delta[axis]
   local last=(half[axis]-a[axis])/delta[axis]
   if first>last then first,last=last,first end
   low=math.max(low,first);high=math.min(high,last)
   if low>high then return false end
  end
 end
 return true
end
function Config.HazardHits(index,position,now,platformFrame,feetOffset)
 return Config.HazardCrosses(index,position,position,now,platformFrame,feetOffset)
end
function Config.Medal(seconds,faults)
 if seconds<=300 and faults==0 then return "ЗОЛОТО",1.5 end
 if seconds<=480 and faults<=4 then return "СЕРЕБРО",1.25 end
 return "БРОНЗА",1
end
return table.freeze(Config)
