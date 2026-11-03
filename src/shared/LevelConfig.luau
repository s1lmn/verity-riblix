--!strict
local Numeric = require(script.Parent.Numeric)
local LevelConfig = { MaxLevel = 100, Milestones = table.freeze({10, 25, 50, 75, 100}) }
function LevelConfig.getVerityScale(level: number): number
	assert(Numeric.isInteger(level, 1, 100), "Invalid Verity level")
	return 1 + 14 * ((level - 1) / 99) ^ 0.85
end
function LevelConfig.isMilestone(level: number): boolean
	return table.find(LevelConfig.Milestones, level) ~= nil
end
function LevelConfig.getNextMilestone(level: number): number?
	for _, milestone in LevelConfig.Milestones do
		if milestone > level then return milestone end
	end
	return nil
end
return table.freeze(LevelConfig)
