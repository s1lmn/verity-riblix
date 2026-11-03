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
	local selection = load("src/server/PlotService").new(16, 16, function() return true end)
	check(selection:Assign(101, 7) == 7, "Player claims the requested free plot")
	local _, taken = selection:Assign(102, 7)
	check(taken == "PLOT_TAKEN" and selection.owners[102] == nil, "Occupied plot rejects another player")
	local _, changed = selection:Assign(101, 8)
	check(changed == "ALREADY_CLAIMED" and selection.owners[101] == 7, "Existing owner cannot switch plots")
	local _, invalid = selection:Assign(102, 17)
	check(invalid == "INVALID_PLOT", "Out of range choice is rejected")
	check(selection:Release(101) == 7 and selection:Assign(102, 7) == 7, "Leaving frees the plot for someone else")
	local larger = load("src/server/PlotService").new(24, 24, function() return true end)
	for id = 1, 24 do check(larger:Assign(id) == id) end
	check(larger:GetLayout(24).Z > larger:GetLayout(16).Z)
	local previous = larger:GetLayout(1)
	for id = 3, 23, 2 do
		local current = larger:GetLayout(id)
		check(current.Z - previous.Z >= current.Depth, "Reserved plots do not overlap")
		previous = current
	end
end
