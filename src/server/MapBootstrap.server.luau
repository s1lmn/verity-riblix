-- Standalone map preview. Integrators can call WorldBuilder.Build themselves.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local WorldBuilder = require(ReplicatedStorage:WaitForChild("World"):WaitForChild("WorldBuilder"))
local world = WorldBuilder.Build(workspace, 16)
-- Rojo sync preserves the Studio template's Baseplate. Its top is Y=0,
-- exactly coplanar with our Ground, so both stud surfaces fight for depth.
-- Park only that overlapping template floor; Stop restores the Edit scene.
local baseplate = workspace:FindFirstChild("Baseplate")
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
Lighting.ClockTime = 13.5
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(158, 166, 184)
Lighting.OutdoorAmbient = Color3.fromRGB(179, 184, 194)
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.4
