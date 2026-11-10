--!nonstrict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Actions=game:GetService("ContextActionService")
local Gui=game:GetService("GuiService")
local C=require(RS.Shared.VerityFusionConfig)
local Factory=require(RS.World.VerityFusionFactory)
local Premium=require(RS.Shared.PremiumVisualCatalog)
local Cleanup=require(script.Parent.Cleanup)
local ActivityCard=require(script.Parent.ActivityCard)
local Locale=require(script.Parent.Locale)
local T=require(script.Parent.UITheme)
local W=require(script.Parent.UIWidgets)
local MobileHUD=require(script.Parent.MobileHUDLayout)
local Controller={};Controller.__index=Controller
local active={Merging=true,Running=true}
local DESKTOP_ACTION_Y={88,138,104,154}
local function button(parent,name,text,color,x,y,w)
 local b=W.Button(parent,name,text,color);b.Size=UDim2.fromOffset(w or 108,44)
 b.AnchorPoint=Vector2.new(1,0);b.Position=UDim2.new(1,x,0,y);b.TextSize=12
 b.Active=true;b.TextWrapped=true;b:SetAttribute("FixedFeedbackSize",true);return b
end
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),held={},nextMove=0,nextBind=0,windowFocused=true},Controller)
 self.folder=self.cleanup:Add(Instance.new("Folder"));self.folder.Name="FusionPresentation";self.folder.Parent=workspace
 self.card,self.title,self.detail,self.leave=ActivityCard.Build(ctx.refs.Safe,"FusionStatus","LeaveFusion")
 self.cleanup:Add(self.card)
 self.controls=self.cleanup:Add(W.Frame(ctx.refs.Safe,"FusionControls",UDim2.fromScale(1,1)))
 self.controls.BackgroundTransparency=1;self.controls.Visible=false;self.controls.ZIndex=22
 self.join=button(self.controls,"Join","",T.Mint,-12,88);self.join.Visible=false
 self.joinButtons={self.join}
 self.ready=button(self.controls,"Ready","Готов",T.Mint,-12,88)
 self.swap=button(self.controls,"Swap","Сменить роль",T.Gold,-12,138)
 self.jump=button(self.controls,"Jump","Прыжок",T.Mint,-12,104)
 self.boost=button(self.controls,"Boost","Рывок",T.Gold,-12,154)
 self.jumpCue=W.Stroke(self.jump,T.Gold,3);self.jumpCue.Transparency=1
 self.actionButtons={self.ready,self.swap,self.jump,self.boost}
 local touch=W.Frame(self.controls,"Steering",UDim2.fromScale(1,1));touch.BackgroundTransparency=1;self.touch=touch
 self.steeringButtons={}
 for _,spec in {{"Left","◀"},{"Brake","Ⅱ"},{"Right","▶"}} do
  local b=W.Button(touch,spec[1],spec[2],T.Paper);b.Size=UDim2.fromOffset(46,44)
  table.insert(self.steeringButtons,b)
  b.Active=true;b.Selectable=false;b:SetAttribute("FixedFeedbackSize",true)
  self.cleanup:Add(b.InputBegan:Connect(function(input)
   if input.UserInputType==Enum.UserInputType.Touch or input.UserInputType==Enum.UserInputType.MouseButton1 then self.held[spec[1]]=input end
  end))
 end
 self.cleanup:Add(Input.InputEnded:Connect(function(input)
  for key,value in self.held do if value==input then self.held[key]=nil end end
 end))
 self.cleanup:Add(Input.WindowFocusReleased:Connect(function()
  self.windowFocused=false
  table.clear(self.held)
  if self.mine and self.mine.role=="Pilot" then self:Send("Move",Vector2.zero) end
 end))
 self.cleanup:Add(Input.WindowFocused:Connect(function() self.windowFocused=true end))
 for b,action in {[self.join]="Join",[self.ready]="Ready",[self.swap]="Swap",[self.jump]="Jump",[self.boost]="Boost",[self.leave]="Leave"} do
  self.cleanup:Add(b.InputBegan:Connect(function(input)
   if input.UserInputType==Enum.UserInputType.Touch and b.Interactable then self:Send(action) end
  end))
  self.cleanup:Add(b.Activated:Connect(function(input)
   if not input or input.UserInputType~=Enum.UserInputType.Touch then self:Send(action) end
  end))
 end
 local function bind(name,action,...)
  Actions:BindActionAtPriority(name,function(_,state)
   if state==Enum.UserInputState.Begin and self:Send(action) then return Enum.ContextActionResult.Sink end
   return Enum.ContextActionResult.Pass
  end,false,3400,...)
  self.cleanup:Add(function()Actions:UnbindAction(name)end)
 end
 bind("FusionJump","Jump",Enum.KeyCode.Space,Enum.KeyCode.ButtonA)
 bind("FusionBoost","Boost",Enum.KeyCode.F,Enum.KeyCode.ButtonR1)
 bind("FusionLeave","Leave",Enum.KeyCode.Q,Enum.KeyCode.ButtonB)
 self.cleanup:Add(Input.JumpRequest:Connect(function() if Input.PreferredInput==Enum.PreferredInput.Touch then self:Send("Jump") end end))
 self.cleanup:Add(Run.RenderStepped:Connect(function(dt)self:Tick(math.min(dt,.1))end))
 self.cleanup:Add(function()if self.stateLink then self.stateLink:Disconnect() end;self:ReleaseCamera()end)
 return self
