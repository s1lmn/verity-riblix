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

-- Exclusive achievement inventory and house trophies from the team.
Rewards.Order=table.freeze({"parkour_clear","race_champion","titan_victory"})
Rewards.Items=table.freeze({
 parkour_clear=table.freeze({id="parkour_clear",itemId="parkour_star_band",name="Звезда паркура",condition="Пройди весь паркур из 48 платформ.",
  progress="Прохождение паркура • %d/1",trophy="Звёздная медаль",color="FFCE45",activity="Parkour"}),
 race_champion=table.freeze({id="race_champion",itemId="champion_goggles",name="Чемпион трассы",condition="Победи в одной бесплатной гонке Verity.",
  progress="Победы в гонках • %d/1",trophy="Кубок чемпиона",color="62DAD4",activity="Race"}),
 titan_victory=table.freeze({id="titan_victory",itemId="titan_charms",name="Победитель титана",condition="Переживи все пять волн и победи босса арены.",
  progress="Победы над боссом • %d/1",trophy="Трофей Неонового титана",color="B68CFF",activity="Battle"}),
})
function Rewards.Unlocked(owned)
 local result={}
 for _,id in Rewards.Order do result[id]=owned~=nil and owned[Rewards.Items[id].itemId]==true end
 return result
end
return table.freeze(Rewards)
