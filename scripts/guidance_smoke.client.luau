--!nonstrict
if not game:GetService("RunService"):IsStudio() then return end
local Players=game:GetService("Players");local Run=game:GetService("RunService")
local p=Players.LocalPlayer
local bridge=game.ReplicatedStorage:WaitForChild("GuidanceReviewBridge",60)
local function waitFor(fn,seconds)
 local untilAt=os.clock()+(seconds or 20)
 repeat local v=fn();if v then return v end;task.wait(.04) until os.clock()>untilAt
 error("Guidance client timed out")
end
local Main=require(p.PlayerScripts:WaitForChild("VerityClient"):WaitForChild("MainUIController"))
local ui=waitFor(function()local x=Main.GetCurrent();return x and x.ctx.net.state and x end,45)
local results={};ui.ctx.net.Result.Event:Connect(function(r)results[r.operationId]=r end)
local function request(action,args)
 waitFor(function()return not ui.ctx.net:IsBusy()end)
 local id=assert(ui.ctx.net:Request(action,args))
 local result=waitFor(function()return results[id]end)
 waitFor(function()return ui.ctx.net.state.stateRevision>=result.stateRevision end)
 return result
end
local function walk()
 local goal=ui.tutorial.goal;assert(goal and goal.kind=="World","No world guide")
 local position=assert(ui.tutorial:Target(goal));local root=p.Character.HumanoidRootPart
 local hum=p.Character:FindFirstChildOfClass("Humanoid")
 waitFor(function()return ui.tutorial.route and #ui.tutorial.route>1 and ui.tutorial.routeStart and (ui.tutorial.routeStart-root.Position).Magnitude<8 end,20)
 local route=ui.tutorial.route
 local waypoint=2
 local steps=0
 local function steer()
  steps+=1
  if waypoint>#route then hum:Move(Vector3.zero,false);return end
  local delta=route[waypoint].Position-root.Position;local flat=Vector3.new(delta.X,0,delta.Z)
  if flat.Magnitude<1.6 and math.abs(delta.Y)<5 then waypoint+=1;return end
  if route[waypoint].Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
  hum:Move(if flat.Magnitude>.1 then flat.Unit else Vector3.zero,false)
 end
 Run:BindToRenderStep("GuidanceSmokeWalk",Enum.RenderPriority.Input.Value+1,steer)
 local simulation=Run.PreSimulation:Connect(steer)
 local ok,reason=pcall(function()
  waitFor(function()
   local delta=position-root.Position
   return waypoint>#route or (Vector3.new(delta.X,0,delta.Z).Magnitude<=goal.radius-1 and math.abs(delta.Y)<5)
  end,45)
 end)
 Run:UnbindFromRenderStep("GuidanceSmokeWalk");simulation:Disconnect();hum:Move(Vector3.zero,false)
 assert(ok,tostring(reason).." frames="..steps.." state="..tostring(hum:GetState()).." speed="..hum.WalkSpeed.." anchored="..tostring(root.Anchored).." waypoint="..waypoint.."/"..#route.." root="..tostring(root.Position).." target="..tostring(route[math.min(waypoint,#route)].Position).." action="..tostring(route[math.min(waypoint,#route)].Action))
 return #route
end
bridge.Report:FireServer({kind="ready"})
bridge.Command.OnClientEvent:Connect(function(token,kind,args)
 local ok,result=pcall(function()
  if kind=="inspect" then
   local t=ui.tutorial
   local visible=0;for _,arrow in t.arrows do if arrow[1].Transparency<1 then visible+=1 end end
   return {goal=t.goal and t.goal.id,kind=t.goal and t.goal.kind,target=t.goal and t.goal.target,
    position=t.goal and t.goal.kind=="World" and t:Target(t.goal),title=ui.refs.GuideTitle.Text,action=ui.refs.TutorialText.Text,
    pin=t.pin.Enabled,arrows=visible,path=ui.refs.Gui:GetAttribute("GuidancePathStatus"),pointer=t.pointer.Visible,
    level=ui.ctx.net.state.VerityLevel,cash=ui.ctx.net.state.Cash,folders=(function()local n=0;for _,f in workspace:GetChildren()do if f.Name=="VerityGuidance"then n+=1 end end;return n end)()}
  elseif kind=="walk" then return {waypoints=walk()}
  elseif kind=="open-box" then return request("OpenBox")
  elseif kind=="phone" then
   ui:Open("PHONE");waitFor(function()return ui.ctx.net.state.PhoneSessionOpen and not ui.ctx.net:IsBusy()end)
   return {goal=ui.tutorial.goal and ui.tutorial.goal.target}
  elseif kind=="earn" then
   local count=0
   while ui.ctx.net.state.Cash<ui.ctx.net.state.NextVerityUpgradeCost do
    waitFor(function()return not ui.ctx.net:IsBusy() and not ui.phone.feed.busy end)
    if ui.phone:Swipe()then count+=1 end;task.wait(.8)
    assert(count<35,"No earning progress")
   end
   if ui.ctx.net.state.TutorialStep~=6 then ui.phone:Swipe();task.wait(.9)end
   return {swipes=count,cash=ui.ctx.net.state.Cash}
  elseif kind=="upgrade" then
   ui:Open("VERITY");task.wait(.2)
   assert(ui.tutorial.goal.target=="Verity.Buy" and ui.tutorial.pointer.Visible,"Upgrade button not guided")
   local r=request("UpgradeVerity");ui:Open(nil);return r
  elseif kind=="task" then
   ui:Open("TASKS");ui.tasks.selectedTaskId=args.taskId
   local r=request("TaskStart",{taskId=args.taskId});task.wait(.2)
   return {success=r.success,closed=ui.ctx.active==nil,target=ui.tutorial.goal and ui.tutorial.goal.target}
  elseif kind=="press" then
   local target=workspace.GameplayInteractions.PRESS_BUTTON
   local camera=workspace.CurrentCamera;local cf,mode=camera.CFrame,camera.CameraType
   camera.CameraType=Enum.CameraType.Scriptable;camera.CFrame=CFrame.lookAt(target.Position+Vector3.new(0,5,10),target.Position)
   task.wait(.2);target:FindFirstChildOfClass("ProximityPrompt"):InputHoldBegin();task.wait(.1);target:FindFirstChildOfClass("ProximityPrompt"):InputHoldEnd()
   camera.CFrame=cf;camera.CameraType=mode;return true
  elseif kind=="reload" then
   ui:Destroy();ui=Main.new();results={};ui.ctx.net.Result.Event:Connect(function(r)results[r.operationId]=r end)
   waitFor(function()return ui.ctx.net.state and not ui.ctx.net:IsBusy()end);return true
  end
  error("Unknown guidance test command")
 end)
 bridge.Report:FireServer({kind="result",token=token,ok=ok,result=if ok then result else nil,error=if ok then nil else tostring(result)})
end)