end
function Controller:Bind(model)
 if self.stateLink then self.stateLink:Disconnect();self.stateLink=nil end
 self.model=model;self.snapshot=nil;self.mine=nil;self.control=nil;self.nextSync=0;self.wasMember=false;self.readyRequest=nil;self.joinPendingUntil=nil
 self:ClearVisual();self:ReleaseCamera();self:ReleaseFocus()
 if not model then return end
 local event=model:FindFirstChild("FusionState");local control=model:FindFirstChild("FusionControl")
 if not event or not event:IsA("RemoteEvent") or not control or not control:IsA("RemoteEvent") then return end
 self.control=control
 self.stateLink=event.OnClientEvent:Connect(function(message)
  if type(message)~="table" or message.version~=C.Version or type(message.sequence)~="number" or type(message.entries)~="table"
   or typeof(message.pose)~="CFrame" or self.snapshot and self.snapshot.sequence>=message.sequence then return end
  local previous=self.snapshot;self.snapshot=message;self.mine=nil
  self.receivedAt=os.clock()
  for _,entry in message.entries do if entry.id==Players.LocalPlayer.UserId then self.mine=entry;break end end
  if self.mine then
   self.joinPendingUntil=nil
   if (not previous or not self.wasMember) and self.ctx.active then self.ctx.close() end
  end
  self.wasMember=self.mine~=nil
  if self.readyRequest and (not self.mine or self.mine.ready==self.readyRequest.value or message.phase~="Waiting") then
   self.readyRequest=nil
  end
  if self.mine and (not previous or previous.phase~=message.phase) then
   if message.phase=="Merging" then
    if self.ctx.active then self.ctx.close() end
    self.ctx.sound:Play("Milestone25")
   end
  end
  if self.mine and previous and message.phase=="Running" and previous.round==message.round then
   if message.faults>previous.faults then self.ctx.sound:Play("NotEnoughCash")
   elseif message.obstacle>previous.obstacle then self.ctx.sound:Play("TaskCheckpoint") end
  end
 end)
end
function Controller:NearbySlot(s)
 local char=Players.LocalPlayer.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local state=self.ctx.net.state
 if not root or not state or not state.VerityUnlocked or ActivityCard.ActivityRunning()
  or Players.LocalPlayer:GetAttribute("VerityRiding") or s.phase~="Waiting" or not self.model then return nil end
 local best,distance=nil,C.JoinReach
 for slot=1,2 do
  local pad=self.model:FindFirstChild("FusionPad"..slot)
  if not pad then continue end
  local taken=false
  for _,entry in s.entries do if entry.slot==slot then taken=true;break end end
  local gap=(root.Position-pad.Position).Magnitude
  if not taken and gap<distance then best=slot;distance=gap end
 end
 return best
end

