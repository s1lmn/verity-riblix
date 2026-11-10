--!strict
-- Pure presentation logic. No prices, rewards or player progress are generated here.
local Model = {}
local LevelConfig = if game then require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("LevelConfig")) else require("../shared/LevelConfig")
local StoryConfig = if game then require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("StoryConfig")) else require("../shared/StoryConfig")
local TaskConfig = if game then require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("TaskConfig")) else require("../shared/TaskConfig")
Model.Milestones = LevelConfig.Milestones

function Model.IsFinite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Model.IsInteger(value: any, minimum: number, maximum: number): boolean
	return Model.IsFinite(value) and value % 1 == 0 and value >= minimum and value <= maximum
end

function Model.Scale(level: number): number
	assert(Model.IsInteger(level, 1, 100), "Verity level must be an integer from 1 to 100")
	return LevelConfig.getVerityScale(level)
end

function Model.NextMilestone(level: number)
	for _, milestone in Model.Milestones do
		if milestone.level > level then return milestone end
	end
	return nil
end

function Model.Format(value: number?): string
	if not Model.IsFinite(value) then return "—" end
	local number = value :: number
	local suffixes = { "", "K", "M", "B", "T", "Qa", "Qi" }
	local tier = 1
	while math.abs(number) >= 1000 and tier < #suffixes do
		number /= 1000
		tier += 1
	end
	-- Avoid displaying 1000K at a suffix boundary.
	if math.abs(number) >= 999.95 and tier < #suffixes then
		number /= 1000
		tier += 1
	end
	local formatted = if tier == 1 then string.format("%.0f", number) else string.format("%.1f", number)
	return (formatted:gsub("%.0$", "")) .. suffixes[tier]
end

function Model.ValidateSnapshot(raw: any): (any?, string?)
	if type(raw) ~= "table" or raw.version ~= 1 then return nil, "Unsupported state version" end
	if not Model.IsInteger(raw.stateRevision, 0, 2 ^ 53 - 1) then return nil, "Invalid revision" end
	for _, key in { "Cash", "IncomePerSecond", "SwipeIncome" } do
		if not Model.IsFinite(raw[key]) or raw[key] < 0 then return nil, "Invalid " .. key end
	end
	if not Model.IsInteger(raw.VerityLevel, 1, 100)
		or not Model.IsInteger(raw.SwipeUpgradeLevel, 0, 40)
		or not Model.IsInteger(raw.HouseTier, 1, 6)
		or type(raw.VerityUnlocked) ~= "boolean"
		or type(raw.PhoneSessionOpen) ~= "boolean"
	then return nil, "Invalid player state" end
	for _, key in { "NextVerityUpgradeCost", "NextSwipeUpgradeCost", "NextIncomePerSecond", "NextSwipeIncome" } do
		if raw[key] ~= nil and (not Model.IsFinite(raw[key]) or raw[key] < 0) then
			return nil, "Invalid " .. key
		end
	end
	if raw.VerityLevel < 100 and (raw.NextVerityUpgradeCost == nil or raw.NextIncomePerSecond == nil) then
		return nil, "Missing Verity quote"
	end
	if raw.SwipeUpgradeLevel < 40 and (raw.NextSwipeUpgradeCost == nil or raw.NextSwipeIncome == nil) then
		return nil, "Missing Swipe quote"
	end
	local state = table.clone(raw)
	state.Tasks = {}
	if type(raw.Tasks) == "table" then
		local seen = {}
		for _, entry in raw.Tasks do
			if type(entry) ~= "table" or type(entry.taskId) ~= "string" or not TaskConfig[entry.taskId] or seen[entry.taskId]
				or not Model.IsFinite(entry.reward) or entry.reward < 0
				or not Model.IsFinite(entry.cooldownEndsAt)
                or (entry.step ~= nil and not Model.IsInteger(entry.step,1,#TaskConfig[entry.taskId].Steps))
                or (entry.stepCount ~= nil and entry.stepCount ~= #TaskConfig[entry.taskId].Steps)
                or (entry.holdStartedAt ~= nil and not Model.IsFinite(entry.holdStartedAt))
				or (entry.status ~= "Ready" and entry.status ~= "Active" and entry.status ~= "Cooldown" and entry.status ~= "Done" and entry.status ~= "Locked" and entry.status ~= "Paused")
			then return nil, "Invalid task state" end
			seen[entry.taskId] = true
			table.insert(state.Tasks, table.clone(entry))
		end
	end
 if raw.Story~=nil then
  local story=raw.Story
  if type(story)~="table" or not Model.IsInteger(story.chapter,1,#StoryConfig.Chapters+1) or story.total~=#StoryConfig.Chapters
   or type(story.paused)~="boolean" or type(story.completed)~="boolean" or type(story.available)~="boolean"
   or story.completed~=(story.chapter>#StoryConfig.Chapters) or (not story.completed and story.taskId~=StoryConfig.Chapters[story.chapter].TaskId) then return nil,"Invalid story state" end
  state.Story=table.clone(story)
 end
	state.TutorialCompleted = raw.TutorialCompleted == true
	state.TutorialStep = if Model.IsInteger(raw.TutorialStep, 1, 7) then raw.TutorialStep else nil
	return state, nil
end

function Model.IsSwipe(dx: number, dy: number, height: number): boolean
	return dy <= -math.max(44, height * 0.13) and math.abs(dy) > math.abs(dx) * 1.2
end

return Model
