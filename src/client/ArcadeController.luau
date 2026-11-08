--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Actions=game:GetService("ContextActionService")
local Input=game:GetService("UserInputService")
local Gui=game:GetService("GuiService")
local C=require(RS.Shared.ArcadeConfig)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Locale=require(script.Parent.Locale)
local Cleanup=require(script.Parent.Cleanup)
local ActivityCard=require(script.Parent.ActivityCard)
local Controller={};Controller.__index=Controller
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),prompts={},drops={},lane=2},Controller)
 require(script.Parent.ArcadeSkin).Build(self,ctx)
 local root=self.root
 self.cleanup:Add(self.left.Activated:Connect(function()self:Move(-1)end));self.cleanup:Add(self.right.Activated:Connect(function()self:Move(1)end))
 self.cleanup:Add(self.close.Activated:Connect(function()self:Leave()end))
 local function bind(name,keys,direction)
  Actions:BindActionAtPriority(name,function(_,state)
   if self.message and self.message.phase=="Playing" and not Gui.MenuIsOpen and not ctx.active and not ctx.presenting and not ctx.rewardOverlay and not Input:GetFocusedTextBox() then
    if state==Enum.UserInputState.Begin then if direction then self:Move(direction) else self:Leave() end end
    return Enum.ContextActionResult.Sink
   end
   return Enum.ContextActionResult.Pass
  end,false,4100,table.unpack(keys))
  self.cleanup:Add(function()Actions:UnbindAction(name)end)
 end
 bind("ArcadeLeft",{Enum.KeyCode.A,Enum.KeyCode.Left,Enum.KeyCode.DPadLeft},-1)
 bind("ArcadeRight",{Enum.KeyCode.D,Enum.KeyCode.Right,Enum.KeyCode.DPadRight},1)
 bind("ArcadeLeave",{Enum.KeyCode.Q,Enum.KeyCode.ButtonB},nil)
 local function add(p)self.prompts[p]=p.Enabled end
 self.cleanup:Add(Collection:GetInstanceAddedSignal("VerityHomeArcadePrompt"):Connect(add))
 self.cleanup:Add(Collection:GetInstanceRemovedSignal("VerityHomeArcadePrompt"):Connect(function(p)self.prompts[p]=nil end))
 for _,p in Collection:GetTagged("VerityHomeArcadePrompt") do add(p) end
 local function attach(remote)
  if not remote or remote.Name~="VerityArcade" or not remote:IsA("RemoteEvent") or remote==self.remote then return end
  if self.link then self.link:Disconnect() end;self.remote=remote
  self.link=remote.OnClientEvent:Connect(function(m)
   if type(m)~="table" or m.version~=C.Version or self.message and m.round<self.message.round then return end
   local previous=self.message;self.message=m
   if not previous or previous.round~=m.round then
    self.plan=C.Plan(m.seed);self.lane=m.lane;ctx.close()
    self.impactAt=nil;self.openScale.Scale=if ctx.settings.values.ReducedMotion then 1 else .96
    ctx.animation:Tween(self.openScale,.22,{Scale=1})
    if Input.PreferredInput==Enum.PreferredInput.Gamepad then Gui.SelectedObject=self.left end
   elseif m.feedback>previous.feedback then
    self.impactAt=os.clock();self.lastJudgement=m.judgement
    if m.judgement=="STAR" then ctx.sound:Play("Click") elseif m.judgement=="HIT" then ctx.sound:Play("NotEnoughCash") end
   end
   if m.phase~="Playing" then
    self.resultUntil=os.clock()+6
    if Gui.SelectedObject and Gui.SelectedObject:IsDescendantOf(root) then Gui.SelectedObject=nil end
    if m.phase=="Finished" then ctx.sound:Play("TaskCompleted") end
   end
  end)
  remote:FireServer("Sync",0)
 end
 self.cleanup:Add(RS.ChildAdded:Connect(attach));attach(RS:FindFirstChild("VerityArcade"))
 self.cleanup:Add(RS.ChildRemoved:Connect(function(remote)if remote==self.remote then if self.link then self.link:Disconnect();self.link=nil end;self.remote=nil;self.message=nil end end))
 self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function()self.message=nil end))
 self.cleanup:Add(function()if self.link then self.link:Disconnect()end end)
 return self
end
function Controller:Move(direction)
 local m=self.message
 if self.remote and m and m.phase=="Playing" and not Gui.MenuIsOpen and not self.ctx.active and not self.ctx.presenting and not self.ctx.rewardOverlay and not Input:GetFocusedTextBox() then self.remote:FireServer("Move",m.round,direction) end
end
function Controller:Leave()
 if self.message and self.message.phase=="Playing" and self.remote then self.remote:FireServer("Leave",self.message.round)
 else self.message=nil end
