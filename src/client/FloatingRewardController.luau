--!nonstrict
local Model = require(script.Parent.UIModel)
local Reward = {}
Reward.__index = Reward

function Reward.new(label, settings)
	return setmetatable({ label = label, settings = settings, amount = 0, deadline = 0 }, Reward)
end

function Reward:Add(amount)
	if not Model.IsFinite(amount) or amount <= 0 then return end
	self.amount += amount
	self.deadline = os.clock() + 1.1
	self.label.Text = "+$" .. Model.Format(self.amount)
	self.label.Visible = true
end

function Reward:Tick(now)
	if now >= self.deadline then self.label.Visible = false; self.amount = 0 end
	-- One fixed label is the Reduced Effects mode too; no particle allocation.
end

function Reward:Destroy() self.label.Visible = false end
return Reward
