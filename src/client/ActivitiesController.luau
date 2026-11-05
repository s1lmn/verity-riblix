--!nonstrict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Actions=game:GetService("ContextActionService")
local Input=game:GetService("UserInputService")
local Gui=game:GetService("GuiService")
local P=require(RS.Shared.ParkourConfig)
local B=require(RS.Shared.VerityBattleConfig)
local Locale=require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Cleanup=require(script.Parent.Cleanup)
local Controller={};Controller.__index=Controller
local function disc(folder)
 local p=Instance.new("Part");p.Name="StrikeWarning";p.Shape=Enum.PartType.Cylinder;p.Anchored=true
 p.Size=Vector3.new(.08,1,1);p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Material=Enum.Material.Neon;p.Color=Color3.fromHex("FF547A");p.Transparency=1;p.Parent=folder;return p
end
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),enemyCleanup=Cleanup.new(),courseCleanup=Cleanup.new(),enemies={},hazards={},elapsed=0,lastLeave=-math.huge},Controller)
 self.folder=self.cleanup:Add(Instance.new("Folder"));self.folder.Name="VerityActivityVisuals";self.folder.Parent=workspace
 self.card=self.cleanup:Add(W.Round(W.Frame(ctx.refs.Safe,"ActivityStatus",UDim2.fromOffset(320,74),T.Paper),12));self.card.Visible=false
 W.Stroke(self.card,T.Purple,2)
 self.title=W.Text(self.card,"Title","",13,true,T.Purple);self.title.Position=UDim2.fromOffset(10,5);self.title.Size=UDim2.new(1,-66,0,26)
 self.detail=W.Text(self.card,"Detail","",11,false,T.Ink);self.detail.Position=UDim2.fromOffset(10,32);self.detail.Size=UDim2.new(1,-66,0,31)
 self.leave=W.Button(self.card,"Leave","×",T.Pink);self.leave.Size=UDim2.fromOffset(44,44);self.leave.Position=UDim2.new(1,-54,0,8)
 self.cleanup:Add(self.leave.Activated:Connect(function()self:Leave()end))
 self.next=Instance.new("Highlight");self.next.Name="NextParkourPlatform";self.next.FillTransparency=.82;self.next.OutlineTransparency=.1
 self.next.FillColor=T.Gold;self.next.OutlineColor=T.Gold;self.next.Enabled=false;self.next.DepthMode=Enum.HighlightDepthMode.Occluded;self.next.Parent=self.folder
 Actions:BindAction("VerityActivityLeave",function(_,state)
  if state==Enum.UserInputState.Begin and self:Leave() then return Enum.ContextActionResult.Sink end
  return Enum.ContextActionResult.Pass
 end,false,Enum.KeyCode.Q,Enum.KeyCode.ButtonB)
 self.cleanup:Add(function()Actions:UnbindAction("VerityActivityLeave")end)
 self.cleanup:Add(Players.LocalPlayer:GetAttributeChangedSignal("VerityParkourFinishTime"):Connect(function()
  local player=Players.LocalPlayer;local time=player:GetAttribute("VerityParkourFinishTime");local medal=player:GetAttribute("VerityParkourMedal")
  if time and medal then ctx.notifications:Show(string.format(Locale.Text("%s • паркур за %d с"),Locale.Text(medal),math.round(time))) end
 end))
 self.cleanup:Add(Run.RenderStepped:Connect(function(dt)
  self.elapsed+=dt;local graphics=ctx.settings.values.Graphics
  if self.elapsed<(graphics and graphics.AbilityInterval or 1/30) then return end
  self.elapsed=0;self:Tick()
 end))
 self.cleanup:Add(function()self.enemyCleanup:Destroy();self.courseCleanup:Destroy();for _,r in self.hazards do if r.part.Parent then r.part.CFrame=r.base;r.part.Transparency=.8 end end end)
 return self
end
function Controller:Leave()
 local player=Players.LocalPlayer
 if not self.card.Visible or self.ctx.active or self.ctx.presenting or Gui.MenuIsOpen or Input:GetFocusedTextBox() or os.clock()-self.lastLeave<.6 then return false end
 local remote=RS:FindFirstChild("VerityActivities");if not remote then return false end
 self.lastLeave=os.clock();remote:FireServer(if player:GetAttribute("VerityBattleActive") then "LeaveBattle" else "LeaveParkour");return true
end
function Controller:BindArena(arena)
 self.enemyCleanup:Destroy();self.enemyCleanup=Cleanup.new()
 for model,r in self.enemies do r.marker:Destroy();self.enemies[model]=nil end
 self.arena=arena;if not arena then return end
 local function add(model)
  if not model:IsA("Model") or self.enemies[model] then return end
  local r={marker=disc(self.folder),parts={}}
  for _,p in model:GetDescendants() do if p:IsA("BasePart") then table.insert(r.parts,p) end end
  self.enemies[model]=r
 end
 local function remove(model)local r=self.enemies[model];if r then r.marker:Destroy();self.enemies[model]=nil end end
 self.enemyCleanup:Add(arena.Enemies.ChildAdded:Connect(add));self.enemyCleanup:Add(arena.Enemies.ChildRemoved:Connect(remove))
 for _,model in arena.Enemies:GetChildren() do add(model) end
