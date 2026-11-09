--!nonstrict
-- Stable Core contract. Actual prices come from MarketplaceService, not SuggestedPrice.
local Config=require(script.Parent.GameConfig)
local Bridge=require(script.Parent.PremiumVisualBridge)
local Catalog={Version=1}
Catalog.Order={"money_x3","hero_kit","home_style_pack","aura_pack","fusion_pack","party_pack","collector_pack","atmosphere_pack"}
Catalog.Slots={"HouseStyle","Aura","FusionStyle","PartyStyle","AlbumStyle","Atmosphere"}
Catalog.Defaults={HouseStyle="default",Aura="default",FusionStyle="default",PartyStyle="default",AlbumStyle="default",Atmosphere="default"}
local configured=Config.PremiumPassIds or {}
local ready=Config.PremiumPresentationReady or {}
Catalog.Items={
 money_x3={Name="×3 ко всем деньгам",Description="Постоянный множитель денежного заработка.",Category="Acceleration",PassId=Config.MoneyPassId,SuggestedPrice=99,PriceApproved=true,PresentationReady=true},
 hero_kit={Name="Алый страж",Description="Полёт героя и красные лазеры из глаз.",Category="Verity",PassId=Config.HeroPassId,SuggestedPrice=99,PriceApproved=true,PresentationReady=true},
 home_style_pack={Name="Премиальные дома",Description="Сакура, космический дом и неоновая вилла.",Category="Home",SuggestedPrice=149},
 aura_pack={Name="Особые ауры",Description="Солнечная корона, галактическая пыль и жидкое золото.",Category="Verity",SuggestedPrice=79},
 fusion_pack={Name="Особое слияние",Description="Оформление общего Verity. Достаточно покупки у одного участника.",Category="Verity",SuggestedPrice=99},
 party_pack={Name="Набор для вечеринок",Description="Оформление домашней вечеринки.",Category="Home",SuggestedPrice=79},
 collector_pack={Name="Оформление коллекционера",Description="Витрина, рамки и обложка альбома.",Category="Verity",SuggestedPrice=59},
 atmosphere_pack={Name="Атмосфера дома",Description="Звёздный потолок, светлячки и северное сияние на участке.",Category="Home",SuggestedPrice=99},
}
Catalog.Options={
 HouseStyle={sakura={Item="home_style_pack",Name="Дом сакуры"},cosmic_villa={Item="home_style_pack",Name="Космический дом"},neon_villa={Item="home_style_pack",Name="Неоновая вилла"}},
 Aura={solar_corona={Item="aura_pack",Name="Солнечная корона"},galaxy_dust={Item="aura_pack",Name="Галактическая пыль"},liquid_gold={Item="aura_pack",Name="Жидкое золото"}},
 FusionStyle={stellar_duo={Item="fusion_pack",Name="Звёздный союз"},aurora_duo={Item="fusion_pack",Name="Союз сияния"}},
 PartyStyle={disco={Item="party_pack",Name="Звёздная дискотека"}},
 AlbumStyle={collector={Item="collector_pack",Name="Золотой альбом"}},
 Atmosphere={star_ceiling={Item="atmosphere_pack",Name="Звёздный потолок"},fireflies={Item="atmosphere_pack",Name="Светлячки"},aurora={Item="atmosphere_pack",Name="Северное сияние"}},
}
for _,id in Catalog.Order do
 local item=Catalog.Items[id];item.Id=id;item.Kind="GamePass"
 if id~="money_x3" and id~="hero_kit" then item.PassId=configured[id];item.PresentationReady=ready[id]==true;item.PriceApproved=false end
 table.freeze(item)
end
for _,options in Catalog.Options do for _,option in options do table.freeze(option) end;table.freeze(options) end
function Catalog.ValidId(id) return type(id)=="number" and id==id and id%1==0 and id>0 and id<=9007199254740991 end
function Catalog.Choice(slot,id)
 if type(slot)~="string" or type(id)~="string" then return false end
 local options=Catalog.Options[slot]
 return options~=nil and (id=="default" or options[id]~=nil)
end
function Catalog.Owned(data,id)
 local item=Catalog.Items[id]
 return item~=nil and Catalog.ValidId(item.PassId) and (data.PremiumGrants or {})[id]==item.PassId
end
function Catalog.Public(data)
 local styles=table.clone(Catalog.Defaults)
 for _,slot in Catalog.Slots do
  local id=(data.PremiumLoadout or {})[slot];local option=id and Catalog.Options[slot][id]
  if option and Bridge.Supported(slot,id) and Catalog.Owned(data,option.Item) and Catalog.Items[option.Item].PresentationReady then styles[slot]=id end
 end
 return styles
end
table.freeze(Catalog.Order);table.freeze(Catalog.Slots);table.freeze(Catalog.Defaults);table.freeze(Catalog.Items);table.freeze(Catalog.Options)
return table.freeze(Catalog)
