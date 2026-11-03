--!nonstrict
return function(load, check)
	local f = load("tests/Fixture")(load)
	local p = f.join(1)
	p.Data.VerityUnlocked = true; p.Data.DeliveryState = "Opened"
	check(f.Tasks:Start(1, "PRESS_BUTTON") == "OK")
	f.setNear(false); check(f.Tasks:Complete(1, "PRESS_BUTTON") == "TOO_FAR")
	f.setNear(true); check(f.Tasks:Complete(1, "PRESS_BUTTON") == "OK")
	check(p.Data.Cash == 20)
	check(f.Tasks:Complete(1, "PRESS_BUTTON") == "NOT_ACTIVE")
	check(f.Tasks:Start(1, "PRESS_BUTTON") == "COOLDOWN")
	check(f.Tasks:Start(1, "STAND_ON_PLATFORM") == "OK")
	f.Tasks:Tick(); f.advance(0.9)
	check(f.Tasks:Complete(1, "STAND_ON_PLATFORM") == "HOLD_REQUIRED")
	f.setNear(false); f.Tasks:Tick(); f.setNear(true); f.Tasks:Tick()
	f.advance(0.9); check(f.Tasks:Complete(1, "STAND_ON_PLATFORM") == "HOLD_REQUIRED")
	f.advance(0.11); f.Tasks:Tick(); check(p.Data.Cash == 45)
	f.Tasks:Tick(); check(p.Data.Cash == 45)
	check(f.Tasks:Start(1, "REACH_POINT") == "OK")
	f.Tasks:OnDeath(1); check(f.Tasks:Complete(1, "REACH_POINT") == "NOT_ACTIVE")
	check(f.Plots:Assign(1) == 1)
	for id = 2, 16 do check(f.Plots:Assign(id) == id) end
	check(f.Plots:Assign(17) == nil)
	check(f.Plots:Release(8) == 8 and f.Plots:Assign(17) == 8)
	check(not f.Plots:IsNear(100, "DeliveryPoint"))
	local larger = load("src/server/PlotService").new(24, 24, function() return true end)
	for id = 1, 24 do check(larger:Assign(id) == id) end
	check(larger:GetLayout(24).X > larger:GetLayout(16).X)
	local previous = larger:GetLayout(1)
	for id = 3, 23, 2 do
		local current = larger:GetLayout(id)
		check(current.X - previous.X >= current.Width, "Reserved plots do not overlap")
		previous = current
	end
end
