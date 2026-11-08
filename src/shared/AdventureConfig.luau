--!nonstrict
local L=require(script.Parent.WorldLayout)
local C={Version=1,Reach=8,TrialSeconds=65,CaveSeconds=150,PartyLobby=20,PartySeconds=100,ArcadePartySeconds=240,PartyLimit=6}
C.WeatherCycle={{Kind="Clear",Seconds=30},{Kind="Fire",Seconds=110},{Kind="Clear",Seconds=45},{Kind="Stars",Seconds=135},{Kind="Clear",Seconds=60},{Kind="Storm",Seconds=95},{Kind="Rainbow",Seconds=180},{Kind="Clear",Seconds=60}}
C.WeatherNames={Fire="Огненное небо",Clear="Ясная погода",Stars="Звёздный дождь",Storm="Грозовой ливень",Rainbow="После дождя: тайная пещера"}
C.WeatherColors={Fire="FFA567",Clear="FFE2A4",Stars="C2A4FF",Storm="86CFFF",Rainbow="A5F4D2"}
C.TrialCenter=Vector3.new(-224,.7,-L.GroundHalfLength+44)
C.TrialOrder={"dash","leap","flight","laser"}
local t=C.TrialCenter
C.Trials={
 dash={Name="Квантовая трасса",Action="dash",Slot="Mobility",Ability="dash",Color="8BE9FF",Gold=4,Silver=8,Start=t+Vector3.new(-29,0,-7),Points={t+Vector3.new(-29,3,-16),t+Vector3.new(-29,3,-22),t+Vector3.new(-29,3,-28)}},
 leap={Name="Башня титана",Action="leap",Slot="Mobility",Ability="leap",Color="ACF99B",Gold=5,Silver=9,Start=t+Vector3.new(-1,0,-22),Points={t+Vector3.new(-1,10,-22),t+Vector3.new(-1,20,-22),t+Vector3.new(-1,30,-22)}},
 flight={Name="Небесный слалом",Action="flight",Slot="Mobility",Ability="flight",Color="91FCE0",Gold=10,Silver=17,Start=t+Vector3.new(30,0,25),Points={t+Vector3.new(30,12,12),t+Vector3.new(32,22,-2),t+Vector3.new(19,31,-15),t+Vector3.new(8,18,-30)}},
 laser={Name="Призматический тир",Action="laser",Slot="Attack",Ability="eye_laser",Color="FFAAE4",Gold=17,Silver=25,Start=t+Vector3.new(-30,0,26),Points={t+Vector3.new(-40,5,3),t+Vector3.new(-27,6,-1),t+Vector3.new(-14,5,3)}},
}
C.CaveEntrance=Vector3.new(89,1,-L.GroundHalfLength+11)
C.CaveCenter=Vector3.new(0,-63,-L.GroundHalfLength+75)
C.CaveSpawn=C.CaveCenter+Vector3.new(0,4,23)
C.Runes={C.CaveCenter+Vector3.new(-27,3,10),C.CaveCenter+Vector3.new(24,3,-4),C.CaveCenter+Vector3.new(-13,3,-19)}
C.Chest=C.CaveCenter+Vector3.new(18,2,-21)
C.Jets={C.CaveCenter+Vector3.new(-12,0,10),C.CaveCenter+Vector3.new(10,0,-2),C.CaveCenter+Vector3.new(-2,0,-18)}
C.StarPoints={}
for i=1,10 do C.StarPoints[i]=Vector3.new(if i%2==0 then 19.5 else -19.5,2.2,-L.RoadHalfLength+38+i*31) end
C.PartyPoints={Vector3.new(-9,2,-24),Vector3.new(8,2,-26),Vector3.new(11,2,-39),Vector3.new(-8,2,-45),Vector3.new(5,2,-49),Vector3.new(-12,2,-35)}
C.Prizes={
 {Id="home_star_mobile",Name="Звёздный мобиль",Color="C6AAFF"},{Id="home_rain_relic",Name="Реликвия дождевой пещеры",Color="80E8EB"},
 {Id="home_trial_dash",Name="Медаль квантовой трассы",Color="8BE9FF"},{Id="home_trial_leap",Name="Медаль башни титана",Color="ACF99B"},
 {Id="home_trial_flight",Name="Медаль небесного слалома",Color="91FCE0"},{Id="home_trial_laser",Name="Медаль призматического тира",Color="FFAAE4"},
 {Id="home_party_badge",Name="Праздничная звезда",Color="FFB0D9"},{Id="home_party_cup",Name="Кубок домашней вечеринки",Color="FFE18C"},
 {Id="home_ember_lantern",Name="Жар-светильник",Color="FFAF62"},
}
function C.TrialContains(p)
 local d=p-C.TrialCenter;return math.abs(d.X)<58 and math.abs(d.Z)<57 and d.Y> -5 and d.Y<80
end
function C.CaveContains(p)
 local d=p-C.CaveCenter;return math.abs(d.X)<45 and math.abs(d.Z)<34 and d.Y> -5 and d.Y<23
end
function C.JetPhase(now,index) return (now+index*1.3)%5 end
return C
