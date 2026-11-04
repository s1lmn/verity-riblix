--!nonstrict
local Locale = require(script.Parent.Locale)
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Abilities=require(ReplicatedStorage.Shared.VerityAbilities)
local W=require(script.Parent.UIWidgets)
local RunService=game:GetService("RunService")
local GuiService=game:GetService("GuiService")
local UserInputService=game:GetService("UserInputService")
local ContextActionService=game:GetService("ContextActionService")
local Cleanup=require(script.Parent.Cleanup)
local Builder=require(script.Parent.UIBuilder)
local Model=require(script.Parent.UIModel)
local Ledger=require(script.Parent.EventLedger)
local Network=require(script.Parent.NetworkAdapter)
local Settings=require(script.Parent.SettingsController)
local Animation=require(script.Parent.UIAnimationController)
local Sound=require(script.Parent.UISoundController)
local Notifications=require(script.Parent.NotificationController)
local Rewards=require(script.Parent.FloatingRewardController)
local Verity=require(script.Parent.VerityUIController)
local HouseSelection=require(script.Parent.HouseSelectionController)
local Phone=require(script.Parent.PhoneUIController)
local Workshop=require(script.Parent.WorkshopUIController)
local Tasks=require(script.Parent.TasksUIController)
local Cosmetics=require(script.Parent.CosmeticsUIController)
local Tutorial=require(script.Parent.TutorialController)
local Versions=require(script.Parent.VersionController)
local Presentation=require(script.Parent.VerityPresentationController)
local Visuals=require(game:GetService("ReplicatedStorage").World.VerityVisualController)
local Main={}
Main.__index=Main
local Errors={
 NOT_OWNED="You do not own this accessory.",PRODUCT_UNAVAILABLE="This item is not on sale yet.",
 ALREADY_OWNED="You already own this item.",BUSY="Finish the previous purchase first.",
	INSUFFICIENT_CASH="You need a little more Cash for that upgrade.",
	COOLDOWN="A little too soon. Try again in a moment.",
	MAX_LEVEL="This upgrade is already maxed out.",
	PHONE_SESSION_CLOSED="Open the phone to start an earning session.",
	PROFILE_NOT_READY="Your progress is still loading.",
	VERITY_LOCKED="Open your delivery box first.",
	RATE_LIMITED="Please wait a moment before the next action.",
}

