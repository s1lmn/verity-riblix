--!nonstrict
-- Server-only integration point. No yield or automatic startup on require.
local Runtime = {Services = nil}
function Runtime.GetServices()
	assert(Runtime.Services ~= nil, "Wait for ServerScriptService.Core.CoreReady attribute")
	return Runtime.Services
end
return Runtime
