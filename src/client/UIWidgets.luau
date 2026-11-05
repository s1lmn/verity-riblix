--!nonstrict
local Locale = require(script.Parent.Locale)
local Theme = require(script.Parent.UITheme)
local W = {}

function W.New(className, props, parent)
	local instance = Instance.new(className)
	for key, value in props do instance[key] = value end
	instance.Parent = parent
	return instance
end

function W.Round(instance, radius)
	W.New("UICorner", { CornerRadius = UDim.new(0, radius or Theme.Radius) }, instance)
	return instance
end

function W.Stroke(instance, color, thickness)
	return W.New("UIStroke", { Color = color or Theme.Ink, Thickness = thickness or 2,
		Transparency = 0.88, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, instance)
end

function W.Frame(parent, name, size, color)
	return W.New("Frame", { Name = name, Size = size or UDim2.fromScale(1, 1),
		BackgroundColor3 = color or Theme.Paper, BorderSizePixel = 0 }, parent)
end

function W.Text(parent, name, text, size, bold, color)
	local label = W.New("TextLabel", { Name = name, Text = text, TextSize = size or 16,
		Font = if bold then Theme.Bold else Theme.Font, TextColor3 = color or Theme.Ink,
		BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, RichText = false, AutoLocalize = false }, parent)
	return Locale.BindStatic(label, text)
end

function W.Button(parent, name, text, color)
	local button = W.New("TextButton", { Name = name, Text = text, Font = Theme.Bold,
		TextSize = 15, TextColor3 = Theme.Ink, BackgroundColor3 = color or Theme.Mint,
		Size = UDim2.new(1, 0, 0, Theme.TouchTarget), BorderSizePixel = 0,
		AutoButtonColor = false, AutoLocalize = false, Selectable = true }, parent)
	button:SetAttribute("BaseColor", color or Theme.Mint)
	button:SetAttribute("UIState", "Normal")
	W.Round(button, 12)
	W.Stroke(button)
	return Locale.BindStatic(button, text)
end

function W.SetButton(button, text, enabled, loading)
	enabled=enabled==true
	if button.Text~=text then button.Text=text end
	if button.Interactable~=enabled then button.Interactable=enabled end
	if button.Selectable~=enabled then button.Selectable=enabled end
	local state=if loading then "Loading" elseif enabled then "Normal" else "Disabled"
	if button:GetAttribute("UIState")~=state then button:SetAttribute("UIState",state) end
end

function W.List(parent, gap, horizontal)
	return W.New("UIListLayout", { Padding = UDim.new(0, gap or Theme.Gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical }, parent)
end

function W.Padding(parent, amount)
	return W.New("UIPadding", { PaddingTop = UDim.new(0, amount), PaddingBottom = UDim.new(0, amount),
		PaddingLeft = UDim.new(0, amount), PaddingRight = UDim.new(0, amount) }, parent)
end

function W.Block(parent, name, height, color)
	local block = W.Round(W.Frame(parent, name, UDim2.new(1, -4, 0, height), color or Theme.Soft), 12)
	W.Padding(block, 12)
	return block
end

function W.Line(parent, name, text, height, size, bold, color)
	local label = W.Text(parent, name, text, size, bold, color)
	label.Size = UDim2.new(1, -4, 0, height)
	return label
end

return W
