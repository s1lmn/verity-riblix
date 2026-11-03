--!nonstrict
local UserInputService=game:GetService("UserInputService")
local GuiService=game:GetService("GuiService")
local Cleanup=require(script.Parent.Cleanup)
local Model=require(script.Parent.UIModel)
local Swipe={}
Swipe.__index=Swipe

function Swipe.new(viewport, callback, enabled)
	local self=setmetatable({cleanup=Cleanup.new(),gesture=nil,last=-math.huge},Swipe)
	local function emit()
		if not enabled() or GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then return end
		if os.clock()-self.last<0.75 then return end
		if callback() then self.last=os.clock() end
	end
	self.Emit=emit
	self.cleanup:Add(viewport.InputBegan:Connect(function(input)
		if not enabled() or self.gesture then return end
		local mouse=input.UserInputType==Enum.UserInputType.MouseButton1
		if mouse or input.UserInputType==Enum.UserInputType.Touch then
			self.gesture={input=input,mouse=mouse,start=input.Position,latest=input.Position}
		end
	end))
	self.cleanup:Add(UserInputService.InputChanged:Connect(function(input)
		local g=self.gesture
		if g and ((g.mouse and input.UserInputType==Enum.UserInputType.MouseMovement) or input==g.input) then g.latest=input.Position end
	end))
	self.cleanup:Add(UserInputService.InputEnded:Connect(function(input)
		local g=self.gesture
		if not g or not ((g.mouse and input.UserInputType==Enum.UserInputType.MouseButton1) or input==g.input) then return end
		self.gesture=nil
		local ending=if g.mouse then g.latest else input.Position
		if Model.IsSwipe(ending.X-g.start.X,ending.Y-g.start.Y,viewport.AbsoluteSize.Y) then emit() end
	end))
	-- Wheel events are scoped to the feed; scrolling elsewhere cannot earn money.
	self.cleanup:Add(viewport.InputChanged:Connect(function(input)
		if input.UserInputType==Enum.UserInputType.MouseWheel and input.Position.Z>0 then emit() end
	end))
	self.cleanup:Add(UserInputService.WindowFocusReleased:Connect(function() self.gesture=nil end))
	self.cleanup:Add(UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function() self.gesture=nil end))
	return self
end

function Swipe:Cancel() self.gesture=nil end
function Swipe:Destroy() self.cleanup:Destroy();self.gesture=nil end
return Swipe
