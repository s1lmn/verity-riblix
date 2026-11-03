--!nonstrict
-- Studio-only harness; excluded from default.project.json and shipped places.
if not game:GetService("RunService"):IsStudio() then return end
local p=game.Players.LocalPlayer
local bridge=game.ReplicatedStorage:WaitForChild("PresentationReviewBridge",60)
local Main=require(p.PlayerScripts:WaitForChild("VerityClient"):WaitForChild("MainUIController"))
local function waitFor(fn,seconds)
 local deadline=os.clock()+(seconds or 15)
 repeat local value=fn();if value then return value end;task.wait(.03)until os.clock()>deadline
 error("Presentation test timed out")
end
local ui=waitFor(function()local v=Main.GetCurrent();return v and v.ctx.net.state and v end,45)
local results={}
local function listen()ui.ctx.net.Result.Event:Connect(function(r)results[r.operationId]=r end)end
listen()
local function settled(id)
 assert(id,"Request was not accepted")
 local r=waitFor(function()return results[id]end)
 waitFor(function()return ui.ctx.net.state.stateRevision>=r.stateRevision and not ui.ctx.net:IsBusy()end)
 assert(r.success,tostring(r.errorCode));return r
end
local function request(action)waitFor(function()return not ui.ctx.net:IsBusy()end);return settled(ui.ctx.net:Request(action))end
local checks={}
local function check(v,label)assert(v,label);table.insert(checks,label)end
bridge.Report:FireServer("ready")
bridge.Command.OnClientEvent:Connect(function(token,kind)
 local ok,result=pcall(function()
  if kind=="open" then return request("OpenBox")
  elseif kind=="observer" then
   return {active=ui.ctx.presenting==true,count=ui.presentation.count,camera=workspace.CurrentCamera.CameraType.Name}
  elseif kind=="review" then
   waitFor(function()return ui.ctx.net.state.Cash>=100000 end)
   ui:Open("PHONE");waitFor(function()return ui.ctx.net.state.PhoneSessionOpen and not ui.ctx.net:IsBusy()end)
   local before=ui.ctx.net.state.SwipeUpgradeLevel
   settled(ui.phone:Upgrade("UpgradeSwipe"))
   check(ui.ctx.active=="PHONE" and ui.ctx.net.state.SwipeUpgradeLevel==before+1,"phone upgrades swipe power directly without navigation")
   check(ui.phone.refs.PowerHint.Text:find("→")~=nil,"phone shows current and next swipe reward")
   local count=ui.presentation.count
   local level=ui.ctx.net.state.VerityLevel
   settled(ui.phone:Upgrade("UpgradeVerity"))
   waitFor(function()return ui.ctx.presenting end)
   check(ui.ctx.active==nil and not ui.refs.Panels.PHONE.Root.Visible,"confirmed Verity purchase closes phone")
   check(workspace.CurrentCamera.CameraType==Enum.CameraType.Scriptable,"owned purchase focuses real world companion")
   task.wait(.15)
   check(not ui.refs.Tutorial.Visible and not ui.tutorial.pointer.Visible and not ui.tutorial.pin.Enabled,"guidance yields while presenting")
   local event=ui.presentation.active.event
   check(not ui.presentation:Start(event,ui.presentation.active.model),"same confirmed event cannot replay presentation")
   waitFor(function()return ui.presentation.active and ui.presentation.active.completed end)
   check(ui.presentation.title.Text:find(tostring(level+1))~=nil,"completion names the actual purchased level")
   check(ui.presentation.active.model:GetAttribute("PresentedLevel")==level+1,"presentation waits for actual world animation completion")
   waitFor(function()return not ui.ctx.presenting end)
   check(workspace.CurrentCamera.CameraType==Enum.CameraType.Custom and ui.presentation.count==count+1,"one presentation restores player camera automatically")
   check(not ui.presentation.layer.Visible,"celebration overlay is temporary")
   waitFor(function()return not ui.ctx.net:IsBusy()end)
   ui:Open("PHONE");waitFor(function()return not ui.ctx.net:IsBusy()end)
   settled(ui.phone:Upgrade("UpgradeVerity"));waitFor(function()return ui.ctx.presenting end)
   ui:Open("PHONE")
   check(ui.ctx.presenting and ui.ctx.active==nil and not ui.presentation.card:FindFirstChild("Skip"),"reveal cannot be skipped through the card or menu")
   waitFor(function()return not ui.ctx.presenting end)
   ui:Open("PHONE")
   ui.ctx.settings.values.ReducedMotion=true;ui.ctx.settings.Changed:Fire(ui.ctx.settings.values)
   waitFor(function()return not ui.ctx.net:IsBusy()end)
   settled(ui.phone:Upgrade("UpgradeVerity"));waitFor(function()return ui.ctx.presenting end)
   check(workspace.CurrentCamera.CameraType==Enum.CameraType.Custom,"Reduced Motion celebrates without taking camera")
   check(ui.ctx.active==nil,"Reduced Motion still closes menu after purchase")
   ui.presentation:Stop();task.wait(1.8)
   ui.ctx.settings.values.ReducedMotion=false;ui.ctx.settings.Changed:Fire(ui.ctx.settings.values)
   ui:Open("PHONE");waitFor(function()return not ui.ctx.net:IsBusy()end)
   settled(ui.phone:Upgrade("UpgradeVerity"));waitFor(function()return ui.ctx.presenting end)
   ui.ctx.settings.values.ReducedMotion=true;ui.ctx.settings.Changed:Fire(ui.ctx.settings.values)
   check(workspace.CurrentCamera.CameraType==Enum.CameraType.Custom,"changing Reduced Motion during reveal releases camera immediately")
   ui.presentation:Stop();task.wait(.2)
   ui:Open("PHONE");waitFor(function()return not ui.ctx.net:IsBusy()end)
   local state=ui.ctx.net.state
   local cash=state.Cash;state.Cash=0;ui.phone:Render()
   check(not ui.phone.refs.Power.Interactable and not ui.phone.refs.Grow.Interactable and not ui.phone:Upgrade("UpgradeVerity"),"unaffordable quick upgrades cannot dispatch")
   state.Cash=cash
   local oldPower,oldLevel=state.SwipeUpgradeLevel,state.VerityLevel
   state.SwipeUpgradeLevel=40;state.VerityLevel=100;ui.phone:Render()
   check(not ui.phone.refs.Power.Interactable and not ui.phone.refs.Grow.Interactable,"maximum levels disable both quick upgrades")
   state.SwipeUpgradeLevel=oldPower;state.VerityLevel=oldLevel;ui.phone:Render()
   local safe=ui.refs.Safe;local savedSize=safe.Size
   for _,size in {{1920,1080},{1280,720},{844,390},{640,300},{390,844},{320,480}} do
    safe.Size=UDim2.fromOffset(size[1],size[2]);task.wait(.08);ui.refs.Layout(true);task.wait(.05)
    local body=ui.phone.refs.Body;local grow=ui.phone.refs.Grow
    local content=body.CanvasSize.Y.Offset
    check(grow.AbsoluteSize.Y>=44 and grow.AbsolutePosition.X>=body.AbsolutePosition.X-1 and grow.AbsolutePosition.X+grow.AbsoluteSize.X<=body.AbsolutePosition.X+body.AbsoluteSize.X+1,"touch targets fit phone width "..size[1].."x"..size[2])
    check(grow.Position.Y.Offset+grow.AbsoluteSize.Y<=ui.phone.refs.Controls.AbsoluteSize.Y and content>=ui.phone.refs.Controls.Position.Y.Offset+grow.Position.Y.Offset+grow.AbsoluteSize.Y,"grow button reachable in canvas "..size[1].."x"..size[2])
   end
   safe.Size=savedSize;ui.refs.Layout(true)
   ui.ctx.settings.values.ReducedMotion=false;ui.ctx.settings.Changed:Fire(ui.ctx.settings.values)
   waitFor(function()return not ui.ctx.net:IsBusy()end)
   settled(ui.phone:Upgrade("UpgradeVerity"));waitFor(function()return ui.ctx.presenting end)
   local savedCamera=workspace.CurrentCamera
   local old=ui
   ui:Destroy();ui=Main.new();results={};listen()
   waitFor(function()return ui.ctx.net.state end)
   check(savedCamera.CameraType==Enum.CameraType.Custom and not old.presentation.layer.Parent,"UI reload destroys reveal and releases camera")
   check(ui.presentation.count==0,"snapshot reload does not replay a purchase")
   return {checks=checks,assertions=#checks}
  elseif kind=="death" then
   ui:Open("PHONE");waitFor(function()return not ui.ctx.net:IsBusy()end)
   settled(ui.phone:Upgrade("UpgradeVerity"));waitFor(function()return ui.ctx.presenting end)
   return true
  elseif kind=="after-death" then
   check(not ui.ctx.presenting and workspace.CurrentCamera.CameraType==Enum.CameraType.Custom,"death cancels reveal and returns camera control")
   return {checks=checks,assertions=#checks}
  elseif kind=="phone" then ui:Open("PHONE");return true
  elseif kind=="show" then
   waitFor(function()return not ui.ctx.net:IsBusy()end)
   settled(ui.phone:Upgrade("UpgradeVerity"));waitFor(function()return ui.ctx.presenting end)
   ui.presentation.active.started=os.clock()+20
   task.spawn(function()
    waitFor(function()return ui.presentation.active and ui.presentation.active.completed end)
    ui.presentation.active.completed=os.clock()+20
   end)
   return true
  end
 end)
 bridge.Report:FireServer("result",token,{ok=ok,result=if ok then result else nil,error=if ok then nil else tostring(result)})
end)
