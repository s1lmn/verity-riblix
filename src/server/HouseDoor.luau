--!nonstrict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Door = {}
Door.__index = Door

local OPEN_ANGLE = math.rad(88)
local SWING_TIME = 0.55
local LEAF_OFFSET = CFrame.new(3.745, 4.45, 0)
local LEAF_SIZE = Vector3.new(7.41, 8.72, 0.44)

local function detail(parent, name, position, size, color)
	local part = Instance.new("Part")
	part.Name, part.Anchored = name, true
	part.CFrame, part.Size = CFrame.new(position), size
	part.Color, part.Material = Color3.fromHex(color), Enum.Material.SmoothPlastic
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.Parent = parent
	return part
end

function Door.new(parent, housePivot)
	local model = Instance.new("Model")
	model.Name = "OwnerDoor"
	local leaf = detail(model, "Leaf", LEAF_OFFSET.Position, LEAF_SIZE, "794942")
	for _, side in {-1, 1} do
		for _, panel in {{"Upper", 6.35, 3.2}, {"Lower", 2.37, 2.65}} do
			detail(model, panel[1] .. "Moulding", Vector3.new(3.7, panel[2], side * .245),
				Vector3.new(5.3, panel[3], .12), "55374B")
			detail(model, panel[1] .. "Panel", Vector3.new(3.7, panel[2], side * .34),
				Vector3.new(4.92, panel[3] - .38, .10), "A76A54")
		end
		detail(model, "HandlePlate", Vector3.new(6.72, 4.1, side * .25), Vector3.new(.48, 1.35, .13), "65485A")
		detail(model, "HandleStem", Vector3.new(6.72, 4.3, side * .39), Vector3.new(.24, .24, .28), "D9A75B")
		detail(model, "Handle", Vector3.new(6.42, 4.3, side * .55), Vector3.new(.82, .21, .23), "FFD584")
	end
	for _, y in {1.55, 7.45} do
		local hinge = detail(model, "Hinge", Vector3.new(0, y, 0), Vector3.new(.8, .22, .22), "D9A75B")
		hinge.Shape = Enum.PartType.Cylinder
		hinge.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
	end
	model.WorldPivot = CFrame.identity
	local axis = housePivot * CFrame.new(-3.64, 0, 14.25)
	model:PivotTo(axis)
	return setmetatable({model = model, leaf = leaf, parent = parent, axis = axis, angle = 0}, Door)
end

function Door:Stop()
	if self.motion then self.motion:Disconnect(); self.motion = nil end
end

function Door:Apply(angle)
	self.angle = angle
	self.model:PivotTo(self.axis * CFrame.Angles(0, angle, 0))
end

function Door:Set(owned, closed, animate)
	self:Stop()
	self.leaf.CanCollide, self.leaf.CanQuery = owned, owned
	local target = if closed then 0 else OPEN_ANGLE
	if not owned or not animate or math.abs(target - self.angle) < .001 then
		self:Apply(target)
		self.model.Parent = if owned then self.parent else nil
		return
	end
	local from, elapsed = self.angle, 0
	local duration = math.max(.16, SWING_TIME * math.abs(target - from) / OPEN_ANGLE)
	self.motion = RunService.Heartbeat:Connect(function(dt)
		local nextElapsed = math.min(duration, elapsed + math.min(dt, 1 / 30))
		local t = nextElapsed / duration
		local nextAngle = from + (target - from) * t * t * (3 - 2 * t)
		local nextLeaf = self.axis * CFrame.Angles(0, nextAngle, 0) * LEAF_OFFSET
		for _, player in Players:GetPlayers() do
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if not root then continue end
			local position = nextLeaf:PointToObjectSpace(root.Position)
			if math.abs(position.X) < LEAF_SIZE.X / 2 + 1.1 and math.abs(position.Y) < LEAF_SIZE.Y / 2 + 1
				and math.abs(position.Z) < 1.1 then
				local previousZ = self.leaf.CFrame:PointToObjectSpace(root.Position).Z
				if previousZ * position.Z <= 0 or math.abs(position.Z) <= math.abs(previousZ) then return end
			end
		end
		elapsed = nextElapsed
		self:Apply(nextAngle)
		if elapsed == duration then self:Stop() end
	end)
end

return Door
