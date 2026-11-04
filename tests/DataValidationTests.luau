--!nonstrict
return function(load, check)
	local Schema = load("src/server/ProfileSchema")
	local make = load("tests/Fixture")
	check(Schema.validate(nil) ~= nil)
	local legacy=Schema.new()
	legacy.FeedCollection=nil
	check(next(Schema.validate(legacy).FeedCollection)==nil)
	for _,invalid in { {["41"]=1}, {["01"]=1}, {["1"]=-1}, {["1"]=0}, {["1"]=1.5}, {["1"]=math.huge}, {[1]=1} } do
		local raw=Schema.new()
		raw.FeedCollection=invalid
		check(Schema.validate(raw)==nil,"Invalid collection must not reset a profile")
	end
	for _, value in {0/0, math.huge, -1, "100"} do
		local raw = Schema.new(); raw.Cash = value
		check(Schema.validate(raw) == nil, "Invalid cash must not reset profile")
	end
	local future = Schema.new(); future.DataVersion = 99
	check(Schema.validate(future) == nil)
	local bad = Schema.new(); bad.VerityUnlocked = true
	check(Schema.validate(bad) == nil)
	bad = Schema.new(); bad.Receipts = {foo = false}
	check(Schema.validate(bad) == nil)
	local f = make(load)
	local p = f.join(1)
	f.Economy:AddCash(1, 500)
	check(f.Data:SaveAsync(1, false))
	local competing = load("src/server/DataService").new(f.Store, f.clock, function() end, "test-b")
	local foreign, reason = competing:LoadAsync(1)
	check(foreign == nil and reason == "SESSION_LOCKED", "Cross-server lock")
	check(f.Data:ReleaseAsync(1))
	local nextProfile = assert(competing:LoadAsync(1))
	check(nextProfile.Data.Cash == 500 and nextProfile.Data.TotalEarned == 500)
	check(not f.Data:SaveAsync(1, false), "Old owner cannot save")
	local g = make(load)
	g.Store.Fail = true
	check(g.Data:LoadAsync(2) == nil, "Failed load creates no playable default")
	check(g.Data.profiles[2] == nil and g.Records.player_2 == nil)
	g.Store.Fail = false
	local q = g.join(2)
	g.advance(170)
	check(g.Data:Get(2) == nil and not q.Writable, "Expired/unsafe lease freezes gameplay")
	-- A stolen/expired lease cannot be overwritten by the old owner.
	local h = make(load)
	local r = h.join(3)
	h.advance(181)
	local thief = load("src/server/DataService").new(h.Store, h.clock, function() end, "test-c")
	check(thief:LoadAsync(3) ~= nil)
	r.Data.Cash = 999
	check(not h.Data:SaveAsync(3, false))
	check(h.Records.player_3.Data.Cash == 0)
end
