
--!nonstrict
local Players=game:GetService("Players")
local Market=game:GetService("MarketplaceService")
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local MoneyPass={}
MoneyPass.__index=MoneyPass
function MoneyPass.new(ctx)
	local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),refs=ctx.refs.Panels.VERITY},MoneyPass)
	self.cleanup:Add(ctx.net.StateChanged.Event:Connect(function(state)
		local passId=state.MoneyPassId
		if passId~=self.passId then
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
	self.cleanup:Add(self.refs.MoneyPass.Activated:Connect(function() self:Buy() end))
	self.cleanup:Add(Market.PromptGamePassPurchaseFinished:Connect(function(player,passId)
		if player==Players.LocalPlayer and passId==self.passId then self.promptOpen=false;self:Render() end
	end))
	self.cleanup:Add(Locale.Changed.Event:Connect(function() self:Render() end))
	self:Render()
	return self
end
function MoneyPass:Buy()
 local net=self.ctx.net
 local state=net.state
 if not self.offer or not state or state.Premium and not state.Premium.salesEnabled or state.MoneyPassOwned or self.promptOpen or not net.connected then return end
 self.promptOpen=true
 self:Render()
 local ok=pcall(function() Market:PromptGamePassPurchase(Players.LocalPlayer,self.passId) end)
 if not ok then self.promptOpen=false;self:Render() end
end
function MoneyPass:Render()
	local state=self.ctx.net.state
	local owned=state and state.MoneyPassOwned==true
	local text=if owned then Locale.Text("×3 ДЕНЬГИ • АКТИВНО")
		elseif self.promptOpen then Locale.Text("ПОДТВЕРДИ ПОКУПКУ В ROBLOX")
		elseif self.offer then string.format(Locale.Text("×3 ДЕНЬГИ • %d R$"),self.offer.PriceInRobux)
		elseif self.passId then Locale.Text("ПРОПУСК ВРЕМЕННО НЕДОСТУПЕН")
		else Locale.Text("×3 ДЕНЬГИ • СКОРО")
	W.SetButton(self.refs.MoneyPass,text,self.offer~=nil and state~=nil and not owned
		and not self.promptOpen and self.ctx.net.connected and (not state.Premium or state.Premium.salesEnabled),self.promptOpen==true)
 if self.ctx.renderShop then self.ctx.renderShop() end
end
function MoneyPass:Destroy() self.dead=true;self.cleanup:Destroy() end
return MoneyPass
