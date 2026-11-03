--!nonstrict
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local Model=require(script.Parent.UIModel)
local Feed=require(script.Parent.FeedController)
local Swipe=require(script.Parent.SwipeInputController)
local Phone={}
Phone.__index=Phone

function Phone.new(ctx)
	local self=setmetatable({ctx=ctx,refs=ctx.refs.Panels.PHONE,cleanup=Cleanup.new(),open=false,lastSwipe=-math.huge,retryAt=0},Phone)
	self.feed=self.cleanup:Add(Feed.new(self.refs.Viewport,ctx.animation,ctx.settings))
	self.input=self.cleanup:Add(Swipe.new(self.refs.Viewport,function() return self:Swipe() end,function() return self.open end))
	self.cleanup:Add(self.refs.Next.Activated:Connect(function() self.input.Emit() end))
	self.cleanup:Add(self.refs.Power.Activated:Connect(function() ctx.open("UPGRADES") end))
	return self
end

function Phone:SetOpen(open)
	self.open=open
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
	self.feed:Next()
	ctx.sound:Play("SwipeWhoosh")
	self:Render()
	return true
end

function Phone:Render()
	local net=self.ctx.net
	local state=net.state
	local ready=state and state.PhoneSessionOpen and self.open and not net:IsBusy("PhoneSession")
	local busy=net:IsBusy("Swipe")
	self.refs.Reward.Text=if state then "$"..Model.Format(state.SwipeIncome).." per swipe" else "$— per swipe"
	self.refs.Session.Text=if not state then "Waiting for server session…" elseif not ready then "Phone session is closed / connecting…" elseif busy then "Waiting for confirmed reward…" else "Touch ↑  •  Drag ↑  •  Wheel ↑  •  Next"
	W.SetButton(self.refs.Next,if busy then "ПОДОЖДИ…" else "ЛИСТАТЬ ↑",ready and not busy,busy)
end

function Phone:Destroy() self.cleanup:Destroy() end
return Phone
