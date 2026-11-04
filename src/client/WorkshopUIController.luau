--!nonstrict
local Houses=require(game:GetService("ReplicatedStorage").Shared.HouseConfig)
local Locale=require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Cleanup=require(script.Parent.Cleanup)
local Workshop={};Workshop.__index=Workshop
function Workshop.new(ctx)
	local body=ctx.refs.Panels.WORKSHOP.Body
	local self=setmetatable({ctx=ctx,rows={},cleanup=Cleanup.new(),features={}},Workshop)
	local summary=W.Block(body,"WorkshopSummary",88,T.Mint:Lerp(T.Paper,.64));summary.LayoutOrder=-4
	self.summary=W.Text(summary,"Progress","",15,true);self.summary.Size=UDim2.new(1,0,0,27)
	self.income=W.Text(summary,"Income","",12,false,T.Purple);self.income.Position=UDim2.fromOffset(0,29);self.income.Size=UDim2.new(1,0,0,22)
	local track=W.Round(W.Frame(summary,"Track",UDim2.new(1,0,0,8),T.Paper),4);track.Position=UDim2.fromOffset(0,55)
	self.fill=W.Round(W.Frame(track,"Fill",UDim2.fromScale(0,1),T.Mint),4)
	for index,upgrade in Houses.IncomeUpgrades do
		local color=Color3.fromHex(upgrade.Color)
		local row=W.Block(body,"Upgrade"..index,140,color:Lerp(T.Paper,.82));row.LayoutOrder=index
		local title=W.Text(row,"Title","",15,true);title.Size=UDim2.new(1,0,0,23)
		local description=W.Text(row,"Description","",12,false,T.Muted);description.Position=UDim2.fromOffset(0,27);description.Size=UDim2.new(1,0,0,40)
		local buy=W.Button(row,"Build","",color);buy.AnchorPoint=Vector2.new(0,1);buy.Position=UDim2.new(0,0,1,0);buy.Size=UDim2.new(1,0,0,38);buy.TextSize=12
		self.rows[index]={root=row,title=title,description=description,buy=buy,upgrade=upgrade}
		self.cleanup:Add(buy.Activated:Connect(function() ctx.request("UpgradeHouse") end))
	end
	for index,featureId in {"Door","SecondFloor"} do
		local row=W.Block(body,featureId,78,T.Purple:Lerp(T.Paper,.82));row.LayoutOrder=index-4
		W.Text(row,"Name",Houses.Features[featureId].Name,15,true)
		local detail=W.Text(row,"Details","",12,false,T.Muted);detail.Position=UDim2.fromOffset(0,28);detail.Size=UDim2.new(1,0,0,34)
		self.features[featureId]=detail
	end
	self.lock=W.Button(body,"HouseDoorLock","Закрыть для гостей",T.Mint);self.lock.LayoutOrder=0
	self.cleanup:Add(self.lock.Activated:Connect(function()
		local state=ctx.net.state
		if state and state.HouseDoorOwned and not ctx.net:IsBusy() then ctx.request("HouseDoor",{locked=not state.HouseDoorLocked}) end
	end))
	self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
		if result.success and result.action=="UpgradeHouse" then ctx.sound:Play("Success");ctx.notifications:Show("Дом построен! Доход вырос.") end
	end))
	return self
end
function Workshop:Render()
	local state=self.ctx.net.state;local total=#Houses.IncomeUpgrades
	local count=state and state.HouseIncomeLevel or 0
	local multiplier=Houses.getIncomeMultiplier(count,state and state.HouseDoorOwned,state and state.HouseSecondFloorOwned)
	self.summary.Text=string.format(Locale.Text("Стройка %d / %d • доход дома ×%.2f"),count,total,multiplier)
	self.income.Text=if state then Locale.Text("Пассивный доход: $")..Locale.Number(state.IncomePerSecond)..Locale.Text(" / sec") else Locale.Text("Строй и повышай заработок.")
	self.fill.Size=UDim2.fromScale(count/total,1)
	for featureId,detail in self.features do
		local feature=Houses.Features[featureId]
		local text=if state and state[feature.Field] then Locale.Text("Куплено")
			else Locale.Text(if featureId=="Door" then "Купить у входа • $" else "Купить у лестницы • $")..Locale.Number(feature.Cost)
		detail.Text=text..string.format(Locale.Text(" • +%d%% дохода"),math.round(feature.Bonus*100))
	end
	self.lock.Visible=state~=nil and state.HouseDoorOwned==true
	W.SetButton(self.lock,Locale.Text(if state and state.HouseDoorLocked then "Открыть гостям" else "Закрыть для гостей"),state~=nil and state.HouseDoorOwned==true and self.ctx.net.connected and not self.ctx.net:IsBusy(),false)
	for index,row in self.rows do
		local bonus=math.round(row.upgrade.Bonus*100)
		local unlocked=state and state.VerityUnlocked and state.VerityLevel>=row.upgrade.Level
		local nextPurchase=index==count+1
		row.title.Text=string.format("%02d  %s",index,Locale.Text(row.upgrade.Name))
		row.description.Text=Locale.Text(row.upgrade.Build)..string.format(Locale.Text("\n+%d%% к базовому доходу"),bonus)
		local text=if index<=count then Locale.Text("ПОСТРОЕНО") elseif not nextPurchase then Locale.Text("СНАЧАЛА ПРЕДЫДУЩИЙ ЭТАП")
			elseif not unlocked then string.format(Locale.Text("НУЖЕН УРОВЕНЬ VERITY %d"),row.upgrade.Level)
			else Locale.Text("СТРОИТЬ В ДОМЕ • $")..Locale.Number(row.upgrade.Cost)
		W.SetButton(row.buy,text,nextPurchase and unlocked and state.Cash>=row.upgrade.Cost and self.ctx.net.connected and not self.ctx.net:IsBusy() or false,false)
	end
end
function Workshop:Destroy() self.cleanup:Destroy() end
return Workshop
