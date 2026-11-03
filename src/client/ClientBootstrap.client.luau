--!nonstrict
local MainUIController=require(script.Parent.MainUIController)
local controller=MainUIController.new()
script.Destroying:Connect(function() controller:Destroy() end)
