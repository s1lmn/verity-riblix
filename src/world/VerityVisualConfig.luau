local Definitions = require(script.Parent.VerityDefinitions)
local LevelConfig = require(script.Parent.Parent.Shared.LevelConfig)
local Config = { MinLevel = 1, MaxAuthoredLevel = 10, Tag = "VerityPrototypeVisual" }
function Config.Get(level)
    assert(type(level) == "number" and level == level and level % 1 == 0 and level >= 1 and level <= 10,
        "Verity visuals are authored for integer levels 1..10 only")
    return Definitions[level]
end
function Config.GetScale(level)
    Config.Get(level)
    return LevelConfig.getVerityScale(level)
end
function Config.GetColor(level)
    return Color3.fromHex(Config.Get(level).Color)
end
return Config
