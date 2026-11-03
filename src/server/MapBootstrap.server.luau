-- Standalone map preview. Integrators can call WorldBuilder.Build themselves.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local WorldBuilder = require(ReplicatedStorage:WaitForChild("World"):WaitForChild("WorldBuilder"))
WorldBuilder.Build(workspace, 16)
Lighting.ClockTime = 13.5
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(158, 166, 184)
Lighting.OutdoorAmbient = Color3.fromRGB(179, 184, 194)
Lighting.GlobalShadows = true
Lighting.ShadowSoftness = 0.4
