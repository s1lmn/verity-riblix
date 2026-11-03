--!nonstrict
-- Prevent stale Rojo preview/game scripts from starting a second runtime.
if game:GetService("ReplicatedStorage"):GetAttribute("VerityRuntimeMode")=="Preview" then return end
local MainUIController=require(script.Parent.MainUIController)
local controller=MainUIController.new()
script.Destroying:Connect(function() controller:Destroy() end)
