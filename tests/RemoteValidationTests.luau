--!nonstrict
return function(load, check)
	local make = load("tests/Fixture")
	local f = make(load)
	local p = f.join(1)
	p.Data.VerityUnlocked = true; p.Data.DeliveryState = "Opened"
	check(f.Phone:SetOpen(1, true) == "OK")
	check(f.Remote:Handle(1, "RequestSwipe", {operationId = "1"}).reward == 2)
	check(p.Data.Cash == 2)
	local repeated = f.Remote:Handle(1, "RequestSwipe", {operationId = "1"})
	check(repeated.replayed and p.Data.Cash == 2, "Duplicate pays once")
	check(f.Remote:Handle(1, "RequestUpgradeVerity", {operationId = "1"}).status == "OPERATION_CONFLICT")
	check(f.Remote:Handle(1, "RequestSwipe", {operationId = "2"}).status == "COOLDOWN")
	check(p.Data.Cash == 2)
	f.advance(0.75)
	check(f.Remote:Handle(1, "RequestSwipe", {operationId = "3"}).reward == 2)
	local forged = f.Remote:Handle(1, "RequestSwipe", {operationId = "4", reward = 1e9})
	check(forged.status == "UNEXPECTED_FIELD")
	check(forged.operationId == "4", "Rejected payload retains a valid ID for client correlation")
	check(f.Remote:Handle(1, "RequestSwipe", {operationId = "05"}).status == "INVALID_OPERATION_ID")
	check(f.Remote:Handle(1, "RequestSwipe", {operationId = string.rep("x", 100)}).status == "INVALID_OPERATION_ID")
	f.advance(121)
	check(f.Remote:Handle(1, "RequestSwipe", {operationId = "1"}).status == "STALE_OPERATION",
		"Old IDs cannot replay after cache expires")
	check(p.Data.Cash == 4)
	local paid = 0
	for index = 6, 1000 do
		local result = f.Remote:Handle(1, "RequestSwipe", {operationId = tostring(index)})
		if result and result.status == "OK" then paid += 1 end
	end
	check(paid == 1, "Flood pays no more than cooldown permits")
	-- Failed transactions are deduplicated too.
	local g = make(load)
	local q = g.join(2)
	q.Data.VerityUnlocked = true; q.Data.DeliveryState = "Opened"
	check(g.Remote:Handle(2, "RequestUpgradeVerity", {operationId = "1"}).status == "INSUFFICIENT_CASH")
	g.Economy:AddCash(2, 1000)
	check(g.Remote:Handle(2, "RequestUpgradeVerity", {operationId = "1"}).replayed)
	check(q.Data.VerityLevel == 1)
	check(g.Remote:Handle(2, "RequestUpgradeVerity", {operationId = "2"}).status == "OK")
	check(q.Data.VerityLevel == 2)
end
