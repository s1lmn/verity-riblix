--!nonstrict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Actions=game:GetService("ContextActionService")
local Input=game:GetService("UserInputService")
local Gui=game:GetService("GuiService")
local P=require(RS.Shared.ParkourConfig)
local B=require(RS.Shared.VerityBattleConfig)
local Motion=require(RS.Shared.EnemyMotion)
local Locale=require(script.Parent.Locale)
local T=require(script.Parent.UITheme)
local Cleanup=require(script.Parent.Cleanup)
local ActivityCard=require(script.Parent.ActivityCard)
local Controller={};Controller.__index=Controller
local function disc(folder)
 local p=Instance.new("Part");p.Name="StrikeWarning";p.Shape=Enum.PartType.Cylinder;p.Anchored=true
 p.Size=Vector3.new(.08,1,1);p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Material=Enum.Material.Neon;p.Color=Color3.fromHex("FF547A");p.Transparency=1;p.Parent=folder;return p
end
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),enemyCleanup=Cleanup.new(),courseCleanup=Cleanup.new(),enemies={},motion={},hazards={},belts={},elapsed=0,lastLeave=-math.huge},Controller)
 self.folder=self.cleanup:Add(Instance.new("Folder"));self.folder.Name="VerityActivityVisuals";self.folder.Parent=workspace
 self.card,self.title,self.detail,self.leave=ActivityCard.Build(ctx.refs.Safe,"ActivityStatus","Leave")
 self.cleanup:Add(self.card)
 self.cleanup:Add(self.leave.Activated:Connect(function()self:Leave()end))
 self.next=Instance.new("Highlight");self.next.Name="NextParkourPlatform";self.next.FillTransparency=.82;self.next.OutlineTransparency=.1
 self.next.FillColor=T.Gold;self.next.OutlineColor=T.Gold;self.next.Enabled=false;self.next.DepthMode=Enum.HighlightDepthMode.Occluded;self.next.Parent=self.folder
 self.saved=Instance.new("Highlight");self.saved.Name="SavedFactoryCheckpoint";self.saved.FillTransparency=1;self.saved.OutlineTransparency=.1
 self.saved.OutlineColor=T.Mint;self.saved.DepthMode=Enum.HighlightDepthMode.Occluded;self.saved.Enabled=false;self.saved.Parent=self.folder
 Actions:BindAction("VerityActivityLeave",function(_,state)
  if state==Enum.UserInputState.Begin and self:Leave() then return Enum.ContextActionResult.Sink end
  return Enum.ContextActionResult.Pass
 end,false,Enum.KeyCode.Q,Enum.KeyCode.ButtonB)
 self.cleanup:Add(function()Actions:UnbindAction("VerityActivityLeave")end)
 local function bindMotion()
  local remote=RS:FindFirstChild("VerityEnemyMotion")
  if not remote or not remote:IsA("RemoteEvent") or self.motionRemote==remote then return end
  if self.motionLink then self.motionLink:Disconnect();table.clear(self.motion) end
  self.motionRemote=remote
  self.motionLink=remote.OnClientEvent:Connect(function(packet)
   if type(packet)~="table" or packet.version~=Motion.Version or type(packet.enemyId)~="number"
    or type(packet.sequence)~="number" or type(packet.startedAt)~="number" or packet.duration~=Motion.Step
    or typeof(packet.from)~="CFrame" or typeof(packet.to)~="CFrame" then return end
   local now=workspace:GetServerTimeNow()
   if math.abs(now-packet.startedAt)>2 then return end
   local old=self.motion[packet.enemyId]
   if old and old.sequence>=packet.sequence then return end
   self.motion[packet.enemyId]=packet
  end)
 end
 self.cleanup:Add(RS.ChildAdded:Connect(function(child)if child.Name=="VerityEnemyMotion" then bindMotion() end end))
 self.cleanup:Add(function()if self.motionLink then self.motionLink:Disconnect() end;table.clear(self.motion) end)
 bindMotion()
 self.cleanup:Add(Players.LocalPlayer:GetAttributeChangedSignal("VerityParkourFinishTime"):Connect(function()
  local player=Players.LocalPlayer;local time=player:GetAttribute("VerityParkourFinishTime");local medal=player:GetAttribute("VerityParkourMedal")
  if time and medal then ctx.notifications:Show(string.format(Locale.Text("%s • паркур за %d с"),Locale.Text(medal),math.round(time))) end
 end))
 self.cleanup:Add(Run.RenderStepped:Connect(function(dt)
  self:MoveEnemies(dt)
  self.elapsed+=dt;local graphics=ctx.settings.values.Graphics
  if self.elapsed<(graphics and graphics.AbilityInterval or 1/30) then return end
  self.elapsed=0;self:Tick()
 end))
 self.cleanup:Add(function()self:BindArena(nil);self.courseCleanup:Destroy();for _,r in self.hazards do if r.part.Parent then r.part.CFrame=r.base;r.part.Transparency=.8 end end end)
 return self
