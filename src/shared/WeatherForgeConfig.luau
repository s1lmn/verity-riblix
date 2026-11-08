--!nonstrict
local L=require(script.Parent.WorldLayout)
local F={Version=1,Reach=10,MaxMaterial=100000,RevealSeconds=3.8,Position=Vector3.new(-64,1,-L.RoadHalfLength-26)}
F.MaterialOrder={"Ember","Stardust","RainPearl"}
F.Materials={Ember={Name="Солнечные угольки",Short="Угольки",Color="FFAC67",Source="Собери пять угольков во время огненного неба"},Stardust={Name="Звёздная пыль",Short="Звёздная пыль",Color="C5A5FF",Source="Заверши поиск пяти звёздных осколков"},RainPearl={Name="Дождевые жемчужины",Short="Жемчужины",Color="88E5EC",Source="Открой сундук дождевой пещеры"}}
F.Harvest={Fire={Ember=5},Stars={Stardust=5},Cave={RainPearl=3}}
F.LookOrder={"ember","star","storm","aurora"}
F.Looks={
 ember={Id="ember",Name="Сердце пламени",Skin="MagmaBlaze",Family="Magma",Color="FFAA52",Item="weather_look_ember"},
 star={Id="star",Name="Звёздная душа",Skin="CosmicNova",Family="Cosmic",Color="C9A4FF",Item="weather_look_star"},
 storm={Id="storm",Name="Живая гроза",Skin="FrostAurora",Family="Cyber",Color="84E6FF",Item="weather_look_storm"},
 aurora={Id="aurora",Name="Дитя радуги",Skin="Rainbow",Family="Rainbow",Color="FFB1E2",Item="weather_look_aurora"},
}
F.WeatherLooks={Fire="ember",Stars="star",Storm="storm",Rainbow="aurora"}
F.Order={"ember","star","storm","aurora","brazier","globe","halo"}
F.Recipes={
 ember={Id="ember",Name="Сердце пламени",Description="Пламенный облик, восходящие искры и огненный след навсегда.",Type="Look",Look="ember",Item="weather_look_ember",Cost={Ember=5},Color="FFAA52"},
 star={Id="star",Name="Звёздная душа",Description="Космический облик с орбитами и звёздным шлейфом навсегда.",Type="Look",Look="star",Item="weather_look_star",Cost={Stardust=5},Color="C9A4FF"},
 storm={Id="storm",Name="Живая гроза",Description="Ледяной свет, электрические дуги и сияющий след навсегда.",Type="Look",Look="storm",Item="weather_look_storm",Cost={RainPearl=3,Stardust=2},Color="84E6FF"},
 aurora={Id="aurora",Name="Дитя радуги",Description="Радужный облик и разноцветные переливающиеся ленты навсегда.",Type="Look",Look="aurora",Item="weather_look_aurora",Cost={Ember=3,Stardust=3,RainPearl=3},Color="FFB1E2"},
 brazier={Id="brazier",Name="Очаг солнечных углей",Description="Тёплый светящийся очаг. Появится дома со второго этапа стройки.",Type="Decor",Item="home_forge_brazier",Cost={Ember=3,RainPearl=1},Color="FFB06C"},
 globe={Id="globe",Name="Глобус созвездий",Description="Сияющая планета с золотой орбитой. Дома со второго этапа стройки.",Type="Decor",Item="home_forge_globe",Cost={Stardust=3,RainPearl=1},Color="B8A4FF"},
 halo={Id="halo",Name="Венец трёх стихий",Description="Золотой венец с огненным, звёздным и дождевым камнями.",Type="Cosmetic",Item="forge_halo",Cost={Ember=4,Stardust=4,RainPearl=2},Color="FFE39C"},
}
F.DecorOrder={"home_forge_brazier","home_forge_globe"}
F.Decor={home_forge_brazier={Id="home_forge_brazier",Name="Очаг солнечных углей",Color="FFB06C"},home_forge_globe={Id="home_forge_globe",Name="Глобус созвездий",Color="B8A4FF"}}
function F.Resolve(selection,weather)
 if selection=="Original" then return nil end
 return F.Looks[if selection and selection~="Auto" then selection else F.WeatherLooks[weather]]
end
return F
