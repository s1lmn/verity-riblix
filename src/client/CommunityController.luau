--!nonstrict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.CommunityConfig)
local Cleanup=require(script.Parent.Cleanup)
local Card=require(script.Parent.ActivityCard)
local Locale=require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local carryGeometry={
 van={sizes={Vector3.new(.6,.1,.12),Vector3.new(.10,.3,.12),Vector3.new(.10,.3,.12)},offsets={Vector3.new(0,.6,0),Vector3.new(-.25,.45,0),Vector3.new(.25,.45,0)}},
 festival={sizes={Vector3.new(.13,.88,.88),Vector3.new(.88,.13,.88),Vector3.new(.4,.15,.2),Vector3.new(.4,.15,.2)},offsets={Vector3.zero,Vector3.zero,Vector3.new(-.15,.51,0),Vector3.new(.15,.51,0)}},
}
local Controller={};Controller.__index=Controller
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),prompts={},parts={}},Controller)
 self.card,self.title,self.detail,self.leave=Card.Build(ctx.refs.Safe,"CommunityStatus","LeaveCommunity")
 self.cleanup:Add(self.card)
 self.progress={}
 for i=1,3 do
  local track=W.Round(W.Frame(self.card,"Stage"..i,UDim2.new(1/3,-9,0,3),T.Soft),3)
  track.Position=UDim2.new((i-1)/3,7,1,-5)
  self.progress[i]=W.Round(W.Frame(track,"Fill",UDim2.fromScale(0,1),T.Purple),3)
 end
 self.cleanup:Add(self.leave.Activated:Connect(function()
  if self.remote and self.message and self.message.joined then self.remote:FireServer("Leave",self.message.round) end
 end))
 local folder=Instance.new("Folder");folder.Name="CommunityPresentation";folder.Parent=workspace;self.folder=self.cleanup:Add(folder)
 local function part(name,size,color)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=Color3.fromHex(color);p.Shape=Enum.PartType.Ball
  p.Material=Enum.Material.Neon;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  p.Transparency=1;p.Parent=folder;return p
 end
 self.carry=part("CarriedEnergy",Vector3.one*.85,"83F6FC")
 self.carryDetails={}
 for i=1,4 do self.carryDetails[i]=part("CarryDetail"..i,Vector3.one*.15,"FFF1CC");self.carryDetails[i].Shape=Enum.PartType.Block end
 for index=1,18 do
  local p=part("CelebrationConfetti",Vector3.new(.10,.34,.08),({"FFE287","87F7D3","FF9FD3","B7AAFF"})[(index-1)%4+1])
  p.Shape=Enum.PartType.Block;self.parts[index]=p
 end
 local function attach(remote)
  if not remote or remote.Name~="VerityCommunity" or not remote:IsA("RemoteEvent") or self.remote==remote then return end
  if self.remoteLink then self.remoteLink:Disconnect() end
  self.remote=remote
  self.remoteLink=remote.OnClientEvent:Connect(function(message)
   if type(message)~="table" or message.version~=C.Version or self.message and message.round<self.message.round then return end
   local previous=self.message;self.message=message
   if message.phase=="Celebrating" and (not previous or previous.phase~="Celebrating" or previous.round~=message.round) then self.celebrateAt=os.clock() end
   if previous and previous.joined and message.round==previous.round and (message.contribution>previous.contribution or message.carrying and not previous.carrying) then
    self.pulseAt=os.clock();self.pulsePosition=previous.targetPosition
   end
   if message.joined and (not previous or not previous.joined) then ctx.close() end
   if previous and message.round==previous.round and message.contribution>previous.contribution then ctx.sound:Play("TaskCheckpoint") end
   self:Render()
  end)
  remote:FireServer("Sync",0)
 end
 self.cleanup:Add(RS.ChildAdded:Connect(attach))
 self.cleanup:Add(RS.ChildRemoved:Connect(function(remote)
  if self.remote==remote then
   self.remote=nil;self.message=nil
   for _,entry in self.droneParts or {} do if entry.p.Parent then entry.p.LocalTransparencyModifier=0;entry.p.CFrame=entry.base end end
   if self.remoteLink then self.remoteLink:Disconnect();self.remoteLink=nil end
   self:Render()
  end
 end))
 self.cleanup:Add(function() if self.remoteLink then self.remoteLink:Disconnect() end end)
 attach(RS:FindFirstChild("VerityCommunity"))
 return self
