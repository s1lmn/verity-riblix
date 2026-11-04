--!nonstrict
local Houses = require(game:GetService("ReplicatedStorage").Shared.HouseConfig)
local Locale = require(script.Parent.Locale)
local Model = require(script.Parent.UIModel)
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local Cleanup = require(script.Parent.Cleanup)
local Skin = require(script.Parent.GrowthPanelsSkin)
local Workshop = {}
Workshop.__index = Workshop

function Workshop.new(ctx)
 local cards=Skin.WorkshopCards(ctx.refs.Panels.WORKSHOP,Houses)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),rows=cards.rows,features=cards.features,
  summary=cards.summary,fill=cards.fill,lock=cards.lock},Workshop)
	self.cleanup:Add(self.lock.Activated:Connect(function()
		local state=ctx.net.state
		if state and state.HouseDoorOwned and not ctx.net:IsBusy() then
			ctx.request("HouseDoor",{locked=not state.HouseDoorLocked})
		end
	end))
	return self
end

function Workshop:Render()
	local state=self.ctx.net.state
	for featureId,detail in self.features do
		local feature=Houses.Features[featureId]
		detail.Text=if state and state[feature.Field] then Locale.Text("Куплено")
			else Locale.Text(if featureId=="Door" then "Купить у входа • $" else "Купить у лестницы • $")..Locale.Number(feature.Cost)
	end
	self.lock.Visible=state~=nil and state.HouseDoorOwned==true
	W.SetButton(self.lock,Locale.Text(if state and state.HouseDoorLocked then "Открыть гостям" else "Закрыть для гостей"),
		state~=nil and state.HouseDoorOwned==true and self.ctx.net.connected and not self.ctx.net:IsBusy(),false)
	local total=#Houses.IncomeUpgrades
	local count=state and state.HouseIncomeLevel
	if not Model.IsInteger(count,0,total) then count=0 end
	local step=math.round(Houses.IncomeStep*100)
	self.summary.Text=string.format(Locale.Text("Куплено %d из %d   •   +%d%% дохода"),count,total,count*step)
	self.fill.Size=UDim2.fromScale(count/total,1)
	for index,row in self.rows do
		local unlocked=state and state.VerityUnlocked and state.VerityLevel>=row.upgrade.Level
		local nextPurchase=index==count+1 and unlocked
		row.title.Text=Locale.Text(row.upgrade.Name)
		row.root.BackgroundColor3=if nextPurchase then T.Gold:Lerp(T.Paper,.58)
			elseif index<=count then T.Mint:Lerp(T.Paper,.71) else T.Paper
		local price=Locale.Number(row.upgrade.Cost)
		row.detail.Text=if index<=count then string.format(Locale.Text("Куплено • +%d%% к доходу"),step)
			elseif nextPurchase then string.format(Locale.Text("Следующее • $%s • +%d%%"),price,step)
			else string.format(Locale.Text("Уровень Verity %d • $%s"),row.upgrade.Level,price)
	end
end

function Workshop:Destroy() self.cleanup:Destroy() end
return Workshop
