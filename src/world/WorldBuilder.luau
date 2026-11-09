local Recipe = require(script.Parent.MapRecipe)
local InteriorFactory = require(script.Parent.InteriorFactory)
local ParkourBuilder = require(script.Parent.ParkourBuilder)
local RaceBuilder = require(script.Parent.VerityRaceBuilder)
local SurfaceTiles = require(script.Parent.WorldSurfaceTiles)
local Boundary = require(script.Parent.WorldBoundary)
local WorldBuilder = {}
local VERSION = "open-neighborhood-6-compact"
local ROW_SPACING = 72

local function prepareWorld(world)
    local spawn = world.Plaza.WelcomeSpawn
    local road = world.Environment.Road
    spawn.CFrame = CFrame.new(road.Position + Vector3.yAxis * (road.Size.Y/2 + .1))
    spawn.Transparency = 1
    spawn.CanCollide, spawn.CanTouch, spawn.CanQuery = false, false, false
    if not world:FindFirstChild("AbilityCampusGround") then
        local ground = world.Environment.Ground
        local part = Instance.new("Part")
        part.Name = "AbilityCampusGround"
        part.Size = Vector3.new(112, ground.Size.Y, 110)
        part.Position = ground.Position - Vector3.new((ground.Size.X + part.Size.X)/2, 0, (ground.Size.Z - part.Size.Z)/2)
        part.Anchored = true
        part.CanTouch = false
        part.Color = ground.Color
        part.Material = ground.Material
        part.Parent = world
    end
    Boundary.Build(world)
end

local function parkTemplateFloor(target, world)
    -- Rojo sync preserves the Studio template's Baseplate. Its top is Y=0,
    -- exactly coplanar with our Ground, so both stud surfaces fight for depth.
    -- Park only that overlapping template floor; Stop restores the Edit scene.
    local baseplate = target:FindFirstChild("Baseplate")
    local ground = world:FindFirstChild("Environment") and world.Environment:FindFirstChild("Ground")
    if baseplate and baseplate:IsA("BasePart") and ground then
        local flat = baseplate.CFrame.UpVector:Dot(Vector3.yAxis) > .9999
        local sameHeight = math.abs(baseplate.Position.Y + baseplate.Size.Y/2 - (ground.Position.Y + ground.Size.Y/2)) < .05
        local overlaps = math.abs(baseplate.Position.X-ground.Position.X) < (baseplate.Size.X+ground.Size.X)/2
            and math.abs(baseplate.Position.Z-ground.Position.Z) < (baseplate.Size.Z+ground.Size.Z)/2
        if flat and sameHeight and overlaps then
            local storage = Instance.new("Folder")
            storage.Name = "VerityTemplateFloor"
            storage.Parent = game:GetService("ServerStorage")
            baseplate.Parent = storage
            print("[Verity map] Parked coplanar Studio Baseplate to prevent floor flicker")
        end
    end
end
function WorldBuilder.Build(parent, plotCount)
    local target = parent or workspace
    local count = plotCount or 12
    assert(type(count) == "number" and count >= 12 and count <= 128 and count % 2 == 0, "PlotCount must be even, 12..128")
    local existing = target:FindFirstChild("GeneratedWorld")
    -- Explicit migration of our generated 16-house map; unrelated/custom worlds remain protected.
    if existing and count==12 and existing:IsA("Model") and existing:GetAttribute("PlotCount")==16
      and existing:GetAttribute("BuilderVersion")=="open-neighborhood-5" then
        existing:Destroy();existing=nil
    end
    if existing then
        assert(existing:IsA("Model"), "GeneratedWorld name is occupied")
        if existing:GetAttribute("BuilderVersion") == VERSION and existing:GetAttribute("PlotCount") == count then
            ParkourBuilder.Build(existing)
            RaceBuilder.Build(existing)
            SurfaceTiles.Build(existing)
            prepareWorld(existing)
            parkTemplateFloor(target, existing)
            return existing
        end
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
                object.CastShadow = data.alpha == 0 and data.collide and data.size[1]*data.size[2]*data.size[3]>=6
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
        if data.path ~= "" and not data.path:match("^Plots/Plot_") and not (data.path:match("/RoadDash") and math.abs(data.pos[3])+data.size[3]/2>310+extra/2) then
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
    ParkourBuilder.Build(root)
    RaceBuilder.Build(root)
    SurfaceTiles.Build(root)
    prepareWorld(root)
    parkTemplateFloor(target, root)
    root.Parent = target
    return root
end
return WorldBuilder
