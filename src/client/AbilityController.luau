--!nonstrict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local Actions=game:GetService("ContextActionService")
local GuiService=game:GetService("GuiService")
local RunService=game:GetService("RunService")
local Catalog=require(ReplicatedStorage.Shared.AbilityCatalog)
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local Controller={};Controller.__index=Controller
function Controller.new(ctx)
	local self=setmetatable({ctx=ctx,cleanup=Cleanup.new()},Controller)
	self.remote=ReplicatedStorage:WaitForChild("UseVerityAbility",10)
	for slot,button in {Mobility=ctx.refs.AbilityButton,Attack=ctx.refs.AttackButton} do
		self.cleanup:Add(button.Activated:Connect(function() self:Activate(slot,true) end))
		local action="Verity"..slot
		Actions:BindAction(action,function(_,state)
			if state==Enum.UserInputState.Begin and self:Activate(slot,false) then return Enum.ContextActionResult.Sink end
			return Enum.ContextActionResult.Pass
		end,false,if slot=="Mobility" then Enum.KeyCode.F else Enum.KeyCode.G,if slot=="Mobility" then Enum.KeyCode.ButtonL1 else Enum.KeyCode.ButtonR1)
		self.cleanup:Add(function() Actions:UnbindAction(action) end)
	end
	local reticle=W.Text(ctx.refs.Safe,"CombatReticle","+",22,true,Color3.fromHex("FFE7BD"))
	reticle.AnchorPoint,reticle.Position,reticle.Size=Vector2.new(.5,.5),UDim2.fromScale(.5,.5),UDim2.fromOffset(24,24)
	reticle.TextXAlignment=Enum.TextXAlignment.Center;reticle.TextStrokeTransparency=.35;reticle.Visible=false
	self.reticle=reticle
	self.cleanup:Add(Input.JumpRequest:Connect(function()
  if not ctx.active and not ctx.presenting and not GuiService.MenuIsOpen and not Input:GetFocusedTextBox() then
   self.ascendUntil=workspace:GetServerTimeNow()+.3
  end
 end))
 local elapsed=0
	self.cleanup:Add(RunService.Heartbeat:Connect(function(dt)
		self:Render();elapsed+=dt
		if elapsed<.1 then return end;elapsed=0
		local item=self:Item("Mobility")
		if not self.remote or not item or (item.Action~="flight" and not item.MobilityAction)
			or (Players.LocalPlayer:GetAttribute("VerityMobilityUntil") or 0)<workspace:GetServerTimeNow() then return end
		local char=Players.LocalPlayer.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health<=0 then return end
		local blocked=ctx.active or ctx.presenting or GuiService.MenuIsOpen or Input:GetFocusedTextBox()
  local movement=if blocked then Vector3.zero else hum.MoveDirection
  local vertical=if blocked then 0 elseif Input:IsKeyDown(Enum.KeyCode.LeftControl) then -.65
   elseif hum.Jump or Input:IsKeyDown(Enum.KeyCode.Space) or (self.ascendUntil or 0)>workspace:GetServerTimeNow() then 1 else 0
		local direction=Vector3.new(movement.X,vertical,movement.Z)
		if direction.Magnitude>1 then direction=direction.Unit end
		self.remote:FireServer("Steer",direction)
	end))
	self:Render();return self
end
function Controller:Item(slot)
	local state=self.ctx.net.state
	if not state or not state.VerityUnlocked then return nil end
	return Catalog.Equipped(state,slot,state.HeroPassOwned)
end
function Controller:Activate(slot,fromButton)
	local ctx=self.ctx;local button=if slot=="Mobility" then ctx.refs.AbilityButton else ctx.refs.AttackButton
	if not self.remote or ctx.active or ctx.presenting or GuiService.MenuIsOpen or Input:GetFocusedTextBox()
		or not button.Visible or not button.Interactable then return false end
	local direction
	if slot=="Attack" then
		local camera=workspace.CurrentCamera;local char=Players.LocalPlayer.Character
		local root=char and char:FindFirstChild("Head")
		if not camera or not root then return false end
		local ray
		if fromButton or Input.PreferredInput~=Enum.PreferredInput.KeyboardAndMouse then
			ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
		else local pos=Input:GetMouseLocation();ray=camera:ScreenPointToRay(pos.X,pos.Y) end
		local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char}
		local hit=workspace:Raycast(ray.Origin,ray.Direction*400,params)
		local target=if hit then hit.Position else ray.Origin+ray.Direction*400
		local delta=target-root.Position;if delta.Magnitude<.1 then return false end;direction=delta.Unit
	end
	self.remote:FireServer(slot,direction);return true
end
function Controller:Render()
	local ctx=self.ctx;local char=Players.LocalPlayer.Character
	local humanoid=char and char:FindFirstChildOfClass("Humanoid")
	local visible=not ctx.active and not ctx.presenting and humanoid and humanoid.Health>0
	for slot,button in {Mobility=ctx.refs.AbilityButton,Attack=ctx.refs.AttackButton} do
		local item=self:Item(slot)
		button.Visible=visible and item~=nil or false
		if not button.Visible then continue end
		local attribute=if slot=="Mobility" then "VerityAbilityReadyAt" else "VerityAttackReadyAt"
		local remaining=math.max(0,math.ceil((Players.LocalPlayer:GetAttribute(attribute) or 0)-workspace:GetServerTimeNow()))
		local key=if Input.PreferredInput==Enum.PreferredInput.Touch then "" elseif Input.PreferredInput==Enum.PreferredInput.Gamepad then (if slot=="Mobility" then "L1 " else "R1 ") else (if slot=="Mobility" then "F " else "G ")
		local name=if slot=="Mobility" and item.MobilityAction then "Полёт героя" else item.Name
		local flightRemaining=if slot=="Mobility" and (item.Action=="flight" or item.MobilityAction)
   then math.max(0,math.ceil((Players.LocalPlayer:GetAttribute("VerityMobilityUntil") or 0)-workspace:GetServerTimeNow())) else 0
  local text=if flightRemaining>0 then string.format(Locale.Text("ПОЛЁТ • %d с"),flightRemaining)
   else key..Locale.Text(name)..(if remaining>0 then " · "..remaining..Locale.Text(" с") else "")
  W.SetButton(button,text,remaining==0 and flightRemaining==0 and ctx.net.connected,false)
	end
	self.reticle.Visible=ctx.refs.AttackButton.Visible
end
function Controller:Destroy() self.cleanup:Destroy();self.reticle:Destroy() end
return Controller
