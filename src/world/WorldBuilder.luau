local Recipe = require(script.Parent.MapRecipe)
local InteriorFactory = require(script.Parent.InteriorFactory)
local WorldBuilder = {}
local VERSION = "open-neighborhood-5"
local ROW_SPACING = 72
function WorldBuilder.Build(parent, plotCount)
    local target = parent or workspace
    local count = plotCount or 16
    assert(type(count) == "number" and count >= 16 and count <= 128 and count % 2 == 0, "PlotCount must be even, 16..128")
    local existing = target:FindFirstChild("GeneratedWorld")
    if existing then
        assert(existing:IsA("Model"), "GeneratedWorld name is occupied")
        if existing:GetAttribute("BuilderVersion") == VERSION and existing:GetAttribute("PlotCount") == count then return existing end
        error("Preserve/remove the previous GeneratedWorld explicitly before rebuilding v5")
    end
    local root = Instance.new("Model")
    root.Name = "GeneratedWorld"
    root:SetAttribute("BuilderVersion", VERSION)
    root:SetAttribute("PlotCount", count)
    local objects = {[""] = root}
    local function create(data, path, offset)
        local parentPath = path:match("^(.*)/[^/]+$") or ""
        local destination = assert(objects[parentPath], "Missing map parent " .. parentPath)
        local shift = offset or Vector3.zero
        local object
        if data.house then
            local pos = Vector3.new(data.origin[1], data.origin[2], data.origin[3]) + shift
            object = InteriorFactory.CreateHouse(destination, CFrame.new(pos) * CFrame.Angles(0, data.yaw, 0), Color3.fromHex(data.accent))
        else
            object = Instance.new(data.cls)
            object.Name = path:match("[^/]+$")
            if data.pos then
                object.Anchored = true
                object.CanCollide = data.collide
                object.CanTouch = false
                object.CanQuery = data.alpha < 1
                object.CastShadow = data.alpha == 0
                object.Material = if data.topSurface == "Studs" then Enum.Material.Plastic else Enum.Material.SmoothPlastic
                object.TopSurface = if data.topSurface == "Studs" then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
                object.BottomSurface = Enum.SurfaceType.Smooth
                object.Size = Vector3.new(data.size[1], data.size[2], data.size[3])
                object.CFrame = CFrame.new(Vector3.new(data.pos[1], data.pos[2], data.pos[3]) + shift)
                if data.upright then object.CFrame *= CFrame.Angles(0, 0, math.pi/2) end
                object.Color = Color3.fromHex(data.color)
                object.Transparency = data.alpha
                if object:IsA("Part") then object.Shape = Enum.PartType[data.shape] end
                if object:IsA("SpawnLocation") then object.Neutral = true; object.Duration = 0 end
            end
            object.Parent = destination
        end
        objects[path] = object
        return object
    end
    local extra = (count / 2 - 8) * ROW_SPACING
    for _, data in Recipe do
        if data.path ~= "" and not data.path:match("^Plots/Plot_") then
            local object = create(data, data.path)
            if object:IsA("BasePart") then
                local name = object.Name
                if name == "Ground" or name == "Road" or name:match("^Sidewalk") or name:match("^Curb") then
                    object.Size += Vector3.new(0, 0, extra)
                elseif name:match("^EndPath") or name:match("^Crosswalk") or data.path:match("^Plaza/") or data.path:match("^Environment/Park") then
                    local sign = if object.Position.Z < 0 then -1 else 1
                    object.CFrame += Vector3.new(0, 0, sign * extra / 2)
                end
            end
        end
    end
    for id = 1, count do
        local templateId = ((id - 1) % 16) + 1
        local sourcePrefix = string.format("Plots/Plot_%02d", templateId)
        local destination = string.format("Plots/Plot_%02d", id)
        local sourceRow = math.floor((templateId - 1) / 2)
        local row = math.floor((id - 1) / 2)
        local offset = Vector3.new(0, 0, (row - (count/2 - 1)/2) * ROW_SPACING - (sourceRow - 3.5) * ROW_SPACING)
        for _, data in Recipe do
            if data.path == sourcePrefix or data.path:sub(1, #sourcePrefix + 1) == sourcePrefix .. "/" then
                local object = create(data, destination .. data.path:sub(#sourcePrefix + 1), offset)
                if data.path == sourcePrefix then object:SetAttribute("PlotId", id) end
            end
        end
    end
    root.Parent = target
    return root
end
return WorldBuilder
