-- Cosmetic descriptor root exists before any later Core unlock.
local Service = require(game:GetService("ReplicatedStorage"):WaitForChild("World"):WaitForChild("VerityCompanionService"))
Service.Initialize()
Service.StartStudioPreview() -- guarded by RunService:IsStudio() and config inside the service