function Controller:Send(action,value)
 local s=self.snapshot;local e=self.mine
 if not self.control or not s or Gui.MenuIsOpen or Input:GetFocusedTextBox() then return false end
 if action=="Join" then
  local slot=not e and not self.ctx.active and self:NearbySlot(s)
  local now=os.clock()
  if not slot or now<(self.joinPendingUntil or 0) then return false end
  self.joinPendingUntil=now+1
  self.control:FireServer("Join",s.round,slot)
  return true
 end
 if not e then return false end
 if action=="Jump" or action=="Boost" then
  if s.phase~="Running" or e.role~="Jumper" or self.ctx.active or workspace:GetServerTimeNow()<s.retryAt then return false end
  if action=="Boost" and workspace:GetServerTimeNow()<s.boostReady then return false end
  local now=os.clock();self.lastAction=self.lastAction or {}
  if now<(self.lastAction[action] or 0) then return true end
  self.lastAction[action]=now+.15
 elseif action=="Ready" or action=="Swap" then
  if s.phase~="Waiting" or self.ctx.active then return false end
  if action=="Ready" then
   local now=os.clock()
   if self.readyRequest and now<self.readyRequest.deadline then return false end
   value=not e.ready
   self.readyRequest={value=value,deadline=now+.9}
  end
 elseif action=="Leave" and self.ctx.active then return false end
 self.control:FireServer(action,s.round,value);return true
end
function Controller:InputVector()
 if not self.windowFocused or self.ctx.active or self.ctx.presenting or Gui.MenuIsOpen or Input:GetFocusedTextBox() then return Vector2.zero end
 local left=Input:IsKeyDown(Enum.KeyCode.A) or Input:IsKeyDown(Enum.KeyCode.Left) or self.held.Left~=nil
 local right=Input:IsKeyDown(Enum.KeyCode.D) or Input:IsKeyDown(Enum.KeyCode.Right) or self.held.Right~=nil
 local brake=Input:IsKeyDown(Enum.KeyCode.S) or Input:IsKeyDown(Enum.KeyCode.Down) or self.held.Brake~=nil
 local x=(if left then 1 else 0)-(if right then 1 else 0)
 if Input.PreferredInput==Enum.PreferredInput.Gamepad then
  for _,state in Input:GetGamepadState(Enum.UserInputType.Gamepad1) do
   if state.KeyCode==Enum.KeyCode.Thumbstick1 then x=if math.abs(state.Position.X)>.12 then -state.Position.X else 0;brake=brake or state.Position.Y<-.35;break end
  end
 elseif Input.PreferredInput==Enum.PreferredInput.Touch and x==0 then
  local char=Players.LocalPlayer.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
  if hum then x=math.clamp(hum.MoveDirection.X,-1,1);brake=brake or hum.MoveDirection.Z<-.35 end
 end
 local v=Vector2.new(x,if brake then 0 else 1)
 return if v.Magnitude>1 then v.Unit else v
end
function Controller:ClearVisual()
 if self.ghosts then for _,g in self.ghosts do g.model:Destroy() end;self.ghosts=nil end
 if self.visual then self.visual:Destroy() end
 if self.starlight then self.starlight:Destroy();self.starlight=nil end
 self.visual=nil;self.spark=nil;self.trail=nil;self.visualLook=nil;self.pose=nil;self.lastRound=nil;self.lastFault=nil;self.lastJump=nil;self.revealed=false;self.bounceAt=nil;self.scale=nil;self.lastPhase=nil
end
function Controller:ReleaseFocus()
 if not self.ownsFocus then return end
 self.ownsFocus=false
 local selected=Gui.SelectedObject
 if selected==nil or selected:IsDescendantOf(self.controls) then
  local previous=self.previousFocus
  Gui.SelectedObject=if previous and previous.Parent and previous.Visible then previous else nil
 end
 self.previousFocus=nil
end
function Controller:ReleaseCamera()
 local saved=self.camera;if not saved then return end
 self.camera=nil
 if saved.instance.Parent and saved.instance.CameraType==Enum.CameraType.Scriptable then
  if saved.subject and saved.subject.Parent then saved.instance.CameraSubject=saved.subject end
  saved.instance.CameraType=saved.kind
 end
