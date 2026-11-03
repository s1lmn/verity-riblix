--!nonstrict
return function(load, check)
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
