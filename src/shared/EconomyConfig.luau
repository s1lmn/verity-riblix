--!strict
local Numeric = require(script.Parent.Numeric)
local EconomyConfig = {
	BalanceVersion = "core-v1-simulation-candidate",
	MaxSwipeLevel = 40,
	SwipeInterval = 0.75,
	IncomeBase = 5,
	IncomeGrowth = 1.16,
	SwipeBase = 2,
	SwipeGrowth = 1.35,
	SwipeCostBase = 30,
	SwipeCostGrowth = 1.50,
	LevelCost = {}, -- Filled with explicit calibrated values by scripts/simulate_balance.py.
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
-- BEGIN LEVEL COSTS
EconomyConfig.LevelCost = table.freeze({
	50, 100, 180, 300, 500, 800, 1200, 1800, 2600,
	15881, 19441, 23982, 28685, 33548, 40595, 47896, 57568, 67563,
	80089, 95263, 112039, 132810, 156540, 184537, 216947, 255161, 300635,
	353602, 415590, 488184, 573028, 673171, 790410, 926593, 1086410, 1274720,
	1493686, 1749839, 2049922, 2400883, 2812837, 3293211, 3854154, 4511212, 5278836,
	6174962, 7224262, 8448924, 9879645, 11551125, 13505406, 15785592, 18448949, 21560765,
	25192895, 29433975, 34384858, 40165733, 46911524, 54786051, 63975884, 74699654, 87214159,
	101815353, 118850005, 138724149, 161908169, 188951060, 220495117, 257285532, 300193136, 350230375,
	408582616, 476621566, 555956706, 648455935, 756297166, 882019390, 1028578902, 1199424374, 1398566061,
	1630679955, 1901216556, 2216518226, 2583977126, 3012203018, 3511221143, 4092711120, 4770277840, 5559757193,
	6479602524, 7551298554, 8799863170, 10254433224, 11948936476, 13922876916, 16222255247, 18900630025, 22020367436,
})
-- END LEVEL COSTS
return table.freeze(EconomyConfig)
