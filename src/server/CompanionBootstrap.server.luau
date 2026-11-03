-- Prevent stale Rojo preview/game scripts from starting a second runtime.
if game:GetService("ReplicatedStorage"):GetAttribute("VerityRuntimeMode")=="Core" then return end
-- Cosmetic descriptor root exists before any later Core unlock.
local Service = require(game:GetService("ReplicatedStorage"):WaitForChild("World"):WaitForChild("VerityCompanionService"))
Service.Initialize()
Service.StartStudioPreview() -- guarded by RunService:IsStudio() and config inside the service
