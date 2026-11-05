
--!nonstrict
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Drops = require(game:GetService("ReplicatedStorage").Shared.FeedDrops)
local Feed = require(script.Parent.FeedController)
local Locale = require(script.Parent.Locale)
local Cleanup = require(script.Parent.Cleanup)
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local Collection = {}
Collection.__index = Collection

function Collection.Count(state)
	local count = 0
	for cardId = 1, #Feed.Posts do
		if state and (state.FeedCollection or {})[tostring(cardId)] then count += 1 end
	end
	return count
end

function Collection.new(refs, ctx)
	local self = setmetatable({cleanup=Cleanup.new(),open=false,rows={},signature=nil,body=refs.Body,ctx=ctx},Collection)
	self.root=self.cleanup:Add(W.Round(W.Frame(refs.Root,"CardCollection"),12))
	self.root.Visible,self.root.Active,self.root.ZIndex=false,true,8
	W.New("UIGradient",{Color=ColorSequence.new(T.Paper,T.Purple:Lerp(T.White,.82)),Rotation=75},self.root)
	local function resize()
		self.root.Position,self.root.Size=refs.Body.Position,refs.Body.Size
	end
	self.cleanup:Add(refs.Body:GetPropertyChangedSignal("Position"):Connect(resize))
	self.cleanup:Add(refs.Body:GetPropertyChangedSignal("Size"):Connect(resize))
	resize()
	self.title=W.Text(self.root,"CollectionTitle","",15,true)
	self.title.Position,self.title.Size=UDim2.fromOffset(10,2),UDim2.new(1,-74,0,38)
	local back=W.Button(self.root,"Back","←",T.Purple:Lerp(T.White,.75))
	self.back = back
	back.AnchorPoint,back.Position,back.Size=Vector2.new(1,0),UDim2.new(1,-4,0,2),UDim2.fromOffset(48,44)
	self.cleanup:Add(back.Activated:Connect(function()
		if self.preview then self:ClosePreview()
		else self:SetOpen(false) end
	end))
	self.list=W.New("ScrollingFrame",{
		Name="Cards",Position=UDim2.fromOffset(4,46),Size=UDim2.new(1,-8,1,-50),
		CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
		BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,
		ScrollBarImageColor3=T.Purple,ScrollingDirection=Enum.ScrollingDirection.Y,
	},self.root)
	W.List(self.list,8)
	self.cleanup:Add(Locale.Changed.Event:Connect(function() self.signature=nil;self:Render(self.state) end))
	return self
end

function Collection:SetOpen(open)
	self.open,self.root.Visible=open,open
	self.body.Visible=not open
	if not open then self:ClosePreview() end
	if open then
		self:Render(self.state)
		if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then GuiService.SelectedObject = self.back end
	end
end

function Collection:ClosePreview()
	local previousSelection = self.previousSelection
	self.previousSelection = nil
	if self.previewScale then self.ctx.animation:Cancel(self.previewScale); self.previewScale = nil end
	if self.preview then self.preview:Destroy(); self.preview = nil end
	if self.controls then self.controls:Destroy(); self.controls = nil end
	self.previewId, self.slotButtons, self.focusSlot = nil, nil, nil
	self.list.Visible = true
	if previousSelection and previousSelection.Parent and UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
		GuiService.SelectedObject = previousSelection
	end
end

function Collection:OpenPreview(cardId)
	self:ClosePreview()
	self.previousSelection = GuiService.SelectedObject
	self.list.Visible = false
	self.previewId = cardId
	self.preview = Feed.Draw(self.root, cardId)
	self.preview.Position, self.preview.Size = UDim2.fromOffset(4, 46), UDim2.new(1, -8, 1, -126)
	self.controls = W.Frame(self.root, "ShowcaseControls", UDim2.new(1, -8, 0, 72))
	self.controls.Position, self.controls.BackgroundTransparency = UDim2.new(0, 4, 1, -74), 1
	local heading = W.Text(self.controls, "ShowcaseTitle", "Витрина у дома", 13, true)
	heading.Size, heading.TextXAlignment = UDim2.new(1, 0, 0, 22), Enum.TextXAlignment.Center
	self.slotButtons = {}
	for slot = 1, Drops.ShowcaseSlots do
		local button = W.Button(self.controls, "Slot" .. slot, "", T.Mint)
		button.Position = UDim2.new((slot - 1) / Drops.ShowcaseSlots, 2, 0, 24)
		button.Size = UDim2.new(1 / Drops.ShowcaseSlots, -4, 0, 44)
		button.TextScaled = true
		W.New("UITextSizeConstraint", {MinTextSize = 8, MaxTextSize = 14}, button)
		self.slotButtons[slot] = button
		button.Activated:Connect(function()
			local net = self.ctx.net
			local state = net.state
			if not state or net:IsBusy() or not (state.FeedCollection or {})[tostring(cardId)] then return end
			local current = (state.ShowcaseCards or {})[tostring(slot)]
			if UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
				self.focusSlot = slot
				GuiService.SelectedObject = self.back
			end
			self.ctx.request("SetShowcaseCard", {slot = slot, cardId = if current == cardId then 0 else cardId})
			self:RenderSlots()
		end)
	end
	if not self.ctx.settings.values.ReducedMotion then
		local scale = W.New("UIScale", {Scale = 0.96}, self.preview)
		self.previewScale = scale
		self.ctx.animation:Tween(scale, 0.18, {Scale = 1})
	end
	self:RenderSlots()
	if self.slotButtons[1].Selectable and UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
		GuiService.SelectedObject = self.slotButtons[1]
	end
