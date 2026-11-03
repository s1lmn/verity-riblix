--!nonstrict
local Locale = require(script.Parent.Locale)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cleanup = require(script.Parent.Cleanup)
local Expected = require(ReplicatedStorage.Shared.ProjectVersion)
local Versions = {}
Versions.__index = Versions
function Versions:IssueText()
	return self.issue and (Locale.Text(self.issue)..Expected.Place)
end

function Versions.new(ctx)
	local self = setmetatable({cleanup=Cleanup.new(), issue=nil, ctx=ctx, dead=false}, Versions)
	local info = ReplicatedStorage:FindFirstChild("BuildInfo")
	if info then
		local ok, data = pcall(require, info)
		if ok and type(data)=="table" then ctx.refs.Gui:SetAttribute("BuildFingerprint",data.fingerprint) end
	end
	local function check(child)
		if child.Name~="GeneratedWorld" then return end
		local actual=child:GetAttribute("BuilderVersion")
		ctx.refs.Gui:SetAttribute("MapVersion",actual)
		self.issue=if actual~=Expected.Map then "VERSION MISMATCH • open " else nil
		if self.issue then
			warn("[Verity] Map version "..tostring(actual).."; expected "..Expected.Map..". Old geometry is preserved. Open the complete project build.")
			ctx.notifications:Show(self.issue,"Error",5,Expected.Place)
		end
	end
	self.cleanup:Add(workspace.ChildAdded:Connect(check))
	local world=workspace:FindFirstChild("GeneratedWorld")
	if world then check(world) end
	task.delay(10,function()
		if not self.dead and not workspace:FindFirstChild("GeneratedWorld") then
			self.issue="WORLD MISSING • open "
			ctx.notifications:Show(self.issue,"Error",5,Expected.Place)
		end
	end)
	return self
end
function Versions:Destroy() self.dead=true;self.cleanup:Destroy() end
return Versions
