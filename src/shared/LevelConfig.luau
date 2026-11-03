--!strict
-- Shared exact growth contract. Core owns economy; this module has no prices.
local LevelConfig = { MinLevel = 1, MaxLevel = 100 }

function LevelConfig.getVerityScale(level: number): number
	assert(type(level) == "number" and level == level and level % 1 == 0 and level >= 1 and level <= 100,
		"Verity level must be an integer from 1 to 100")
	return 1 + 14 * ((level - 1) / 99) ^ 0.85
end

return table.freeze(LevelConfig)
