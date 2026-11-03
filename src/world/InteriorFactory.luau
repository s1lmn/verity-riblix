-- World-owned walk-in houses. Geometry lives on the plot; no player teleporting.
local Recipe = require(script.Parent.InteriorRecipe)
local InteriorFactory = {}
local function construct(parent, origin, accent, name)
    assert(typeof(parent) == "Instance", "House parent must be an Instance")
    assert(typeof(origin) == "CFrame", "House origin must be a CFrame")
    local root = Instance.new("Model")
    root.Name = name
    root.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    root:SetAttribute("InteriorVersion", 3)
    root:SetAttribute("EntryMode", "WalkIn")
    local objects = {[""] = root}
    for _, data in Recipe do
        local parentPath = data.path:match("^(.*)/[^/]+$") or ""
        local object = Instance.new(data.cls)
        object.Name = data.path:match("[^/]+$")
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
            object.CFrame = CFrame.new(data.pos[1], data.pos[2], data.pos[3])
            object.Color = if data.accent and accent then accent else Color3.fromHex(data.color)
            object.Transparency = data.alpha
            if data.light then
                local light = Instance.new("PointLight")
                light.Name = "InteriorLight"
                light.Brightness = 1.2
                light.Range = 24
                light.Shadows = false
                light.Parent = object
            end
        end
        object.Parent = assert(objects[parentPath], "Missing house parent " .. parentPath)
        objects[data.path] = object
    end
    root.PrimaryPart = objects["Geometry/Floor"]
    root.PrimaryPart.PivotOffset = CFrame.new(0, 0.5, 0)
    root:PivotTo(origin)
    root.Parent = parent
    return root
end
function InteriorFactory.CreateHouse(parent, origin, accent)
    return construct(parent, origin, accent, "House")
end
-- Optional authoring preview; WorldBuilder uses CreateHouse on each plot.
function InteriorFactory.CreateTemplate(parent)
    return construct(parent, CFrame.identity, nil, "StandardInterior")
end
return InteriorFactory
