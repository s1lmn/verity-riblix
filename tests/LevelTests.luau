--!nonstrict
return function(load, check)
	local Levels = load("src/shared/LevelConfig")
	local Houses = load("src/shared/HouseConfig")
	local Economy = load("src/shared/EconomyConfig")
	local lastScale, lastIncome = 0, 0
	for level = 1, 100 do
		local scale, income = Levels.getVerityScale(level), Economy.getIncome(level)
		check(scale > lastScale and scale < math.huge, "All 99 transitions must grow")
		check(income > lastIncome and income < math.huge, "Income must increase")
		check(scale <= 5, "Scale never exceeds agreed5x")
		if level < 100 then check(Economy.LevelCost[level] > 0, "99 explicit costs required") end
		lastScale, lastIncome = scale, income
	end
	check(Levels.getVerityScale(1) == 1 and Levels.getVerityScale(100) == 5)
	for index, level in {1, 10, 25, 50, 75, 100} do
		check(Levels.getVerityScale(level) == ({1, 1.4, 2, 3, 4, 5})[index], "Agreed scale milestones")
	end
	check(not pcall(Levels.getVerityScale, 101))
	check(not pcall(Levels.getVerityScale, 0 / 0))
	check(not pcall(Levels.getVerityScale, 1.5))
	check(#Economy.LevelCost == 99)
	for index, level in {1, 10, 25, 50, 75, 100} do check(Houses.getHouseTier(level) == index) end
	check(Houses.getHouseTier(99) == 5)
	check(Economy.getSwipeIncome(0) == 2 and Economy.getSwipeCost(0) == 30)
	check(Economy.getSwipeCost(40) == nil and Economy.getSwipeIncome(40) > 0)
end
