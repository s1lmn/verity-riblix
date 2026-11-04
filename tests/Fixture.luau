--!nonstrict
return function(load)
	local now = 1000
	local records, events, results = {}, {}, {}
	local store = {Fail = false}
	function store:UpdateAsync(key, transform)
		if self.Fail then error("Simulated DataStore outage") end
		local value = transform(records[key])
		if value ~= nil then records[key] = value end
		return value
	end
	local function clock() return now end
	local Data = load("src/server/DataService").new(store, clock, function(dt) now += dt end, "test-a")
	local State = load("src/server/PlayerStateService").new(Data, clock)
	local Economy = load("src/server/EconomyService").new(Data, clock)
	local Income = load("src/server/IncomeService").new(Data, State, Economy, clock)
	local counter = 0
	local Verity = load("src/server/VerityService").new(Data, State, function() counter += 1; return tostring(counter) end,
		function(event) table.insert(events, event) end)
	local near, alive = true, true
	local Plots = load("src/server/PlotService").new(16, 16, function() return near and alive end)
	local Delivery = load("src/server/DeliveryService").new(Data, State, Plots, Income, Verity, clock, 2)
	local Upgrade = load("src/server/UpgradeService").new(Data, State, Economy, Income, Verity)
	local Phone = load("src/server/PhoneService").new(Data, State, Economy, clock, function() return 1 end)
	local Tasks = load("src/server/TaskService").new(Data, State, Economy, clock, function() return near, alive end)
	local Remote = load("src/server/RemoteService").new(Data, State, clock, function(_, result) table.insert(results, result) end)
	Remote:Register("RequestSwipe", function(id) return Phone:Swipe(id) end)
	Remote:Register("RequestUpgradeVerity", function(id) return Upgrade:UpgradeVerity(id) end)
	Remote:Register("RequestUpgradeSwipe", function(id) return Upgrade:UpgradeSwipe(id) end)
	Remote:Register("RequestOpenBox", function(id) return Delivery:Open(id) end)
	Remote:Register("RequestTaskStart", function(id, p) return Tasks:Start(id, p.taskId) end)
	Remote:Register("RequestTaskComplete", function(id, p) return Tasks:Complete(id, p.taskId) end)
	Remote:Register("RequestPhoneSession", function(id, p) return Phone:SetOpen(id, p.open) end)
	return {Data = Data, State = State, Economy = Economy, Income = Income, Verity = Verity, Plots = Plots,
		Delivery = Delivery, Upgrade = Upgrade, Phone = Phone, Tasks = Tasks, Remote = Remote,
		Records = records, Store = store, Events = events, Results = results, clock = clock,
		advance = function(seconds) now += seconds end,
		setNear = function(value) near = value end, setAlive = function(value) alive = value end,
		join = function(id)
			local profile = assert(Data:LoadAsync(id))
			State:Attach(id, assert(Plots:Assign(id)))
			return profile
		end}
end
