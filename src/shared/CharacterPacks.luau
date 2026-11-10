--!nonstrict
local Config=require(script.Parent.GameConfig)
local Packs={}

Packs.Order=table.freeze({"reef_captain","phase_courier","magma_smith","amber_medic","polar_ranger"})
Packs.Items=table.freeze({
 reef_captain=table.freeze({
  Name="Рифовый капитан",Description="Скользи на волне и собирай мелких врагов водоворотом.",
  Icon="≈",Color="32D6CB",Accent="FF8E86",MobilityLabel="Прилив",AttackLabel="Водоворот",ShortMobility="Волна",ShortAttack="Вихрь",
  MobilityAction="flight",Travel="surf",MobilityDuration=7,MobilityCooldown=16,MobilityPower=52,
  Action="gravity",PackAction="pull",Range=68,Radius=14,Damage=22,Cooldown=13,Duration=.75,
 }),
 phase_courier=table.freeze({
  Name="Фазовый гонец",Description="Сделай два рывка. Следующий точный выстрел пометит цель для команды.",
  Icon="»",Color="83A7FF",Accent="FFCE75",MobilityLabel="Двойной рывок",AttackLabel="Метка фазы",ShortMobility="Рывок",ShortAttack="Метка",
  MobilityAction="dash",MobilityDuration=.24,MobilityCooldown=8,MobilityPower=85,SecondDashWindow=1.45,
  Action="pulse",PackAction="mark",Range=120,Damage=34,Cooldown=7,Duration=.52,
 }),
 magma_smith=table.freeze({
  Name="Магмовый кузнец",Description="Прерви атаки мелких врагов приземлением и укрой команду куполом.",
  Icon="◆",Color="F67449",Accent="FFD289",MobilityLabel="Сейсмопрыжок",AttackLabel="Кузнечный купол",ShortMobility="Удар",ShortAttack="Купол",
  MobilityAction="leap",MobilityDuration=3.2,MobilityCooldown=11,MobilityPower=76,LandingSlam=true,
  Action="shield",PackAction="dome",Radius=12,Damage=16,Cooldown=20,Duration=5,
 }),
 amber_medic=table.freeze({
  Name="Янтарный медик",Description="Ускорься к союзникам и восстанови здоровье команды.",
  Icon="+",Color="FFBC56",Accent="FFF0B6",MobilityLabel="Спасательный спринт",AttackLabel="Лечебная вспышка",ShortMobility="Бег",ShortAttack="Лечение",
  MobilityAction="sprint",MobilityDuration=5,MobilityCooldown=13,MobilityPower=59,
  Action="shield",PackAction="heal",Radius=16,Damage=18,Cooldown=19,Duration=.85,
 }),
 polar_ranger=table.freeze({
  Name="Полярный следопыт",Description="Раскрой ледяные крылья и замедли наступающую волну.",
  Icon="✦",Color="83DEF8",Accent="B1A2FF",MobilityLabel="Ледяной планер",AttackLabel="Иней",ShortMobility="Планер",ShortAttack="Иней",
  MobilityAction="flight",Travel="glide",MobilityDuration=8,MobilityCooldown=17,MobilityPower=41,
  Action="gravity",PackAction="freeze",Range=74,Radius=13,Damage=19,Cooldown=12,Duration=1,
 }),
})

function Packs.PassId(id)
 local value=(Config.PremiumPassIds or {})[id]
 return if Packs.Items[id] and type(value)=="number" and value>0 and value%1==0 and value<=9007199254740991 then value else nil
end

function Packs.Owns(data,id)
 local passId=Packs.PassId(id)
 return passId~=nil and (data.PremiumGrants or {})[id]==passId
end

return table.freeze(Packs)