end

function Collection:RenderSlots()
	if not self.slotButtons then return end
	local state, net = self.state, self.ctx.net
	local slots = state and state.ShowcaseCards or {}
	local pending = net:IsBusy("SetShowcaseCard")
	for slot, button in self.slotButtons do
		local current = slots[tostring(slot)]
		local label = if current == self.previewId then "Снять %d" elseif current then "Заменить %d" else "Рамка %d"
		local enabled = state ~= nil and net.connected and not net:IsBusy()
		W.SetButton(button, string.format(Locale.Text(label), slot), enabled, pending)
		button.BackgroundColor3 = if not enabled then T.Disabled elseif current == self.previewId then T.Gold else T.Mint
	end
	if self.focusSlot and not net:IsBusy() then
		local button = self.slotButtons[self.focusSlot]
		self.focusSlot = nil
		if button and button.Selectable and GuiService.SelectedObject == self.back then GuiService.SelectedObject = button end
	end
end

function Collection:Render(state)
	self.state=state
	if not self.open then return end
	self:RenderSlots()
	local cards=state and state.FeedCollection or {}
	self.title.Text=string.format(Locale.Text("Коллекция • %d / %d"),Collection.Count(state),#Feed.Posts)
	local parts={}
	for id=1,#Feed.Posts do table.insert(parts,tostring(cards[tostring(id)] or 0)) end
	local signature=table.concat(parts,",")
	if self.signature==signature then return end
	self.signature=signature
	for _,row in self.rows do row:Destroy() end
	table.clear(self.rows)
	for tierIndex, tierName in {"Common","Uncommon","Rare","Epic","Legendary"} do
		local found,total=0,0
		for id=1,#Feed.Posts do
			if Drops.Get(id).label==tierName then
				total+=1
				if cards[tostring(id)] then found+=1 end
			end
		end
		local heading=W.Text(self.list,"Tier","",14,true,T.Purple)
		heading.Text=Locale.Text(tierName).."  "..found.." / "..total
		heading.Size,heading.LayoutOrder=UDim2.new(1,-8,0,28),tierIndex*100
		table.insert(self.rows,heading)
		for id,post in Feed.Posts do
			local rarity,chance=Drops.Get(id)
			if rarity.label~=tierName then continue end
			local copies=cards[tostring(id)]
			local accent=Color3.fromHex(rarity.color)
			local row=W.Button(self.list,"Card"..id,"",accent:Lerp(T.White,.72))
			row.Size,row.LayoutOrder=UDim2.new(1,-8,0,96),tierIndex*100+id
			row:SetAttribute("FixedFeedbackSize",true)
			W.SetButton(row,"",copies~=nil,false)
			local thumb=W.Round(W.Frame(row,"Thumbnail",UDim2.fromOffset(82,82),accent),8)
			thumb.Position,thumb.ClipsDescendants=UDim2.fromOffset(7,7),true
			if copies then
				local image=Feed.Draw(thumb,id)
				image.Rarity.Visible=false
				image.Payout.Visible=false
				image.PostTitle.Visible=false
				image.PostCaption.Visible=false
				image.Illustration.Position,image.Illustration.Size=UDim2.new(),UDim2.fromScale(1,1)
			else
				local mystery=W.Text(thumb,"Mystery","?",38,true,T.White)
				mystery.TextXAlignment,mystery.Size=Enum.TextXAlignment.Center,UDim2.fromScale(1,1)
				W.New("UIGradient",{Color=ColorSequence.new(accent,accent:Lerp(T.Ink,.5)),Rotation=55},thumb)
			end
			local title=W.Text(row,"Name",if copies then post[1] else "Не открыта",14,true,T.Ink)
			title.Position,title.Size=UDim2.fromOffset(98,9),UDim2.new(1,-108,0,42)
			local detail=W.Text(row,"Details","",11,false,T.Ink)
			local odds=string.format("%.2f",chance)
			if Locale.GetLanguage()=="ru" then odds=odds:gsub("%.",",") end
			detail.Text=Locale.Text(rarity.label).." • "..odds.."%"
				..(if copies then "\n"..string.format(Locale.Text("Найдено раз • %d"),copies) else "\n"..string.format("#%02d",id))
			detail.Position,detail.Size=UDim2.fromOffset(98,53),UDim2.new(1,-108,0,36)
			if copies then
				row.Activated:Connect(function() self:OpenPreview(id) end)
			end
			table.insert(self.rows,row)
		end
	end
end

function Collection:Destroy()
	self:ClosePreview()
	self.cleanup:Destroy()
end
return Collection
