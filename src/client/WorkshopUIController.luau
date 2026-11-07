--!nonstrict
local Houses = require(game:GetService("ReplicatedStorage").Shared.HouseConfig)
local Locale = require(script.Parent.Locale)
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local Cleanup = require(script.Parent.Cleanup)
local Skin = require(script.Parent.GrowthPanelsSkin)
local Workshop = {}
Workshop.__index = Workshop

function Workshop.new(ctx)
 local cards=Skin.WorkshopCards(ctx.refs.Panels.WORKSHOP,Houses)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),rows=cards.rows,features=cards.features,
  summary=cards.summary,income=cards.income,fill=cards.fill,lock=cards.lock,style=cards.style},Workshop)
 self.cleanup:Add(self.style.Activated:Connect(function() ctx.homeRouteRequested=true;ctx.close() end))
 self.cleanup:Add(ctx.net.Notification.Event:Connect(function(payload)
  if payload.source=="HomeStyle" and (payload.code=="HOME_STYLE_APPLIED" or payload.code=="HOME_DECOR_PURCHASED") then ctx.homeRouteRequested=nil end
 end))
 for _,row in self.rows do
  self.cleanup:Add(row.buy.Activated:Connect(function() ctx.request("UpgradeHouse") end))
 end
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
 W.SetButton(self.style,Locale.Text("СТИЛЬ И ДЕКОР ДОМА →"),state~=nil and state.VerityUnlocked and count>=1 and self.ctx.net.connected,false)
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
		row.title.Text=Locale.Text(row.upgrade.Name)
		row.root.BackgroundColor3=if nextPurchase then T.Gold:Lerp(T.Paper,.58) elseif index<=count then T.Mint:Lerp(T.Paper,.71) else T.Paper
		row.description.Text=Locale.Text(row.upgrade.Build)..string.format(Locale.Text("\n+%d%% к базовому доходу"),bonus)
		local text=if index<=count then Locale.Text("ПОСТРОЕНО") elseif not nextPurchase then Locale.Text("СНАЧАЛА ПРЕДЫДУЩИЙ ЭТАП")
			elseif not unlocked then string.format(Locale.Text("НУЖЕН УРОВЕНЬ VERITY %d"),row.upgrade.Level)
			else Locale.Text("СТРОИТЬ В ДОМЕ • $")..Locale.Number(row.upgrade.Cost)
		W.SetButton(row.buy,text,nextPurchase and unlocked and state.Cash>=row.upgrade.Cost and self.ctx.net.connected and not self.ctx.net:IsBusy() or false,false)
	end
end
function Workshop:Destroy() self.cleanup:Destroy() end
return Workshop
