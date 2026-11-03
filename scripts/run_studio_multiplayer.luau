--!nonstrict
-- Execute in the Edit DataModel of the smoke place via the Studio MCP/plugin context.
-- This helper is not mapped into either place. Change count to2 or8 as needed.
local count = 2
local tests = game:GetService("StudioTestService")
assert(tests.EditModeActive, "Stop the current test before starting another")
game:SetAttribute("CoreMultiStatus", "RUNNING")
game:SetAttribute("CoreMultiReport", "")
task.spawn(function()
	local ok, result = pcall(function()
		return tests:ExecuteMultiplayerTestAsync(count, {mode = "multiplayer", players = count})
	end)
	local report = if ok then result else {status = "FAIL", error = tostring(result)}
	game:SetAttribute("CoreMultiStatus", if type(report) == "table" then report.status else "FAIL")
	game:SetAttribute("CoreMultiReport", game:GetService("HttpService"):JSONEncode(report))
end)
return {started = true, players = count}
