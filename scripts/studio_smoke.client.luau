--!nonstrict
-- Included ONLY by smoke.project.json; never shipped in the normal Core place.
if not game:GetService("RunService"):IsStudio() then return end
local replicated = game:GetService("ReplicatedStorage")
local bridge = replicated:WaitForChild("CoreSmokeBridge", 30)
assert(bridge, "Smoke bridge missing")
local remotes = replicated:WaitForChild("Remotes", 30)
local command = bridge:WaitForChild("Command", 10)
local report = bridge:WaitForChild("Report", 10)
remotes.ActionResult.OnClientEvent:Connect(function(result)
	report:FireServer(result)
end)
remotes.InteriorTransition.OnClientEvent:Connect(function(event)
	report:FireServer({status = "INTERIOR_EVENT", event = event})
end)
command.OnClientEvent:Connect(function(name, payload)
	if name == "__LEAVE_TEST" then
		local tests = game:GetService("StudioTestService")
		if tests:CanLeaveTest() then tests:LeaveTest() end
		return
	end
	local remote = remotes:FindFirstChild(name)
	assert(remote and remote:IsA("RemoteEvent"), "Unknown smoke request")
	remote:FireServer(payload)
end)
bridge:SetAttribute("ClientReady", true) -- Local only; server gets an explicit readiness report.
report:FireServer({status = "CLIENT_READY"})