end
function Controller:Render()
 local m=self.message
 if m and m.phase~="Playing" and os.clock()>=(self.resultUntil or 0) then self.message=nil;m=nil end
 local player=Players.LocalPlayer
 local otherActivity=player:GetAttribute("VerityDiversionKind") and player:GetAttribute("VerityDiversionKind")~="Arcade"
 if m and m.phase~="Playing" and otherActivity then self.message=nil;m=nil end
 local blocked=self.ctx.active or self.ctx.presenting or self.ctx.rewardOverlay or Gui.MenuIsOpen
 self.root.Visible=m~=nil and m.phase~="Left" and not blocked
 if self.root.Visible then require(script.Parent.ArcadeSkin).Layout(self,self.ctx.refs.Safe.AbsoluteSize)
 elseif Gui.SelectedObject and Gui.SelectedObject:IsDescendantOf(self.root) then Gui.SelectedObject=nil end
 if m then
  self.score.Text=tostring(m.score)
  self.time.Text=tostring(if m.phase=="Playing" then math.max(0,math.ceil(m.deadline-workspace:GetServerTimeNow())) else 0)..Locale.Text("с")
  for i,heart in self.lives do heart.TextTransparency=if i<=m.lives then 0 else .8 end
  self.record.Text=string.format(Locale.Text("РЕКОРД • %d"),m.best)
  for i,prize in C.Prizes do
   local earned=((self.ctx.net.state or {}).CosmeticsOwned or {})[prize.Id]
   self.prizeBadges[i].Text=(if earned then "✓ " else "★ ")..prize.Score
   self.prizeBadges[i].TextTransparency=if earned or m.score>=prize.Score then 0 else .42
  end
  self.controls.Text=Locale.Text(if Input.PreferredInput==Enum.PreferredInput.Touch then "← / → • лови ★, избегай розовых ●" elseif Input.PreferredInput==Enum.PreferredInput.Gamepad then "Лови ★ • крестовина ←/→ • B — выйти" else "Лови ★ • избегай ● • A/D или ←/→ • Q — выйти")
 end
 local busy=ActivityCard.ActivityRunning() or player:GetAttribute("VerityRiding")
 for p in self.prompts do if p.Parent then
  local plot=p:GetAttribute("ArcadePlotId");local adventures=self.ctx.adventures
  local reserved=adventures and adventures:ArcadeReserved(plot)==true
  local partyAllowed=adventures and adventures:CanPlayArcade(plot)==true
  p.Enabled=(p:GetAttribute("ArcadeAvailable")==true and not p:GetAttribute("MachineUserId") and ((not busy and not reserved) or partyAllowed))==true
 end end
end
function Controller:VisualTick(now,dt)
 for _,icon in self.drops do icon.root.Visible=false end
 local m=self.message;if not m or not self.root.Visible then return end
 local playing=m.phase=="Playing";local settings=self.ctx.settings.values
 local reduced=settings.ReducedMotion;local light=settings.ReducedEffects or settings.LowGraphics
 self.cursor.Visible=playing;self.resultPanel.Visible=not playing
 W.SetButton(self.left,"←",playing,false);W.SetButton(self.right,"→",playing,false)
 self.combo.Text=if playing and m.combo>=2 then string.format(Locale.Text("КОМБО ×%d"),m.combo) else ""
 self.feedback.Visible=false;self.flash.BackgroundTransparency=1
 self.timeFill.Size=UDim2.fromScale(if playing then math.clamp((m.deadline-workspace:GetServerTimeNow())/C.Duration,0,1) else 0,1)
 if not playing then
  self.resultTitle.Text=Locale.Text(if m.newBest then "НОВЫЙ РЕКОРД!" else "ОТЛИЧНАЯ ПОПЫТКА!")
  self.resultScore.Text=tostring(m.score)
  local names={};for _,name in m.prizes or {} do table.insert(names,Locale.Text(name)) end
  self.resultDetail.Text=if #names>0 then table.concat(names," • ") else Locale.Text("Попробуй побить свой рекорд")
  return
 end
 self.lane+=(m.lane-self.lane)*(1-math.exp(-22*math.min(dt or .016,.1)))
 if reduced then self.lane=m.lane end
 self.cursor.Position=UDim2.fromScale((self.lane-.5)/3,.89)
 local age=now-(self.impactAt or -100)
 local pulse=math.max(0,1-age/.4)
 self.cursorScale.Scale=if reduced then 1 else 1+pulse*.14
 self.cursor.Rotation=if reduced then 0 else math.clamp((m.lane-self.lane)*-12,-14,14)
 if pulse>0 then
  local hit=self.lastJudgement=="HIT"
  if hit or self.lastJudgement=="STAR" then
   self.feedback.Visible=true;self.feedback.Text=if hit then "−10" else "+"..(10+math.min(15,m.combo)*2)
   self.feedback.TextColor3=if hit then T.Pink else T.Gold
   self.feedback.TextTransparency=1-pulse;self.feedback.Position=UDim2.fromScale((m.lane-.5)/3-.20,.59-(if reduced then 0 else age*.16));self.feedback.Size=UDim2.fromScale(.4,.15)
   if not light then self.flash.BackgroundColor3=self.feedback.TextColor3;self.flash.BackgroundTransparency=1-pulse*.11 end
  end
 end
 for lane,track in self.tracks do track.BackgroundTransparency=if lane==m.lane then .83 else .96 end
 for i,spark in self.sky do spark.BackgroundTransparency=if light or reduced then .65 else .6+math.sin(now*1.7+i)*.18 end
 local time=workspace:GetServerTimeNow()-m.started;local slot=0
 for _,drop in self.plan or {} do
  local progress=1-(drop.at-time)/C.FallSeconds
  if progress>=0 and progress<=1.015 then
   slot+=1;local icon=self.drops[slot];if not icon then break end
   icon.root.Visible=true;icon.star.Visible=drop.star;icon.meteor.Visible=not drop.star
   icon.root.Position=UDim2.fromScale((drop.lane-.5)/3,.89*progress)
   icon.root.Rotation=if reduced then 0 elseif drop.star then math.sin(progress*4)*9 else -12
  end
 end
end
function Controller:Destroy()
 if Gui.SelectedObject and Gui.SelectedObject:IsDescendantOf(self.root) then Gui.SelectedObject=nil end
 for p,enabled in self.prompts do if p.Parent then p.Enabled=enabled end end
 self.ctx.animation:Cancel(self.openScale)
 self.cleanup:Destroy()
end
return Controller
