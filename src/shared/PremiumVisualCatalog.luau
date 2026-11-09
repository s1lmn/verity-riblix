--!nonstrict
-- Presentation keys shared with Core. Prices and entitlements come from the server.
local Catalog={}
Catalog.HeroAbilityId="homelander"
Catalog.FusionLookId="fusion_starlight"
Catalog.Sections={
 {id="boost",title="УСКОРЕНИЕ",color="FFE189"},
 {id="verity",title="VERITY",color="C4ABFF"},
 {id="house",title="ДОМ",color="9FE9CC"},
}
Catalog.Order={"money_x3","scarlet_sentinel",Catalog.FusionLookId,"home_theme_sakura","home_theme_cosmic","home_theme_neon",
 "aura_solar_crown","aura_galactic_dust","aura_liquid_gold","party_disco","collector_gallery",
 "atmosphere_starry","atmosphere_fireflies","atmosphere_aurora"}
Catalog.Auras={
 aura_solar_crown={Id="aura_solar_crown",Color="FFB94F",Family="Magma"},
 aura_galactic_dust={Id="aura_galactic_dust",Color="BD9EFF",Family="Cosmic"},
 aura_liquid_gold={Id="aura_liquid_gold",Color="FFD67B",Family="Aqua"},
}
Catalog.Gallery={id="collector_gallery",Frame="F0BD60",Accent="8051BE",Paper="EFE2FF"}
Catalog.Atmospheres={atmosphere_starry=true,atmosphere_fireflies=true,atmosphere_aurora=true}
Catalog.Items={
 money_x3={Section="boost",Title="Деньги ×3",Description="Постоянный множитель денежного дохода.",Color="FFD36B",Preview="Money"},
 scarlet_sentinel={Section="verity",Title="Алый страж",Description="Полёт героя на 18 секунд и красные лазеры на 40 урона.",Color="FF7B95",Preview="Hero"},
 fusion_starlight={Section="verity",Title="Звёздное слияние",Description="Облик общего Verity, вспышка слияния и звёздный след на трассе.",Color="C6A8FF",Preview="Fusion"},
 home_theme_sakura={Section="house",Title="Сакура",Description="Розовая отделка, цветущие деревья и тёплые фонарики у входа.",Color="FCA4C8",Preview="House",Theme="sakura"},
 home_theme_cosmic={Section="house",Title="Космический дом",Description="Звёздный фасад, созвездия и миниатюрный Сатурн у крыльца.",Color="786AC5",Preview="House",Theme="cosmic"},
 home_theme_neon={Section="house",Title="Неоновая вилла",Description="Графитовые панели, мятная подсветка и розовый контур входа.",Color="79E9D9",Preview="House",Theme="neon"},
 aura_solar_crown={Section="verity",Title="Солнечная корона",Description="Тёплые лучи и искры вокруг Verity.",Color="FFB94F",Preview="Aura"},
 aura_galactic_dust={Section="verity",Title="Галактическая пыль",Description="Сиреневые орбиты и созвездия вокруг Verity.",Color="BD9EFF",Preview="Aura"},
 aura_liquid_gold={Section="verity",Title="Жидкое золото",Description="Золотые капли и мягкие волны света.",Color="FFD67B",Preview="Aura"},
 party_disco={Section="house",Title="Диско-вечеринка",Description="Дискошар, танцпол, гирлянды и конфетти для домашней вечеринки.",Color="FF9ACF",Preview="Decor"},
 collector_gallery={Section="house",Title="Галерея коллекционера",Description="Золотые рамки витрины и фиолетовая обложка альбома.",Color="C6A8FF",Preview="Decor"},
 atmosphere_starry={Section="house",Title="Звёздный потолок",Description="Мягкое созвездие над входной комнатой.",Color="C1A7FF",Preview="Decor"},
 atmosphere_fireflies={Section="house",Title="Светлячки",Description="Тёплые огоньки у дорожки дома.",Color="F4DB92",Preview="Decor"},
 atmosphere_aurora={Section="house",Title="Северное сияние",Description="Мятные и сиреневые ленты над участком.",Color="90F1DA",Preview="Decor"},
}
return Catalog