end
function Controller:Model()
 local world=workspace:FindFirstChild("GeneratedWorld")
 return world and world:FindFirstChild("NeighborhoodLight")
end
function Controller:Goal()
 local m=self.message;local model=self:Model()
 if not m or not m.joined or m.phase~="Charging" then return nil end
 local target=model and model:FindFirstChild((if m.carrying then "Station" else "Cell")..(if m.carrying then m.station else m.node))
 local position=if target then target.Position else m.targetPosition
 if typeof(position)~="Vector3" then return nil end
 local variant=C.Variants[m.variant or "light"]
 local waiting=(m.nodeReadyAt or 0)>workspace:GetServerTimeNow()
 return {id="community:"..m.round..":"..m.contribution..":"..tostring(m.carrying)..":"..m.station..":"..m.node,
  kind="World",target="Community",object=target,position=position,
  title=if m.carrying then variant.Stations[m.station] else variant.Collect,
  detail="",near=if waiting then string.format(Locale.Text("Появится через %dс"),math.ceil(m.nodeReadyAt-workspace:GetServerTimeNow())) else "%s · "..Locale.Text(if m.carrying then variant.Deliver else variant.Collect),
  touch=if waiting then nil else (if m.carrying then variant.Deliver else variant.Collect),prompt=not waiting,radius=6}
end
function Controller:Render()
 local message=self.message
 self.card.Visible=message~=nil and message.joined and not Card.Blocked(self.ctx) or false
 if message and message.joined then
  Card.Layout(self.card,self.title,self.detail,self.ctx.refs.Safe.AbsoluteSize)
  local total,goal=0,0;for i=1,3 do total+=message.delivered[i];goal+=message.goals[i] end
  local variant=C.Variants[message.variant or "light"]
  self.title.Text=string.format(Locale.Text("%s • %dс"),Locale.Text(({light="Зажигаем район",van="Ремонт фургона",drones="Верни дронов",festival="Готовим праздник"})[message.variant or "light"]),math.max(0,math.ceil(message.deadline-workspace:GetServerTimeNow())))
  self.title.TextColor3=Color3.fromHex(variant.Color):Lerp(T.White,.35)
  for i,fill in self.progress do
   local ratio=math.clamp(message.delivered[i]/math.max(1,message.goals[i]),0,1)
   fill.BackgroundColor3=Color3.fromHex(variant.Color):Lerp(T.Purple,.2)
   if fill:GetAttribute("Progress")~=ratio then
    fill:SetAttribute("Progress",ratio)
    if self.ctx.settings.values.ReducedMotion then fill.Size=UDim2.fromScale(ratio,1)
    else self.ctx.animation:Tween(fill,.25,{Size=UDim2.fromScale(ratio,1)}) end
   end
  end
  self.detail.Text=string.format(Locale.Text("%s %d/%d • вклад %d/2"),Locale.Text(variant.Unit),total,goal,message.contribution)
 end
 local model=self:Model();if not model then return end
 local joined=message and message.joined
 for _,child in model:GetChildren() do
  local prompt=child:FindFirstChild("Interact")
  if not prompt then continue end
  if self.prompts[prompt]==nil then self.prompts[prompt]=prompt.Enabled end
  local enabled=false
  if child.Name=="Join" then enabled=not joined and message and message.joinable and not Card.ActivityRunning()
  elseif joined then
   enabled=(message.nodeReadyAt or 0)<=workspace:GetServerTimeNow() and child.Name==(if message.carrying then "Station"..message.station else "Cell"..message.node)
  end
  prompt.Enabled=enabled==true
 end
