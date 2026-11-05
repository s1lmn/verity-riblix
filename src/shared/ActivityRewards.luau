--!strict
-- Ownership is stored in the existing CosmeticsOwned dictionary; trophies are derived from it.
local Rewards={}
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
