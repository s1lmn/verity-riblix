--!nonstrict
-- Execute in the Edit DataModel of the smoke place via the Studio MCP/plugin context.
-- This helper is not mapped into either place. Change count to2 or8 as needed.
local count = 2
local tests = game:GetService("StudioTestService")
assert(tests.EditModeActive, "Stop the current test before starting another")
game:SetAttribute("FinalTestStatus", "RUNNING")
game:SetAttribute("FinalTestReport", "")
task.spawn(function()
	local ok, result = pcall(function()
		return tests:ExecuteMultiplayerTestAsync(count, {players = count})
	end)
	local report = if ok then result else {status = "FAIL", error = tostring(result)}
	game:SetAttribute("FinalTestStatus", if type(report) == "table" then report.status else "FAIL")
	game:SetAttribute("FinalTestReport", game:GetService("HttpService"):JSONEncode(report))
end)
return {started = true, players = count}