end
function Controller:VisualTick(now)
 self.carry.Transparency=1
 for _,p in self.carryDetails do p.Transparency=1 end
 for _,p in self.parts do p.Transparency=1 end
 local message=self.message;if not message then return end
 local settings=self.ctx.settings.values;local reduced=settings.ReducedMotion;local low=settings.LowGraphics or settings.ReducedEffects
 local model=self:Model();local variants=model and model:FindFirstChild("Variants")
 local drones=variants and variants:FindFirstChild("drones")
 if drones and self.droneModel~=drones then
  self.droneModel=drones;self.droneParts={}
  for _,node in drones:GetChildren() do for _,p in node:GetChildren() do
   if p:IsA("BasePart") then table.insert(self.droneParts,{p=p,index=node:GetAttribute("NodeIndex"),base=p:GetAttribute("EventBaseCFrame") or p.CFrame,spin=p:GetAttribute("EventSpin")==true}) end
  end end
 end
 if now>=(self.droneFrame or 0) then
  self.droneFrame=now+1/30
  local camera=workspace.CurrentCamera;local serverNow=workspace:GetServerTimeNow()
  for _,entry in self.droneParts or {} do if entry.p.Parent then
   local hidden=message.variant=="drones" and serverNow<((message.nodeReady or {})[entry.index] or 0)
   local alpha=if hidden then 1 else 0
   if entry.p.LocalTransparencyModifier~=alpha then entry.p.LocalTransparencyModifier=alpha end
   local animated=not hidden and message.variant=="drones" and not low and not reduced and camera and (camera.CFrame.Position-entry.base.Position).Magnitude<90
   local cf=entry.base
   if animated then cf=(cf+Vector3.new(0,math.sin(now*2+entry.index)*.20,0))*(if entry.spin then CFrame.Angles(0,now*12,0) else CFrame.identity) end
   if entry.p.CFrame~=cf then entry.p.CFrame=cf end
  end end
 end
 local player=Players.LocalPlayer;local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 local hidden=Card.Blocked(self.ctx) or not root or not hum or hum.Health<=0
 local camera=workspace.CurrentCamera
 local firstPerson=camera and (camera.CFrame.Position-camera.Focus.Position).Magnitude<1
 if message.joined and message.carrying and not hidden and not firstPerson then
  local variant=C.Variants[message.variant or "light"]
  self.carry.Color=Color3.fromHex(variant.Color)
  self.carry.Shape=if message.variant=="light" then Enum.PartType.Ball else Enum.PartType.Block
  self.carry.Size=if message.variant=="van" then Vector3.new(1.1,.65,.8) else Vector3.one*.85
  local cf=root.CFrame*CFrame.new(-1.2,.1,-1.2);self.carry.CFrame=cf;self.carry.Transparency=.05
  local geometry=carryGeometry[message.variant]
  local sizes=geometry and geometry.sizes;local offsets=geometry and geometry.offsets
  for i,size in sizes or {} do
   local p=self.carryDetails[i];p.Transparency=0;p.Size=size;p.Color=Color3.fromHex(if message.variant=="van" then "435676" else "FFF1CC")
   p.CFrame=cf*CFrame.new(offsets[i])
   if message.variant=="festival" and i>=3 then p.CFrame*=CFrame.Angles(0,0,if i==3 then -.3 else .3) end
  end
 end
 if hidden or low or reduced then return end
 local pulse=now-(self.pulseAt or -100)
 if pulse<.5 and typeof(self.pulsePosition)=="Vector3" then
  for i=1,6 do
   local angle=i*math.pi/3;local p=self.parts[i]
   p.CFrame=CFrame.new(self.pulsePosition+Vector3.new(math.cos(angle)*pulse*3,pulse*2,math.sin(angle)*pulse*3))*CFrame.Angles(0,angle,pulse*3)
   p.Transparency=.2+pulse*1.5
  end
 end
 if message.phase~="Celebrating" then return end
 local center=model and model:FindFirstChild("Station3")
 if not center or (root.Position-center.Position).Magnitude>90 then return end
 local elapsed=now-(self.celebrateAt or now)
 for index,p in self.parts do
  local t=(elapsed+(index%3)*.17)%2.8;local angle=index*2.39996
  local spread=1+t*1.2
  local position=center.Position+Vector3.new(math.cos(angle)*spread,2+t*4-t*t*1.8,math.sin(angle)*spread)
  p.CFrame=CFrame.new(position)*CFrame.Angles(t*2,index,t*3+angle)
  p.Transparency=math.clamp(.1+math.max(0,t-1.2)*.55,.1,1)
 end
end
function Controller:Destroy()
 for _,entry in self.droneParts or {} do if entry.p.Parent then entry.p.LocalTransparencyModifier=0;entry.p.CFrame=entry.base end end
 for prompt,enabled in self.prompts do if prompt.Parent then prompt.Enabled=enabled end end
 self.cleanup:Destroy()
end
return Controller
