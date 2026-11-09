--!strict
-- Ride is earned by progression; no paid ability or saved equipment is required.
local Ride={MinLevel=50,Speed=36,Duration=60,TakeoffSpeed=24,LandingSpeed=32,TransitionTimeout=6}

function Ride.GetSeatOffset(humanoid: Humanoid, root: BasePart): number
 local rigScale=root.Size.Y/2
 return math.max(2.5*rigScale,humanoid.HipHeight+root.Size.Y/2)+.25*rigScale
end

return table.freeze(Ride)
