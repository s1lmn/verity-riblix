--!nonstrict
if not game:GetService("RunService"):IsStudio() then return end
local Players=game:GetService("Players")
local player=Players.LocalPlayer
local bridge=game.ReplicatedStorage:WaitForChild("CompleteSmokeBridge",60)
local command=bridge:WaitForChild("Command",10);local report=bridge:WaitForChild("Report",10)
local Main=require(player:WaitForChild("PlayerScripts"):WaitForChild("VerityClient"):WaitForChild("MainUIController"))
local function untilValue(fn,timeout)
	local deadline=os.clock()+(timeout or 15)
	repeat local result=fn();if result then return result end;task.wait(0.03) until os.clock()>deadline
	error("Client smoke timeout")
end
local ui=untilValue(function()local current=Main.GetCurrent();return current and current.ctx.net.state and current end,45)
local results,wire={},{}
local function bind()
	ui.ctx.net.Result.Event:Connect(function(result)results[result.operationId]=result end)
end
bind()
game.ReplicatedStorage.Remotes.ActionResult.OnClientEvent:Connect(function(result)
	if result.replayed then wire[result.operationId]=result end
end)
local lastSwipe
local function invoke(action,args)
	untilValue(function()return not ui.ctx.net:IsBusy()end)
	local id,reason=ui.ctx.net:Request(action,args)
	assert(id,reason)
	local result=untilValue(function()return results[id]end)
	untilValue(function()return ui.ctx.net.state.stateRevision>=result.stateRevision end)
	return result
end
local function ownModel()
	for _,model in game:GetService("CollectionService"):GetTagged("VerityVisual")do
		if model:GetAttribute("OwnerUserId")==player.UserId then return model end
	end
