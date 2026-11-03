--!nonstrict
-- Gameplay objects are separate from the approved World geometry.
local Interactions = {}
function Interactions.Start(workspace, world, tasks, state, send, guid)
	local folder=Instance.new("Folder");folder.Name="GameplayInteractions";folder.Parent=workspace
	local plaza=workspace.GeneratedWorld.Plaza.WelcomePad
	local definitions={
		{Id="PRESS_BUTTON",Offset=Vector3.new(-7,1.5,0),Color=Color3.fromRGB(255,210,50),Text="PRESS • $20"},
		{Id="REACH_POINT",Offset=Vector3.new(7,0.55,0),Color=Color3.fromRGB(255,110,170),Text="REACH • $40"},
		{Id="STAND_ON_PLATFORM",Offset=Vector3.new(0,0.55,5),Color=Color3.fromRGB(90,210,255),Text="STAND1s • $25"},
	}
	for _,def in definitions do
		local part=Instance.new("Part");part.Name=def.Id;part.Anchored=true
		part.Size=if def.Id=="PRESS_BUTTON" then Vector3.new(3,2,3) else Vector3.new(5,0.3,5)
		part.Position=plaza.Position+def.Offset;part.Color=def.Color
		part.Material=Enum.Material.SmoothPlastic;part:SetAttribute("TaskId",def.Id);part.Parent=folder
		world:RegisterTaskTarget(def.Id,part)
		local gui=Instance.new("BillboardGui");gui.Name="TaskLabel";gui.Size=UDim2.fromOffset(150,35)
		gui.StudsOffsetWorldSpace=Vector3.new(0,3,0);gui.MaxDistance=140;gui.Parent=part
		local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
		label.Text=def.Text;label.Font=Enum.Font.GothamBold;label.TextSize=16;label.TextColor3=Color3.fromRGB(30,35,70)
		label.TextStrokeColor3=Color3.new(1,1,1);label.TextStrokeTransparency=0.2;label.Parent=gui
		if def.Id=="PRESS_BUTTON" then
			local prompt=Instance.new("ProximityPrompt");prompt.ActionText="Press";prompt.ObjectText="Task button"
			prompt.MaxActivationDistance=8;prompt.RequiresLineOfSight=false;prompt.Parent=part
			prompt.Triggered:Connect(function(player)
				local near,alive=world:IsNearTask(player.UserId,def.Id)
				if not near or not alive then return end
				tasks:Start(player.UserId,def.Id)
				local status,reward=tasks:Complete(player.UserId,def.Id)
				state:Publish(player.UserId,true)
			end)
		end
	end
	state.TaskPosition=function(taskId) local target=world.targets[taskId];return target and target.Position end
	return folder
end
return Interactions
