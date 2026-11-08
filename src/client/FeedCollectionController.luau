
--!nonstrict
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local Art=require(script.Parent.CollectionArt)
local Album=require(game:GetService("ReplicatedStorage").Shared.AlbumConfig)
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
	local self = setmetatable({cleanup=Cleanup.new(),open=false,rows={},signature=nil,body=refs.Body,ctx=ctx,view="Sets",thumbnails={},tabButtons={}},Collection)
	self.root=self.cleanup:Add(W.Round(W.Frame(refs.Root,"CardCollection"),12))
	self.root.Visible,self.root.Active,self.root.ZIndex=false,true,8
 self.root.ClipsDescendants=true
 self.openScale=W.New("UIScale",{Scale=1},self.root)
 W.Stroke(self.root,T.Purple,1).Transparency=.6
	W.New("UIGradient",{Color=ColorSequence.new(T.Paper,T.Purple:Lerp(T.White,.82)),Rotation=75},self.root)
	local function resize()
		local size=refs.Root.AbsoluteSize
  local top=if size.X>size.Y then 20 else 34
  self.root.Position=UDim2.fromOffset(14,top);self.root.Size=UDim2.new(1,-28,1,-top-18)
  self.signature=nil
	end
	self.cleanup:Add(refs.Body:GetPropertyChangedSignal("Position"):Connect(resize))
	self.cleanup:Add(refs.Body:GetPropertyChangedSignal("Size"):Connect(resize))
 self.cleanup:Add(refs.Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
	resize()
	self.title=W.Text(self.root,"CollectionTitle","",15,true)
	self.title.Position,self.title.Size=UDim2.fromOffset(10,2),UDim2.new(1,-74,0,38)
	local back=W.Button(self.root,"Back","←",T.Purple:Lerp(T.White,.75))
	self.back = back
	back.AnchorPoint,back.Position,back.Size=Vector2.new(1,0),UDim2.new(1,-4,0,2),UDim2.fromOffset(48,44)
	self.cleanup:Add(back.Activated:Connect(function()
		if self.preview then self:ClosePreview()
		elseif self.selectedSet then self.selectedSet=nil;self.signature=nil;self:Render(self.state)
		else self:SetOpen(false) end
	end))
	self.tabs=W.Frame(self.root,"AlbumTabs",UDim2.new(1,-8,0,44));self.tabs.Position=UDim2.fromOffset(4,46);self.tabs.BackgroundTransparency=1
 for index,entry in {{"Sets","НАБОРЫ"},{"All","ВСЕ КАРТЫ"}} do
  local button=W.Button(self.tabs,entry[1],entry[2],if index==1 then T.Gold else T.Mint)
  self.tabButtons[entry[1]]=button
  button.Position=UDim2.new((index-1)/2,2,0,0);button.Size=UDim2.new(.5,-4,1,0)
  self.cleanup:Add(button.Activated:Connect(function() self.view=entry[1];self.selectedSet=nil;self.signature=nil;self.list.CanvasPosition=Vector2.zero;self:Render(self.state) end))
 end
 self.list=W.New("ScrollingFrame",{
		Name="Cards",Position=UDim2.fromOffset(4,96),Size=UDim2.new(1,-8,1,-100),
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
	if not open then self:ClosePreview();self.ctx.animation:Cancel(self.openScale);self:PaintThumbnails() end
	if open then
  self.openScale.Scale=if self.ctx.settings.values.ReducedMotion then 1 else .98
  self.ctx.animation:Tween(self.openScale,.20,{Scale=1})
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
 self.tabs.Visible=true
	if previousSelection and previousSelection.Parent and UserInputService.PreferredInput == Enum.PreferredInput.Gamepad then
		GuiService.SelectedObject = previousSelection
	end
end

function Collection:OpenPreview(cardId)
	self:ClosePreview()
	self.previousSelection = GuiService.SelectedObject
	self.list.Visible = false
 self.tabs.Visible=false
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

function Collection:PaintThumbnails()
 local bounds=self.list.AbsolutePosition;local height=self.list.AbsoluteSize.Y
 local enabled=self.open and not self.preview and self.root.Visible
 local budget=if self.ctx.settings.values.LowGraphics then 3 else 6
 local used=0
 for _,entry in self.thumbnails do
  local y=entry.thumb.AbsolutePosition.Y;local h=entry.thumb.AbsoluteSize.Y
  local visible=enabled and entry.owned and used<budget and y+h>=bounds.Y-25 and y<=bounds.Y+height+25
  if visible then
   used+=1
   if not entry.image then
    local image=Feed.Draw(entry.thumb,entry.id)
    image.Position=UDim2.new();image.Size=UDim2.fromScale(1,1)
    image.Rarity.Visible=false;image.Payout.Visible=false;image.PostTitle.Visible=false;image.PostCaption.Visible=false
    image.Illustration.Position=UDim2.new();image.Illustration.Size=UDim2.fromScale(1,1)
    entry.image=image
   end
  elseif entry.image then entry.image:Destroy();entry.image=nil end
  entry.placeholder.Visible=not visible
 end
end

function Collection:Render(state)
 self.state=state;if not self.open then return end;self:RenderSlots();self:PaintThumbnails()
 local cards=state and state.FeedCollection or {};local owned=state and state.CosmeticsOwned or {}
 local found=Collection.Count(state)
 self.title.Text=if self.selectedSet then Locale.Text(Album.Sets[self.selectedSet].Name) else string.format(Locale.Text("АЛЬБОМ • %d/40"),found)
 for id,button in self.tabButtons do
  button.BackgroundColor3=if id==self.view then T.Gold else T.Purple:Lerp(T.White,.82)
  button:SetAttribute("BaseColor",button.BackgroundColor3)
 end
 local compact=self.root.AbsoluteSize.Y<310
 local parts={self.view,self.selectedSet or "",tostring(compact)}
 for id=1,#Feed.Posts do table.insert(parts,tostring(cards[tostring(id)] or 0)) end
 for _,id in Album.Order do table.insert(parts,tostring(owned[Album.Sets[id].Decor])) end
 table.insert(parts,tostring(self.ctx.net.connected));table.insert(parts,tostring(self.ctx.net:IsBusy()));local signature=table.concat(parts,",")
 if self.signature==signature then return end;self.signature=signature
 if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(self.list) then GuiService.SelectedObject=self.back end
 for _,row in self.rows do row:Destroy() end;table.clear(self.rows);table.clear(self.thumbnails)
 local function keep(row) table.insert(self.rows,row);return row end
 if self.view=="Sets" and not self.selectedSet then
  local goal=keep(W.Round(W.Frame(self.list,"CollectorCrown",UDim2.new(1,-8,0,98),Color3.fromHex("FFF0CA")),14));goal.LayoutOrder=0
  W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("FFF7DE"),Color3.fromHex("E7D5FF")),Rotation=20},goal)
  local trophy=W.Frame(goal,"Crown",UDim2.fromOffset(54,62));trophy.Position=UDim2.fromOffset(7,9);trophy.BackgroundTransparency=1
  Art.Star(trophy,T.Gold)
  local crown=W.Text(goal,"Title","40 карт → корона коллекционера",13,true,T.Purple);crown.Position=UDim2.fromOffset(68,7);crown.Size=UDim2.new(1,-78,0,44)
  local hint=W.Text(goal,"Hint",string.format(Locale.Text("Твой альбом • %d/40"),found),11,true,T.Muted);hint.Position=UDim2.fromOffset(68,53);hint.Size=UDim2.new(1,-78,0,24)
  local track=W.Round(W.Frame(goal,"Progress",UDim2.new(1,-24,0,5),T.White),3);track.Position=UDim2.new(0,12,1,-12)
  W.Round(W.Frame(track,"Fill",UDim2.fromScale(found/40,1),T.Purple),3)
  for order,id in Album.Order do
   local set=Album.Sets[id];local count=Album.Count(cards,id);local claimed=owned[set.Decor]==true;local color=Color3.fromHex(set.Color)
   local row=keep(W.Round(W.Frame(self.list,id,UDim2.new(1,-8,0,if compact then 136 else 184),T.Paper),15));row.LayoutOrder=order
   W.New("UIGradient",{Color=ColorSequence.new(T.White,color:Lerp(T.White,.76)),Rotation=40},row)
   W.Stroke(row,color,if count==5 then 2 else 1).Transparency=if count==5 then .1 else .5
   local cover=Art.Cover(row,id,color);cover.Position=UDim2.fromOffset(10,10);cover.Size=UDim2.fromOffset(if compact then 70 else 82,if compact then 72 else 104)
   local title=W.Text(row,"Name",set.Name,14,true,T.Ink);title.Position=UDim2.fromOffset(if compact then 90 else 104,7);title.Size=UDim2.new(1,if compact then -102 else -116,0,if compact then 30 else 42)
   local progress=W.Text(row,"Progress",string.format(Locale.Text("Карт %d/5"),count),12,true,T.Purple)
   progress.Position=UDim2.fromOffset(if compact then 90 else 104,if compact then 38 else 53);progress.Size=UDim2.new(1,if compact then -102 else -116,0,if compact then 17 else 23)
   local stamps=W.Frame(row,"Stamps",UDim2.new(1,if compact then -100 else -114,0,if compact then 21 else 26));stamps.Position=UDim2.fromOffset(if compact then 88 else 102,if compact then 57 else 82);stamps.BackgroundTransparency=1
   for index,card in set.Cards do
    local present=cards[tostring(card)]~=nil
    local stamp=W.Round(W.Frame(stamps,"Card"..index,UDim2.new(.2,-3,1,0),if present then color else T.Soft),4)
    stamp.Position=UDim2.new((index-1)*.2,1,0,0)
    local mark=W.Text(stamp,"Mark",if present then "✓" else "?",11,true,if present then T.Ink else T.Muted);mark.Size=UDim2.fromScale(1,1);mark.TextXAlignment=Enum.TextXAlignment.Center
   end
   local track=W.Round(W.Frame(row,"Track",UDim2.new(1,-24,0,5),T.Soft),3);track.Position=UDim2.fromOffset(12,if compact then 80 else 122)
   W.Round(W.Frame(track,"Fill",UDim2.fromScale(count/5,1),color),3)
   local view=W.Button(row,"View","СМОТРЕТЬ",color:Lerp(T.White,.6));view.Position=UDim2.fromOffset(10,if compact then 86 else 134);view.Size=UDim2.new(.43,-12,0,44);view.TextSize=11
   view:SetAttribute("FixedFeedbackSize",true)
   view.Activated:Connect(function() self.selectedSet=id;self.signature=nil;self.list.CanvasPosition=Vector2.zero;self:Render(self.state) end)
   local claim=W.Button(row,"Claim","",if claimed then T.Mint else T.Gold);claim.Position=UDim2.new(.43,2,0,if compact then 86 else 134);claim.Size=UDim2.new(.57,-12,0,44);claim.TextSize=11
   claim:SetAttribute("FixedFeedbackSize",true)
   W.SetButton(claim,Locale.Text(if claimed then "✓ ПОЛУЧЕНО" elseif count==5 then "ЗАБРАТЬ ДЕКОР" else "СОБЕРИ НАБОР"),count==5 and not claimed and self.ctx.net.connected and not self.ctx.net:IsBusy(),false)
   claim.Activated:Connect(function() self.ctx.request("ClaimAlbumSet",{itemId=id}) end)
  end
  return
 end
 local ids=if self.selectedSet then Album.Sets[self.selectedSet].Cards else nil
 for id,post in Feed.Posts do
  if ids and not table.find(ids,id) then continue end
  local rarity,chance=Drops.Get(id);local copies=cards[tostring(id)];local accent=Color3.fromHex(rarity.color)
  local row=keep(W.Button(self.list,"Card"..id,"",accent:Lerp(T.White,.83)))
  row.Size,row.LayoutOrder=UDim2.new(1,-8,0,112),id;row:SetAttribute("FixedFeedbackSize",true);W.SetButton(row,"",copies~=nil,false)
  W.New("UIGradient",{Color=ColorSequence.new(T.Paper,accent:Lerp(T.White,.75)),Rotation=20},row)
  local thumb=W.Round(W.Frame(row,"Thumbnail",UDim2.fromOffset(86,96),accent),9);thumb.Position=UDim2.fromOffset(8,8);thumb.ClipsDescendants=true
  local placeholder=W.Frame(thumb,"CardBack");placeholder.BackgroundTransparency=1
  local panel=Art.Shape(placeholder,"Back",.5,.5,.70,.82,accent:Lerp(T.Ink,.45),7,-5)
  W.Stroke(panel,T.White,1).Transparency=.5
  local mark=W.Text(panel,"Mystery",if copies then string.format("#%02d",id) else "?",22,true,T.White)
  mark.Size=UDim2.fromScale(1,1);mark.TextXAlignment=Enum.TextXAlignment.Center
  table.insert(self.thumbnails,{thumb=thumb,id=id,owned=copies~=nil,placeholder=placeholder})
  local title=W.Text(row,"Name",if copies then post[1] else "Не открыта",13,true,T.Ink);title.Position=UDim2.fromOffset(104,6);title.Size=UDim2.new(1,-116,0,42)
  local rarityLabel=W.Text(row,"Rarity",rarity.label,11,true,T.Purple);rarityLabel.Position=UDim2.fromOffset(104,50);rarityLabel.Size=UDim2.new(1,-116,0,19)
  local detail=W.Text(row,"Details","",10,false,T.Muted);detail.Position=UDim2.fromOffset(104,72);detail.Size=UDim2.new(1,-116,0,34)
  local odds=string.format("%.2f%%",chance);if Locale.GetLanguage()=="ru" then odds=odds:gsub("%.",",") end
  detail.Text=odds.." · "..(if copies then string.format(Locale.Text("Найдено раз • %d"),copies) else Locale.Text("Ищи в ленте телефона"))
  if copies then row.Activated:Connect(function()self:OpenPreview(id)end) end
 end
 self:PaintThumbnails()
end

function Collection:Destroy()
 self.ctx.animation:Cancel(self.openScale)
 self:ClosePreview()
 self.cleanup:Destroy()
end
return Collection
