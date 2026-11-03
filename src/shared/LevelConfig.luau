--!strict
local Numeric = require(script.Parent.Numeric)
local LevelConfig = { MaxLevel = 100, Milestones = table.freeze({10, 25, 50, 75, 100}) }
LevelConfig.MaxScale = 5
local ScalePoints = {{level = 1, scale = 1}, {level = 10, scale = 1.4},
	{level = 25, scale = 2}, {level = 50, scale = 3}, {level = 75, scale = 4}, {level = 100, scale = 5}}
function LevelConfig.getVerityScale(level: number): number
	assert(Numeric.isInteger(level, 1, 100), "Invalid Verity level")
	for index = 2, #ScalePoints do
		local previous, current = ScalePoints[index - 1], ScalePoints[index]
		if level <= current.level then
			local alpha = (level - previous.level) / (current.level - previous.level)
			return previous.scale + (current.scale - previous.scale) * alpha
		end
	end
	return LevelConfig.MaxScale
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
