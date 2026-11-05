--!strict
-- Stable inventory IDs. Prices and product IDs belong to Roblox/server configuration.
local Catalog = {}
Catalog.Slots = table.freeze({Face = true, Head = true, Ears = true})
Catalog.Order = table.freeze({"round_glasses", "party_hat", "star_earrings", "delivery_cap", "delivery_goggles", "delivery_wings"})
Catalog.Items = table.freeze({
 delivery_cap=table.freeze({id="delivery_cap",name="Кепка Verity Express",slot="Head",category="Hats",source="StreetDelivery",exclusive=true}),
 delivery_goggles=table.freeze({id="delivery_goggles",name="Очки экспресс-курьера",slot="Face",category="Glasses",source="StreetDelivery",exclusive=true}),
 delivery_wings=table.freeze({id="delivery_wings",name="Крылья доставки",slot="Ears",category="Earrings",source="StreetDelivery",exclusive=true}),
 round_glasses = table.freeze({id="round_glasses",name="Round glasses",slot="Face",category="Glasses"}),
 party_hat = table.freeze({id="party_hat",name="Party hat",slot="Head",category="Hats"}),
 star_earrings = table.freeze({id="star_earrings",name="Star earrings",slot="Ears",category="Earrings"}),
})
return table.freeze(Catalog)
