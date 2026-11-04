--!nonstrict
return function(load, check)
	local make = load("tests/Fixture")
	local drops = load("src/shared/FeedDrops")
	local total, previousReward = 0, 0
	for cardId = 1, 40 do
		local tier, chance = drops.Get(cardId)
		check(tier ~= nil and chance > 0, "Every card has a rarity and a chance")
		total += chance
	end
	check(math.abs(total - 100) < 0.001)
	for _, roll in {1, 59, 86, 97, 100} do
		local card, multiplier = drops.Roll(function(_, maximum) return if maximum == 100 then roll else maximum end)
		check(drops.Get(card).multiplier == multiplier and multiplier > previousReward)
		previousReward = multiplier
	end
	local f = make(load)
	local p = f.join(1)
	p.Data.VerityUnlocked = true; p.Data.DeliveryState = "Opened"
	check(f.Phone:SetOpen(1, true) == "OK")
	local first = f.Remote:Handle(1, "RequestSwipe", {operationId = "1"})
	check(first.reward == 2 and first.cardId == 1)
	check(p.Data.Cash == 2)
	local repeated = f.Remote:Handle(1, "RequestSwipe", {operationId = "1"})
	check(repeated.replayed and repeated.cardId == first.cardId and repeated.reward == first.reward and p.Data.Cash == 2, "Duplicate pays once")
	check(f.Remote:Handle(1, "RequestUpgradeVerity", {operationId = "1"}).status == "OPERATION_CONFLICT")
	check(f.Remote:Handle(1, "RequestSwipe", {operationId = "2"}).status == "COOLDOWN")
	check(p.Data.Cash == 2)
	f.advance(0.75)
	check(f.Remote:Handle(1, "RequestSwipe", {operationId = "3"}).reward == 2)
	local forged = f.Remote:Handle(1, "RequestSwipe", {operationId = "4", cardId = 40})
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
	f.Phone.randomInteger = function(_, maximum) return maximum end
	f.advance(0.75)
	local rare = f.Remote:Handle(1, "RequestSwipe", {operationId = "1001"})
	check(rare.cardId == 40 and rare.reward == 32)
	f.advance(0.75)
	p.Data.SwipeUpgradeLevel = 2
	local improved = f.Remote:Handle(1, "RequestSwipe", {operationId = "1002"})
	check(improved.cardId == 40 and improved.reward > rare.reward)
	check(improved.reward == f.Economy:GetSwipeIncome(1) * 16)
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
