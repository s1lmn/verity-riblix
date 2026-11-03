-- Read-only diagnostic. Run through Roblox Studio MCP in Edit/Server context.
local rs=game:GetService("ReplicatedStorage")
local world=rs:FindFirstChild("World")
local builder=world and world:FindFirstChild("WorldBuilder")
local shared=rs:FindFirstChild("Shared")
local version=shared and shared:FindFirstChild("ProjectVersion")
local info=rs:FindFirstChild("BuildInfo")
local result={
	place=game.Name,
	builder=builder and builder.Source:match('local VERSION = "([^"]+)"'),
	hasVersionModule=version~=nil,
	hasVisualController=world and world:FindFirstChild("VerityVisualController")~=nil,
	hasHiddenInteriors=game:GetService("ServerStorage"):FindFirstChild("InteriorTemplates")~=nil,
}
local live=workspace:FindFirstChild("GeneratedWorld")
result.liveMap=live and live:GetAttribute("BuilderVersion")
if info and info:IsA("ModuleScript") then
	local data=require(info)
	result.fingerprint=data.fingerprint
	result.preview=data.preview
end
return result
