--!nonstrict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Input=game:GetService("UserInputService")
local Actions=game:GetService("ContextActionService")
local GuiService=game:GetService("GuiService")
local RunService=game:GetService("RunService")
local Catalog=require(ReplicatedStorage.Shared.AbilityCatalog)
local Ride=require(ReplicatedStorage.Shared.VerityRideConfig)
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local Controller={};Controller.__index=Controller
local icons={dash="↠",leap="↑",sprint="»",shield="◆",flight="▲",pulse="✦",laser="═",lightning="ϟ",gravity="◉",nova="★"}
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
	self.cleanup:Add(ctx.refs.RideButton.Activated:Connect(function() self:Activate("Ride",true) end))
 Actions:BindAction("VerityRide",function(_,state)
  if state==Enum.UserInputState.Begin and self:Activate("Ride",false) then return Enum.ContextActionResult.Sink end
  return Enum.ContextActionResult.Pass
 end,false,Enum.KeyCode.R,Enum.KeyCode.ButtonL3)
 self.cleanup:Add(function() Actions:UnbindAction("VerityRide") end)
 local reticle=W.Text(ctx.refs.Safe,"CombatReticle","+",22,true,Color3.fromHex("FFE7BD"))
	reticle.AnchorPoint,reticle.Position,reticle.Size=Vector2.new(.5,.5),UDim2.fromScale(.5,.5),UDim2.fromOffset(24,24)
	reticle.TextXAlignment=Enum.TextXAlignment.Center;reticle.TextStrokeTransparency=.35;reticle.Visible=false
	self.reticle=reticle
	self.cleanup:Add(Input.JumpRequest:Connect(function()
  if not ctx.active and not ctx.presenting and not ctx.forgeReveal and not GuiService.MenuIsOpen and not Input:GetFocusedTextBox() then
   self.ascendUntil=workspace:GetServerTimeNow()+.3
  end
 end))
 local elapsed=0
	self.cleanup:Add(RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt
		if elapsed<.1 then return end;elapsed=0
		self:Render()
		local item=self:Item("Mobility")
		if not self.remote or (not Players.LocalPlayer:GetAttribute("VerityRiding") and (not item or (item.Action~="flight" and not item.MobilityAction)))
			or (Players.LocalPlayer:GetAttribute("VerityMobilityUntil") or 0)<workspace:GetServerTimeNow() then return end
		local char=Players.LocalPlayer.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health<=0 then return end
		local blocked=ctx.active or ctx.presenting or ctx.forgeReveal or GuiService.MenuIsOpen or Input:GetFocusedTextBox()
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
	local ctx=self.ctx;local button=if slot=="Ride" then ctx.refs.RideButton elseif slot=="Mobility" then ctx.refs.AbilityButton else ctx.refs.AttackButton
	if not self.remote or ctx.active or ctx.presenting or ctx.forgeReveal or ctx.rewardOverlay or GuiService.MenuIsOpen or Input:GetFocusedTextBox()
		or not button.Visible or not button.Interactable then return false end
	if slot~="Ride" and not self:Item(slot) then
		ctx.open("ABILITIES")
		return true
	end
	local direction
	if slot=="Attack" then
		local camera=workspace.CurrentCamera;local char=Players.LocalPlayer.Character
		local root=char and char:FindFirstChild("Head")
		if not camera or not root then return false end
		local ray
		if fromButton or Input.PreferredInput~=Enum.PreferredInput.KeyboardAndMouse then
			ray=camera:ViewportPointToRay(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
		else local pos=Input:GetMouseLocation();ray=camera:ScreenPointToRay(pos.X,pos.Y) end
		local exclude,bodies={char},{}
		for _,player in Players:GetPlayers() do
			if player.Character and player.Character~=char then
				table.insert(exclude,player.Character);table.insert(bodies,player.Character)
			end
		end
		local params=RaycastParams.new();params.FilterDescendantsInstances=exclude;params.RespectCanCollide=true
		local hit=workspace:Raycast(ray.Origin,ray.Direction*400,params)
		local arenaShot=Players.LocalPlayer:GetAttribute("VerityBattleFighting")==true
		if #bodies>0 and not arenaShot then
			params.FilterType,params.FilterDescendantsInstances,params.RespectCanCollide=Enum.RaycastFilterType.Include,bodies,false
			local body=workspace:Raycast(ray.Origin,ray.Direction*400,params)
			if body and (not hit or body.Distance<hit.Distance) then hit=body end
		end
		local world=workspace:FindFirstChild("GeneratedWorld")
		local arena=world and world:FindFirstChild("VerityBattleArena")
		local enemies=arena and arena:FindFirstChild("Enemies")
		local target=if arenaShot and ctx.activities then ctx.activities:ResolveEnemyAim(ray,if hit then hit.Distance else 400) else nil
		if not target and enemies and arenaShot then
			params.FilterType,params.FilterDescendantsInstances,params.RespectCanCollide=Enum.RaycastFilterType.Include,{enemies},false
			local enemy=workspace:Raycast(ray.Origin,ray.Direction*400,params)
			if enemy and (not hit or enemy.Distance<hit.Distance) then hit=enemy end
		end
		if not target and ctx.adventures then target=ctx.adventures:ResolveAim(ray,if hit then hit.Distance else 400) end
		target=target or (if hit then hit.Position else ray.Origin+ray.Direction*400)
		local delta=target-root.Position;if delta.Magnitude<.1 then return false end;direction=delta.Unit
	end
	self.remote:FireServer(slot,direction);return true
end
function Controller:Render()
	local ctx=self.ctx;local char=Players.LocalPlayer.Character
	local humanoid=char and char:FindFirstChildOfClass("Humanoid")
	local riding=Players.LocalPlayer:GetAttribute("VerityRiding")==true
 local state=ctx.net.state
 local player=Players.LocalPlayer
 local racing=player:GetAttribute("VerityRaceSlot")~=nil
 local fusion=player:GetAttribute("VerityFusionSlot")~=nil
 local adventure=player:GetAttribute("VerityAdventureKind")
 local visible=(not adventure or adventure=="Trial") and player:GetAttribute("VerityDiversionKind")~="Arcade" and not fusion and not ctx.active and not ctx.presenting and not ctx.forgeReveal and not ctx.rewardOverlay and humanoid and humanoid.Health>0
 local size=ctx.refs.Safe.AbsoluteSize
 local inActivity=fusion or racing or player:GetAttribute("VerityParkourStep") or player:GetAttribute("VerityBattleActive")
 local actionY=math.max(if inActivity then 88 else 52,math.min(140,size.Y-168))
 ctx.refs.AbilityButton.Position=UDim2.new(1,-12,0,actionY)
 ctx.refs.AttackButton.Position=UDim2.new(1,-12,0,actionY+52)
	local rideButton=ctx.refs.RideButton
 rideButton.Visible=visible and not adventure and not inActivity and state and state.VerityUnlocked and state.VerityLevel>=Ride.MinLevel or false
 local key=if Input.PreferredInput==Enum.PreferredInput.Touch then "" elseif Input.PreferredInput==Enum.PreferredInput.Gamepad then "L3 " else "R "
 local remaining=math.max(0,math.ceil((Players.LocalPlayer:GetAttribute("VerityMobilityUntil") or 0)-workspace:GetServerTimeNow()))
 local phase=Players.LocalPlayer:GetAttribute("VerityRidePhase")
 local transitioning=riding and (phase=="Takeoff" or phase=="Landing")
 local caption=if phase=="Takeoff" then "Взлетаем!" elseif phase=="Landing" then "Приземляемся" elseif riding then "Спешиться" else "Верхом на Verity"
 W.SetButton(rideButton,key..Locale.Text(caption)..(if riding and not transitioning then " · "..remaining else ""),ctx.net.connected and not transitioning,false)
 for slot,button in {Mobility=ctx.refs.AbilityButton,Attack=ctx.refs.AttackButton} do
		local item=self:Item(slot)
		local trial=self.ctx.adventures and self.ctx.adventures.message and self.ctx.adventures.message.run
  local allowed=not adventure or adventure=="Trial" and trial and trial.kind=="Trial" and require(game:GetService("ReplicatedStorage").Shared.AdventureConfig).Trials[trial.id].Slot==slot
  button.Visible=visible and allowed and state~=nil and state.VerityUnlocked or false
		if not button.Visible then continue end
		local attribute=if slot=="Mobility" then "VerityAbilityReadyAt" else "VerityAttackReadyAt"
		local snapshot=state.AbilitySlots and state.AbilitySlots[slot]
		local now=workspace:GetServerTimeNow()
		local remaining=math.max(0,math.ceil((player:GetAttribute(attribute) or (snapshot and snapshot.readyAt) or 0)-now))
		local key=if Input.PreferredInput==Enum.PreferredInput.Touch then "" elseif Input.PreferredInput==Enum.PreferredInput.Gamepad then (if slot=="Mobility" then "L1 · " else "R1 · ") else (if slot=="Mobility" then "F · " else "G · ")
		local name=if not item then (if slot=="Mobility" then "Движение" else "Атака") elseif slot=="Mobility" and item.MobilityAction then "Полёт героя" else item.Name
		local icon=if item and snapshot and Catalog.Items[snapshot.itemId]==item then snapshot.icon
			elseif item then icons[if slot=="Mobility" then item.MobilityAction or item.Action else item.Action] or "◆" else "◇"
		local activeUntil=player:GetAttribute(if slot=="Attack" then "VerityAttackUntil" else "VerityMobilityUntil") or 0
		local active=math.max(0,math.ceil(activeUntil-now))
		local blocked=racing or player:GetAttribute("VerityParkourStep")~=nil or (riding and slot=="Mobility") or snapshot and snapshot.blockedReason~=nil
		local status=if snapshot and snapshot.blockedReason=="HOUSE_POWER" then "Выйди из дома" elseif racing then "Недоступно в гонке" elseif blocked then "Заблокировано здесь" elseif not item then "Выбери в коллекции" elseif not ctx.net.connected then "Нет связи"
		 elseif active>0 then string.format(Locale.Text("Действует • %d с"),active)
		 elseif remaining>0 then string.format(Locale.Text("Перезарядка • %d с"),remaining) else "Готово"
		W.SetButton(button,icon.." "..key..Locale.Text(name).."\n"..Locale.Text(status),not blocked and remaining==0 and active==0 and ctx.net.connected,false)
	end
	self.reticle.Visible=ctx.refs.AttackButton.Visible and self:Item("Attack")~=nil and not racing and not player:GetAttribute("VerityParkourStep")
end
function Controller:Destroy() self.cleanup:Destroy();self.reticle:Destroy() end
return Controller
