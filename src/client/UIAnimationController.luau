--!nonstrict
local TweenService = game:GetService("TweenService")
local Cleanup = require(script.Parent.Cleanup)
local T = require(script.Parent.UITheme)
local Animation = {}
Animation.__index = Animation

function Animation.new(settings)
	local self=setmetatable({ settings = settings, cleanup = Cleanup.new(), tweens = {}, goals = {}, dead = false }, Animation)
	self.cleanup:Add(settings.Changed.Event:Connect(function(values)
		if not values.ReducedMotion then return end
		for instance,tween in table.clone(self.tweens) do
			local goal=self.goals[instance]
			tween:Cancel()
			if goal and instance.Parent then for key,value in goal do instance[key]=value end end
			self.tweens[instance],self.goals[instance]=nil,nil
		end
	end))
	return self
end

function Animation:Tween(instance, duration, properties)
	local previous = self.tweens[instance]
	if previous then previous:Cancel(); previous:Destroy() end
	if self.settings.values.ReducedMotion then
		for key, value in properties do instance[key] = value end
		self.tweens[instance] = nil
		self.goals[instance] = nil
		return
	end
	local tween = TweenService:Create(instance, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), properties)
	self.tweens[instance] = tween
	self.goals[instance] = properties
	tween.Completed:Once(function()
		if self.tweens[instance] == tween then self.tweens[instance] = nil;self.goals[instance]=nil end
		tween:Destroy()
	end)
	tween:Play()
end

function Animation:BindButton(button)
	local scale = Instance.new("UIScale")
	scale.Name, scale.Parent = "FeedbackScale", button
	local hover, pressed = false, false
	local function update()
		local state = button:GetAttribute("UIState")
		local enabled = state ~= "Disabled" and state ~= "Loading"
		local color = if enabled then button:GetAttribute("BaseColor") else T.Disabled
		if state == "Success" then color = T.Mint end
		if enabled and hover then color = color:Lerp(T.White, 0.12) end
		self:Tween(button, 0.12, { BackgroundColor3 = color })
		self:Tween(scale, 0.12, { Scale = if enabled and pressed then 0.97 elseif enabled and hover then 1.015 else 1 })
	end
	self.cleanup:Add(button.MouseEnter:Connect(function() hover = true; update() end))
	self.cleanup:Add(button.MouseLeave:Connect(function() hover = false; pressed = false; update() end))
	self.cleanup:Add(button.SelectionGained:Connect(function() hover = true; update() end))
	self.cleanup:Add(button.SelectionLost:Connect(function() hover = false; pressed = false; update() end))
	self.cleanup:Add(button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then pressed = true; update() end
	end))
	self.cleanup:Add(button.InputEnded:Connect(function() pressed = false; update() end))
	self.cleanup:Add(button:GetAttributeChangedSignal("UIState"):Connect(update))
	update()
end

function Animation:Success(button)
	button:SetAttribute("UIState", "Success")
	task.delay(0.25, function()
		if not self.dead and button.Parent and button:GetAttribute("UIState") == "Success" then button:SetAttribute("UIState", "Normal") end
	end)
end

function Animation:Destroy()
	self.dead = true
	self.cleanup:Destroy()
	for _, tween in self.tweens do tween:Cancel(); tween:Destroy() end
	table.clear(self.tweens)
	table.clear(self.goals)
end
return Animation
