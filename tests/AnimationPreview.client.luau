--!nonstrict
if not game:GetService("RunService"):IsStudio() then return end
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local modules=player:WaitForChild("PlayerScripts",10):WaitForChild("VerityClient",10)
local Main=require(modules.MainUIController)
local deadline=os.clock()+10
while not Main.GetCurrent() and os.clock()<deadline do task.wait(0.05) end
local main=assert(Main.GetCurrent(),"UI bootstrap did not start")
local gui=Instance.new("ScreenGui")
gui.Name,gui.ResetOnSpawn,gui.DisplayOrder="AnimationPreviewBadge",false,25
gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets
local label=Instance.new("TextLabel")
label.Name,label.Size,label.Position="Instructions",UDim2.new(1,-32,0,72),UDim2.fromOffset(16,168)
label.BackgroundColor3,label.BackgroundTransparency=Color3.fromRGB(34,38,75),0.1
label.TextColor3,label.Font,label.TextSize=Color3.fromRGB(255,249,255),Enum.Font.GothamBold,14
label.TextWrapped=true
local function text(level,scale)
	label.Text="ANIMATION PREVIEW • no economy / no saved progress\nE: +1 level    R: next milestone sample    T: reset\n"..(if level then string.format("VERITY %d / 100 • %.3f×",level,scale) else "Walk to the preview controls beside Verity.")
end
text()
local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=label
label.Parent,gui.Parent=gui,player:WaitForChild("PlayerGui",10)
local connection=main.visuals.Started.Event:Connect(function(event)
	if event.ownerUserId==math.max(1,math.abs(player.UserId)) then text(event.newLevel,event.newScale) end
end)
script.Destroying:Connect(function() connection:Disconnect();gui:Destroy() end)