end
function Controller:Camera(frame,dt,snap,merging)
 local camera=workspace.CurrentCamera;if not camera then return end
 if not self.camera or self.camera.instance~=camera then
  self:ReleaseCamera();self.camera={instance=camera,kind=camera.CameraType,subject=camera.CameraSubject};camera.CameraType=Enum.CameraType.Scriptable;snap=true
 end
 local pos=frame.Position
 local aim=pos+Vector3.new(0,5,if merging then 0 else 8)
 local wanted=CFrame.lookAt(pos+(if merging then Vector3.new(0,13,-27) else Vector3.new(0,15,-32)),aim)
 camera.CFrame=if snap then wanted else camera.CFrame:Lerp(wanted,1-math.exp(-12*dt))
 camera.Focus=CFrame.new(aim)
end
function Controller:Draw(s,now,dt)
 local camera=workspace.CurrentCamera
 local inRound=self.mine and active[s.phase]
 local close=camera and (s.pose.Position-camera.CFrame.Position).Magnitude<190
 if (not active[s.phase] and not (s.phase=="Results" and s.result=="Won" and now<s.deadline-C.ResultSeconds+1.15)) or not (inRound or close) then
  self:ClearVisual();self:ReleaseCamera();return
 end
 local look=if s.premiumLook==Premium.FusionLookId then s.premiumLook else nil
 if self.visual and self.visualLook~=look then self:ClearVisual() end
 if not self.visual then
  self.visual,self.spark,self.trail=Factory.Create(self.folder,s.entries,look)
  self.visualLook=look
 end
 local reduced=self.ctx.settings.values.ReducedMotion
 local effects=self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics
 local snap=self.lastRound~=s.round or not self.pose or (s.pose.Position-self.pose.Position).Magnitude>30
 local target=s.pose
 if s.phase=="Running" and typeof(s.velocity)=="Vector3" and type(s.serverTime)=="number" and now>=s.retryAt then
  local age=math.clamp(now-s.serverTime,0,.10)
  local delta=s.velocity*age;delta=Vector3.new(delta.X,math.max(-s.pose.Position.Y,delta.Y),delta.Z)
  target=s.pose+delta
 end
 self.pose=if snap then s.pose else self.pose:Lerp(target,1-math.exp(-30*dt))
 if self.lastRound~=s.round then self.revealed=false;self.lastFault=s.faults;self.lastJump=s.jump end
 if s.faults~=(self.lastFault or s.faults) then self.bounceAt=now;snap=true;self.pose=s.pose end
 local merge=if s.phase=="Merging" then math.clamp((now-s.mergeAt)/C.MergeSeconds,0,1) else 1
 local scale=if s.phase=="Merging" then math.max(.01,math.clamp((merge-.60)/.40,0,1)) else 1
 if self.bounceAt and not reduced then scale*=.82+.18*math.clamp((now-self.bounceAt)/.38,0,1) end
 if reduced then scale=if merge<.72 then .01 else 1 end
 if s.phase=="Merging" then
  if not self.ghosts then self.ghosts=Factory.Ghosts(self.folder,s.entries) end
  Factory.Merge(self.ghosts,self.pose,merge,reduced)
 elseif self.ghosts then for _,g in self.ghosts do g.model:Destroy() end;self.ghosts=nil end
 if look and s.phase=="Merging" and merge>=.46 and not effects and not reduced then
  if not self.starlight then self.starlight=Factory.StarlightRing(self.folder) end
  Factory.PoseStarlightRing(self.starlight,self.pose,merge)
 elseif self.starlight then self.starlight:Destroy();self.starlight=nil end
 if s.phase=="Results" then scale=math.max(.06,1-math.clamp((now-(s.deadline-C.ResultSeconds)-.25)/.8,0,1)) end
 if not self.scale or math.abs(scale-self.scale)>.025 or scale==1 and self.scale~=1 then self.visual:ScaleTo(scale);self.scale=scale end
 local wobble=if reduced then 0 else math.sin(now*7)*.055
 self.visual:PivotTo(self.pose*CFrame.Angles(0,0,wobble))
 if effects then self.spark:Clear()
 else
  local budget=self.ctx.settings.values.Graphics
  local factor=budget and budget.ParticleScale or 1
  if merge>=.85 and not self.revealed then self.spark:Emit(math.max(5,math.floor((if look then 42 else 24)*factor))) end
  if self.lastJump and s.jump>self.lastJump then self.spark:Emit(math.max(2,math.floor(7*factor))) end
  if s.phase=="Results" and self.lastPhase~="Results" then self.spark:Emit(math.max(5,math.floor(24*factor))) end
 end
 if self.trail then
  self.trail.Enabled=s.phase=="Running" and not effects and not reduced and now>=s.retryAt and not snap
  if snap or not self.trail.Enabled then self.trail:Clear() end
 end
 self.revealed=self.revealed or merge>=.85
 self.lastRound=s.round;self.lastFault=s.faults;self.lastJump=s.jump;self.lastPhase=s.phase
 if inRound and not self.ctx.presenting and Players.LocalPlayer:GetAttribute("VerityFusionActive") then self:Camera(self.pose,dt,snap,s.phase=="Merging") else self:ReleaseCamera() end
