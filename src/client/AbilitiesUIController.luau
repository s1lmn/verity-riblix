--!nonstrict
local Players=game:GetService("Players")
local Market=game:GetService("MarketplaceService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Catalog=require(ReplicatedStorage.Shared.AbilityCatalog)
local Config=require(ReplicatedStorage.Shared.GameConfig)
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Controller={};Controller.__index=Controller
function Controller.new(ctx)
	local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),rows={}},Controller)
	local body=ctx.refs.Panels.ABILITIES.Body
 ctx.refs.Panels.ABILITIES.Rows=self.rows
	W.Line(body,"HowTo","Покупай способности, затем выбери одну для F и одну для G.",56,13,false,T.Muted).Visible=false
	for index,id in Catalog.Order do
		local item=Catalog.Items[id]
		local color=Color3.fromHex(item.Color)
		local row=W.Block(body,id,if item.Premium then 218 else 150,color:Lerp(T.Paper,.82))
		row.LayoutOrder=if item.Premium then -1 else index
		W.New("UIGradient",{Color=ColorSequence.new(T.White,color:Lerp(T.Paper,.55)),Rotation=115},row)
		if item.Premium then W.Stroke(row,T.Gold,3).Transparency=.1 end
		local title=W.Text(row,"Name","",17,true);title.Size=UDim2.new(1,0,0,26)
		local description=W.Text(row,"Description","",12,false,T.Ink)
		description.Position,description.Size=UDim2.fromOffset(0,30),UDim2.new(1,0,0,44)
		local details=W.Text(row,"Details","",11,false,T.Muted)
		details.Position,details.Size=UDim2.fromOffset(0,77),UDim2.new(1,0,0,24)
		local button=W.Button(row,"Buy","",if item.Premium then T.Gold else color)
		button.AnchorPoint,button.Position,button.Size=Vector2.new(0,1),UDim2.new(0,0,1,0),UDim2.new(1,0,0,44)
		button.TextSize=12
		if item.Premium then
			local emblem=W.Text(row,"Emblem","◉  ═══════  ◉",28,true,Color3.fromHex("FF244A"))
			emblem.Position,emblem.Size=UDim2.fromOffset(0,109),UDim2.new(1,0,0,38);emblem.TextXAlignment=Enum.TextXAlignment.Center
		end
		self.rows[id]={root=row,title=title,description=description,details=details,button=button}
		self.cleanup:Add(button.Activated:Connect(function() self:Activate(id) end))
	end
	self.cleanup:Add(ctx.net.StateChanged.Event:Connect(function(state)
		local passId=state.HeroPassId
		if self.passId~=passId then
			self.passId=passId;self.offer=nil;self.promptOpen=false
			if passId then task.spawn(function()
				local ok,offer=pcall(function() return Market:GetProductInfoAsync(passId,Enum.InfoType.GamePass) end)
				if self.dead or self.passId~=passId then return end
				self.offer=if ok and type(offer)=="table" and offer.IsForSale and type(offer.PriceInRobux)=="number" then offer else nil
				self:Render()
			end) end
		end
		self:Render()
	end))
	self.cleanup:Add(ctx.net.PendingChanged.Event:Connect(function() self:Render() end))
	self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
		if result.success and (result.action=="BuyAbility" or result.action=="EquipAbility") then
			ctx.sound:Play("Success");ctx.notifications:Show("Способность выбрана!")
		end
	end))
	self.cleanup:Add(Market.PromptGamePassPurchaseFinished:Connect(function(player,id)
		if player==Players.LocalPlayer and id==self.passId then self.promptOpen=false;self:Render() end
	end))
	self.cleanup:Add(Locale.Changed.Event:Connect(function() self:Render() end))
	local remote=ReplicatedStorage:WaitForChild("VerityAbilityShop",10)
	if remote then self.cleanup:Add(remote.OnClientEvent:Connect(function(id)
		ctx.open("ABILITIES")
		local row=self.rows[id]
		if row then
			local offset=row.root.AbsolutePosition.Y-body.AbsolutePosition.Y+body.CanvasPosition.Y
			body.CanvasPosition=Vector2.new(0,math.max(0,offset))
		end
	end)) end
	self.cleanup:Add(ctx.refs.Panels.ABILITIES.Root:GetPropertyChangedSignal("Visible"):Connect(function() self:Render() end))
	self:Render();return self
