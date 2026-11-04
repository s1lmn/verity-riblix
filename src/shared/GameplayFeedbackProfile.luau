--!strict
-- Confirmed snapshots only; initial saves are a baseline, never a replay.
local Profile={BurstDuration=.95,BurstCooldown=.55,ArrivalDuration=.85,ButtonDuration=.32,MaxBursts=2,Stars=8,Segments=16}
function Profile.Smooth(t: number): number
 t=math.clamp(t,0,1);return t*t*(3-2*t)
end
function Profile.Transitions(previous: any,current: any)
 local out={delivery=false,completed={}}
 if not previous or previous.PlotId~=current.PlotId then return out end
 out.delivery=previous.DeliveryState=="NotDelivered" and current.DeliveryState=="Delivered"
 local before={}
 for _,entry in previous.Tasks or {} do before[entry.taskId]=entry end
 for _,entry in current.Tasks or {} do
  local old=before[entry.taskId]
  if old and entry.status=="Cooldown" and entry.cooldownEndsAt>old.cooldownEndsAt then
   table.insert(out.completed,entry.taskId)
  end
 end
 return out
end
function Profile.Burst(age: number,reduced: boolean)
 local t=math.clamp(age/Profile.BurstDuration,0,1)
 return {radius=if reduced then 1.4 else .7+2.6*Profile.Smooth(t),
  height=if reduced then 0 else 3*t-2.5*t*t,alpha=1-t,done=age>=Profile.BurstDuration}
end
return table.freeze(Profile)
