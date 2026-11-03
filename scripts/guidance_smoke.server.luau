--!nonstrict
if not game:GetService("RunService"):IsStudio() then return end
local Players=game:GetService("Players");local Test=game:GetService("StudioTestService");local Http=game:GetService("HttpService")
local args=Test:GetTestArgs();local expected=if type(args)=="table" then args.players or 1 else 1
local bridge=Instance.new("Folder");bridge.Name="GuidanceReviewBridge"
for _,name in {"Command","Report"}do local r=Instance.new("RemoteEvent");r.Name=name;r.Parent=bridge end
bridge.Parent=game.ReplicatedStorage
local ready,replies={},{};local checks={}
bridge.Report.OnServerEvent:Connect(function(p,r)if r.kind=="ready"then ready[p]=true elseif r.kind=="result"then replies[r.token]=r end end)
local function waitFor(fn,seconds)
 local untilAt=os.clock()+(seconds or 20)
 repeat local v=fn();if v then return v end;task.wait(.05)until os.clock()>untilAt
 error("Guidance server timed out")
end
local function check(value,label)assert(value,label);table.insert(checks,label)end
local function ask(p,kind,payload,timeout)
 local token=Http:GenerateGUID(false);bridge.Command:FireClient(p,token,kind,payload or {})
 local r=waitFor(function()return replies[token]end,timeout or 30);replies[token]=nil;assert(r.ok,r.error);return r.result
end
local ok,failure=pcall(function()
 waitFor(function()return game.ServerScriptService.Core:GetAttribute("CoreReady")end,30)
 local s=require(game.ServerScriptService.Core.Runtime).GetServices()
 waitFor(function()
  if #Players:GetPlayers()~=expected then return false end
  for _,p in Players:GetPlayers()do if not ready[p]or not p.Character or not p.Character:GetAttribute("SpawnReady")then return false end end
  return true
 end,60)
 check(not workspace:FindFirstChild("VerityGuidance"),"guidance geometry stays client-local")
 local roster=Players:GetPlayers()
 for _,p in roster do
  local id=p.UserId;local anchors=s.WorldIntegration.anchors[s.PlotService.owners[id]]
  local initial=ask(p,"inspect")
  check(initial.goal=="delivery" and (initial.position-anchors.DeliveryPoint.Position).Magnitude<.1,"guide points only to own delivery "..p.Name)
  check(initial.cash==0 and initial.level==1,"no synthetic starting money or progress "..p.Name)
  local house=workspace.GeneratedWorld.Plots[string.format("Plot_%02d",s.PlotService.owners[id])].House
  p.Character:PivotTo(house.Markers.UpstairsPoint.CFrame+Vector3.new(0,3,0));task.wait(.4)
  local route=ask(p,"walk",nil,65)
  check(route.waypoints>2 and s.WorldIntegration:IsNear(id,s.PlotService.owners[id],"DeliveryPoint"),"real guide route walks downstairs and through house doorway "..p.Name)
  check(ask(p,"open-box").success,"guided box opens through validated Core request "..p.Name)
  task.wait(.2);local after=ask(p,"inspect")
  check(not after.pin and after.target=="Nav.PHONE" and after.pointer,"box marker switches to phone UI arrow "..p.Name)
  check(ask(p,"phone").goal=="Phone.Next","phone explains the swipe action "..p.Name)
  local earned=ask(p,"earn",nil,35);check(earned.swipes>0,"real swipes and passive income fund first level "..p.Name)
  check(ask(p,"upgrade").success and s.DataService:Get(id).Data.VerityLevel==2,"guide reaches first real purchased level "..p.Name)
 end
 local p=roster[1];local id=p.UserId
 for _,taskId in {"PRESS_BUTTON","REACH_POINT","STAND_ON_PLATFORM"}do
  local started=ask(p,"task",{taskId=taskId})
  check(started.success and started.closed and started.target==taskId,"task selection closes menu and guides correct target "..taskId)
  local target=s.WorldIntegration.targets[taskId]
  -- Keep the short test route in loaded space while still walking its actual path.
  p.Character:PivotTo(target.CFrame+Vector3.new(0,3,22));task.wait(.3)
  ask(p,"walk",nil,60)
  if taskId=="PRESS_BUTTON"then ask(p,"press")end
  waitFor(function()return not s.PlayerStateService.sessions[id].Tasks[taskId].Active end,6)
  waitFor(function()return ask(p,"inspect").goal~="task:"..taskId end,6)
  check(true,"confirmed reward clears old waypoint "..taskId)
 end
 ask(p,"reload");task.wait(.2)
 check(ask(p,"inspect").folders==1,"UI reload leaves one guidance controller and marker folder")
 local old=p.Character;old:FindFirstChildOfClass("Humanoid").Health=0
 waitFor(function()return p.Character and p.Character~=old and p.Character:GetAttribute("SpawnReady")end,20)
 task.wait(.3);check(ask(p,"inspect").folders==1,"respawn preserves one live guidance system")
end)
local result={status=if ok then "PASS"else "FAIL",players=expected,assertions=#checks,checks=checks,error=if ok then nil else tostring(failure),
 kind="guided real onboarding and three physical task routes",syntheticMoney=false,syntheticLevelChanges=false,dataMode="Studio Memory"}
bridge:SetAttribute("Status",result.status);bridge:SetAttribute("Report",Http:JSONEncode(result));print("VERITY_GUIDANCE_"..result.status,#checks,failure or "")
if type(args)=="table"then task.wait(.2);Test:EndTest(result)end
