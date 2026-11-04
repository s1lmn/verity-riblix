--!nonstrict
local Locale = require(script.Parent.Locale)
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local Model=require(script.Parent.UIModel)
local Abilities=require(game:GetService("ReplicatedStorage").Shared.VerityAbilities)
local Verity={}
Verity.__index=Verity

function Verity.new(ctx)
	local self=setmetatable({ctx=ctx,refs=ctx.refs.Panels.VERITY,cleanup=Cleanup.new()},Verity)
	self.cleanup:Add(self.refs.Buy.Activated:Connect(function() ctx.request("UpgradeVerity") end))
	return self
end

function Verity:Render()
	local net=self.ctx.net
	local state=net.state
	local r=self.refs
	if not state then
		W.SetButton(r.Buy,Locale.Text("WAITING FOR SERVER"),false,false)
		return
	end
	local level=state.VerityLevel
	if state.VerityUnlocked then
		local ability=Abilities.Get(level)
		r.Ability.Text=string.format(Locale.Text("Способность: %s\nСкорость %d • сила прыжка %d"),
			Locale.Text(ability.name),ability.speed,ability.jump)
	else
		r.Ability.Text=Locale.Text("Распакуй Verity, чтобы получить способность.")
	end
	local maxed=level==100
	r.Level.Text=if maxed then Locale.Text("MAX LEVEL 100 • GIANT FINAL FORM") else string.format(Locale.Text("VERITY LEVEL %d / 100"),level)
	r.Level.TextSize=if maxed then 18 else 20
	r.Level.Size=UDim2.new(1,-24,0,48)
	r.Income.Text=Locale.Text("INCOME  $")..Locale.Number(state.IncomePerSecond)..Locale.Text(" / sec")..(if maxed then "" else " → $"..Locale.Number(state.NextIncomePerSecond))
	r.Scale.Text=if maxed then Locale.Text("SCALE  15× • final evolution") else string.format(Locale.Text("SCALE  %.3f× → %.3f×"),Model.Scale(level),Model.Scale(level+1))
	local nextHouseMilestone=Model.Milestones[state.HouseTier]
	local nextHouseLevel=nextHouseMilestone and nextHouseMilestone.level
	r.House.Text=if nextHouseLevel then string.format(Locale.Text("Дом %d / 6  •  Следующий этап на уровне Verity %d"),state.HouseTier,nextHouseLevel)
		else Locale.Text("Дом 6 / 6  •  Максимальный этап")
	r.Progress.Size=UDim2.fromScale((level-1)/99,1)
	local nextStage=Model.NextMilestone(level)
	r.Milestone.Text=if nextStage then string.format(Locale.Text("NEXT • LEVEL %d  /  %s\n%s"),nextStage.level,Locale.Text(nextStage.name),Locale.Text(nextStage.reward))
		else Locale.Text("ALL DISCOVERIES UNLOCKED\nCrown, unique idle, layered aura and celebration effects.")
	local busy=net:IsBusy("UpgradeVerity")
	local affordable=not maxed and state.NextVerityUpgradeCost~=nil and state.Cash>=state.NextVerityUpgradeCost
	local text=if maxed then Locale.Text("MAX LEVEL • 15×") elseif not state.VerityUnlocked then Locale.Text("OPEN YOUR DELIVERY BOX FIRST")
		elseif busy then Locale.Text("WAITING FOR CONFIRMATION…") elseif not affordable then Locale.Text("NEED $")..Locale.Number(state.NextVerityUpgradeCost)
		else Locale.Text("UPGRADE • $")..Locale.Number(state.NextVerityUpgradeCost)
	W.SetButton(r.Buy,text,net.connected and state.VerityUnlocked and not maxed and affordable and not busy,busy)
	r.Boost.Visible=false
	local boost=state.Boost
	if type(boost)=="table" and Model.IsFinite(boost.multiplier) and Model.IsFinite(boost.endsAt) then
		local remaining=math.max(0,math.ceil(boost.endsAt-workspace:GetServerTimeNow()))
		r.Boost.Visible=remaining>0
		r.Boost.Text=if remaining>0 then string.format(Locale.Text("ACTIVE BOOST  %.2f× • %ds remaining\n%s"),boost.multiplier,remaining,
			if type(boost.description)=="string" then string.sub(Locale.Text(boost.description),1,100) else Locale.Text("Server-verified earning boost.")) else Locale.Text("No active boost. Free progression remains available.")
	end
end

function Verity:Destroy() self.cleanup:Destroy() end
return Verity
