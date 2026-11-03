--!strict
local Levels = {MinLevel = 1, MaxLevel = 100, MaxScale = 5}
Levels.Milestones = table.freeze({
 {level=10,name="STARLIGHT",reward="New idle + star trail"},
 {level=25,name="LEVITATION",reward="Floating idle + glowing aura"},
 {level=50,name="POWER PULSE",reward="Power impulse + light wave"},
 {level=75,name="LEGENDARY",reward="Legendary spin + energy rings"},
 {level=100,name="FINAL EVOLUTION",reward="Giant5x form + crown + layered aura"},
})
local points = {{level=1,scale=1},{level=10,scale=1.4},{level=25,scale=2},{level=50,scale=3},{level=75,scale=4},{level=100,scale=5}}
function Levels.getVerityScale(level: number): number
 assert(type(level)=="number" and level==level and level%1==0 and level>=1 and level<=100,"Invalid Verity level")
 for i=2,#points do
  local a,b=points[i-1],points[i]
  if level<=b.level then return a.scale+(b.scale-a.scale)*(level-a.level)/(b.level-a.level) end
 end
 return 5
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
