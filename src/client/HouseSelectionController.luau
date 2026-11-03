--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Cleanup = require(script.Parent.Cleanup)
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)

local Selection = {}
Selection.__index = Selection

local messages = {
	PLOT_TAKEN = "Этот дом уже заняли. Выбери другой.",
	SERVER_FULL = "Все дома заняты. Подожди, пока один освободится.",
	NOT_READY = "Профиль ещё загружается. Попробуй снова.",
}

function Selection.new(ctx)
	local player = Players.LocalPlayer
	local remote = ReplicatedStorage:WaitForChild("ChooseHouse")
	local self = setmetatable({cleanup = Cleanup.new(), buttons = {}}, Selection)
	local layer = self.cleanup:Add(W.Frame(ctx.refs.Safe, "HouseSelection", nil, T.Ink))
	layer.ZIndex = 40
	layer.Active = true
	layer.BackgroundTransparency = .4
	local card = W.Round(W.Frame(layer, "Card", UDim2.new(1, -24, 1, -24)))
	card.AnchorPoint = Vector2.new(.5, .5)
	card.Position = UDim2.fromScale(.5, .5)
	card.SelectionGroup = true
	W.New("UISizeConstraint", {MaxSize = Vector2.new(470, 410)}, card)
	local title = W.Text(card, "Title", "Выбери свой дом", 23, true)
	title.Position, title.Size = UDim2.fromOffset(16, 9), UDim2.new(1, -32, 0, 30)
	local hint = W.Text(card, "Hint", "Один дом на сервер. Он улучшается вместе с Verity.", 12, false, T.Muted)
	hint.Position, hint.Size = UDim2.fromOffset(16, 40), UDim2.new(1, -32, 0, 34)
	local grid = W.New("ScrollingFrame", {
		Name = "Houses", Position = UDim2.fromOffset(16, 79), Size = UDim2.new(1, -32, 1, -125),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, card)
	W.New("UIGridLayout", {
		CellSize = UDim2.new(.25, -7, 0, 54), CellPadding = UDim2.fromOffset(6, 6),
		FillDirectionMaxCells = 4, SortOrder = Enum.SortOrder.LayoutOrder,
	}, grid)
	local status = W.Text(card, "Status", "", 12, true, T.Ink)
	status.Position, status.Size = UDim2.new(0, 16, 1, -42), UDim2.new(1, -32, 0, 34)

	local function render()
		local chosen = player:GetAttribute("HousePlotId")
		layer.Visible = chosen == nil
		if chosen then
			local selected = GuiService.SelectedObject
			if selected and selected:IsDescendantOf(layer) then GuiService.SelectedObject = nil end
			return
		end
		local ready = player:GetAttribute("HouseSelectionReady")
		local firstFree
		for id, button in self.buttons do
			local occupied = remote:GetAttribute("Owner" .. id) ~= nil
			W.SetButton(button, string.format("Дом %02d\n%s", id, if occupied then "Занят" else "Свободен"),
				ready == true and not occupied and not self.pending, false)
			button.BackgroundColor3 = if occupied then T.Disabled else T.Mint
			if button.Selectable and not firstFree then firstFree = button end
		end
		status.Text = if not ready then "Загружаем профиль…" elseif self.pending then "Занимаем дом…"
			elseif not firstFree then "Все дома заняты." else self.message or "Нажми на свободный дом."
		if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
			local selected = GuiService.SelectedObject
			if not selected or not selected:IsDescendantOf(layer) or not selected.Selectable then
				GuiService.SelectedObject = firstFree
			end
		end
	end

	for id = 1, remote:GetAttribute("PlotCount") do
		local button = W.Button(grid, "House" .. id, "", T.Mint)
		button.TextSize = 12
		button.TextWrapped = true
		button.LayoutOrder = id
		self.buttons[id] = button
		self.cleanup:Add(button.Activated:Connect(function()
			if not button.Interactable or not layer.Visible or self.pending then return end
			self.pending = true
			self.message = nil
			render()
			remote:FireServer(id)
		end))
	end
	self.cleanup:Add(remote.OnClientEvent:Connect(function(result)
		self.pending = nil
		self.message = if result == "OK" then nil else messages[result] or "Дом недоступен. Выбери другой."
		render()
	end))
	self.cleanup:Add(remote.AttributeChanged:Connect(render))
	self.cleanup:Add(player:GetAttributeChangedSignal("HousePlotId"):Connect(render))
	self.cleanup:Add(player:GetAttributeChangedSignal("HouseSelectionReady"):Connect(render))
	self.cleanup:Add(UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(render))
	render()
	return self
end

function Selection:Destroy()
	self.cleanup:Destroy()
end

return Selection
