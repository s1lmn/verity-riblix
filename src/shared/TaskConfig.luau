--!strict
type Task = {Reward: number, Cooldown: number, HoldSeconds: number, Radius: number, Mode: string, CooldownField: string}
local tasks: {[string]: Task} = {
	PRESS_BUTTON = table.freeze({Reward = 20, Cooldown = 8, HoldSeconds = 0, Radius = 8, Mode = "Prompt", CooldownField = "TaskCooldowns"}),
	REACH_POINT = table.freeze({Reward = 40, Cooldown = 12, HoldSeconds = 0, Radius = 8, Mode = "Reach", CooldownField = "TaskCooldowns"}),
	STAND_ON_PLATFORM = table.freeze({Reward = 25, Cooldown = 10, HoldSeconds = 1, Radius = 8, Mode = "Hold", CooldownField = "TaskCooldowns"}),
	POSTBOX = table.freeze({Reward = 55, Cooldown = 35, HoldSeconds = 0, Radius = 7, Mode = "Prompt", CooldownField = "NeighborhoodTaskCooldowns"}),
	CHECKPOINT = table.freeze({Reward = 65, Cooldown = 45, HoldSeconds = 0, Radius = 4, Mode = "Reach", CooldownField = "NeighborhoodTaskCooldowns"}),
	CHARGE_PAD = table.freeze({Reward = 75, Cooldown = 50, HoldSeconds = 3, Radius = 8, Mode = "Hold", CooldownField = "NeighborhoodTaskCooldowns"}),
}
return table.freeze(tasks)
