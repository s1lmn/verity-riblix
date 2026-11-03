--!strict
-- Pure, bounded pose sampling. Exact settled scale always comes from LevelConfig.
local Levels = if script then require(script.Parent.LevelConfig) else require("./LevelConfig")
local Profile = {}
Profile.BaseWidth, Profile.BaseDepth, Profile.BaseHeight = 0.66, 0.50, 1.25
Profile.MaxExpansion, Profile.Clearance = 1.035, 1.5
Profile.FrameInterval, Profile.IdleDistance = 1 / 30, 260
Profile.Tag = "VerityVisual"

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

function Profile.Stage(level: number): number
	local stage = 0
	for _, item in Levels.Milestones do if level >= item.level then stage += 1 end end
	return stage
end

function Profile.IsMilestone(level: number): boolean
	for _, item in Levels.Milestones do if level == item.level then return true end end
	return false
end

function Profile.Duration(level: number): number
	return if Profile.IsMilestone(level) then 1.7 else 0.8
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
	local lift = if reducedMotion then 0 else math.sin(math.pi * t) * target * (if stage == 5 then 0.13 else 0.06)
	local yaw = if reducedMotion then 0 elseif newLevel == 75 or newLevel == 100 then 2 * math.pi * smooth(t) else math.sin(math.pi * 2 * t) * 0.12
	return { scale = scale, lift = lift, yaw = yaw, blend = smooth(t), stage = stage }
end

function Profile.Footprint(): number
	-- Includes full yaw rotation, animation overshoot and VFX/walkway margin.
	return math.sqrt(Profile.BaseWidth ^ 2 + Profile.BaseDepth ^ 2) * 15 * Profile.MaxExpansion + 2 * Profile.Clearance
end

return table.freeze(Profile)
