--!nonstrict
-- Pass IDs and planned prices for this experience. Core and Roblox supply live offers.
local Packs=require(script.Parent.CharacterPacks)
local Products=require(script.Parent.ShopProducts)
local Catalog={}
Catalog.HeroAbilityId="homelander"
Catalog.FusionLookId="fusion_starlight"
Catalog.Sections={
 {id="boost",title="УСКОРЕНИЕ",color="FFE189"},
 {id="verity",title="VERITY",color="C4ABFF"},
 {id="house",title="ДОМ",color="9FE9CC"},
}
Catalog.Order={"money_x3","scarlet_sentinel","premium_homes","premium_auras",Catalog.FusionLookId,"party_disco","collector_gallery","home_atmosphere"}
Catalog.Passes={
 premium_homes={Id=2076112611,Price=149,Section="house",Title="Премиальные дома",Description="Сакура, космический дом и неоновая вилла с оформлением интерьера.",Color="FCA4C8",
  Variants={"home_theme_sakura","home_theme_cosmic","home_theme_neon"}},
 premium_auras={Id=2076046768,Price=79,Section="verity",Title="Особые ауры Verity",Description="Солнечная корона, галактическая пыль и жидкое золото в одном наборе.",Color="BD9EFF",
  Variants={"aura_solar_crown","aura_galactic_dust","aura_liquid_gold"}},
 fusion_starlight={Id=2074726849,Price=99},
 party_disco={Id=2075758718,Price=79},
 collector_gallery={Id=2074552741,Price=59},
 home_atmosphere={Id=2074366798,Price=99,Section="house",Title="Личная атмосфера дома",Description="Звёздный потолок, светлячки и северное сияние над участком.",Color="90F1DA",
  Variants={"atmosphere_starry","atmosphere_fireflies","atmosphere_aurora"}},
}
function Catalog.Card(id)
 local pass=Catalog.Passes[id]
 return if pass and pass.Variants then pass else Catalog.Items[id]
end
Catalog.Auras={
 aura_solar_crown={Id="aura_solar_crown",Color="FFB94F",Family="Magma"},
 aura_galactic_dust={Id="aura_galactic_dust",Color="BD9EFF",Family="Cosmic"},
 aura_liquid_gold={Id="aura_liquid_gold",Color="FFD67B",Family="Aqua"},
}
Catalog.Gallery={id="collector_gallery",Frame="F0BD60",Accent="8051BE",Paper="EFE2FF"}
Catalog.Atmospheres={atmosphere_starry=true,atmosphere_fireflies=true,atmosphere_aurora=true}
Catalog.Items={
 money_x3={Section="boost",Title="Деньги ×3",Description="Постоянный множитель денежного дохода.",Color="FFD36B",Preview="Money"},
 scarlet_sentinel={Section="verity",Title="Алый страж",Description="Долгий скоростной полёт и красные лазеры с усилением против NPC.",Color="FF7B95",Preview="Hero"},
 fusion_starlight={Section="verity",Title="Звёздное слияние",Description="Общий облик, церемония и след. Достаточно пропуска у одного участника.",Color="C6A8FF",Preview="Fusion"},
 home_theme_sakura={Section="house",Title="Сакура",Description="Розовая отделка, цветущие деревья и тёплые фонарики у входа.",Color="FCA4C8",Preview="House",Theme="sakura"},
 home_theme_cosmic={Section="house",Title="Космический дом",Description="Звёздный фасад, созвездия и миниатюрный Сатурн у крыльца.",Color="786AC5",Preview="House",Theme="cosmic"},
 home_theme_neon={Section="house",Title="Неоновая вилла",Description="Графитовые панели, мятная подсветка и розовый контур входа.",Color="79E9D9",Preview="House",Theme="neon"},
 aura_solar_crown={Section="verity",Title="Солнечная корона",Description="Тёплые лучи и искры вокруг Verity.",Color="FFB94F",Preview="Aura"},
 aura_galactic_dust={Section="verity",Title="Галактическая пыль",Description="Сиреневые орбиты и созвездия вокруг Verity.",Color="BD9EFF",Preview="Aura"},
 aura_liquid_gold={Section="verity",Title="Жидкое золото",Description="Золотые капли и мягкие волны света.",Color="FFD67B",Preview="Aura"},
 party_disco={Section="house",Title="Диско-вечеринка",Description="Дискошар, танцпол, гирлянды и управляемый праздничный эффект.",Color="FF9ACF",Preview="Decor"},
 collector_gallery={Section="house",Title="Галерея коллекционера",Description="Золотые рамки витрины и фиолетовая обложка альбома.",Color="C6A8FF",Preview="Decor"},
 atmosphere_starry={Section="house",Title="Звёздный потолок",Description="Мягкое созвездие над входной комнатой.",Color="C1A7FF",Preview="Decor"},
 atmosphere_fireflies={Section="house",Title="Светлячки",Description="Тёплые огоньки у дорожки дома.",Color="F4DB92",Preview="Decor"},
 atmosphere_aurora={Section="house",Title="Северное сияние",Description="Мятные и сиреневые ленты над участком.",Color="90F1DA",Preview="Decor"},
}
for index,id in Products.Order do
 local offer=Products.Items[id]
 Catalog.Items[id]={Section="boost",Title=offer.Title,Color=offer.Color,
  Description=if offer.Cash then "Валюта сразу поступает на игровой баланс." else "Удваивает денежный доход на указанное время."}
 table.insert(Catalog.Order,index,id)
end
for _,id in Packs.Order do
 local pack=Packs.Items[id]
 Catalog.Items[id]={Section="verity",Title=pack.Name,Description=pack.Description,Color=pack.Color,Preview="CharacterPack"}
 table.insert(Catalog.Order,id)
end
for _,id in {"home_theme_sakura","home_theme_cosmic","home_theme_neon"} do Catalog.Items[id].Description..=" Входит в набор из трёх стилей дома." end
for _,id in {"aura_solar_crown","aura_galactic_dust","aura_liquid_gold"} do Catalog.Items[id].Description..=" Входит в набор из трёх аур." end
for _,id in {"atmosphere_starry","atmosphere_fireflies","atmosphere_aurora"} do Catalog.Items[id].Description..=" Входит в набор из трёх атмосфер." end
return Catalog
