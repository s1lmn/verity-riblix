--!nonstrict
if not game:GetService("RunService"):IsStudio() then return end
local Players=game.Players;local Http=game:GetService("HttpService");local Test=game:GetService("StudioTestService")
local args=Test:GetTestArgs();local expected=if type(args)=="table"then args.players or 1 else 1
local bridge=Instance.new("Folder");bridge.Name="PresentationReviewBridge"
for _,name in {"Command","Report"}do local r=Instance.new("RemoteEvent");r.Name=name;r.Parent=bridge end
bridge.Parent=game.ReplicatedStorage
local ready,replies={},{}
bridge.Report.OnServerEvent:Connect(function(p,kind,token,r)if kind=="ready"then ready[p]=true elseif kind=="result"then replies[token]=r end end)
local function waitFor(fn,seconds)
 local deadline=os.clock()+(seconds or 20)
 repeat local v=fn();if v then return v end;task.wait(.04)until os.clock()>deadline
 error("Presentation server timed out")
end
local function ask(p,kind,timeout)
 local token=Http:GenerateGUID(false);bridge.Command:FireClient(p,token,kind)
 local r=waitFor(function()return replies[token]end,timeout or 25);replies[token]=nil;assert(r.ok,r.error);return r.result
end
local checks={};local function check(v,label)assert(v,label);table.insert(checks,label)end
local ok,failure=pcall(function()
 waitFor(function()return game.ServerScriptService.Core:GetAttribute("CoreReady")end,30)
 local s=require(game.ServerScriptService.Core.Runtime).GetServices()
 local rosterForClaim = waitFor(function()
  local players = Players:GetPlayers()
  if #players ~= expected then return nil end
  for _, player in players do
   if not player:GetAttribute("HouseSelectionReady") then return nil end
  end
  return players
 end, 60, "House selection not ready")
 for plotId, player in rosterForClaim do
  assert(s.PlayerLifecycle.ClaimHouse(player, plotId) == "OK", "Smoke house claim failed")
 end
 waitFor(function()
  if #Players:GetPlayers()~=expected then return false end
  for _,p in Players:GetPlayers()do if not ready[p]or not p.Character or not p.Character:GetAttribute("SpawnReady")then return false end end
  return true
 end,60)
 local roster=Players:GetPlayers();local p=roster[1];local id=p.UserId
 local plot=s.PlotService.owners[id];p.Character:PivotTo(s.WorldIntegration.anchors[plot].DeliveryPoint.CFrame+Vector3.new(0,3,0));task.wait(.2)
 waitFor(function()return s.DataService:Get(id).Data.DeliveryState=="Delivered"end)
 check(ask(p,"open").success,"validated delivery opens before phone upgrades")
 -- Explicit test-only money, not part of the production build or progression claim.
 local profile=s.DataService:Get(id);profile.Data.Cash=100000;profile.Data.TotalEarned=100000;s.DataService:Touch(profile);s.PlayerStateService:Publish(id,true)
 local client=ask(p,"review",70)
 for _,label in client.checks do table.insert(checks,label)end
 if expected>1 then
  local other=ask(roster[2],"observer")
  check(not other.active and other.count==0 and other.camera=="Custom","another player's upgrades never seize observer camera or celebrate")
 end
 ask(p,"death")
 local old=p.Character;old:FindFirstChildOfClass("Humanoid").Health=0
 waitFor(function()return p.Character and p.Character~=old and p.Character:GetAttribute("SpawnReady")end,20)
 task.wait(.5);ask(p,"after-death")
 check(true,"respawn completes with reveal cancelled")
 bridge:SetAttribute("ReviewPlayer",id)
end)
local result={status=if ok then "PASS"else "FAIL",players=expected,assertions=#checks,checks=checks,error=if ok then nil else tostring(failure),
 kind="phone direct upgrades and owned world presentation",syntheticMoney=true,syntheticLevelChanges=false,dataMode="Studio Memory"}
bridge:SetAttribute("Status",result.status);bridge:SetAttribute("Result",Http:JSONEncode(result));print("VERITY_PRESENTATION_"..result.status,#checks,failure or "")
if type(args)=="table"then task.wait(.2);Test:EndTest(result)end
