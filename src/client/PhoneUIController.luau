--!nonstrict
local Locale = require(script.Parent.Locale)
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local Feed=require(script.Parent.FeedController)
local Swipe=require(script.Parent.SwipeInputController)
local Phone={}
Phone.__index=Phone

function Phone.new(ctx)
	local self=setmetatable({ctx=ctx,refs=ctx.refs.Panels.PHONE,cleanup=Cleanup.new(),open=false,lastSwipe=-math.huge,retryAt=0},Phone)
	self.feed=self.cleanup:Add(Feed.new(self.refs.Viewport,ctx.animation,ctx.settings,function() self:Render() end))
	self.input=self.cleanup:Add(Swipe.new(self.refs.Viewport,function() return self:Swipe() end,function() return self.open end))
	self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
		if result.action=="Swipe" and result.success then
			self.feed:Reveal(result.cardId,result.reward,self.open,function(multiplier)
				if result.reward and result.reward>0 then ctx.rewards:Add(result.reward) end
				ctx.sound:Play(if multiplier==16 then "Milestone" elseif multiplier==8 then "LevelUp" else "Reward")
			end)
			self:Render()
		end
	end))
	self.cleanup:Add(self.refs.Next.Activated:Connect(function() self.input.Emit() end))
	self.cleanup:Add(self.refs.Power.Activated:Connect(function() self:Upgrade("UpgradeSwipe") end))
	self.cleanup:Add(self.refs.Grow.Activated:Connect(function() self:Upgrade("UpgradeVerity") end))
	return self
end

function Phone:SetOpen(open)
	self.open=open
	if not open then self.feed:FinishReveal() end
	self.input:Cancel()
	self:ReconcileSession()
end

function Phone:ReconcileSession()
	local net=self.ctx.net
	if not net.state or net:IsBusy("PhoneSession") or os.clock()<self.retryAt then return end
	if net.state.PhoneSessionOpen~=self.open then
		self.retryAt=os.clock()+2
		net:Request("PhoneSession",{open=self.open})
	end
end

function Phone:Swipe()
	local ctx=self.ctx
	local state=ctx.net.state
	if not self.open or self.feed.busy or not state or not state.PhoneSessionOpen
		or ctx.net:IsBusy("PhoneSession") or ctx.net:IsBusy("Swipe") or os.clock()-self.lastSwipe<0.75 then return false end
	local id=ctx.request("Swipe")
	if not id then return false end
	self.lastSwipe=os.clock()
	ctx.sound:Play("SwipeWhoosh")
	self:Render()
	return true
end

-- Recheck the confirmed quote at activation; button appearance is never authority.
function Phone:Upgrade(action)
	local net=self.ctx.net
	local state=net.state
	if not self.open or not state or not net.connected or net:IsBusy() then return nil end
	local grow=action=="UpgradeVerity"
	local cost=if grow then state.NextVerityUpgradeCost else state.NextSwipeUpgradeCost
	local maxed=if grow then state.VerityLevel>=100 else state.SwipeUpgradeLevel>=40
	if not state.VerityUnlocked or maxed or not cost or state.Cash<cost then return nil end
	return self.ctx.request(action)
end

function Phone:Render()
	local net=self.ctx.net
	local state=net.state
	local ready=state and state.PhoneSessionOpen and self.open and not net:IsBusy("PhoneSession")
	local busy=net:IsBusy("Swipe")
	self.refs.Reward.Text=if state then "$"..Locale.Number(state.SwipeIncome)..Locale.Text(" за обычную карту") else Locale.Text("$— за обычную карту")
	self.refs.Session.Text=if not state then Locale.Text("Загружаем прогресс…") elseif not ready then Locale.Text("Подключаем телефон…") elseif busy then Locale.Text("Получаем награду…") else Locale.Text("Редкие карты приносят больше")
	for _,entry in {{self.refs.Power,"UpgradeSwipe","СИЛА СВАЙПА",40,"SwipeUpgradeLevel","NextSwipeUpgradeCost"},
		{self.refs.Grow,"UpgradeVerity","ВЫРАСТИТЬ VERITY",100,"VerityLevel","NextVerityUpgradeCost"}} do
		local maxed=state and state[entry[5]] >= entry[4]
		local cost=state and state[entry[6]]
		local pending=net:IsBusy(entry[2])
		local affordable=cost and state.Cash>=cost
		local text=Locale.Text(entry[3]).."\n"..(if not state then Locale.Text("Загрузка…") elseif not state.VerityUnlocked then Locale.Text("Сначала открой коробку")
			elseif maxed then Locale.Text("Максимальный уровень") elseif pending then Locale.Text("Улучшаем…")
			elseif not affordable then Locale.Text("Нужно $")..Locale.Number(cost) else "$"..Locale.Number(cost)..Locale.Text("  •  улучшить"))
		W.SetButton(entry[1],text,net.connected and state~=nil and state.VerityUnlocked and not maxed and affordable and not net:IsBusy(),pending)
	end
	self.refs.PowerHint.Text=if state then Locale.Text("Базовая награда $")..Locale.Number(state.SwipeIncome)..(if state.NextSwipeIncome then " → $"..Locale.Number(state.NextSwipeIncome) else Locale.Text(" • MAX")) else Locale.Text("Больше дохода за каждое движение")
	local revealing=self.feed.busy
	W.SetButton(self.refs.Next,if busy or revealing then Locale.Text("ПОДОЖДИ…") else Locale.Text("ЛИСТАТЬ ↑"),ready and not busy and not revealing,busy or revealing)
end

function Phone:Destroy() self.cleanup:Destroy() end
return Phone
