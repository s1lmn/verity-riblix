--!strict
local Numeric = require(script.Parent.Numeric)
local HouseConfig = {}
HouseConfig.IncomeUpgrades = table.freeze({
	table.freeze({Level = 1, Cost = 25, Name = "Сад светлячков"}),
	table.freeze({Level = 10, Cost = 500, Name = "Чайная Verity"}),
	table.freeze({Level = 25, Cost = 8000, Name = "Мастерская звёзд"}),
	table.freeze({Level = 50, Cost = 350000, Name = "Облачная теплица"}),
	table.freeze({Level = 75, Cost = 14000000, Name = "Обсерватория Verity"}),
	table.freeze({Level = 80, Cost = 26000000, Name = "Фонтан сияния"}),
	table.freeze({Level = 85, Cost = 52000000, Name = "Лунная оранжерея"}),
	table.freeze({Level = 90, Cost = 100000000, Name = "Почта комет"}),
	table.freeze({Level = 95, Cost = 180000000, Name = "Кристальная турбина"}),
	table.freeze({Level = 100, Cost = 300000000, Name = "Реактор радуги"}),
})
HouseConfig.IncomeStep = 0.25

function HouseConfig.getIncomeMultiplier(upgrades: number): number
	return 1 + upgrades * HouseConfig.IncomeStep
end
function HouseConfig.getHouseTier(level: number): number
	assert(Numeric.isInteger(level, 1, 100), "Invalid Verity level")
	if level >= 100 then return 6 end
	if level >= 75 then return 5 end
	if level >= 50 then return 4 end
	if level >= 25 then return 3 end
	if level >= 10 then return 2 end
	return 1
end
return table.freeze(HouseConfig)
