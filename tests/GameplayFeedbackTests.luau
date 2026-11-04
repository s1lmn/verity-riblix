local P=require("../src/shared/GameplayFeedbackProfile")
local function snapshot(delivery,status,cooldown,plot)
 return {PlotId=plot or 1,DeliveryState=delivery,Tasks={{taskId="PRESS_BUTTON",status=status,cooldownEndsAt=cooldown}}}
end
local initial=snapshot("NotDelivered","Ready",0)
local delivered=snapshot("Delivered","Ready",0)
assert(not P.Transitions(nil,delivered).delivery,"initial delivery replay")
assert(P.Transitions(initial,delivered).delivery)
assert(not P.Transitions(delivered,delivered).delivery)
assert(not P.Transitions(initial,snapshot("Delivered","Ready",0,2)).delivery,"plot change replay")
assert(#P.Transitions(initial,snapshot("NotDelivered","Active",0)).completed==0,"acceptance is not completion")
assert(#P.Transitions(snapshot("Opened","Active",0),snapshot("Opened","Ready",0)).completed==0,"death reset is not a win")
local completed=snapshot("Opened","Cooldown",100)
assert(P.Transitions(initial,completed).completed[1]=="PRESS_BUTTON","instant button completion")
assert(#P.Transitions(completed,completed).completed==0,"snapshot replay")
assert(#P.Transitions(completed,snapshot("Opened","Cooldown",99)).completed==0,"older snapshot")
for _,reduced in {false,true} do
 for i=0,200 do
  local pose=P.Burst(i*P.BurstDuration/200,reduced)
  assert(pose.radius>=.7-1e-9 and pose.radius<=3.9+1e-9 and pose.alpha>=0 and pose.alpha<=1)
  assert(pose.height==pose.height)
  if reduced then assert(pose.radius==1.4 and pose.height==0) end
 end
 assert(P.Burst(P.BurstDuration,reduced).done)
end
print("Gameplay feedback: delivery baseline, plot change, confirmed cooldowns, death reset, replay and reduced motion passed")
