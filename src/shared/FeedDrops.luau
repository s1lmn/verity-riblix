--!nonstrict
local FeedDrops = {}

local tiers = {
	{label = "Common", chance = 58, multiplier = 1, color = "77F8CF"},
	{label = "Uncommon", chance = 27, multiplier = 2, color = "78D7FF"},
	{label = "Rare", chance = 11, multiplier = 4, color = "CB96FF"},
	{label = "Epic", chance = 3, multiplier = 8, color = "FF8BEB"},
	{label = "Legendary", chance = 1, multiplier = 16, color = "FFD45F"},
}

-- Each pair follows the established illustration and its alternating scene.
local assignments = {
	1, 3,  3, 2,  2, 2,  3, 4,  2, 1,
	4, 1,  3, 1,  2, 3,  3, 4,  1, 2,
	1, 2,  3, 1,  1, 1,  2, 1,  2, 2,
	2, 1,  2, 4,  4, 4,  1, 1,  5, 5,
}
local groups = {}
for tier in tiers do groups[tier] = {} end
for card, tier in assignments do table.insert(groups[tier], card) end

function FeedDrops.Get(card)
	local tier = assignments[card]
	if tier then return tiers[tier], tiers[tier].chance / #groups[tier] end
end

function FeedDrops.Roll(randomInteger)
	local roll = randomInteger(1, 100)
	for tier, info in tiers do
		roll -= info.chance
		if roll <= 0 then
			local cards = groups[tier]
			return cards[randomInteger(1, #cards)], info.multiplier
		end
	end
	error("Invalid card rarity roll")
end

return FeedDrops