end
report:FireServer({kind="ready",versionIssue=ui.versions.issue})
command.OnClientEvent:Connect(function(token,kind,payload)
	local ok,result=pcall(function()
		if kind=="request" then return invoke(payload.action,payload.args)
		elseif kind=="walk" then
			local hum=player.Character:FindFirstChildOfClass("Humanoid")
			local root=player.Character.HumanoidRootPart
			local run=game:GetService("RunService")
			run:BindToRenderStep("FinalSmokeWalk",Enum.RenderPriority.Input.Value+1,function()
				local delta=payload.position-root.Position;local flat=Vector3.new(delta.X,0,delta.Z)
				hum:Move(if flat.Magnitude>1 then flat.Unit else Vector3.zero,false)
			end)
			local reached=pcall(function()untilValue(function()return(root.Position-payload.position).Magnitude<4 end,10)end)
			run:UnbindFromRenderStep("FinalSmokeWalk");hum:Move(Vector3.zero,false)
			assert(reached,"Client could not walk through doorway")
			return {success=true}
		elseif kind=="phone" then
			ui:Open(if payload.open then "PHONE" else nil)
			untilValue(function()return ui.ctx.net.state.PhoneSessionOpen==payload.open and not ui.ctx.net:IsBusy()end)
			return {success=true}
		elseif kind=="swipe" then
			untilValue(function()return not ui.ctx.net:IsBusy() and not ui.phone.feed.busy end)
			assert(ui.phone:Swipe(),"Phone handler rejected swipe")
			local id=string.format("%.0f",ui.ctx.net.sequence)
			lastSwipe=id
			return untilValue(function()return results[id]end)
		elseif kind=="replay" then
			assert(lastSwipe);wire[lastSwipe]=nil
			game.ReplicatedStorage.Remotes.RequestSwipe:FireServer({operationId=lastSwipe})
			return untilValue(function()return wire[lastSwipe]end)
		elseif kind=="prompt" then
			ui:Open(nil)
			local target=workspace.GameplayInteractions.PRESS_BUTTON
			local prompt=target:FindFirstChildOfClass("ProximityPrompt")
			local camera=workspace.CurrentCamera;local cf,kindBefore=camera.CFrame,camera.CameraType
			camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.lookAt(target.Position+Vector3.new(0,5,10),target.Position)
			task.wait(0.3);prompt:InputHoldBegin();task.wait(0.1);prompt:InputHoldEnd()
			camera.CameraType=kindBefore;camera.CFrame=cf
			return {success=true}
		elseif kind=="grow" then
			ui:Open("VERITY")
			untilValue(function()local m=ownModel();return m and ui.visuals.records[m]end)
			local count=0
			while ui.ctx.net.state.VerityLevel<100 do
				local result=invoke("UpgradeVerity");assert(result.success,result.errorCode)
				count+=1;if count%10==0 then report:FireServer({kind="progress",level=ui.ctx.net.state.VerityLevel})end
				task.wait(0.17)
			end
			untilValue(function()local m=ownModel();return m and m:GetAttribute("PresentedLevel")==100 end,160)
			local m=ownModel()
			return {success=true,purchases=count,level=ui.ctx.net.state.VerityLevel,scale=m:GetScale(),
				completed=ui.visuals.completed,label=ui.refs.Panels.VERITY.Scale.Text}
		elseif kind=="presentation" then
   local m=assert(ownModel())
   local root=player.Character.HumanoidRootPart
   root.Name="StreamingMissingRoot"
   task.wait(.2)
   local hidden=m:GetAttribute("CompanionMode")=="Hidden"
   root.Name="HumanoidRootPart"
   untilValue(function()return m:GetAttribute("CompanionMode")~="Hidden"end)
   local group=ui.visuals.effects.groups[m]
   local auraOutside=group and (Vector3.new(group.rings[1][1].Position.X,0,group.rings[1][1].Position.Z)-Vector3.new(m:GetPivot().Position.X,0,m:GetPivot().Position.Z)).Magnitude>.85*m:GetScale()
   local camera=workspace.CurrentCamera
   local cf,cameraType=camera.CFrame,camera.CameraType
   camera.CameraType=Enum.CameraType.Scriptable
   camera.CFrame=CFrame.new(m:GetPivot().Position+Vector3.new(0,.85*m:GetScale(),0))
   task.wait(.2)
   local faded=m.Body.LocalTransparencyModifier>.9
   camera.CFrame=cf;camera.CameraType=cameraType
   local values=ui.ctx.settings.values
   values.ReducedMotion=true;values.ReducedEffects=true;ui.ctx.settings.Changed:Fire(values)
   task.wait(.2)
   local suppressed=#ui.visuals.effects.active==0
   for _,group in ui.visuals.effects.groups do for _,part in group.root:GetDescendants()do
    if part:IsA("BasePart") and part.Transparency<1 then suppressed=false end
   end end
   values.ReducedMotion=false;values.ReducedEffects=false;ui.ctx.settings.Changed:Fire(values)
   return {auraOutside=auraOutside,hiddenOwner=hidden,cameraFade=faded,reducedEffects=suppressed}
  elseif kind=="preview" then
   ui:Open("COSMETICS")
   return {success=ui.cosmetics:Preview(payload.itemId)}
  elseif kind=="inspect" then
			local count=0;for _,gui in player.PlayerGui:GetChildren()do if gui.Name=="VerityUI"then count+=1 end end
			local m=ownModel()
   local all={}
   for _,other in game:GetService("CollectionService"):GetTagged("VerityVisual") do
    all[tostring(other:GetAttribute("OwnerUserId"))]={mode=other:GetAttribute("CompanionMode"),position=other:GetPivot().Position,
      face=other:GetAttribute("Cosmetic_Face"),cosmeticModel=other:FindFirstChild("Cosmetics") and other.Cosmetics:FindFirstChild("round_glasses")~=nil}
   end
   local records=0;for _ in ui.visuals.records do records+=1 end
   return {visualRecords=records,companions=all,position=m and m:GetPivot().Position,scale=m and m:GetScale(),mode=m and m:GetAttribute("CompanionMode"),success=true,level=ui.ctx.net.state.VerityLevel,cash=ui.ctx.net.state.Cash,guiCount=count,
				model=m~=nil,presented=m and m:GetAttribute("PresentedLevel"),versionIssue=ui.versions.issue,
				prototypeCount=#game:GetService("CollectionService"):GetTagged("VerityPrototypeVisual")}
		elseif kind=="reload" then
			ui:Destroy();ui=Main.new();bind()
			untilValue(function()return ui.ctx.net.state and not ui.ctx.net:IsBusy()end)
			return {success=true,level=ui.ctx.net.state.VerityLevel}
		elseif kind=="leave" then
			local service=game:GetService("StudioTestService")
			assert(service:CanLeaveTest());service:LeaveTest();return {}
		end
		error("Unknown command")
	end)
	report:FireServer({kind="result",token=token,ok=ok,result=if ok then result else nil,error=if ok then nil else tostring(result)})
end)
