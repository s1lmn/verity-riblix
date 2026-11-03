--!strict
local Levels = {MinLevel = 1, MaxLevel = 100, MaxScale = 15}
Levels.Milestones = table.freeze({
 {level=10,name="STARLIGHT",reward="Playful idle + color shift"},
 {level=25,name="LEVITATION",reward="Floating idle + glowing aura"},
 {level=50,name="POWER PULSE",reward="Power impulse + light wave"},
 {level=75,name="LEGENDARY",reward="Legendary spin + energy rings"},
 {level=100,name="FINAL EVOLUTION",reward="Giant 15× form + crown + layered aura"},
})
function Levels.getVerityScale(level: number): number
 assert(type(level)=="number" and level==level and level%1==0 and level>=1 and level<=100,"Invalid Verity level")
 return 1 + 14 * ((level - 1) / 99) ^ 0.85
end
function Levels.isMilestone(level: number): boolean
 for _, item in Levels.Milestones do if item.level==level then return true end end
 return false
end
function Levels.getNextMilestone(level: number): number?
 for _, item in Levels.Milestones do if item.level>level then return item.level end end
 return nil
end
return table.freeze(Levels)
