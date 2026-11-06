--!strict
local Numeric = require(script.Parent.Numeric)
local EconomyConfig = {
	BalanceVersion = "core-v2-smoother-growth",
	MaxSwipeLevel = 40,
	SwipeInterval = 0.75,
	IncomeBase = 5,
	IncomeGrowth = 1.16,
	SwipeBase = 2,
	SwipeGrowth = 1.35,
	SwipeCostBase = 30,
	SwipeCostGrowth = 1.50,
	LevelCost = {},
	Boost = table.freeze({ Multiplier = 5.3721, DurationSeconds = 14400, MaxStackSeconds = 86400 }),
	-- Paid products are deliberately unconfigured. Core checks real ProcessReceipt only.
	Products = table.freeze({}),
}
function EconomyConfig.getIncome(level: number): number
	assert(Numeric.isInteger(level, 1, 100), "Invalid Verity level")
	return Numeric.round(EconomyConfig.IncomeBase * EconomyConfig.IncomeGrowth ^ (level - 1))
end
function EconomyConfig.getSwipeIncome(level: number): number
	assert(Numeric.isInteger(level, 0, 40), "Invalid swipe level")
	return Numeric.round(EconomyConfig.SwipeBase * EconomyConfig.SwipeGrowth ^ level) + level
end
function EconomyConfig.getSwipeCost(level: number): number?
	assert(Numeric.isInteger(level, 0, 40), "Invalid swipe level")
	if level == 40 then return nil end
	return Numeric.round(EconomyConfig.SwipeCostBase * EconomyConfig.SwipeCostGrowth ^ level)
end
-- Price at the current level. Levels 1-9 retain their onboarding prices.
-- From level 10, prices follow base income with a gradually rising savings target.
-- BEGIN LEVEL COSTS
EconomyConfig.LevelCost = table.freeze({
	50, 100, 180, 300, 500, 800, 1200, 1800, 2600,
	3400, 4200, 5200, 6400, 7800, 9500, 11500, 14000, 17000,
	20500, 24700, 29800, 35900, 43100, 51800, 62100, 74400, 89000,
	106000, 127000, 152000, 181000, 216000, 257000, 306000, 363000, 432000,
	513000, 609000, 723000, 857000, 1020000, 1200000, 1430000, 1690000, 2000000,
	2360000, 2790000, 3300000, 3900000, 4610000, 5440000, 6420000, 7580000, 8940000,
	10500000, 12400000, 14700000, 17300000, 20400000, 24000000, 28200000, 33300000, 39100000,
	46100000, 54200000, 63800000, 75000000, 88200000, 104000000, 122000000, 143000000, 168000000,
	198000000, 232000000, 273000000, 321000000, 376000000, 442000000, 519000000, 609000000, 715000000,
	839000000, 984000000, 1150000000, 1350000000, 1590000000, 1860000000, 2180000000, 2560000000, 3000000000,
	3520000000, 4120000000, 4830000000, 5660000000, 6630000000, 7770000000, 9100000000, 10700000000, 12500000000,
})
-- END LEVEL COSTS
return table.freeze(EconomyConfig)
