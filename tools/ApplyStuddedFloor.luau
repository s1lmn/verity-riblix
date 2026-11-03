-- Paste into Roblox Studio Command Bar in Edit mode to update an existing map.
-- No objects are created or replaced; only selected floor TopSurface properties change.
local world = workspace:FindFirstChild("GeneratedWorld")
assert(world, "GeneratedWorld was not found in Workspace")
local environment = world:FindFirstChild("Environment")
local plots = world:FindFirstChild("Plots")
local changed = 0
local function apply(part)
    if part and part:IsA("BasePart") then
        part.TopSurface = Enum.SurfaceType.Studs
        changed += 1
    end
end
if environment then
    for _, part in environment:GetChildren() do
        local name = part.Name
        if name == "Ground" or name == "Road" or name:match("^Sidewalk")
            or name:match("^OuterGreen") or name:match("^EndPath") then
            apply(part)
        end
    end
end
if plots then
    for _, plot in plots:GetChildren() do
        apply(plot:FindFirstChild("Lawn"))
        apply(plot:FindFirstChild("Path"))
    end
end
print(string.format("Applied fine studs to %d floor surfaces", changed))
