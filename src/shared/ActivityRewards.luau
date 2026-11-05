--!nonstrict
-- Non-yielding server quotes. All activities stay free; boosts multiply cash only.
local Economy=require(script.Parent.EconomyConfig)
local Rewards={Version=1}
Rewards.Definitions=table.freeze({
 Parkour=table.freeze({Seconds=60,TargetFraction=.08,MaximumSeconds=240}),
 Battle=table.freeze({Seconds=55,TargetFraction=.10,MaximumSeconds=300}),
 Race=table.freeze({Seconds=12,TargetFraction=.015,MaximumSeconds=60}),
})
local taskSeconds={PRESS_BUTTON=4,REACH_POINT=8,STAND_ON_PLATFORM=5,POSTBOX=11,CHECKPOINT=13,CHARGE_PAD=15}
function Rewards.Base(level,id)
 local d=Rewards.Definitions[id];if not d then return 0 end
 local income=Economy.getIncome(level);local cost=Economy.LevelCost[level] or 0
 return math.max(income*d.Seconds,math.min(cost*d.TargetFraction,income*d.MaximumSeconds))
end
function Rewards.Task(level,id,minimum)
 return math.max(minimum,Economy.getIncome(level)*(taskSeconds[id] or 4))
end
return table.freeze(Rewards)
