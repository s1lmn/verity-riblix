--!strict
local Numeric = require(script.Parent.Numeric)
local HouseConfig = {}
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