function Main.new()
	local playerGui=Players.LocalPlayer:WaitForChild("PlayerGui")
	local old=playerGui:FindFirstChild("VerityUI")
	if old then
		local shutdown=old:FindFirstChild("Shutdown")
		if shutdown and shutdown:IsA("BindableEvent") then shutdown:Fire();task.wait() end
		old:Destroy()
	end
	local self=setmetatable({cleanup=Cleanup.new(),dead=false,displayCash=nil,nextPresentation=0,bannerUntil=0,
		notificationIds={},notificationOrder={}},Main)
	local refs=Builder.Build(playerGui)
	self.refs=refs
	self.cleanup:Add(refs.Gui)
	self.cleanup:Add(Locale.TrackWorld())
	local ctx={refs=refs,active=nil}
	self.ctx=ctx
	ctx.net=self.cleanup:Add(Network.new())
	ctx.settings=self.cleanup:Add(Settings.new(refs.Panels.SETTINGS))
	ctx.animation=self.cleanup:Add(Animation.new(ctx.settings))
	ctx.sound=self.cleanup:Add(Sound.new(ctx.settings))
	ctx.notifications=self.cleanup:Add(Notifications.new(refs.Toasts))
	ctx.rewards=self.cleanup:Add(Rewards.new(refs.Reward,ctx.settings))
	ctx.open=function(name) self:Open(name) end
	ctx.close=function() self:Open(nil) end
	ctx.request=function(action,args)
		local id,reason=ctx.net:Request(action,args)
		if not id and reason then ctx.notifications:Show(reason,"Error") end
		return id
	end
	self.verity=self.cleanup:Add(Verity.new(ctx))
	self.phone=self.cleanup:Add(Phone.new(ctx))
	self.workshop=Workshop.new(ctx)
	self.houseSelection=self.cleanup:Add(HouseSelection.new())
	self.tasks=self.cleanup:Add(Tasks.new(ctx))
 ctx.tasks=self.tasks
 self.cosmetics=self.cleanup:Add(Cosmetics.new(ctx))
	self.tutorial=self.cleanup:Add(Tutorial.new(ctx))
	self.ledger=Ledger.new()
	self.versions=self.cleanup:Add(Versions.new(ctx))
	self.visuals=self.cleanup:Add(Visuals.new(ctx.settings))
	self.presentation=self.cleanup:Add(Presentation.new(ctx))
	self.cleanup:Add(self.visuals.Started.Event:Connect(function(event,model)
		if event.ownerUserId==Players.LocalPlayer.UserId then
			self.ledger:Push(event);self.presentation:Start(event,model)
		end
	end))
	self.cleanup:Add(self.visuals.Completed.Event:Connect(function(event) self.presentation:Complete(event) end))
	for _,obj in refs.Gui:GetDescendants() do
		if obj:IsA("TextButton") then
			ctx.animation:BindButton(obj)
			self.cleanup:Add(obj.Activated:Connect(function() ctx.sound:Play("Click") end))
		end
	end
	for name,button in refs.Nav do
		self.cleanup:Add(button.Activated:Connect(function() self:Open(if ctx.active==name then nil else name) end))
	end
	for _,panel in refs.Panels do self.cleanup:Add(panel.Close.Activated:Connect(function() self:Open(nil) end)) end
	self.cleanup:Add(refs.SettingsButton.Activated:Connect(function() self:Open(if ctx.active=="SETTINGS" then nil else "SETTINGS") end))
	self.cleanup:Add(refs.Safe:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() refs.Layout(ctx.active~=nil) end))
	local shutdown=Instance.new("BindableEvent")
	shutdown.Name,shutdown.Parent="Shutdown",refs.Gui
	self.cleanup:Add(shutdown.Event:Connect(function() self:Destroy() end))
	self.cleanup:Add(ctx.net.StateChanged.Event:Connect(function(state)
		self.ledger:Seed(state.stateRevision,state.VerityLevel)
		if self.displayCash==nil then self.displayCash=state.Cash end
		if Model.IsFinite(state.IncomeAccrued) and state.IncomeAccrued>0 then ctx.rewards:Add(state.IncomeAccrued) end
		self:Render()
		self.phone:ReconcileSession()
	end))
	self.cleanup:Add(Locale.Changed.Event:Connect(function()
		self:Render()
		self.presentation:RenderCopy()
		self:RenderBanner()
	end))
	self.cleanup:Add(ctx.net.PendingChanged.Event:Connect(function() self:Render() end))
	self.cleanup:Add(ctx.net.ConnectionChanged.Event:Connect(function() self:Render() end))
	self.cleanup:Add(ctx.net.TimedOut.Event:Connect(function(item)
		ctx.notifications:Show("Server reply is delayed. This action stays locked until its result is known.","Error",4)
	end))
	self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
		if result.success then
			if result.action=="TaskStart" then
				if result.reward and result.reward>0 then ctx.rewards:Add(result.reward);ctx.sound:Play("Reward") end
			elseif result.action=="UpgradeVerity" then
				-- Also close when the companion is temporarily not streamed in.
				ctx.close()
			elseif result.action=="UpgradeSwipe" then
				ctx.animation:Success(refs.Panels.PHONE.Power)
				ctx.sound:Play("UpgradeSwipe")
				ctx.notifications:Show("Сила свайпа повышена!")
			end
		else ctx.notifications:Show(Errors[result.errorCode] or "That action could not finish. Please check your progress.","Error") end
	end))
	self.cleanup:Add(ctx.net.Notification.Event:Connect(function(payload)
		if type(payload.eventId)=="string" then
			if self.notificationIds[payload.eventId] then return end
			self.notificationIds[payload.eventId]=true
			table.insert(self.notificationOrder,payload.eventId)
			if #self.notificationOrder>256 then self.notificationIds[table.remove(self.notificationOrder,1)]=nil end
			if Model.IsFinite(payload.reward) and payload.reward>0 then ctx.rewards:Add(payload.reward);ctx.sound:Play("Reward") end
		end
		ctx.notifications:Show(payload.message,payload.kind)
	end))
	self.cleanup:Add(ctx.net.World.Event:Connect(function(event)
		local animated=self.visuals:HandleWorld(event)
		if not animated and event.kind=="VerityLevelChanged" and event.ownerUserId==Players.LocalPlayer.UserId then self.ledger:Push(event) end
	end))
	local function activateAbility()
		local button=refs.AbilityButton
		if not button.Visible or not button.Interactable or ctx.active or ctx.presenting or GuiService.MenuIsOpen then return false end
		local remote=ReplicatedStorage:FindFirstChild("UseVerityAbility")
		if not remote then return false end
		remote:FireServer()
		return true
	end
	self.cleanup:Add(refs.AbilityButton.Activated:Connect(activateAbility))
	ContextActionService:BindAction("VerityAbility",function(_,inputState)
		if inputState==Enum.UserInputState.Begin and not UserInputService:GetFocusedTextBox() and activateAbility() then
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end,false,Enum.KeyCode.F,Enum.KeyCode.ButtonL1)
	self.cleanup:Add(function() ContextActionService:UnbindAction("VerityAbility") end)
	local function back(_,state)
		if ctx.presenting then return Enum.ContextActionResult.Pass end
		if state==Enum.UserInputState.Begin and ctx.active then self:Open(nil);return Enum.ContextActionResult.Sink end
		return Enum.ContextActionResult.Pass
	end
	ContextActionService:BindActionAtPriority("VerityUIBack",back,false,3000,Enum.KeyCode.ButtonB,Enum.KeyCode.Escape)
	ContextActionService:BindActionAtPriority("VerityUIMenu",function(_,state)
		if state==Enum.UserInputState.Begin and not GuiService.MenuIsOpen and not UserInputService:GetFocusedTextBox() then
			if ctx.active then self:Open(nil) else self:Open("VERITY") end
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end,false,3000,Enum.KeyCode.ButtonY)
	self.cleanup:Add(function() ContextActionService:UnbindAction("VerityUIBack");ContextActionService:UnbindAction("VerityUIMenu") end)
	self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function() self:Open(nil);self.phone.input:Cancel() end))
	self.cleanup:Add(UserInputService.WindowFocusReleased:Connect(function() self.phone.input:Cancel() end))
	self.cleanup:Add(UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
		if UserInputService.PreferredInput==Enum.PreferredInput.Gamepad and ctx.active then self:SetFocus(ctx.active) end
	end))
	local elapsed=0
	self.cleanup:Add(RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt
		if elapsed<0.1 then return end
		local interval=elapsed
		elapsed=0
		self:Tick(interval)
	end))
	refs.Layout(false)
	self:Render()
	ctx.net:Start()
	Main.current=self
	return self
