--!nonstrict
-- Static compatibility only. Entitlements are exclusively decided by PremiumService.
local Visual=require(script.Parent.PremiumVisualCatalog)
local B={}
B.Offers={
 money_x3={Item="money_x3"},scarlet_sentinel={Item="hero_kit"},
 fusion_starlight={Item="fusion_pack",Slot="FusionStyle",Choice="stellar_duo"},
 home_theme_sakura={Item="home_style_pack",Slot="HouseStyle",Choice="sakura",Theme="sakura",Bundle=3},
 home_theme_cosmic={Item="home_style_pack",Slot="HouseStyle",Choice="cosmic_villa",Theme="cosmic",Bundle=3},
 home_theme_neon={Item="home_style_pack",Slot="HouseStyle",Choice="neon_villa",Theme="neon",Bundle=3},
 aura_solar_crown={Item="aura_pack",Slot="Aura",Choice="solar_corona",Bundle=3},
 aura_galactic_dust={Item="aura_pack",Slot="Aura",Choice="galaxy_dust",Bundle=3},
 aura_liquid_gold={Item="aura_pack",Slot="Aura",Choice="liquid_gold",Bundle=3},
 party_disco={Item="party_pack",Slot="PartyStyle",Choice="disco"},
 collector_gallery={Item="collector_pack",Slot="AlbumStyle",Choice="collector"},
 atmosphere_starry={Item="atmosphere_pack",Slot="Atmosphere",Choice="star_ceiling",Bundle=3},
 atmosphere_fireflies={Item="atmosphere_pack",Slot="Atmosphere",Choice="fireflies",Bundle=3},
 atmosphere_aurora={Item="atmosphere_pack",Slot="Atmosphere",Choice="aurora",Bundle=3},
}
B.ByChoice={};B.HouseThemes={}
for id,v in B.Offers do
 if v.Slot and Visual.Items[id] then B.ByChoice[v.Slot..":"..v.Choice]=id end
 if v.Theme then B.HouseThemes[v.Choice]=v.Theme end
 table.freeze(v)
end
function B.Supported(slot,id) return id=="default" or B.ByChoice[slot..":"..id]~=nil end
function B.Visual(slot,id) return B.ByChoice[slot..":"..(id or "default")] end
function B.Styles(styles)
 return {aura=B.Visual("Aura",styles.Aura),party=B.Visual("PartyStyle",styles.PartyStyle),
  collection=B.Visual("AlbumStyle",styles.AlbumStyle),atmosphere=B.Visual("Atmosphere",styles.Atmosphere)}
end
table.freeze(B.Offers);table.freeze(B.ByChoice);table.freeze(B.HouseThemes)
return table.freeze(B)
