-- One mesh and one shared face set. Body pigment is independent of expression.
local LevelConfig = require(script.Parent.LevelConfig)
local palettes = table.freeze({
    {Name="Sunny",Hex="FFDA21"},{Name="Mango",Hex="FF8A00"},
    {Name="Cherry",Hex="FF4566"},{Name="Bubblegum",Hex="FF2DBB"},
    {Name="Grape",Hex="9D2AFF"},{Name="Blue",Hex="2468FF"},
    {Name="Cyan",Hex="08DDF5"},{Name="Mint",Hex="04E6B2"},
    {Name="Lime",Hex="B4F51B"},{Name="Golden",Hex="FFCA15"},
})
local Levels = {MinLevel=1,MaxLevel=10}
function Levels.IsValid(level)
    return type(level)=="number" and level==level and level%1==0 and level>=1 and level<=10
end
function Levels.Get(level)
    assert(Levels.IsValid(level),"Only companion looks 1..10 are authored")
    local palette=palettes[level]
    return {Level=level,Name=palette.Name,Hex=palette.Hex,
        Scale=LevelConfig.getVerityScale(level),Duration=if level==10 then .95 else .7,
        Bounce=if level==10 then .055 else .035,Bob=.10+.004*(level-1)}
end
return table.freeze(Levels)