end
function Controller:Activate(id)
 local ctx=self.ctx
 local state=ctx.net.state
 local item=Catalog.Items[id]
 if not item or not state or not ctx.net.connected or ctx.net:IsBusy() then return end
 local owned=if item.Premium then state.HeroPassOwned else (state.AbilitiesOwned or {})[id]
 if item.Premium and not owned then
  if not state.VerityUnlocked or not self.offer or self.promptOpen then return end
  self.promptOpen=true;self:Render()
  local ok=pcall(function() Market:PromptGamePassPurchase(Players.LocalPlayer,self.passId) end)
  if not ok then self.promptOpen=false;self:Render() end
 else ctx.request(if owned then "EquipAbility" else "BuyAbility",{itemId=id}) end
end
function Controller:Render()
 if self.ctx.renderShop then self.ctx.renderShop() end
	if not self.ctx.refs.Panels.ABILITIES.Root.Visible then return end
	local state=self.ctx.net.state
	local projected={}
	for _,entry in state and state.AbilityCollection or {} do projected[entry.id]=entry end
	for id,row in self.rows do
		local item=Catalog.Items[id]
		local entry=projected[id]
		local owned=state and (if item.Premium then state.HeroPassOwned else (state.AbilitiesOwned or {})[id])
		local equipped=state and (state.AbilitiesEquipped or {})[item.Slot]==id
		if item.MobilityAction and equipped then equipped=(state.AbilitiesEquipped or {}).Mobility==id end
		if entry then owned=entry.owned;equipped=#entry.equippedSlots==#entry.availableSlots end
		row.description.Text=Locale.Text(item.Description)
		row.details.Text=if item.Premium then string.format(Locale.Text("F · Полёт %d с   G · Лазеры %d урона"),item.FlightDuration,item.Damage)
			elseif item.Slot=="Attack" then string.format(Locale.Text("Уровень %d • урон %d • перезарядка %d с"),item.Level,item.Damage,item.Cooldown)
			else string.format(Locale.Text("Уровень %d • перезарядка %d с • кнопка F"),item.Level,item.Cooldown)
		local unlocked=state and state.VerityUnlocked and state.VerityLevel>=item.Level
		local price=if item.Premium then (self.offer and self.offer.PriceInRobux or Config.HeroPassPrice) else item.Cost
		local available=unlocked and (if item.Premium then self.offer~=nil else state.Cash>=price)
		local label=if equipped and owned then "Установлена" elseif owned then "Получена"
			elseif entry and entry.state=="Purchasable" and not entry.blockedReason or available then "Доступна" else "Закрыта"
		row.title.Text=Locale.Text(label).." · "..Locale.Text(item.Name)
		row.title.TextSize=if row.root.AbsoluteSize.X<290 then 12 else 15
		local text=if equipped then Locale.Text("ВЫБРАНО") elseif owned then Locale.Text("ВЫБРАТЬ")
			elseif item.Premium and not self.passId then string.format(Locale.Text("СКОРО • %d R$"),price)
			elseif item.Premium and not self.offer then Locale.Text("ПРОПУСК ВРЕМЕННО НЕДОСТУПЕН")
			elseif not unlocked then string.format(Locale.Text("ОТКРОЕТСЯ НА УРОВНЕ %d"),item.Level)
			elseif item.Premium then string.format(Locale.Text("КУПИТЬ • %d R$"),price)
			else Locale.Text("КУПИТЬ • $")..Locale.Number(price)
		local canAct=if not entry then unlocked and (owned or available) elseif owned then entry.canEquip
			elseif item.Premium then unlocked and self.offer~=nil else entry.canBuy and entry.affordable
		W.SetButton(row.button,text,canAct and not equipped and not self.ctx.net:IsBusy() and self.ctx.net.connected and not self.promptOpen or false,false)
	end
end
function Controller:Destroy() self.dead=true;self.cleanup:Destroy() end
return Controller