end

function Main.GetCurrent() return Main.current end

function Main:SetFocus(name)
	if UserInputService.PreferredInput~=Enum.PreferredInput.Gamepad then return end
	local panel=self.refs.Panels[name]
	local target=panel and (if name=="PHONE" then panel.Next elseif name=="VERITY" then panel.Buy else panel.Close)
	if target and not target.Selectable then target=panel.Close end
	GuiService.SelectedObject=target
end

function Main:Open(name)
	local ctx=self.ctx
	if name and name~="SETTINGS" and not Players.LocalPlayer:GetAttribute("HousePlotId") then return end
	if name and ctx.presenting then return end
	if ctx.active==name then return end
	self.previousFocus=GuiService.SelectedObject
	ctx.active=name
	for key,panel in self.refs.Panels do panel.Root.Visible=key==name end
	self.phone:SetOpen(name=="PHONE")
	self.refs.Layout(name~=nil)
	self:Render()
	if name then self:SetFocus(name)
	elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(self.refs.Gui) then
		GuiService.SelectedObject=if UserInputService.PreferredInput==Enum.PreferredInput.Gamepad then self.refs.Nav.VERITY else nil
	end
end

function Main:Render()
	local ctx=self.ctx
	local state=ctx.net.state
	self.refs.Status.Text=if self.versions.issue then self.versions:IssueText() elseif not ctx.net.connected then Locale.Text("Connecting…") elseif not state then Locale.Text("Loading progress…") else ""
 self.refs.Status.Visible=ctx.active==nil and (self.versions.issue~=nil or not ctx.net.connected or (state==nil and not Players.LocalPlayer:GetAttribute("HouseSelectionReady")))
	self.refs.Income.Text=if state then "+$"..Locale.Number(state.IncomePerSecond)..Locale.Text(" / sec") else Locale.Text("+$— / sec")
	self.refs.Level.Text=if state then string.format(Locale.Text("LVL %d / 100"),state.VerityLevel) else Locale.Text("LVL — / 100")
	self:RenderAbility()
	self.verity:Render();self.workshop:Render();self.phone:Render();self.tasks:Render();self.tutorial:Render();self.cosmetics:Render()
	local selected=GuiService.SelectedObject
	if ctx.active and selected and selected:IsDescendantOf(self.refs.Panels[ctx.active].Root) and not selected.Selectable then self:SetFocus(ctx.active) end