end
local function removeEnemy(record)
 if record.visual then record.visual:Destroy() end
 if record.marker then record.marker:Destroy() end
 for part,alpha in record.parts do if part.Parent then part.LocalTransparencyModifier=alpha end end
 if record.label and record.label.Parent then
  record.label.Adornee=record.labelAdornee;record.label.Enabled=record.labelEnabled
 end
end
local function prepareEnemy(model,r,root)
 r.visual=model:Clone();r.visual.Name="EnemyPresentation"
 r.body=r.visual:FindFirstChild("Body")
 for _,p in r.visual:GetDescendants() do
  if p:IsA("BillboardGui") then p:Destroy()
  elseif p:IsA("BasePart") then
   p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
   table.insert(r.visualParts,p)
  end
 end
 r.label=root:FindFirstChild("LevelLabel")
 if r.label then r.labelAdornee=r.label.Adornee;r.labelEnabled=r.label.Enabled end
 for _,p in model:GetDescendants() do if p:IsA("BasePart") then r.parts[p]=p.LocalTransparencyModifier end end
end
function Controller:ResolveEnemyAim(ray,limit)
 local aim
 local direction=ray.Direction.Unit
 for model,r in self.enemies do
  if not r.pose or not r.body or model:GetAttribute("EnemyDead") then continue end
  local body=model:FindFirstChild("Body")
  if not body or not body.CanQuery then continue end
  local offset=r.body.Position-ray.Origin
  local depth=offset:Dot(direction)
  local radius=r.body.Size.X*.5
  local miss=(offset-direction*depth).Magnitude
  if depth<=0 or miss>radius then continue end
  local entry=math.max(0,depth-math.sqrt(radius*radius-miss*miss))
  if entry<limit then limit=entry;aim=body.Position end
 end
 return aim
end
function Controller:MoveEnemies(dt)
 local camera=workspace.CurrentCamera
 local settings=self.ctx.settings.values
 local distance=settings.Graphics and settings.Graphics.EffectDistance or 160
 local now=workspace:GetServerTimeNow()
 for model,r in self.enemies do
  local root=model.PrimaryPart
  if not root then continue end
  local target=model:GetPivot()
  local near=camera and (camera.CFrame.Position-target.Position).Magnitude<distance
  local dead=model:GetAttribute("EnemyDead")==true
  local id=model:GetAttribute("EnemyId")
  if dead and not r.deadAt then r.deadAt=now;if id then self.motion[id]=nil end end
  local segment=id and self.motion[id]
  if not r.visual and (near or dead) then prepareEnemy(model,r,root) end
  if not near then
   if r.visual and (r.pose or dead and not r.hiddenDead) then
    r.visual.Parent=nil;r.pose=nil;r.hiddenDead=dead
    for part,alpha in r.parts do if part.Parent then part.LocalTransparencyModifier=if dead then 1 else alpha end end
    if r.label then r.label.Adornee=r.labelAdornee;r.label.Enabled=r.labelEnabled and not dead end
   end
   continue
  end
  local pose=r.pose
  if dead and pose then
   -- Freeze at the last visible position while the defeated enemy fades.
  elseif settings.ReducedMotion then pose=target
  elseif segment and now<=segment.startedAt+segment.duration+.12 then pose=Motion.Sample(segment,now)
  elseif not pose or (target.Position-pose.Position).Magnitude>8 then pose=target
  else
   pose=pose:Lerp(target,1-math.exp(-20*math.min(dt,.1)))
   -- Limit the visible lag from the authoritative, queryable body.
   local offset=pose.Position-target.Position
   if offset.Magnitude>.38 then pose=CFrame.new(target.Position+offset.Unit*.38)*pose.Rotation end
  end
  r.pose=pose;r.visual:PivotTo(pose)
  if not r.visual.Parent then
   r.visual.Parent=self.folder
   for part in r.parts do if part.Parent then part.LocalTransparencyModifier=1 end end
   if r.label then r.label.Adornee=r.visual.PrimaryPart end
  end
  if r.label and dead then r.label.Enabled=false end
  if dead then
   local alpha=math.clamp((now-r.deadAt)/.6,0,1)
   for _,part in r.visualParts do part.LocalTransparencyModifier=alpha end
  end
 end
