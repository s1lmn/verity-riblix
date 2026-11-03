--!strict
-- Stable inventory IDs. Prices and product IDs belong to Roblox/server configuration.
local Catalog = {}
Catalog.Slots = table.freeze({Face = true, Head = true, Ears = true})
Catalog.Order = table.freeze({"round_glasses", "party_hat", "star_earrings"})
Catalog.Items = table.freeze({
 round_glasses = table.freeze({id="round_glasses",name="Round glasses",slot="Face",category="Glasses"}),
 party_hat = table.freeze({id="party_hat",name="Party hat",slot="Head",category="Hats"}),
 star_earrings = table.freeze({id="star_earrings",name="Star earrings",slot="Ears",category="Earrings"}),
})
return table.freeze(Catalog)
