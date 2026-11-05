--!nonstrict
local Locale = require(script.Parent.Locale)
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local Tasks={}
Tasks.__index=Tasks

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
 self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
  if result.action=="TaskStart" and result.success and ctx.active=="TASKS" then ctx.close() end
 end))
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
		if not entry then
   row.Reward.Text="$—";row.Status.Text=Locale.Text("Загрузка…")
   W.SetButton(row.Button,Locale.Text("WAITING FOR SERVER"),false,false);continue
  end
		row.Reward.Text="$"..Locale.Number(entry.reward)
		local remaining=math.max(0,math.ceil(entry.cooldownEndsAt-workspace:GetServerTimeNow()))
		local busy=net:IsBusy("TaskStart")
		local cooldown=entry.status=="Cooldown" and remaining>0
  row.Status.Text=if cooldown then string.format(Locale.Text("Снова через %dс"),remaining) elseif entry.status=="Active" then Locale.Text("Выполняется") else Locale.Text("Можно начать")
		W.SetButton(row.Button,if cooldown then Locale.Text("СКОРО СНОВА") elseif busy then Locale.Text("WAITING…")
			elseif entry.status=="Active" then Locale.Text("ПОКАЗАТЬ ПУТЬ →") else Locale.Text("НАЧАТЬ ЗАДАНИЕ →"),net.connected and not cooldown and not busy,busy)
		if entry.status=="Active" and typeof(entry.targetPosition)=="Vector3" and (not self.target or taskId==self.selectedTaskId) then
			self.target,self.targetName=entry.targetPosition,row.Title.Text
		end
	end
end

function Tasks:Destroy() self.cleanup:Destroy() end
return Tasks
