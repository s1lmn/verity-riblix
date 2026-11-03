-- Temporary Studio-only visual review. Does not spend/save or change Core levels.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local source = ReplicatedStorage:WaitForChild("VerityCompanions",15)
local remote = source and source:WaitForChild("StudioSetLevel",15)
local descriptor = source and source:WaitForChild(tostring(player.UserId),15)
if not remote or not descriptor then return end
local gui = Instance.new("ScreenGui")
gui.Name = "VerityLevelPreview"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.DisplayOrder = 20
local panel = Instance.new("Frame")
panel.Name = "LevelPanel"
panel.AnchorPoint = Vector2.new(.5,1)
panel.Position = UDim2.new(.5,0,1,-12)
panel.Size = UDim2.fromOffset(234,96)
panel.BackgroundColor3 = Color3.fromRGB(36,39,66)
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0,12)
corner.Parent = panel
local label = Instance.new("TextLabel")
label.BackgroundTransparency = 1
label.Position = UDim2.fromOffset(8,5)
label.Size = UDim2.new(1,-16,0,28)
label.Font = Enum.Font.GothamBold
label.TextSize = 15
label.TextColor3 = Color3.new(1,1,1)
label.Parent = panel
local connections = {}
local buttons = {}
local function current()
    return descriptor:GetAttribute("Level") or 1
end
local function button(name,text,x,color,target)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Text = text
    b.Font = Enum.Font.GothamBold
    b.TextSize = 16
    b.Size = UDim2.fromOffset(68,48)
    b.Position = UDim2.fromOffset(x,39)
    b.BackgroundColor3 = color
    b.TextColor3 = Color3.fromRGB(30,30,50)
    b.Parent = panel
    local round = Instance.new("UICorner")
    round.CornerRadius = UDim.new(0,8)
    round.Parent = b
    connections[#connections+1] = b.Activated:Connect(function()
        remote:FireServer(math.clamp(target(current()),1,10))
    end)
    return b
end
buttons.minus = button("Previous","−",9,Color3.fromRGB(255,132,170),function(n) return n-1 end)
buttons.reset = button("Reset","В 1",83,Color3.fromRGB(255,213,54),function() return 1 end)
buttons.plus = button("Next","+",157,Color3.fromRGB(50,233,184),function(n) return n+1 end)
local function refresh()
    local n = current()
    label.Text = "STUDIO · VERITY "..n.." / 10"
    buttons.minus.Interactable = n>1
    buttons.plus.Interactable = n<10
    buttons.minus.BackgroundTransparency = if n>1 then 0 else .55
    buttons.plus.BackgroundTransparency = if n<10 then 0 else .55
end
connections[#connections+1] = descriptor:GetAttributeChangedSignal("Level"):Connect(refresh)
refresh()
gui.Parent = player:WaitForChild("PlayerGui")
script.Destroying:Connect(function()
    for _,connection in connections do connection:Disconnect() end
    gui:Destroy()
end)
