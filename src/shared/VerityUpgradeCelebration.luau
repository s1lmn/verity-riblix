-- Pure, bounded choreography shared by world effects and the owning player's reveal.
local Levels=if script then require(script.Parent.LevelConfig) else require("./LevelConfig")
local Celebration={MaxParticles=128}
function Celebration.Get(level)
    local special=Levels.isMilestone(level)
    return {special=special,duration=if special then 2.45 else 1.8,
        chargeCount=if special then 24 else 12,
        burstCount=if level==100 then 80 elseif special then 56 else 28,
        lifetime=if special then 1.75 else 1.25}
end
function Celebration.Pulse(age)
    if age<0 or age>.8 then return 0 end
    return math.min(1,age/.05)*math.exp(-age*6)*(1-age/.8)
end
function Celebration.Shake(age,level,disabled)
    if disabled or not Levels.isMilestone(level) then return 0,0,0 end
    local power=Celebration.Pulse(age)*(if level==100 then 1 else .7)
    return math.sin(age*73)*.055*power,math.sin(age*91)*.04*power,math.sin(age*59)*math.rad(.55)*power
end
return table.freeze(Celebration)