end
function Controller:Tick()
 local world=workspace:FindFirstChild("GeneratedWorld");local course=world and world:FindFirstChild("VerityParkour")
 local arena=world and world:FindFirstChild("VerityBattleArena")
 if arena and not arena:FindFirstChild("Enemies") then arena=nil end
 if arena~=self.arena then self:BindArena(arena) end
 if course~=self.course then
  self.courseCleanup:Destroy();self.courseCleanup=Cleanup.new()
  for _,r in self.hazards do if r.part.Parent then r.part.CFrame=r.base;r.part.Transparency=.8 end end
  self.course=course;table.clear(self.hazards)
  if course then
   local function add(p)
    local index=tonumber(p.Name:match("^Hazard(%d+)$"));local pad=index and P.Pads[index]
    if pad and p:IsA("BasePart") then self.hazards[index]={part=p,base=CFrame.new(pad.x,pad.y+1.25,pad.z)} end
   end
   self.courseCleanup:Add(course.ChildAdded:Connect(add))
   self.courseCleanup:Add(course.ChildRemoved:Connect(function(p)for index,r in self.hazards do if r.part==p then self.hazards[index]=nil end end end))
   for _,p in course:GetChildren() do add(p) end
  end
 end
 local player=Players.LocalPlayer;local now=workspace:GetServerTimeNow();local camera=workspace.CurrentCamera
 local graphics=self.ctx.settings.values.Graphics;local distance=graphics and graphics.EffectDistance or 200
 for index,r in self.hazards do
  if not r.part.Parent then continue end
  local near=camera and (r.base.Position-camera.CFrame.Position).Magnitude<distance
  if not near then r.part.Transparency=1;continue end
  local phase,angle=P.Hazard(index,now)
  r.part.CFrame=r.base*CFrame.Angles(0,-angle,0)
  r.part.Color=if phase==2 then Color3.fromHex("FF5277") elseif phase==1 then T.Gold else T.Mint
  r.part.Transparency=if phase==2 then .15 elseif phase==1 then .4 else .88
 end
 for model,r in self.enemies do
  local strike=model:GetAttribute("StrikeAt");local target=model:GetAttribute("StrikeTarget")
  if model:GetAttribute("EnemyDead") then
   r.deadAt=r.deadAt or now
   for _,p in r.parts do if p.Parent then p.LocalTransparencyModifier=math.clamp((now-r.deadAt)/.6,0,1) end end
  end
  if strike then r.lastStrike=strike end
  local impact=not strike and r.lastStrike and now-r.lastStrike>=0 and now-r.lastStrike<.28
  local visible=target and camera and not r.deadAt and (target-camera.CFrame.Position).Magnitude<distance and (strike or impact)
  r.marker.Transparency=if visible then (if impact then .45 else .72) else 1
  if visible then
   local radius=model:GetAttribute("EnemyRadius") or 5
   local pulse=if impact then 1+(now-r.lastStrike)*2 else 1
   r.marker.Size=Vector3.new(.08,radius*2*pulse,radius*2*pulse)
   r.marker.CFrame=CFrame.new(target-Vector3.new(0,2.7,0))*CFrame.Angles(0,0,math.pi/2)
   r.marker.Color=if impact then T.Gold else Color3.fromHex("FF5277")
  end
 end
 local step=player:GetAttribute("VerityParkourStep");local battle=player:GetAttribute("VerityBattleActive")
 self.card.Visible=(step~=nil or battle==true) and not self.ctx.active and not self.ctx.presenting
 self.next.Enabled=step~=nil and course~=nil and not self.ctx.active and not self.ctx.presenting
 if self.next.Enabled then self.next.Adornee=course:FindFirstChild(string.format("Pad%02d",math.min(#P.Pads,step+1))) end
 if not self.card.Visible then return end
 local size=self.ctx.refs.Safe.AbsoluteSize;local narrow=size.X<640
 self.card.AnchorPoint=if narrow then Vector2.new(1,0) else Vector2.new(.5,0)
 self.card.Position=if narrow then UDim2.new(1,-12,0,8) else UDim2.new(.5,0,0,8)
 self.card.Size=UDim2.fromOffset(if narrow then math.max(120,math.min(300,size.X-184)) else 320,if narrow then 94 else 74)
 self.title.TextSize=if narrow then 11 else 13;self.detail.TextSize=if narrow then 10 else 11
 self.detail.Size=UDim2.new(1,-66,0,if narrow then 54 else 31)
 if step then
  local p=P.Pads[step];local elapsed=math.max(0,now-(player:GetAttribute("VerityParkourStartedAt") or now))
  self.title.Text=Locale.Text(P.Sections[p and p.section or 1])
  self.detail.Text=string.format(Locale.Text("%d / %d • %d с • ошибок: %d"),step,#P.Pads,math.floor(elapsed),player:GetAttribute("VerityParkourFaults") or 0)
 elseif arena then
  local wave=arena:GetAttribute("Wave") or 0;local phase=arena:GetAttribute("Phase")
  self.title.Text=string.format(Locale.Text("АРЕНА • ВОЛНА %d / %d"),wave,#B.Waves)
  self.detail.Text=if phase=="Fighting" then Locale.Text(if Input.PreferredInput==Enum.PreferredInput.Touch then "Нажми атаку • выходи из красных кругов" elseif Input.PreferredInput==Enum.PreferredInput.Gamepad then "R1 — атака • выходи из красных кругов" else "G — атака • выходи из красных кругов") else string.format(Locale.Text("Готовься! Следующая волна через %d с"),math.max(0,math.ceil((arena:GetAttribute("Deadline") or now)-now)))
 end
end
function Controller:Destroy() self.cleanup:Destroy() end
return Controller
