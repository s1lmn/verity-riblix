--!nonstrict
-- Trace the exposed edges of the neighborhood and its attached activity islands.
local Boundary = {}
local EPSILON = .01
local WALL_TOP = 160
local POST_SPACING = 24
local colors = {"7DDCC3", "8FCDF8", "C5A4F1", "FFE09D"}

local function part(parent, name, frame, size, color, solid)
	local object = Instance.new("Part")
	object.Name, object.Anchored = name, true
	object.CFrame, object.Size = frame, size
	object.Material, object.Color = Enum.Material.Plastic, Color3.fromHex(color)
	object.CanCollide, object.CanTouch, object.CanQuery = solid, false, solid
	object.CastShadow = false
	object.Parent = parent
	return object
end

function Boundary.Build(world)
	local floors = {world.Environment.Ground, world.VerityParkour.Island, world.VerityRaceTrack.RaceIsland}
 local keys={}
 for _,floor in floors do table.insert(keys,tostring(floor.Position)..":"..tostring(floor.Size)) end
 local signature=table.concat(keys,"|")
 local old=world:FindFirstChild("MapBoundary")
 if old and old:GetAttribute("BoundsSignature")==signature then return end
 if old then old:Destroy() end
	local bounds = {}
	for _, floor in floors do
		local half = floor.Size / 2
		table.insert(bounds, {low = floor.Position - half, high = floor.Position + half})
	end
	local folder = Instance.new("Folder")
	folder.Name = "MapBoundary"
 folder:SetAttribute("BoundsSignature",signature)
	local posts = {}
	local function draw(from, to)
		local length = (to - from).Magnitude
		if length < EPSILON then return end
		local direction = (to - from).Unit
		local count = math.ceil(length / POST_SPACING)
		local span = length / count
		for i = 0, count do
			local point = from + direction * (span * i)
			local key = string.format("%.2f:%.2f", point.X, point.Z)
			if not posts[key] then
				posts[key] = true
				local post = part(folder, "FencePost", CFrame.new(point + Vector3.new(0, 2.8, 0)), Vector3.new(1.7, 5.6, 1.7), "FFF0CF", false)
				post.TopSurface = Enum.SurfaceType.Studs
			end
			if i == count then break end
			local middle = point + direction * (span / 2)
			local frame = CFrame.lookAt(middle, middle + direction)
			-- Keep the collision continuous from below the grass to above the flight ceiling.
			local barrier = part(folder, "EdgeBarrier", frame * CFrame.new(0, (WALL_TOP - 4) / 2, 0),
				Vector3.new(1.25, WALL_TOP + 4, span), "7DDCC3", true)
			barrier.Transparency = 1
			if span > 1.7 then
				local panelLength = span - 1.7
				part(folder, "FencePanel", frame * CFrame.new(0, 2.1, 0), Vector3.new(1.12, 4.2, panelLength), colors[i % #colors + 1], false)
				part(folder, "FenceCap", frame * CFrame.new(0, 4.45, 0), Vector3.new(1.36, .5, panelLength), "FFF0CF", false)
			end
		end
	end

	for _, floor in bounds do
		for _, axis in {"X", "Z"} do
			local along = if axis == "X" then "Z" else "X"
			for _, sign in {-1, 1} do
				local edge = if sign < 0 then floor.low[axis] else floor.high[axis]
				local spans = {{floor.low[along], floor.high[along]}}
				for _, neighbor in bounds do
					if neighbor == floor then continue end
					local joint = if sign < 0 then neighbor.high[axis] else neighbor.low[axis]
					if math.abs(edge - joint) > EPSILON then continue end
					local cutFrom, cutTo = neighbor.low[along], neighbor.high[along]
					local remaining = {}
					for _, span in spans do
						local a, b = span[1], span[2]
						if cutTo <= a or cutFrom >= b then table.insert(remaining, span)
						else
							if cutFrom > a then table.insert(remaining, {a, cutFrom}) end
							if cutTo < b then table.insert(remaining, {cutTo, b}) end
						end
					end
					spans = remaining
				end
				for _, span in spans do
					local a, b = span[1], span[2]
					if axis == "X" then draw(Vector3.new(edge, floor.high.Y, a), Vector3.new(edge, floor.high.Y, b))
					else draw(Vector3.new(a, floor.high.Y, edge), Vector3.new(b, floor.high.Y, edge)) end
				end
			end
		end
	end
	folder.Parent = world
end

return Boundary
