--!nonstrict
local Houses = require(game:GetService("ReplicatedStorage").Shared.HouseConfig)
local Locale = require(script.Parent.Locale)
local Model = require(script.Parent.UIModel)
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local Workshop = {}
Workshop.__index = Workshop

function Workshop.new(ctx)
	local body = ctx.refs.Panels.WORKSHOP.Body
	local self = setmetatable({ctx=ctx, rows={}}, Workshop)
	local summary = W.Block(body, "WorkshopSummary", 62, T.Mint:Lerp(T.Paper,.64))
	summary.LayoutOrder = 0
	self.summary = W.Text(summary,"Progress","",15,true)
	local track = W.Round(W.Frame(summary,"Track",UDim2.new(1,0,0,8),T.Paper),4)
	track.Position = UDim2.fromOffset(0,29)
	self.fill = W.Round(W.Frame(track,"Fill",UDim2.fromScale(0,1),T.Mint),4)
	for index, upgrade in Houses.IncomeUpgrades do
		local row = W.Block(body,"Upgrade"..index,64,T.Paper)
		row.LayoutOrder = index
		local title = W.Text(row,"Title","",14,true)
		title.Size = UDim2.new(1,0,0,20)
		local detail = W.Text(row,"Detail","",11,false,T.Muted)
		detail.Position,detail.Size = UDim2.fromOffset(0,22),UDim2.new(1,0,0,18)
		self.rows[index]={root=row,title=title,detail=detail,upgrade=upgrade}
	end
	return self
end

function Workshop:Render()
	local state=self.ctx.net.state
	local total=#Houses.IncomeUpgrades
	local count=state and state.HouseIncomeLevel
	if not Model.IsInteger(count,0,total) then count=0 end
	local step=math.round(Houses.IncomeStep*100)
	self.summary.Text=string.format(Locale.Text("Куплено %d из %d   •   +%d%% дохода"),count,total,count*step)
	self.fill.Size=UDim2.fromScale(count/total,1)
	for index,row in self.rows do
		local unlocked=state and state.VerityUnlocked and state.VerityLevel>=row.upgrade.Level
		local nextPurchase=index==count+1 and unlocked
		row.title.Text=string.format("%02d  %s",index,Locale.Text(row.upgrade.Name))
		row.root.BackgroundColor3=if nextPurchase then T.Gold:Lerp(T.Paper,.58)
			elseif index<=count then T.Mint:Lerp(T.Paper,.71) else T.Paper
		local price=Locale.Number(row.upgrade.Cost)
		row.detail.Text=if index<=count then string.format(Locale.Text("Куплено • +%d%% к доходу"),step)
			elseif nextPurchase then string.format(Locale.Text("Следующее • $%s • +%d%%"),price,step)
			else string.format(Locale.Text("Уровень Verity %d • $%s"),row.upgrade.Level,price)
	end
end

return Workshop
