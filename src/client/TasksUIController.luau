--!nonstrict
local Players=game:GetService("Players")
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local Model=require(script.Parent.UIModel)
local Tasks={}
Tasks.__index=Tasks
local Titles={PRESS_BUTTON="PRESS THE BUTTON",REACH_POINT="TAKE A LITTLE WALK",STAND_ON_PLATFORM="STAY A MOMENT"}

function Tasks.new(ctx)
	local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),target=nil},Tasks)
	for taskId,row in ctx.refs.Panels.TASKS.Rows do
		self.cleanup:Add(row.Button.Activated:Connect(function()
			local state=ctx.net.state
			if not state then return end
			for _,entry in state.Tasks do
				if entry.taskId==taskId then
					if entry.status=="Ready" or (entry.status=="Cooldown" and entry.cooldownEndsAt<=workspace:GetServerTimeNow()) then self.selectedTaskId=taskId;ctx.request("TaskStart",{taskId=taskId})
					elseif entry.status=="Active" then self.selectedTaskId=taskId;ctx.close() end
					return
				end
			end
		end))
	end
	return self
end

function Tasks:Render()
	local net=self.ctx.net
	local state=net.state
	self.target=nil
	local entries={}
	if state then for _,entry in state.Tasks do entries[entry.taskId]=entry end end
	for taskId,row in self.ctx.refs.Panels.TASKS.Rows do
		local entry=entries[taskId]
		if not entry then W.SetButton(row.Button,"WAITING FOR SERVER",false,false);continue end
		row.Title.Text=Titles[taskId].." • $"..Model.Format(entry.reward)
		local remaining=math.max(0,math.ceil(entry.cooldownEndsAt-workspace:GetServerTimeNow()))
		local busy=net:IsBusy("TaskStart")
		local cooldown=entry.status=="Cooldown" and remaining>0
		W.SetButton(row.Button,if cooldown then string.format("COOLDOWN • %ds",remaining) elseif busy then "WAITING…"
			elseif entry.status=="Active" then "TRACK TARGET ↗" else "START TASK ↗",net.connected and not cooldown and not busy,busy)
		if entry.status=="Active" and typeof(entry.targetPosition)=="Vector3" and (not self.target or taskId==self.selectedTaskId) then
			self.target,self.targetName=entry.targetPosition,Titles[taskId]
		end
	end
end

function Tasks:Tick()
	local label=self.ctx.refs.Direction
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local camera=workspace.CurrentCamera
	label.Visible=self.target~=nil and root~=nil and camera~=nil and self.ctx.active==nil
	if not label.Visible then return end
	local distance=(root.Position-self.target).Magnitude
	local relative=camera.CFrame:PointToObjectSpace(self.target)
	local horizontal=if relative.X < -4 then "←" elseif relative.X > 4 then "→" else "↑"
	label.Text=string.format("%s  %s • %d studs%s",horizontal,self.targetName or "TASK TARGET",math.round(distance),if relative.Z>0 then " • behind you" else "")
end

function Tasks:Destroy() self.cleanup:Destroy() end
return Tasks
