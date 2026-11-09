--!nonstrict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Actions=game:GetService("ContextActionService")
local Input=game:GetService("UserInputService")
local Gui=game:GetService("GuiService")
local Config=require(game:GetService("ReplicatedStorage").Shared.VerityRaceConfig)
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local ActivityCard=require(script.Parent.ActivityCard)
local Controller={};Controller.__index=Controller
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),gates={}},Controller)
 self.card,self.title,self.detail,self.leave=ActivityCard.Build(ctx.refs.Safe,"RaceStatus","LeaveRace")
 self.cleanup:Add(self.card)
 self.cleanup:Add(self.leave.Activated:Connect(function()self:Leave()end))
 Actions:BindAction("VerityRaceLeave",function(_,state)
  if state==Enum.UserInputState.Begin and self:Leave() then return Enum.ContextActionResult.Sink end
  return Enum.ContextActionResult.Pass
 end,false,Enum.KeyCode.Q,Enum.KeyCode.ButtonB)
 self.cleanup:Add(function()Actions:UnbindAction("VerityRaceLeave")end)
 self.cleanup:Add(RunService.RenderStepped:Connect(function(dt)self:Tick(dt)end))
 return self
end
function Controller:Leave()
 if not self.card.Visible or not self.leave.Interactable or self.ctx.active or self.ctx.presenting or Gui.MenuIsOpen or Input:GetFocusedTextBox() then return false end
 local remote=self.track and self.track:FindFirstChild("LeaveRaceQueue")
 if not remote then return false end
 remote:FireServer();return true
end
function Controller:RestoreGates()
 for _,r in self.gates do if r.part.Parent then r.part.CFrame=r.base end end
 self.gates={}
end
function Controller:Tick(dt)
 local world=workspace:FindFirstChild("GeneratedWorld")
 local track=world and world:FindFirstChild("VerityRaceTrack")
 if self.track~=track then self:RestoreGates();self.track=track end
 local player=Players.LocalPlayer;local slot=player:GetAttribute("VerityRaceSlot")
 self.card.Visible=track~=nil and slot~=nil and not ActivityCard.Blocked(self.ctx)
 if not track then return end
 local phase=track:GetAttribute("RacePhase") or "Waiting"
 local count=track:GetAttribute("RaceCount") or 0
 local now=workspace:GetServerTimeNow()
 local remaining=math.max(0,math.ceil((track:GetAttribute("RaceDeadline") or now)-now))
 local caption
 if phase=="Countdown" then caption=string.format(Locale.Text("СТАРТ ЧЕРЕЗ %d с"),remaining)
 elseif phase=="Running" then caption=Locale.Text("ВПЕРЁД, VERITY!")
 elseif phase=="Results" then
  local name=track:GetAttribute("RaceWinner")
  caption=if name then string.format(Locale.Text("ПОБЕДИТЕЛЬ: %s"),name) else Locale.Text("Заезд отменён")
 else caption=string.format(Locale.Text("ЖДЁМ ИГРОКОВ • %d/4"),count)end
 local board=track:FindFirstChild("RaceBoard")
 if board then
  for _,gui in board:GetChildren() do
   local text=gui:IsA("SurfaceGui") and gui:FindFirstChild("Text")
   if text and text.Text~=caption then text.Text=caption end
  end
 end
 if self.card.Visible then
  ActivityCard.Layout(self.card,self.title,self.detail,self.ctx.refs.Safe.AbsoluteSize)
  self.title.Text=caption
  local total,own=0,0
  for lane=1,Config.MaxPlayers do
   local pad=track:FindFirstChild("QueuePad"..lane)
   if pad and pad:GetAttribute("RaceOwner") then
    local weight=Config.Weight(pad:GetAttribute("RaceLevel") or 1);total+=weight
    if lane==slot then own=weight end
   end
  end
  local percent=if total>0 then math.floor(100*own/total+.5) else 0
  self.detail.Text=if phase=="Running" then string.format(Locale.Text("Дорожка %d"),slot)
   elseif count<Config.MinPlayers or own==0 then string.format(Locale.Text("Место %d • ждём соперника • бесплатно"),slot)
   else string.format(Locale.Text("Место %d • шанс ≈%d%% • бесплатно"),slot,percent)
  W.SetButton(self.leave,"×",phase~="Running",false)
 end
 for lane=1,Config.MaxPlayers do
  local gate=track:FindFirstChild("StartGate"..lane);local r=self.gates[lane]
  if gate and (not r or r.part~=gate) then r={part=gate,base=gate.CFrame,open=0};self.gates[lane]=r end
  if r and r.part.Parent then
   local target=if phase=="Running" or phase=="Results" then 1 else 0
   r.open=if self.ctx.settings.values.ReducedMotion then target else r.open+(target-r.open)*(1-math.exp(-9*math.min(dt,.1)))
   r.part.CFrame=r.base*CFrame.new(0,-5*r.open,0)
  end
 end
end
function Controller:Destroy()self:RestoreGates();self.cleanup:Destroy()end
return Controller
