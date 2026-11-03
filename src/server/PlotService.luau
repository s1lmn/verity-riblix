--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.GameConfig)
local Numeric = require(Shared.Numeric)
local Levels = require(Shared.LevelConfig)
local PlotService = {}
PlotService.__index = PlotService
function PlotService.new(count, capacity, isNear, layouts)
	assert(Numeric.isInteger(count, 1, 200) and Numeric.isInteger(capacity, 1, count), "Invalid capacity")
	local reservedWidth = Levels.MaxScale * Config.BaseWidth * Config.AnimationExpansion + 2 * Config.EffectMargin
	local reservedDepth = Levels.MaxScale * Config.BaseDepth * Config.AnimationExpansion + 2 * Config.EffectMargin
	assert(Config.PlotWidth >= reservedWidth and Config.PlotDepth >= reservedDepth + 10, "Plot too small")
	assert(Config.PlotSpacing >= Config.PlotDepth, "Overlapping plots")
	return setmetatable({count = count, capacity = capacity, plots = {}, owners = {},
		near = isNear, layouts = layouts}, PlotService)
end
function PlotService:GetLayout(plotId)
	assert(Numeric.isInteger(plotId, 1, self.count), "Invalid plot ID")
	if self.layouts then return table.clone(assert(self.layouts[plotId], "Missing World layout")) end
	local row = math.floor((plotId - 1) / 2)
	local side = if plotId % 2 == 1 then -1 else 1
	-- Coordinates are plain tables so World can consume them on either runtime.
	return {PlotId = plotId, X = side * (Config.RoadWidth / 2 + Config.SidewalkWidth + Config.PlotWidth / 2),
		Z = (row - (math.ceil(self.count / 2) - 1) / 2) * Config.PlotSpacing, Side = side,
		Width = Config.PlotWidth, Depth = Config.PlotDepth,
		ReservationWidth = Levels.MaxScale * Config.BaseWidth * Config.AnimationExpansion + 2 * Config.EffectMargin,
		ReservationDepth = Levels.MaxScale * Config.BaseDepth * Config.AnimationExpansion + 2 * Config.EffectMargin,
		ReservationHeight = Levels.MaxScale * Config.BaseHeight * Config.AnimationExpansion + Config.EffectMargin}
end
function PlotService:Assign(userId)
	if self.owners[userId] then return self.owners[userId], nil end
	local used = 0
	for _ in self.owners do used += 1 end
	if used >= self.capacity then return nil, "SERVER_FULL" end
	for id = 1, self.count do
		if not self.plots[id] then self.plots[id] = userId; self.owners[userId] = id; return id, nil end
	end
	return nil, "NO_PLOTS"
end
function PlotService:Release(userId)
	local id = self.owners[userId]
	if id then self.plots[id] = nil; self.owners[userId] = nil end
	return id
end
function PlotService:IsNear(userId, pointName)
	local id = self.owners[userId]
	return id ~= nil and self.plots[id] == userId and self.near(userId, id, pointName)
end
return PlotService
