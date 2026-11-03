--!strict
local Recipe = require(script.Parent.MapRecipe)
local WorldBuilder = {}
local VERSION = "brick-floor-4"

function WorldBuilder.Build(parent: Instance?, plotCount: number?): Model
    local target = parent or workspace
    local count = plotCount or 16
    assert(count >= 16 and count <= 128 and count % 2 == 0, "PlotCount must be even, 16..128")
    local existing = target:FindFirstChild("GeneratedWorld")
    if existing then
        assert(existing:IsA("Model"), "GeneratedWorld name is occupied")
        if existing:GetAttribute("BuilderVersion") == VERSION and existing:GetAttribute("PlotCount") == count then
            return existing
        end
        error("GeneratedWorld already exists; preserve it or remove it explicitly before building")
    end
    local root = Instance.new("Model")
    root.Name = "GeneratedWorld"
    root:SetAttribute("BuilderVersion", VERSION)
    root:SetAttribute("PlotCount", count)
    local objects: {[string]: Instance} = {[""] = root}
    local function create(n: any, path: string, offset: Vector3?)
        local parentPath = path:match("^(.*)/[^/]+$") or ""
        local obj = Instance.new(n.cls) :: any
        obj.Name = path:match("[^/]+$") or "GeneratedWorld"
        if n.pos then
            obj.Anchored = true
            obj.CanCollide = n.collide
            obj.CanTouch = false
            obj.CanQuery = n.alpha < 1
            obj.CastShadow = n.alpha < 1
            obj.Material = Enum.Material.SmoothPlastic
            obj.TopSurface = if n.topSurface == "Studs" then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
            obj.BottomSurface = Enum.SurfaceType.Smooth
            obj.Size = Vector3.new(n.size[1], n.size[2], n.size[3])
            obj.CFrame = CFrame.new(Vector3.new(n.pos[1], n.pos[2], n.pos[3]) + (offset or Vector3.zero))
            if n.upright then obj.CFrame *= CFrame.Angles(0, 0, math.pi/2) end
            obj.Color = Color3.fromHex(n.color)
            obj.Transparency = n.alpha
            if obj:IsA("Part") then obj.Shape = Enum.PartType[n.shape] end
            if obj:IsA("SpawnLocation") then obj.Neutral = true; obj.Duration = 0 end
        end
        obj.Parent = assert(objects[parentPath], "Missing parent " .. parentPath)
        objects[path] = obj
        return obj
    end
    -- Environment adapts to the chosen number of pairs. Recipe positions represent 8 pairs.
    local extra = (count / 2 - 8) * 48
    for _, n in Recipe do
        if n.path ~= "" and not n.path:match("^Plots/Plot_") then
            local obj = create(n, n.path)
            if obj:IsA("BasePart") then
                if n.path == "Environment/Ground" then obj.Size += Vector3.new(0, 0, extra)
                elseif n.path:match("^Environment/Sidewalk") or n.path:match("^Environment/Curb") or n.path:match("^Environment/OuterGreen") or n.path == "Environment/Road" then
                    obj.Size += Vector3.new(0, 0, extra)
                elseif n.path:match("^Plaza/") or n.path:match("^Environment/EndPath") or n.path:match("^Environment/ParkTree") or n.path:match("^Environment/Bench") or n.path:match("^Environment/Crosswalk") then
                    local sign = if obj.Position.Z < 0 then -1 else 1
                    obj.CFrame += Vector3.new(0,0,sign*extra/2)
                elseif (n.path:match("RoadDash") or n.path:match("Lamp")) and math.abs(obj.Position.Z) > 192 + extra/2 then
                    obj:Destroy()
                end
            end
        end
    end
    for id = 1, count do
        local templateId = ((id - 1) % 16) + 1
        local sourcePrefix = string.format("Plots/Plot_%02d", templateId)
        local destination = string.format("Plots/Plot_%02d", id)
        local sourceRow = math.floor((templateId-1)/2)
        local row = math.floor((id-1)/2)
        local offset = Vector3.new(0,0,(row-(count/2-1)/2)*48 - (sourceRow-3.5)*48)
        for _, n in Recipe do
            if n.path == sourcePrefix or n.path:sub(1,#sourcePrefix+1) == sourcePrefix .. "/" then
                local obj = create(n, destination .. n.path:sub(#sourcePrefix+1), offset)
                if n.path == sourcePrefix then obj:SetAttribute("PlotId", id) end
            end
        end
    end
    root.Parent = target
    return root
end

return WorldBuilder
