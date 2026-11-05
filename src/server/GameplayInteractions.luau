--!nonstrict
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local LocaleText = require(Shared.LocaleText)
local TaskConfig = require(Shared.TaskConfig)
-- Gameplay objects are separate from the approved World geometry.
local Interactions = {}
function Interactions.Start(workspace, world, tasks, state)
	local folder=Instance.new("Folder");folder.Name="GameplayInteractions";folder.Parent=workspace
	local map=workspace.GeneratedWorld
	local plaza=map.Plaza.WelcomePad
	local function sidewalkPosition(side, distance, height)
		local sidewalk=map.Environment:FindFirstChild("Sidewalk"..side)
		return Vector3.new(sidewalk.Position.X,sidewalk.Position.Y+sidewalk.Size.Y/2+height,plaza.Position.Z+distance)
	end
	local definitions={
		{Id="PRESS_BUTTON",Offset=Vector3.new(-7,1.5,0),Color=Color3.fromRGB(255,210,50),Text="КНОПКА • $20"},
		{Id="REACH_POINT",Offset=Vector3.new(7,0.55,0),Color=Color3.fromRGB(255,110,170),Text="МЕТКА • $40"},
		{Id="STAND_ON_PLATFORM",Offset=Vector3.new(0,0.55,5),Color=Color3.fromRGB(90,210,255),Text="ПОСТОЙ 1с • $25"},
		{Id="POSTBOX",Position=sidewalkPosition(-1,44,1.05),Color=Color3.fromHex("F7A946"),Text="ПОЧТОВЫЙ ЯЩИК",Action="Отправить"},
		{Id="CHECKPOINT",Position=sidewalkPosition(1,75,.15),Color=Color3.fromHex("A575FF"),Text="СИРЕНЕВАЯ МЕТКА"},
		{Id="CHARGE_PAD",Position=sidewalkPosition(-1,108,.15),Color=Color3.fromHex("6BF1AD"),Text="ЗАРЯДНАЯ ПЛОЩАДКА"},
	}
	for _,def in definitions do
		local part=Instance.new("Part");part.Name=def.Id;part.Anchored=true
		local config=TaskConfig[def.Id]
		part.Size=if config.Mode=="Prompt" then Vector3.new(3,2,3) else Vector3.new(5,0.3,5)
		part.Position=def.Position or plaza.Position+def.Offset;part.Color=def.Color
		if def.Position then part.CanTouch=false;part.CastShadow=false end
		part.Material=Enum.Material.SmoothPlastic;part:SetAttribute("TaskId",def.Id);part.Parent=folder
		world:RegisterTaskTarget(def.Id,part)
		local gui=Instance.new("BillboardGui");gui.Name="TaskLabel";gui.Size=UDim2.fromOffset(150,35)
		gui.StudsOffsetWorldSpace=Vector3.new(0,3,0);gui.MaxDistance=24;gui.Parent=part
		local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
		LocaleText.SetWorld(label,"Text",def.Text);label.Font=Enum.Font.GothamBold;label.TextSize=16;label.TextColor3=Color3.fromRGB(30,35,70)
		label.TextStrokeColor3=Color3.new(1,1,1);label.TextStrokeTransparency=0.2;label.Parent=gui
		if config.Mode=="Prompt" then
			local prompt=Instance.new("ProximityPrompt");LocaleText.SetWorld(prompt,"ActionText",def.Action or "Нажать");LocaleText.SetWorld(prompt,"ObjectText",if def.Action then def.Text else "Кнопка задания")
			prompt.MaxActivationDistance=config.Radius;prompt.RequiresLineOfSight=false;prompt.Parent=part
			prompt.Triggered:Connect(function(player)
				local near,alive=world:IsNearTask(player.UserId,def.Id)
				if not near or not alive then return end
				if def.Id=="PRESS_BUTTON" then tasks:Start(player.UserId,def.Id) end
				tasks:Complete(player.UserId,def.Id)
				state:Publish(player.UserId,true)
			end)
		end
	end
	state.TaskPosition=function(taskId) local target=world.targets[taskId];return target and target.Position end
	return folder
end
return Interactions