end

function Main:RenderBanner()
	local event=self.bannerEvent
	if not event then return end
	local milestone=Model.NextMilestone(event.oldLevel)
	if milestone and milestone.level~=event.newLevel then milestone=nil end
	self.refs.BannerText.Text=if milestone then string.format(Locale.Text("LEVEL %d • %s\n%s"),event.newLevel,Locale.Text(milestone.name),Locale.Text(milestone.reward))
		else string.format(Locale.Text("LEVEL UP!  %d → %d\n%.3f× → %.3f×"),event.oldLevel,event.newLevel,event.oldScale,event.newScale)
end

function Main:RenderAbility()
	local ctx=self.ctx
	local button=self.refs.AbilityButton
	local state=ctx.net.state
	local character=Players.LocalPlayer.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	local form=state and state.VerityUnlocked and Abilities.Get(state.VerityLevel)
	button.Visible=form and form.action~=nil and not ctx.active and not ctx.presenting and humanoid~=nil and humanoid.Health>0 or false
	if not button.Visible then return end
	local remaining=math.ceil((Players.LocalPlayer:GetAttribute("VerityAbilityReadyAt") or 0)-workspace:GetServerTimeNow())
	local input=UserInputService.PreferredInput
	local key=if input==Enum.PreferredInput.Touch then "" elseif input==Enum.PreferredInput.Gamepad then "L1  " else "F  "
	local text=key..Locale.Text(form.name)
	if remaining>0 then text..="\n"..string.format(Locale.Text("Готово через %d сек."),remaining) end
	W.SetButton(button,text,remaining<=0 and ctx.net.connected,false)
end

function Main:Tick(dt)
	local ctx=self.ctx
	local state=ctx.net.state
	if state then
		if ctx.settings.values.ReducedMotion then self.displayCash=state.Cash
		else self.displayCash+=(state.Cash-self.displayCash)*(1-math.exp(-dt*15)) end
		if math.abs(state.Cash-self.displayCash)<0.5 then self.displayCash=state.Cash end
		self.refs.Cash.Text="$"..Locale.Number(self.displayCash)
	end
	local now=os.clock()
	if self.versions.issue then self.refs.Status.Text=self.versions:IssueText() end
	self:RenderAbility()
	ctx.rewards:Tick(now)
	self.tasks:Render();self.tutorial:Render()
	self.phone:ReconcileSession()
	self.verity:Render()
	self.refs.Banner.Visible=now<self.bannerUntil
	if now>=self.nextPresentation then
		local event=self.ledger:Pop()
		if event and not self.presentation:Has(event.eventId) then
			local milestone=nil
			for _,entry in Model.Milestones do if entry.level==event.newLevel then milestone=entry end end
			self.bannerEvent=event
			self:RenderBanner()
			ctx.sound:Play(if milestone then "Milestone" else "LevelUp")
			self.bannerUntil=now+(if milestone then 1.6 else 0.7)
			self.nextPresentation=self.bannerUntil+0.1
			self.refs.Banner.Visible=true
		end
	end
end

function Main:Destroy()
	if self.dead then return end
	self.dead=true
	if Main.current==self then Main.current=nil end
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(self.refs.Gui) then GuiService.SelectedObject=nil end
	self.cleanup:Destroy()
end
return Main