end
function Controller:Leave()
 local player=Players.LocalPlayer
 if not self.card.Visible or self.ctx.active or self.ctx.presenting or Gui.MenuIsOpen or Input:GetFocusedTextBox() or os.clock()-self.lastLeave<.6 then return false end
 local remote=RS:FindFirstChild("VerityActivities");if not remote then return false end
 self.lastLeave=os.clock();remote:FireServer(if player:GetAttribute("VerityBattleActive") then "LeaveBattle" else "LeaveParkour");return true
end
function Controller:BindArena(arena)
 self.enemyCleanup:Destroy();self.enemyCleanup=Cleanup.new()
 for model,r in self.enemies do removeEnemy(r);self.enemies[model]=nil end
 if self.arena then table.clear(self.motion) end
 self.arena=arena;if not arena then return end
 local function add(model)
  if not model:IsA("Model") or self.enemies[model] then return end
  local r={marker=disc(self.folder),parts={},visualParts={}}
  self.enemies[model]=r
 end
 local function remove(model)
  local r=self.enemies[model];if not r then return end
  local id=model:GetAttribute("EnemyId");if id then self.motion[id]=nil end
  removeEnemy(r);self.enemies[model]=nil
 end
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
  self.course=course;table.clear(self.hazards);table.clear(self.belts)
  if course then
   local function add(p)
    if p:IsA("BasePart") and p:GetAttribute("FactoryBelt") then self.belts[p]={index=p:GetAttribute("FactoryBelt"),offset=p:GetAttribute("BeltOffset")} end
    local index=tonumber(p.Name:match("^Hazard(%d+)$"));local pad=index and P.Pads[index]
    if pad and pad.hazard and p:IsA("BasePart") then self.hazards[index]={part=p,base=p.CFrame} end
   end
   self.courseCleanup:Add(course.ChildAdded:Connect(add))
   self.courseCleanup:Add(course.ChildRemoved:Connect(function(p)self.belts[p]=nil;for index,r in self.hazards do if r.part==p then self.hazards[index]=nil end end end))
   for _,p in course:GetChildren() do add(p) end
  end
 end
 local player=Players.LocalPlayer;local now=workspace:GetServerTimeNow();local camera=workspace.CurrentCamera
 local graphics=self.ctx.settings.values.Graphics;local distance=graphics and graphics.EffectDistance or 200
 for id,segment in self.motion do if now-segment.startedAt>2 then self.motion[id]=nil end end
 for index,r in self.hazards do
  if not r.part.Parent then continue end
  local near=camera and (r.base.Position-camera.CFrame.Position).Magnitude<math.max(distance,65)
  if not near then r.part.Transparency=1;continue end
  local platform=course and course:FindFirstChild(string.format("Pad%02d",index))
  local frame,size,phase=P.HazardGeometry(index,now,platform and platform.CFrame)
  r.part.CFrame=frame;r.part.Size=size
  r.part.Color=if phase==2 then Color3.fromHex("FF5277") elseif phase==1 then T.Gold else T.Mint
  r.part.Transparency=if phase==2 then .15 elseif phase==1 then .38 else .70
 end
 for part,belt in self.belts do
  if not part.Parent then self.belts[part]=nil;continue end
  local pad=P.Pads[belt.index]
  local near=camera and (part.Position-camera.CFrame.Position).Magnitude<math.max(distance,65)
  part.LocalTransparencyModifier=if near then 0 else 1
  if near and not self.ctx.settings.values.ReducedMotion then
   local z=(belt.offset-now*pad.belt+6)%12-6
   local position=Vector3.new(pad.x,pad.y,pad.z)
   part.CFrame=CFrame.lookAt(position,position+pad.direction)*CFrame.new(0,.55,z)
  end
 end
 if course then
  local activated=course:GetAttribute("CoreActivatedAt")
  local elapsed=if activated then now-activated else math.huge
  local final=P.Pads[#P.Pads]
  local near=camera and (camera.CFrame.Position-Vector3.new(final.x,final.y,final.z)).Magnitude<distance
  for i=1,3 do
   local pulse=course:FindFirstChild("CorePulse"..i)
   if not pulse then continue end
   local t=elapsed-(i-1)*.22
   local show=near and t>=0 and t<1.8 and not self.ctx.settings.values.ReducedEffects and not self.ctx.settings.values.LowGraphics and not self.ctx.settings.values.ReducedMotion
   pulse.Transparency=if show then .55+.45*t/1.8 else 1
   if show then pulse.Size=Vector3.one*(9+t*14) end
  end
 end
 for model,r in self.enemies do
  local strike=model:GetAttribute("StrikeAt");local target=model:GetAttribute("StrikeTarget")
  if strike then r.lastStrike=strike end
  local impact=not strike and r.lastStrike and now-r.lastStrike>=0 and now-r.lastStrike<.28
  local warningDistance=if player:GetAttribute("VerityBattleActive") then math.max(distance,100) else distance
  local visible=target and camera and not model:GetAttribute("EnemyDead") and (target-camera.CFrame.Position).Magnitude<warningDistance and (strike or impact)
  r.marker.Transparency=if visible then (if impact then .45 else .72) else 1
  if visible then
   local radius=model:GetAttribute("EnemyRadius") or 5
   local pulse=if impact and not self.ctx.settings.values.ReducedMotion then 1+(now-r.lastStrike)*2 else 1
   r.marker.Size=Vector3.new(.08,radius*2*pulse,radius*2*pulse)
   r.marker.CFrame=CFrame.new(target-Vector3.new(0,2.7,0))*CFrame.Angles(0,0,math.pi/2)
   r.marker.Color=if impact then T.Gold else Color3.fromHex("FF5277")
  end
 end
 local step=player:GetAttribute("VerityParkourStep");local battle=player:GetAttribute("VerityBattleActive")
 self.card.Visible=(step~=nil or battle==true) and not ActivityCard.Blocked(self.ctx)
 self.next.Enabled=step~=nil and course~=nil and not ActivityCard.Blocked(self.ctx)
 if self.next.Enabled then self.next.Adornee=course:FindFirstChild(string.format("Pad%02d",math.min(#P.Pads,step+1))) end
 self.saved.Enabled=step~=nil and course~=nil and not ActivityCard.Blocked(self.ctx)
 if self.saved.Enabled then self.saved.Adornee=course:FindFirstChild(string.format("Pad%02d",player:GetAttribute("VerityParkourCheckpoint") or 1)) end
 if not self.card.Visible then return end
 ActivityCard.Layout(self.card,self.title,self.detail,self.ctx.refs.Safe.AbsoluteSize)
 if step then
  local p=P.Pads[step];local elapsed=math.max(0,now-(player:GetAttribute("VerityParkourStartedAt") or now))
  local section=p and p.section or 1
  self.title.Text=string.format(Locale.Text("ЦЕХ %d / %d • %s"),section,P.SectionCount,Locale.Text(P.Sections[section]))
  local tips={"Ленты и прессы • выбирай момент","Балки • перепрыгивай вращающиеся механизмы","Лазеры • жди безопасного окна","Лифты и платформы • дождись подъёма","Раскалённый пол • прыгай в безопасные окна","Узкие мосты • держи равновесие","Комбинации • доберись до пульта ядра"}
  local progress=string.format(Locale.Text("%d / %d • %d с • ошибок: %d"),step,#P.Pads,math.floor(elapsed),player:GetAttribute("VerityParkourFaults") or 0)
  self.detail.Text=if step==#P.Pads then Locale.Text("Маршрут пройден! Нажми «Запустить ядро» у пульта.") else progress.."\n"..Locale.Text(tips[section])
 elseif arena then
  local wave=arena:GetAttribute("Wave") or 0;local phase=arena:GetAttribute("Phase")
  local heading=if self.ctx.refs.Safe.AbsoluteSize.X<400 then "ВОЛНА %d / %d" else "АРЕНА • ВОЛНА %d / %d"
  self.title.Text=string.format(Locale.Text(heading),wave,#B.Waves)
  self.detail.Text=if phase=="Fighting" then Locale.Text(if Input.PreferredInput==Enum.PreferredInput.Touch then "Нажми атаку • выходи из красных кругов" elseif Input.PreferredInput==Enum.PreferredInput.Gamepad then "R1 — атака • выходи из красных кругов" else "G — атака • выходи из красных кругов") else string.format(Locale.Text("Готовься! Следующая волна через %d с"),math.max(0,math.ceil((arena:GetAttribute("Deadline") or now)-now)))
 end
end
function Controller:Destroy() self.cleanup:Destroy() end
return Controller
