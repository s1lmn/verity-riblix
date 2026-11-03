--!nonstrict
-- EXPLICIT CLIENT-ONLY QA FIXTURE. Never included by default.project.json.
-- Insert as ReplicatedStorage.UIStudioHarness in a disposable Studio play session.
-- No RemoteEvents, server economy, persistent data or real payouts are created.
assert(game:GetService("RunService"):IsStudio(),"UI test fixture is Studio-only")
assert(game:GetService("RunService"):IsClient(),"Run this fixture in the Play Client VM")
local Players=game:GetService("Players")
local modules=Players.LocalPlayer.PlayerScripts:WaitForChild("VerityClient")
local Main=require(modules.MainUIController)
local main=Main.new()
local net=main.ctx.net
local revision=1
local state={version=1,stateRevision=1,Cash=1250,IncomePerSecond=5,SwipeIncome=2,
	VerityLevel=1,VerityUnlocked=true,HouseTier=1,SwipeUpgradeLevel=0,PhoneSessionOpen=false,
	NextVerityUpgradeCost=50,NextIncomePerSecond=6,NextSwipeUpgradeCost=30,NextSwipeIncome=4,
	TutorialStep=4,TutorialCompleted=false,Tasks={
		{taskId="PRESS_BUTTON",reward=20,cooldownEndsAt=0,status="Ready",targetPosition=Vector3.new(0,5,0)},
		{taskId="REACH_POINT",reward=40,cooldownEndsAt=0,status="Ready",targetPosition=Vector3.new(20,5,20)},
		{taskId="STAND_ON_PLATFORM",reward=25,cooldownEndsAt=0,status="Ready",targetPosition=Vector3.new(-20,5,20)},
	}}
local function snapshot()
	revision+=1
	state.stateRevision=revision
	local level=state.VerityLevel
	state.HouseTier=if level==100 then 6 elseif level>=75 then 5 elseif level>=50 then 4 elseif level>=25 then 3 elseif level>=10 then 2 else 1
	net:AcceptState(state)
end
net.connected=true
net:AcceptState(state)
local fixture={Main=main,Net=net,State=state,Requests={},Mode="Success",lastId=nil}
for _,panel in main.refs.Panels do panel.Subtitle.Text="UI TEST FIXTURE • values are simulated, no real rewards" end
main.refs.Status.Text="UI TEST FIXTURE • NO SERVER / NO REAL REWARDS"
local actions={"PhoneSession","Swipe","UpgradeVerity","UpgradeSwipe","TaskStart"}
for _,action in actions do
	net.remotes[action]={FireServer=function(_,payload)
		table.insert(fixture.Requests,{action=action,payload=payload})
		fixture.lastId=payload.operationId
		if fixture.Mode=="Timeout" then return end
		task.defer(function()
			local success=fixture.Mode~="Reject"
			local result={version=1,operationId=payload.operationId,action=action,success=success,stateRevision=revision,errorCode="INSUFFICIENT_CASH"}
			if success then
				if action=="PhoneSession" then state.PhoneSessionOpen=payload.open
				elseif action=="Swipe" then state.Cash+=2;result.reward=2
				elseif action=="UpgradeSwipe" then state.SwipeUpgradeLevel=math.min(40,state.SwipeUpgradeLevel+1);state.Cash-=30;state.SwipeIncome=4
				elseif action=="UpgradeVerity" and state.VerityLevel<100 then
					local old=state.VerityLevel
					state.VerityLevel+=1;state.Cash-=50
					local Scale=require(game:GetService("ReplicatedStorage").Shared.LevelConfig).getVerityScale
					net:AcceptWorld({version=1,kind="VerityLevelChanged",eventId=payload.operationId,ownerUserId=Players.LocalPlayer.UserId,
						oldLevel=old,newLevel=state.VerityLevel,oldScale=Scale(old),newScale=Scale(state.VerityLevel),stateRevision=revision+1})
				elseif action=="TaskStart" then
					for _,entry in state.Tasks do if entry.taskId==payload.taskId then entry.status="Active" end end
				end
				snapshot();result.stateRevision=revision
			end
			net:AcceptResult(result)
		end)
	end}
end
function fixture:SetLevel(level)
	state.VerityLevel=level
	state.HouseTier=if level==100 then 6 elseif level>=75 then 5 elseif level>=50 then 4 elseif level>=25 then 3 elseif level>=10 then 2 else 1
	snapshot()
end
function fixture:Snapshot() snapshot() end
return fixture
