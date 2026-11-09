--!nonstrict
-- Appearance only: these purchases do not alter existing income or construction.
local Premium=require(script.Parent.PremiumCatalog)
local Bridge=require(script.Parent.PremiumVisualBridge)
local C={}
C.ThemeOrder={"original","candy","lagoon","sunset"}
C.Themes={
 original={Name="Классический дом",Cost=0,Level=1,Color="A98BFF",Accent="FFD45F",Soft="58D7C7"},
 candy={Name="Ягодный дом",Cost=600,Level=5,Color="FF8CCB",Accent="FFE38D",Soft="C6AEFF"},
 lagoon={Name="Лазурная лагуна",Cost=2500,Level=15,Color="6DDAE8",Accent="B5F79D",Soft="A4BFFF"},
 sunset={Name="Тёплый закат",Cost=12000,Level=25,Color="FFB879",Accent="FFF0AD",Soft="EF9BCF"},
 sakura={Name="Сакура",Premium=true,Level=1,Color="FCA4C8",Accent="FFD7B1",Soft="FBC5DD"},
 cosmic={Name="Космический дом",Premium=true,Level=1,Color="786AC5",Accent="FFD798",Soft="A89BE5"},
 neon={Name="Неоновая вилла",Premium=true,Level=1,Color="596980",Accent="79E9D9",Soft="F3A7D9"},
}
C.DecorOrder={"home_lounge","home_garden","home_arcade"}
C.Decor={
 home_lounge={Name="Уютный уголок",Cost=400,Level=3,Build=1,Color="B7A0FF"},
 home_garden={Name="Сад у дома",Cost=1000,Level=8,Build=1,Color="8CF3AD"},
 home_arcade={Name="Игровой автомат",Cost=5000,Level=15,Build=2,Color="FF8DD5"},
 home_beacon={Name="Маяк дружбы",Cost=0,Level=1,Build=1,Color="FFD75B",Earned=true},
}
local Album=require(script.Parent.AlbumConfig)
for id,set in Album.Sets do C.Decor[set.Decor]={Name=set.Name,Cost=0,Level=1,Build=1,Color=set.Color,Earned=true} end
local Arcade=require(script.Parent.ArcadeConfig)
for _,prize in Arcade.Prizes do C.Decor[prize.Id]={Name=prize.Name,Cost=0,Level=1,Build=2,Color=prize.Color,Earned=true} end
for _,entry in {{"home_repair_trophy","Знак автомеханика","FFB66D"},{"home_drone_nest","Домик спасённых дронов","89E8F6"},{"home_festival_lantern","Фонарь праздника","FF99D6"}} do
 C.Decor[entry[1]]={Name=entry[2],Cost=0,Level=1,Build=1,Color=entry[3],Earned=true}
end
local Adventures=require(script.Parent.AdventureConfig)
for _,prize in Adventures.Prizes do C.Decor[prize.Id]={Name=prize.Name,Cost=0,Level=1,Build=2,Color=prize.Color,Earned=true} end
local Forge=require(script.Parent.WeatherForgeConfig)
for _,id in Forge.DecorOrder do local prize=Forge.Decor[id];C.Decor[id]={Name=prize.Name,Cost=0,Level=1,Build=2,Color=prize.Color,Earned=true} end
function C.ThemeOwned(owned,id) return id=="original" or owned["home_theme_"..id]==true end
function C.Project(data)
 local owned,themes={},{}
 for id in C.Decor do owned[id]=data.CosmeticsOwned[id]==true end
 for id,theme in C.Themes do themes[id]=if theme.Premium then Premium.Owned(data,"home_style_pack") and Premium.Items.home_style_pack.PresentationReady else C.ThemeOwned(data.CosmeticsOwned,id) end
 local trialRanks={}
 for id,d in Adventures.Trials do
  local time=(data.AdventureRecords or {})[id]
  if time then trialRanks[id]=if time<=d.Gold then "Gold" elseif time<=d.Silver then "Silver" else "Bronze" end
 end
 local saved=C.Themes[data.HouseTheme or "original"]
 local freeTheme=if saved and not saved.Premium then data.HouseTheme or "original" else "original"
 return {theme=Bridge.HouseThemes[Premium.Public(data).HouseStyle] or freeTheme,owned=owned,themes=themes,trialRanks=trialRanks}
end
return C
