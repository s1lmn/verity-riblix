--!nonstrict
-- Appearance only: these purchases do not alter existing income or construction.
local C={}
C.ThemeOrder={"original","candy","lagoon","sunset"}
C.Themes={
 original={Name="Классический дом",Cost=0,Level=1,Color="A98BFF",Accent="FFD45F",Soft="58D7C7"},
 candy={Name="Ягодный дом",Cost=600,Level=5,Color="FF8CCB",Accent="FFE38D",Soft="C6AEFF"},
 lagoon={Name="Лазурная лагуна",Cost=2500,Level=15,Color="6DDAE8",Accent="B5F79D",Soft="A4BFFF"},
 sunset={Name="Тёплый закат",Cost=12000,Level=25,Color="FFB879",Accent="FFF0AD",Soft="EF9BCF"},
}
C.DecorOrder={"home_lounge","home_garden","home_arcade"}
C.Decor={
 home_lounge={Name="Уютный уголок",Cost=400,Level=3,Build=1,Color="B7A0FF"},
 home_garden={Name="Сад у дома",Cost=1000,Level=8,Build=1,Color="8CF3AD"},
 home_arcade={Name="Игровой автомат",Cost=5000,Level=15,Build=2,Color="FF8DD5"},
 home_beacon={Name="Маяк дружбы",Cost=0,Level=1,Build=1,Color="FFD75B",Earned=true},
}
function C.ThemeOwned(owned,id) return id=="original" or owned["home_theme_"..id]==true end
function C.Project(data)
 local owned,themes={},{}
 for id in C.Decor do owned[id]=data.CosmeticsOwned[id]==true end
 for id in C.Themes do themes[id]=C.ThemeOwned(data.CosmeticsOwned,id) end
 return {theme=data.HouseTheme or "original",owned=owned,themes=themes}
end
return C
