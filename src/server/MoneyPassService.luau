
--!nonstrict
local Config=require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Pass={}
Pass.__index=Pass
function Pass.new(data,state,income,market,passId)
	return setmetatable({data=data,state=state,income=income,market=market,passId=passId or Config.MoneyPassId},Pass)
end
function Pass:RefreshAsync(userId)
 if self.premium then return self.premium:RefreshAsync(userId,"money_x3",false) end
	if not self.passId then return "NOT_CONFIGURED" end
	local profile=self.data:Get(userId)
	if not profile then return "NOT_READY" end
	local ok,owned=pcall(function() return self.market:UserOwnsGamePassAsync(userId,self.passId) end)
	if self.data:Get(userId)~=profile then return "NOT_READY" end
	if not ok then return "UNAVAILABLE" end
	-- Only Roblox ownership can enable the multiplier. Never trust client claims.
	if owned and not profile.MoneyPassOwned then
		self.income:Settle(userId)
		profile.MoneyPassOwned=true
		self.data:Touch(profile)
		self.state:Publish(userId,true)
	end
	return if owned then "OWNED" else "UNOWNED"
end
return Pass
