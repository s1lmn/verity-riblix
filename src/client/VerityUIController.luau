--!nonstrict
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local Model=require(script.Parent.UIModel)
local Verity={}
Verity.__index=Verity

function Verity.new(ctx)
	local self=setmetatable({ctx=ctx,refs=ctx.refs.Panels.VERITY,cleanup=Cleanup.new()},Verity)
	self.cleanup:Add(self.refs.Buy.Activated:Connect(function() ctx.request("UpgradeVerity") end))
	self.cleanup:Add(ctx.refs.Panels.UPGRADES.Buy.Activated:Connect(function() ctx.request("UpgradeSwipe") end))
	return self
end

function Verity:Render()
	local net=self.ctx.net
	local state=net.state
	local r=self.refs
	local power=self.ctx.refs.Panels.UPGRADES
	if not state then
		W.SetButton(r.Buy,"WAITING FOR SERVER",false,false)
		W.SetButton(power.Buy,"WAITING FOR SERVER",false,false)
		return
	end
	local level=state.VerityLevel
	local maxed=level==100
	r.Level.Text=if maxed then "MAX LEVEL 100 • GIANT FINAL FORM" else string.format("VERITY LEVEL %d / 100",level)
	r.Level.TextSize=if maxed then 18 else 22
	r.Level.Size=UDim2.new(1,-4,0,if maxed then 48 else 34)
	r.Income.Text="INCOME  $"..Model.Format(state.IncomePerSecond).." / sec"..(if maxed then "" else " → $"..Model.Format(state.NextIncomePerSecond))
	r.Scale.Text=if maxed then "SCALE  15× • final evolution" else string.format("SCALE  %.3f× → %.3f×",Model.Scale(level),Model.Scale(level+1))
	local nextHouseMilestone=Model.Milestones[state.HouseTier]
	local nextHouseLevel=nextHouseMilestone and nextHouseMilestone.level
	r.House.Text=if nextHouseLevel then string.format("Дом %d / 6  •  Следующий этап на уровне Verity %d",state.HouseTier,nextHouseLevel)
		else "Дом 6 / 6  •  Максимальный этап"
	r.Progress.Size=UDim2.fromScale((level-1)/99,1)
	local nextStage=Model.NextMilestone(level)
	r.Milestone.Text=if nextStage then string.format("NEXT • LEVEL %d  /  %s\n%s",nextStage.level,nextStage.name,nextStage.reward)
		else "ALL DISCOVERIES UNLOCKED\nCrown, unique idle, layered aura and celebration effects."
	local busy=net:IsBusy("UpgradeVerity")
	local affordable=not maxed and state.NextVerityUpgradeCost~=nil and state.Cash>=state.NextVerityUpgradeCost
	local text=if maxed then "MAX LEVEL • 15×" elseif not state.VerityUnlocked then "OPEN YOUR DELIVERY BOX FIRST"
		elseif busy then "WAITING FOR CONFIRMATION…" elseif not affordable then "NEED $"..Model.Format(state.NextVerityUpgradeCost)
		else "UPGRADE • $"..Model.Format(state.NextVerityUpgradeCost)
	W.SetButton(r.Buy,text,net.connected and state.VerityUnlocked and not maxed and affordable and not busy,busy)
	power.Level.Text=string.format("SWIPE POWER %d / 40",state.SwipeUpgradeLevel)
	local swipeMax=state.SwipeUpgradeLevel==40
	power.Income.Text="PER SWIPE  $"..Model.Format(state.SwipeIncome)..(if swipeMax then " • MAXED" else " → $"..Model.Format(state.NextSwipeIncome))
	power.Cost.Text=if swipeMax then "All Swipe Power upgrades unlocked." else "NEXT UPGRADE  $"..Model.Format(state.NextSwipeUpgradeCost)
	local swipeBusy=net:IsBusy("UpgradeSwipe")
	local swipeAffordable=not swipeMax and state.NextSwipeUpgradeCost~=nil and state.Cash>=state.NextSwipeUpgradeCost
	W.SetButton(power.Buy,if swipeMax then "MAXED" elseif swipeBusy then "WAITING FOR CONFIRMATION…"
		elseif not swipeAffordable then "NEED $"..Model.Format(state.NextSwipeUpgradeCost) else "UPGRADE SWIPE • $"..Model.Format(state.NextSwipeUpgradeCost),
		net.connected and swipeAffordable and not swipeBusy,swipeBusy)
	local boost=state.Boost
	if type(boost)=="table" and Model.IsFinite(boost.multiplier) and Model.IsFinite(boost.endsAt) then
		local remaining=math.max(0,math.ceil(boost.endsAt-workspace:GetServerTimeNow()))
		power.Boost.Text=if remaining>0 then string.format("ACTIVE BOOST  %.2f× • %ds remaining\n%s",boost.multiplier,remaining,
			if type(boost.description)=="string" then string.sub(boost.description,1,100) else "Server-verified earning boost.") else "No active boost. Free progression remains available."
	else power.Boost.Text="No active boost. All levels are available through free progression." end
end

function Verity:Destroy() self.cleanup:Destroy() end
return Verity
