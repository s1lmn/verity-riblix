-- Run with Luau CLI from repository root: luau tests/UIModelTests.luau
local Model=require("../src/client/UIModel")
local Tracker=require("../src/client/RequestTracker")
local Ledger=require("../src/client/EventLedger")
local passed=0
local function check(name,fn)
	local ok,err=pcall(fn)
	assert(ok,name..": "..tostring(err))
	passed+=1
	print("PASS",name)
end
local function snapshot()
	return {version=1,stateRevision=5,Cash=100,IncomePerSecond=5,SwipeIncome=2,
		VerityLevel=1,VerityUnlocked=true,HouseTier=1,SwipeUpgradeLevel=0,PhoneSessionOpen=false,
		NextVerityUpgradeCost=50,NextIncomePerSecond=6,NextSwipeUpgradeCost=30,NextSwipeIncome=4,
		TutorialStep=4,TutorialCompleted=false,Tasks={}}
end

check("100 scales, 99 strict increases, endpoints and high levels distinct",function()
	assert(Model.Scale(1)==1 and Model.Scale(100)==5)
	for level=1,99 do
		assert(Model.IsFinite(Model.Scale(level)))
		assert(Model.Scale(level+1)>Model.Scale(level))
		assert(string.format("%.3f",Model.Scale(level+1))~=string.format("%.3f",Model.Scale(level)))
	end
	for _,level in {0,101,1.5,math.huge,0/0} do assert(not pcall(Model.Scale,level)) end
end)
check("all milestone boundaries and final stage",function()
	for _,stage in Model.Milestones do
		assert(Model.NextMilestone(stage.level-1).level==stage.level)
		local nextStage=Model.NextMilestone(stage.level)
		assert(nextStage==nil or nextStage.level>stage.level)
	end
	assert(Model.NextMilestone(100)==nil)
end)
check("suffix boundaries and invalid numbers",function()
	assert(Model.Format(999)=="999" and Model.Format(1000)=="1K")
	assert(Model.Format(999999)=="1M" and Model.Format(1e12)=="1T")
	assert(Model.Format(0/0)=="—" and Model.Format(math.huge)=="—")
end)
check("malformed snapshots, NaN and missing quotes rejected",function()
	assert(Model.ValidateSnapshot(snapshot()))
	for _,key in {"Cash","IncomePerSecond","SwipeIncome","NextVerityUpgradeCost","stateRevision"} do
		local s=snapshot();s[key]=0/0;assert(Model.ValidateSnapshot(s)==nil)
	end
	local s=snapshot();s.NextVerityUpgradeCost=nil;assert(Model.ValidateSnapshot(s)==nil)
	s=snapshot();s.VerityLevel=101;assert(Model.ValidateSnapshot(s)==nil)
	s=snapshot();s.PhoneSessionOpen="true";assert(Model.ValidateSnapshot(s)==nil)
	s=snapshot();s.VerityLevel=100;s.NextVerityUpgradeCost=nil;s.NextIncomePerSecond=nil;assert(Model.ValidateSnapshot(s))
end)
check("task snapshots are copied, invalid entries and duplicates rejected",function()
	local s=snapshot()
	s.Tasks={{taskId="PRESS_BUTTON",reward=20,cooldownEndsAt=0,status="Ready"}}
	local valid=Model.ValidateSnapshot(s)
	assert(valid and valid.Tasks~=s.Tasks and valid.Tasks[1]~=s.Tasks[1])
	table.insert(s.Tasks,s.Tasks[1]);assert(Model.ValidateSnapshot(s)==nil)
	s.Tasks={{taskId="FAKE",reward=20,cooldownEndsAt=0,status="Ready"}};assert(Model.ValidateSnapshot(s)==nil)
end)
check("gesture rejects taps, downward and sideways drags",function()
	assert(Model.IsSwipe(4,-90,300))
	assert(not Model.IsSwipe(0,-12,300))
	assert(not Model.IsSwipe(0,90,300))
	assert(not Model.IsSwipe(140,-90,300))
	assert(not Model.IsSwipe(0,-55,600))
end)
check("one pending operation, timeout stays locked, late result settles once",function()
	local t=Tracker.new()
	assert(t:Begin("UpgradeVerity","one",0,5))
	assert(not t:Begin("UpgradeVerity","two",0,5))
	assert(#t:Expire(7)==0 and #t:Expire(8)==1 and #t:Expire(9)==0)
	assert(t:IsBusy("UpgradeVerity"))
	assert(not t:Begin("UpgradeVerity","two",10,6))
	assert(not t:Resolve({operationId="one",action="Swipe"}))
	assert(t:Resolve({operationId="one",action="UpgradeVerity"}))
	assert(not t:IsBusy("UpgradeVerity"))
	assert(not t:Resolve({operationId="one",action="UpgradeVerity"}))
	assert(not t:Begin("UpgradeVerity","one",12,6))
	assert(t:Begin("UpgradeVerity","two",12,6))
end)
check("independent actions and bounded completed operation storage",function()
	local t=Tracker.new()
	assert(t:Begin("Swipe","swipe",0,0) and t:Begin("PhoneSession","session",0,0))
	for i=1,600 do
		assert(t:Begin("UpgradeVerity",tostring(i),i,0))
		assert(t:Resolve({operationId=tostring(i),action="UpgradeVerity"}))
	end
	assert(#t.order==256)
end)
check("ordered transitions, duplicate events and join baseline",function()
	local ledger=Ledger.new()
	ledger:Seed(10,98)
	ledger:Seed(999,100) -- subsequent state updates cannot erase the live queue
	local a={eventId="98-99",oldLevel=98,newLevel=99,stateRevision=11}
	local b={eventId="99-100",oldLevel=99,newLevel=100,stateRevision=12}
	assert(ledger:Push(b) and not ledger:Pop())
	assert(ledger:Push(a) and not ledger:Push(a))
	assert(not ledger:Push({eventId="duplicate-transition",oldLevel=98,newLevel=99,stateRevision=11}))
	assert(ledger:Pop()==a and ledger:Pop()==b and not ledger:Pop())
	assert(not ledger:Push({eventId="past",oldLevel=97,newLevel=98,stateRevision=9}))
end)
check("queue preserves every one of 99 confirmed upgrades",function()
	local ledger=Ledger.new();ledger:Seed(0,1)
	for level=99,1,-1 do assert(ledger:Push({eventId=tostring(level),oldLevel=level,newLevel=level+1,stateRevision=level})) end
	for level=1,99 do assert(ledger:Pop().newLevel==level+1) end
	assert(not ledger:Pop())
end)
print(string.format("%d UI logic groups passed",passed))
