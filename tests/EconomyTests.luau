--!nonstrict
return function(load, check)
	local make = load("tests/Fixture")
	local f = make(load)
	local p = f.join(1)
	f.advance(10); f.Income:Tick(); check(p.Data.Cash == 0, "No income before box")
	f.Delivery:Begin(1); check(f.Delivery:Open(1) == "NOT_DELIVERED")
	f.advance(2); f.Delivery:Tick()
	f.setNear(false); check(f.Delivery:Open(1) == "TOO_FAR")
	f.setNear(true); check(f.Delivery:Open(1) == "OK")
	check(f.Delivery:Open(1) == "ALREADY_OPENED")
	f.advance(10); f.Income:Tick(); check(p.Data.Cash == 50)
	f.Income:Tick(); check(p.Data.Cash == 50, "No duplicate tick payments")
	check(f.Upgrade:UpgradeVerity(1) == "OK")
	check(p.Data.VerityLevel == 2)
	local levelEvents = 0
	for _, event in f.Events do if event.type == "VerityLevelChanged" then levelEvents += 1 end end
	check(levelEvents == 1, "One event per purchase")
	check(not f.Economy:AddCash(1, 0/0))
	check(not f.Economy:AddCash(1, math.huge))
	check(not f.Economy:TrySpendCash(1, -10))
	local cash = p.Data.Cash
	check(not f.Economy:TrySpendCash(1, cash + 1) and p.Data.Cash == cash)
	f.Economy:AddCash(1, 1e14)
	p.Data.VerityLevel = 99
	check(f.Upgrade:UpgradeVerity(1) == "OK" and p.Data.VerityLevel == 100)
	check(f.Upgrade:UpgradeVerity(1) == "MAX_LEVEL")
	local last = f.Events[#f.Events - 2]
	check(last.type == "VerityLevelChanged" and last.newScale == 5 and last.oldScale < 5)
	check(f.Events[#f.Events].purchaseEventId == last.eventId)
	p.Data.SwipeUpgradeLevel = 40
	check(f.Upgrade:UpgradeSwipe(1) == "MAX_LEVEL")
	-- Split passive earnings exactly at boost expiry, including a delayed tick.
	local g = make(load)
	local q = g.join(2)
	q.Data.VerityUnlocked = true; q.Data.DeliveryState = "Opened"; q.Data.BoostExpiresAt = g.clock() + 5
	g.advance(10); g.Income:Tick()
	local multiplier = load("src/shared/EconomyConfig").Boost.Multiplier
	check(math.abs(q.Data.Cash - (25 * multiplier + 25)) < 1e-6, "Expiry settlement")
	local h = make(load)
	local r = h.join(3)
	r.Data.VerityUnlocked = true; r.Data.DeliveryState = "Opened"
	h.advance(10)
	check(h.Upgrade:UpgradeVerity(3) == "OK")
	check(r.Data.Cash == 50 - load("src/shared/EconomyConfig").LevelCost[1], "Settle old level before upgrade")
end