end
function Controller:Tick(dt)
 local at=os.clock()
 if at>=self.nextBind then
  self.nextBind=at+.3
  local world=workspace:FindFirstChild("GeneratedWorld");local model=world and world:FindFirstChild("VerityFusion")
  if model~=self.model or model and (not self.control or self.control.Parent~=model) then self:Bind(model) end
  if model and self.control and not self.snapshot and at>=self.nextSync then
   self.nextSync=at+1.1;self.control:FireServer("Sync",model:GetAttribute("FusionRound") or 0)
  end
 end
 local s,e=self.snapshot,self.mine
 if s and active[s.phase] and at-(self.receivedAt or 0)>2 then
  self.snapshot=nil;self.mine=nil;self.nextSync=0
  s=nil;e=nil
  self:ClearVisual();self:ReleaseCamera()
 end
 local now=workspace:GetServerTimeNow()
 if s then
  self:Draw(s,now,dt)
  if self.model and at>=(self.obstacleAt or 0) then
   self.obstacleAt=at+1/30
   if self.bumperModel~=self.model then
    self.bumperModel=self.model;self.bumpers={}
    for _,v in self.model:GetChildren() do if v.Name=="FusionBumper" then table.insert(self.bumpers,v) end end
   end
   for _,bumper in self.bumpers do
    local o=C.Obstacles[bumper:GetAttribute("ObstacleIndex")]
    if o then bumper.Position=Vector3.new(C.TrackX+C.BumperX(now,o),C.TrackY+o.height/2,o.z) end
   end
  end
 end
 local touch=MobileHUD.IsTouch()
 local unblocked=not self.ctx.active and not self.ctx.presenting and not self.ctx.forgeReveal and not self.ctx.rewardOverlay and not Gui.MenuIsOpen
 local show=s~=nil and e~=nil and unblocked
 local joinSlot=touch and s and not e and unblocked and self:NearbySlot(s)
 self.join.Visible=joinSlot~=nil and joinSlot~=false
 self.card.Visible=show;self.controls.Visible=show or self.join.Visible
 if self.join.Visible then
  local pending=at<(self.joinPendingUntil or 0)
  W.SetButton(self.join,if pending then "…" else Locale.Text(if joinSlot==1 then "Занять руль" else "Управлять прыжком"),not pending,pending)
  MobileHUD.PlaceActions(self.ctx.refs.Safe,self.joinButtons,52)
 end
 if not show then
  for _,b in self.actionButtons do b.Visible=false end
  self.touch.Visible=false
  table.clear(self.held)
  self:ReleaseFocus()
  return
 end
 local running=s.phase=="Running";local waiting=s.phase=="Waiting"
 if not waiting or Input.PreferredInput~=Enum.PreferredInput.Gamepad then self:ReleaseFocus() end
 local pilot=e.role=="Pilot";local jumper=e.role=="Jumper"
 self.ready.Visible=waiting;self.swap.Visible=waiting and #s.entries==2
 self.jump.Visible=running and jumper;self.boost.Visible=running and jumper
 self.touch.Visible=running and pilot and touch
 if touch then
  MobileHUD.PlaceActions(self.ctx.refs.Safe,if self.touch.Visible then self.steeringButtons else self.actionButtons,if self.touch.Visible then 44 else 52)
 else
  for i,b in self.actionButtons do
   b.AnchorPoint=Vector2.new(1,0)
   b.Position=UDim2.new(1,-12,0,DESKTOP_ACTION_Y[i])
   b.Size=UDim2.fromOffset(108,44)
  end
 end
 if not self.touch.Visible or Gui.MenuIsOpen then table.clear(self.held) end
 ActivityCard.Layout(self.card,self.title,self.detail,self.ctx.refs.Safe.AbsoluteSize)
 local role=if pilot then "Руль" else "Прыжок и рывок"
 self.title.Text=Locale.Text(role).." • "..Locale.Text("Единый Verity")
 if waiting then
  self.detail.Text=if #s.entries<2 then Locale.Text("Ждём второго игрока") else (if e.ready then Locale.Text("Ты готов • ждём напарника") else Locale.Text("Оба должны нажать «Готов»"))
  local pending=self.readyRequest and at<self.readyRequest.deadline
  W.SetButton(self.ready,if pending then "…" else Locale.Text(if e.ready then "Не готов" else "Готов"),not pending,pending==true)
  W.SetButton(self.swap,Locale.Text(if e.swap then "Ждём согласия" else "Сменить роль"),true,false)
  if Input.PreferredInput==Enum.PreferredInput.Gamepad and not self.ownsFocus then
   self.previousFocus=Gui.SelectedObject;self.ownsFocus=true;Gui.SelectedObject=self.ready
  end
 elseif s.phase=="Merging" then self.detail.Text=Locale.Text("Соединяем две Verity…")
 else
  local remaining=math.max(0,math.ceil(s.deadline-now))
  local controls=if Input.PreferredInput==Enum.PreferredInput.Touch then "◀ ▶ — руль • Ⅱ — тормоз"
   elseif Input.PreferredInput==Enum.PreferredInput.Gamepad then "Левый стик — руль • вниз — тормоз" else "A/D — руль • S — тормоз"
  if not pilot then controls=if Input.PreferredInput==Enum.PreferredInput.Touch then "Кнопки справа: прыжок и рывок"
   elseif Input.PreferredInput==Enum.PreferredInput.Gamepad then "A — прыжок • R1 — рывок" else "Пробел — прыжок • F — рывок" end
  local obstacle=C.Obstacles[s.obstacle]
  local hint=if not obstacle then "Финиш прямо" elseif obstacle.kind=="Gate" then (if obstacle.opening<0 then "Ворота справа" else "Ворота слева")
   elseif obstacle.kind=="Bumper" then "Объедь бампер" elseif obstacle.kind=="Gap" then "Прыжок через разрыв" else "Прыжок через барьер"
  self.title.Text=Locale.Text(role).." • "..Locale.Text(hint)
  local distance=obstacle and math.max(0,math.floor(obstacle.z-(s.pose.Position.Z))) or 0
  local section=C.Section(s.pose.Position.Z)
  self.card.Size=UDim2.fromOffset(self.card.Size.X.Offset,84)
  self.detail.Text=Locale.Text(section.Name).." • "..distance..Locale.Text("м").." • "..remaining..Locale.Text("с").." • "..tostring(C.MaxFaults-s.faults).." ♥\n"..Locale.Text(controls)

  local input=Input.PreferredInput
  local jumpKey=if input==Enum.PreferredInput.Touch then "" elseif input==Enum.PreferredInput.Gamepad then "A · " else "Space · "
  local boostKey=if input==Enum.PreferredInput.Touch then "" elseif input==Enum.PreferredInput.Gamepad then "R1 · " else "F · "
  W.SetButton(self.jump,jumpKey..Locale.Text("Прыжок"),now>=s.retryAt,false)
  local cooldown=math.max(0,math.ceil(s.boostReady-now))
  W.SetButton(self.boost,boostKey..Locale.Text("Рывок")..(if cooldown>0 then " · "..cooldown else ""),cooldown==0 and now>=s.retryAt,false)
  self.jumpCue.Transparency=if not pilot and obstacle and (obstacle.kind=="Gap" or obstacle.kind=="Bar") and distance>=5 and distance<=12 and now>=s.retryAt then .1 else 1
  if running and pilot and at>=self.nextMove then self.nextMove=at+.085;self:Send("Move",self:InputVector()) end
 end
end
function Controller:Destroy()
 self:ClearVisual();self:ReleaseFocus();self.cleanup:Destroy()
end
return Controller
