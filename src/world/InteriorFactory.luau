-- World-owned construction only. Core owns per-player rooms and transitions.
local Recipe = require(script.Parent.InteriorRecipe)
local InteriorFactory = {}

function InteriorFactory.CreateTemplate(parent)
    assert(typeof(parent) == "Instance", "Template parent must be an Instance")
    local root = Instance.new("Model")
    root.Name = "StandardInterior"
    root.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    root:SetAttribute("TemplateId", "StandardInterior")
    root:SetAttribute("TemplateVersion", 2)
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
            object.CastShadow = data.alpha < 1
            object.Material = Enum.Material.SmoothPlastic
            object.TopSurface = if data.topSurface == "Studs" then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
            object.BottomSurface = Enum.SurfaceType.Smooth
            object.Size = Vector3.new(data.size[1], data.size[2], data.size[3])
            object.CFrame = CFrame.new(data.pos[1], data.pos[2], data.pos[3])
            object.Color = Color3.fromHex(data.color)
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
        object.Parent = assert(objects[parentPath], "Missing interior parent " .. parentPath)
        objects[data.path] = object
    end
    root.PrimaryPart = objects["Geometry/Floor"]
    root.PrimaryPart.PivotOffset = CFrame.new(0, 0.5, 0)
    root.Parent = parent
    return root
end

function InteriorFactory.EnsureTemplate(serverStorage)
    assert(serverStorage == game:GetService("ServerStorage"), "Templates belong in ServerStorage")
    local templates = serverStorage:FindFirstChild("InteriorTemplates")
    if not templates then
        templates = Instance.new("Folder")
        templates.Name = "InteriorTemplates"
        templates.Parent = serverStorage
    end
    local existing = templates:FindFirstChild("StandardInterior")
    if existing then
        assert(existing:IsA("Model"), "StandardInterior name is occupied")
        assert(existing:FindFirstChild("Geometry") and existing:FindFirstChild("Furniture") and existing:FindFirstChild("Markers"), "Invalid interior template")
        assert(existing.Geometry:FindFirstChild("UpperFloorMain") and existing.Markers:FindFirstChild("UpstairsPoint"), "Outdated interior template: import v2 or remove the old template explicitly")
        existing:SetAttribute("TemplateId", "StandardInterior")
        existing:SetAttribute("TemplateVersion", 2)
        return existing
    end
    return InteriorFactory.CreateTemplate(templates)
end

-- Add invisible markers to the approved v4 map, preserving all existing geometry.
-- The positions match its explicit plot layout. Core supplies ownership/prompts.
function InteriorFactory.AddPlotMarkers(world)
    local plots = assert(world:FindFirstChild("Plots"), "Plots are missing")
    local count = 0
    for _, plot in plots:GetChildren() do
        if plot:IsA("Model") then
            local markers = plot:FindFirstChild("Markers")
            local spawn = markers and markers:FindFirstChild("SpawnPoint")
            if spawn and spawn:IsA("BasePart") then
                -- In v4 SpawnPoint faces the house entrance across the existing path.
                -- Determine road side from the known spawn position, not House bounds.
                local side = if spawn.Position.X < 0 then -1 else 1
                local entry = Vector3.new(side * 46, 3, spawn.Position.Z)
                local destination = Vector3.new(side * 41, 3, spawn.Position.Z)
                for _, spec in {{"InteriorEntrance", entry}, {"InteriorReturn", destination}} do
                    local marker = markers:FindFirstChild(spec[1])
                    if marker then
                        assert(marker:IsA("BasePart"), "Interior marker name is occupied")
                    else
                        marker = Instance.new("Part")
                        marker.Name = spec[1]
                        marker.Size = Vector3.one
                        marker.Transparency = 1
                        marker.Anchored = true
                        marker.CanCollide = false
                        marker.CanTouch = false
                        marker.CanQuery = false
                        marker.CastShadow = false
                        marker.CFrame = CFrame.lookAt(spec[2], spec[2] + Vector3.new(-side, 0, 0))
                        marker.Parent = markers
                    end
                end
                count += 1
            end
        end
    end
    return count
end

return InteriorFactory
