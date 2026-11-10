--!strict
-- Stable inventory IDs. Prices and product IDs belong to Roblox/server configuration.
local Catalog = {}
Catalog.Slots = table.freeze({Face = true, Head = true, Ears = true})
Catalog.Order = table.freeze({"story_spark_band","story_signal_charms","story_neighborhood_crown","parkour_star_band","champion_goggles","titan_charms","sun_cap","bubble_bow","beat_headphones","pixel_specs","round_glasses", "party_hat", "star_earrings","delivery_cap","delivery_goggles","delivery_wings","fusion_charms","prism_specs","leaf_crown","cloud_charms","collector_crown","forge_halo"})
local items: {[string]: any} = {
 story_spark_band=table.freeze({id="story_spark_band",name="Ободок первой искры",slot="Head",category="История района",achievement="story_first_light",exclusive=true}),
 story_signal_charms=table.freeze({id="story_signal_charms",name="Подвески сигнала",slot="Ears",category="История района",achievement="story_signal",exclusive=true}),
 story_neighborhood_crown=table.freeze({id="story_neighborhood_crown",name="Корона доброго соседа",slot="Head",category="История района",achievement="story_finale",exclusive=true}),
 forge_halo=table.freeze({id="forge_halo",name="Венец трёх стихий",slot="Head",category="Кузница погоды",source="WeatherForge",exclusive=true}),
 collector_crown=table.freeze({id="collector_crown",name="Корона коллекционера",slot="Head",category="Альбом карточек",achievement="album_master",exclusive=true}),
 prism_specs=table.freeze({id="prism_specs",name="Призматические очки",slot="Face",category="Секреты района",achievement="secret_solar",exclusive=true}),
 leaf_crown=table.freeze({id="leaf_crown",name="Венок хранителя кроны",slot="Head",category="Секреты района",achievement="secret_canopy",exclusive=true}),
 cloud_charms=table.freeze({id="cloud_charms",name="Облачные подвески",slot="Ears",category="Секреты района",achievement="secret_cloud",exclusive=true}),
 fusion_charms=table.freeze({id="fusion_charms",name="Парные подвески",slot="Ears",category="Награда слияния",source="Fusion",exclusive=true}),
 delivery_cap=table.freeze({id="delivery_cap",name="Кепка Verity Express",slot="Head",category="Награда доставки",source="StreetDelivery",exclusive=true}),
 delivery_goggles=table.freeze({id="delivery_goggles",name="Очки экспресс-курьера",slot="Face",category="Награда доставки",source="StreetDelivery",exclusive=true}),
 delivery_wings=table.freeze({id="delivery_wings",name="Крылья доставки",slot="Ears",category="Награда доставки",source="StreetDelivery",exclusive=true}),
 parkour_star_band=table.freeze({id="parkour_star_band",name="Звёздный ободок",slot="Head",category="Награда за паркур",achievement="parkour_clear"}),
 champion_goggles=table.freeze({id="champion_goggles",name="Очки чемпиона",slot="Face",category="Награда за гонки",achievement="race_champion"}),
 titan_charms=table.freeze({id="titan_charms",name="Подвески титана",slot="Ears",category="Награда за арену",achievement="titan_victory"}),
 round_glasses = table.freeze({id="round_glasses",name="Round glasses",slot="Face",category="Glasses"}),
 party_hat = table.freeze({id="party_hat",name="Party hat",slot="Head",category="Hats"}),
 star_earrings = table.freeze({id="star_earrings",name="Star earrings",slot="Ears",category="Earrings"}),
}
Catalog.Tones=table.freeze({
 mango=table.freeze({name="Манго",color="FFB72D",accent="FFF0CE"}),
 mint=table.freeze({name="Мята",color="51DBCA",accent="E7FF9B"}),
 berry=table.freeze({name="Ягода",color="FF73BF",accent="CAB3FF"}),
})
local variants: {[string]: any}={}
for _,definition in {
 {id="sun_cap",name="Солнечная кепка",slot="Head",tone="mango"},
 {id="bubble_bow",name="Бант-пузырёк",slot="Head",tone="berry"},
 {id="beat_headphones",name="Игрушечные наушники",slot="Head",tone="mint"},
 {id="pixel_specs",name="Пиксельные очки",slot="Face",tone="mint"},
} do
 local options={}
 for _,tone in {"mango","mint","berry"}do
  local id=if tone==definition.tone then definition.id else definition.id.."_"..tone
  items[id]=table.freeze({id=id,name=definition.name,slot=definition.slot,category="Бесплатный набор",starter=true,
   variantOf=if id==definition.id then nil else definition.id,tone=tone,color=Catalog.Tones[tone].color,accent=Catalog.Tones[tone].accent})
  table.insert(options,id)
 end
 variants[definition.id]=table.freeze(options)
end
Catalog.Items=table.freeze(items)
Catalog.Variants=table.freeze(variants)
function Catalog.BaseId(id: string?): string?
 local item=if id then Catalog.Items[id] else nil
 return if item then item.variantOf or id else nil
end
function Catalog.Owns(owned: any,id: string): boolean
 local base=Catalog.BaseId(id)
 return type(owned)=="table" and base~=nil and (owned[id]==true or owned[base]==true)
end
return table.freeze(Catalog)
