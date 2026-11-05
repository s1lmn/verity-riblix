--!strict
-- Pure, bounded pose sampling. Exact settled scale always comes from LevelConfig.
local Levels = if script then require(script.Parent.LevelConfig) else require("./LevelConfig")
local Celebration = if script then require(script.Parent.VerityUpgradeCelebration) else require("./VerityUpgradeCelebration")
local Profile = {}
Profile.BaseWidth, Profile.BaseDepth, Profile.BaseHeight = 1.7, 1.7, 2.4
Profile.MaxExpansion, Profile.Clearance = 1.035, 1.5
Profile.FrameInterval, Profile.IdleDistance = 1 / 30, 260
Profile.Tag = "VerityVisual"
Profile.Bloom = 0.53

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Profile.Stage(level: number): number
	local stage = 0
	for _, item in Levels.Milestones do if level >= item.level then stage += 1 end end
	return stage
end

-- Persistent appearance, separate from the paid upgrade celebration.
function Profile.Aura(level: number)
	local progress = (math.clamp(level,1,100)-1)/99
	return {
		brightness = .18+1.32*progress,
		outline = .88-.55*progress,
		fire = level>=10,
		fireStrength = .65+1.35*progress,
		trails = if level>=100 then 3 elseif level>=75 then 2 elseif level>=50 then 1 else 0,
		lifetime = .35+.6*progress,
		width = .10+.16*progress,
	}
end

function Profile.IsMilestone(level: number): boolean
	for _, item in Levels.Milestones do if level == item.level then return true end end
	return false
end

function Profile.Duration(level: number): number
	return Celebration.Get(level).duration
end

function Profile.Glow(progress: number): number
	return smooth((progress - 0.06) / 0.45) * (1 - smooth((progress - Profile.Bloom) / 0.47))
end

-- Keep the friend's glow/color choreography; conceal only while the storm is dense.
function Profile.Conceal(progress: number): number
	local function rise(t: number): number return smooth(t) end
	return rise((progress-.10)/.12)*(1-rise((progress-.69)/.19))
end

local function motion(level: number, t: number, scale: number): (number, number)
	local arc = math.sin(math.pi * t)
	if level == 10 then
		-- Two light hops, with the second one landing as the colour is revealed.
		local hops = math.sin(2 * math.pi * t) ^ 2
		return arc * (0.025 + 0.055 * hops) * scale, math.sin(4 * math.pi * t) * arc * 0.16
	elseif level == 25 then
		-- Rise gently and hold the hover before settling into the new idle.
		local hover = smooth(t / 0.38) * (1 - smooth((t - 0.7) / 0.3))
		return hover * 0.085 * scale, arc * 0.19
	elseif level == 50 then
		-- The upward impulse peaks with the existing bloom and particle burst.
		local charge = smooth((t - 0.26) / (Profile.Bloom - 0.26))
		local release = 1 - smooth((t - Profile.Bloom) / (1 - Profile.Bloom))
		return charge * release * 0.1 * scale, math.sin(2 * math.pi * t) * arc * 0.22
	elseif level == 75 then
		return arc * 0.09 * scale, 2 * math.pi * smooth((t - 0.1) / 0.78)
	elseif level == 100 then
		return arc * 0.13 * scale, 2 * math.pi * smooth((t - 0.16) / 0.74)
	end
	return arc * 0.06 * scale, math.sin(2 * math.pi * t) * 0.12
end

function Profile.Sample(oldLevel: number, newLevel: number, alpha: number, reducedMotion: boolean)
	assert(newLevel == oldLevel + 1, "One animation must represent one purchased level")
	local old, target = Levels.getVerityScale(oldLevel), Levels.getVerityScale(newLevel)
	local t = math.clamp(alpha, 0, 1)
	local scale
	if reducedMotion then scale = old + (target - old) * smooth(t)
	elseif t < 0.15 then scale = old * (1 - 0.06 * smooth(t / 0.15))
	elseif t < 0.58 then scale = old * 0.94 + (target * Profile.MaxExpansion - old * 0.94) * smooth((t - 0.15) / 0.43)
	else scale = target * (Profile.MaxExpansion - (Profile.MaxExpansion - 1) * smooth((t - 0.58) / 0.42)) end
	if t == 1 then scale = target end
	local stage = Profile.Stage(newLevel)
	local lift, yaw = 0, 0
	if not reducedMotion then lift, yaw = motion(newLevel, t, target) end
	local blend = if reducedMotion then smooth(t) else smooth((t - 0.16) / 0.53)
	return { scale = scale, lift = lift, yaw = yaw, blend = blend, stage = stage }
end

function Profile.Footprint(): number
	-- Includes full yaw rotation, animation overshoot and VFX/walkway margin.
	return math.sqrt(Profile.BaseWidth ^ 2 + Profile.BaseDepth ^ 2) * Levels.MaxScale * Profile.MaxExpansion + 2 * Profile.Clearance
end

return table.freeze(Profile)
