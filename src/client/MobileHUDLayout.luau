--!nonstrict
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")

local Layout = {
 NoticeTop = 6,
 NoticeHeight = 48,
 StatusTop = 60,
 GuideTop = 112,
}

function Layout.IsTouch()
 return Input.PreferredInput == Enum.PreferredInput.Touch
end

function Layout.StatusWidth(size)
 return math.max(1, math.min(300, size.X - 142))
end

function Layout.PlaceActions(safe, buttons)
 local size = safe.AbsoluteSize
 if size.X < 44 or size.Y < 52 then return end

 local count = 0
 for _, button in buttons do
  if button.Visible then count += 1 end
 end
 if count == 0 then return end

 local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
 local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
 local controlFrame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
 local jump = controlFrame and controlFrame:FindFirstChild("JumpButton")
 local right = size.X - math.clamp(size.X * .24, 76, 112)
 local bottom = size.Y - 8
 local centerY = bottom - 34
 if jump and jump:IsA("GuiObject") and jump.Visible and jump.AbsoluteSize.X > 0 then
  local offset = jump.AbsolutePosition - safe.AbsolutePosition
  if offset.X > size.X * .5 and offset.X <= size.X and offset.Y >= 0 and offset.Y < size.Y then
   right = offset.X - 8
   centerY = offset.Y + jump.AbsoluteSize.Y / 2
  end
 end

 -- Stay beside the built-in jump button. Keep the left thumbstick area clear
 -- where there is room, and preserve the minimum touch target on small phones.
 local gap = 6
 local leftReserve = math.clamp(size.X * .25, 76, 118)
 local available = right - leftReserve - gap * (count - 1)
 local width = math.clamp(math.floor(available / count), 44, 100)
 local rowWidth = count * width + (count - 1) * gap
 local left = math.max(6, right - rowWidth)
 local maxY = bottom - 44
 local y = math.clamp(math.floor(centerY - 22), math.min(174, maxY), maxY)
 local column = 0
 for _, button in buttons do
  if button.Visible then
   button.AnchorPoint = Vector2.zero
   button.Position = UDim2.fromOffset(left + column * (width + gap), y)
   button.Size = UDim2.fromOffset(width, 44)
   column += 1
  end
 end
end

return Layout
