--!nonstrict
return function(load, check)
	local qa=load("tests/Fixture")(load)
	local owner=qa.join(42)
	owner.Data.VerityUnlocked=true;owner.Data.DeliveryState="Opened"
	local market={owned=false,fail=false}
	function market:UserOwnsGamePassAsync()
		if self.fail then error("Marketplace unavailable") end
		return self.owned
	end
	local pass=load("src/server/MoneyPassService").new(qa.Data,qa.State,qa.Income,market,999)
	check(pass:RefreshAsync(42)=="UNOWNED" and qa.Economy:GetMultiplier(owner)==1)
	qa.advance(1)
	market.owned=true
	check(pass:RefreshAsync(42)=="OWNED")
	check(owner.Data.Cash==5,"Time before ownership must settle at the old rate")
	check(qa.Economy:GetMultiplier(owner)==3 and qa.Economy:GetIncomePerSecond(42)==15)
	qa.advance(1);qa.Income:Settle(42)
	check(owner.Data.Cash==20,"Passive income must receive exactly three times the normal amount")
	check(pass:RefreshAsync(42)=="OWNED" and qa.Economy:GetMultiplier(owner)==3,"Repeated checks must not stack the permanent multiplier")
	qa.Phone:SetOpen(42,true)
	local status,reward=qa.Phone:Swipe(42)
	check(status=="OK" and reward==6,"Cards must receive the permanent multiplier")
	qa.Tasks:Start(42,"PRESS_BUTTON")
	local taskStatus,taskReward=qa.Tasks:Complete(42,"PRESS_BUTTON")
	check(taskStatus=="OK" and taskReward==60,"Task rewards must receive the permanent multiplier")
	local snapshot=qa.State:Snapshot(42)
	check(snapshot.MoneyPassOwned and snapshot.SwipeIncome==6 and snapshot.Tasks.PRESS_BUTTON.reward==60)
	market.fail=true
	check(pass:RefreshAsync(42)=="UNAVAILABLE" and qa.Economy:GetMultiplier(owner)==3,"A transient query failure must preserve a verified entitlement")
	qa.Data:ReleaseAsync(42);local rejoined=qa.Data:LoadAsync(42)
	check(not rejoined.MoneyPassOwned,"Runtime entitlement must be verified again after a new session")
	check(pass:RefreshAsync(42)=="UNAVAILABLE" and qa.Economy:GetMultiplier(rejoined)==1,"Failed ownership query cannot grant paid benefits")
	local f = load("tests/Fixture")(load)
	local p = f.join(1)
	local Boost = load("src/server/BoostService").new(f.Data, f.State, f.Income, f.clock, {[1234] = true})
	check(not Boost:ProcessReceiptAsync(1, "purchase-a", 999), "Unknown product grants nothing")
	check(p.Data.BoostExpiresAt == 0)
	check(Boost:ProcessReceiptAsync(1, "purchase-a", 1234))
	local expiry = p.Data.BoostExpiresAt
	check(expiry == f.clock() + 14400 and p.Data.Receipts["purchase-a"])
	check(Boost:ProcessReceiptAsync(1, "purchase-a", 1234))
	check(p.Data.BoostExpiresAt == expiry, "Duplicate receipt cannot extend boost")
	f.Store.Fail = true
	check(not Boost:ProcessReceiptAsync(1, "purchase-b", 1234))
	local pendingExpiry = p.Data.BoostExpiresAt
	f.Store.Fail = false
	check(Boost:ProcessReceiptAsync(1, "purchase-b", 1234))
	check(p.Data.BoostExpiresAt == pendingExpiry, "Ambiguous save retry cannot grant twice")
	check(f.Data:ReleaseAsync(1))
	local profile = assert(f.Data:LoadAsync(1))
	check(profile.Data.BoostExpiresAt == pendingExpiry and profile.Data.Receipts["purchase-b"], "Entitlement survives rejoin")
	f.State:Attach(1, 1)
	check(Boost:ProcessReceiptAsync(1, "purchase-b", 1234))
	check(profile.Data.BoostExpiresAt == pendingExpiry)
	-- Explicitly renew a simulated live session while the absolute boost time expires.
	f.advance(pendingExpiry - f.clock() + 1)
	profile.LeaseUntil = f.clock() + 180
	check(f.Economy:GetMultiplier(profile) == 1, "No entitlement after expiry")
end
