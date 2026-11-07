--!nonstrict
local Locale = require(script.Parent.Locale)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Cleanup = require(script.Parent.Cleanup)
local Expected = require(ReplicatedStorage.Shared.ProjectVersion)
local Versions = {}
Versions.__index = Versions
function Versions:IssueText()
	if self.startupIssue then return Locale.Text("Сервер не завершил запуск. Перезапусти игру.") end
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
 local function startupReady()
  if self.dead or not ReplicatedStorage:GetAttribute("VerityCoreReady") or not self.startupIssue then return end
  self.startupIssue,self.issue=nil,nil
  ctx.refs.Status.Visible=false
 end
 self.cleanup:Add(ReplicatedStorage:GetAttributeChangedSignal("VerityCoreReady"):Connect(startupReady))
 task.delay(20,function()
  if self.dead or ReplicatedStorage:GetAttribute("VerityCoreReady") or self.issue then return end
  self.startupIssue=true;self.issue="STARTUP_DELAYED"
  ctx.refs.Status.Text=self:IssueText();ctx.refs.Status.Visible=true
  ctx.notifications:Show(self:IssueText(),"Error",6)
 end)
	return self
end
function Versions:Destroy() self.dead=true;self.cleanup:Destroy() end
return Versions
