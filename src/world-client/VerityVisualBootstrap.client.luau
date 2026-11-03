-- Separate World presentation bootstrap; does not modify the UI team's files.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local world=ReplicatedStorage:WaitForChild("World",15)
if not world then warn("Verity World modules unavailable");return end
local Service=require(world:WaitForChild("VerityVisualService",15))
local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui",15)
if not playerGui then return end
local guiConnections={}
local connections={}
local function bindSettings()
    for _,c in guiConnections do c:Disconnect() end;table.clear(guiConnections)
    local gui=playerGui:FindFirstChild("VerityUI")
    local function refresh()
        Service.SetOptions({
            ReducedMotion=(gui and gui:GetAttribute("ReducedMotion")==true) or workspace:GetAttribute("VerityReducedMotion")==true,
            ReducedEffects=(gui and gui:GetAttribute("ReducedEffects")==true) or workspace:GetAttribute("VerityReducedEffects")==true,
        })
    end
    if gui then
        table.insert(guiConnections,gui:GetAttributeChangedSignal("ReducedMotion"):Connect(refresh))
        table.insert(guiConnections,gui:GetAttributeChangedSignal("ReducedEffects"):Connect(refresh))
    end
    refresh()
end
table.insert(connections,playerGui.ChildAdded:Connect(function(x) if x.Name=="VerityUI" then bindSettings() end end))
table.insert(connections,playerGui.ChildRemoved:Connect(function(x) if x.Name=="VerityUI" then bindSettings() end end))
table.insert(connections,workspace:GetAttributeChangedSignal("VerityReducedMotion"):Connect(bindSettings))
table.insert(connections,workspace:GetAttributeChangedSignal("VerityReducedEffects"):Connect(bindSettings))
bindSettings();Service.Start()
script.Destroying:Connect(function()
    for _,c in connections do c:Disconnect() end
    for _,c in guiConnections do c:Disconnect() end
    Service.Stop()
end)
