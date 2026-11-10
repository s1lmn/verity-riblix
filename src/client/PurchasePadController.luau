--!nonstrict
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Houses=require(Shared.HouseConfig)
local Catalog=require(Shared.AbilityCatalog)
local Config=require(Shared.GameConfig)
local ActivityCard=require(script.Parent.ActivityCard)
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local Controller={};Controller.__index=Controller
local GREEN=Color3.fromHex("72FFAC")
local RED=Color3.fromHex("FF6487")
local BLUE=Color3.fromHex("86E5FF")
local GOLD=Color3.fromHex("FFD877")

function Controller.new(ctx)
	local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),pads={},pending={},elapsed=0,dead=false},Controller)
	self.homePrompts={}
 local function homeAdd(p) self.homePrompts[p]=true end
 local function homeRemove(p) self.homePrompts[p]=nil end
 self.cleanup:Add(Collection:GetInstanceAddedSignal("VerityHomeDecorPrompt"):Connect(homeAdd))
 self.cleanup:Add(Collection:GetInstanceRemovedSignal("VerityHomeDecorPrompt"):Connect(homeRemove))
 for _,p in Collection:GetTagged("VerityHomeDecorPrompt") do homeAdd(p) end
 self.cleanup:Add(function() for p in self.homePrompts do if p.Parent then p.Enabled=p:GetAttribute("HomeAvailable")==true end end end)
 local folder=Instance.new("Folder");folder.Name="VerityPurchaseLabels";folder.Parent=Players.LocalPlayer.PlayerGui
	self.folder=folder;self.cleanup:Add(folder)
	local function add(model)
		if self.dead or self.pads[model] then return end
		local anchor=model:FindFirstChild("Anchor");local reference=model:FindFirstChild("Prompt")
		if not anchor or not reference then
			local attempt=(self.pending[model] or 0)+1;self.pending[model]=attempt
			if attempt<20 then task.delay(.1,function() if model.Parent then add(model) end end) end
			return
		end
		self.pending[model]=nil
		local gui=Instance.new("BillboardGui");gui.Name="Purchase_"..model.Name;gui.Adornee=anchor
		gui.Size=UDim2.fromOffset(224,94);gui.StudsOffsetWorldSpace=Vector3.new(0,model:GetAttribute("LabelHeight") or 3.4,0)
		gui.MaxDistance=model:GetAttribute("LabelDistance") or 48;gui.AlwaysOnTop=false;gui.Active=false;gui.Enabled=false;gui.Parent=folder
  local panel=W.Round(W.Frame(gui,"OfferCard",UDim2.fromScale(1,1),Color3.fromHex("172639")),12)
  panel.BackgroundTransparency=.12
  local border=W.Stroke(panel,Color3.fromHex("89B9C9"),1);border.Transparency=.42
  local accent=W.Round(W.Frame(panel,"Availability",UDim2.new(0,3,1,-16),GREEN),2);accent.Position=UDim2.fromOffset(7,8)
		local function text(name,y,size,bold)
			local label=W.Text(panel,name,"",size,bold,Color3.fromHex("F2FAFF"))
			label.Position=UDim2.fromOffset(16,y);label.Size=UDim2.new(1,-26,0,20)
			label.TextXAlignment=Enum.TextXAlignment.Center;label.TextStrokeColor3=Color3.fromHex("122237");label.TextStrokeTransparency=1
			return label
		end
		local title=text("Action",6,13,true);local detail=text("Upgrade",27,11,false)
		local price=text("Price",47,15,true);local status=text("Status",69,10,false)
		local record={model=model,anchor=anchor,reference=reference,gui=gui,title=title,detail=detail,price=price,status=status,
			accent=accent,parts={},light=anchor:FindFirstChildOfClass("PointLight")}
		for _,p in model:GetDescendants() do
			if p:IsA("BasePart") and p:GetAttribute("PadAlpha")~=nil then
				table.insert(record.parts,{part=p,alpha=p:GetAttribute("PadAlpha"),glow=p:GetAttribute("PadGlow"),size=p:GetAttribute("PadSize") or p.Size})
			end
		end
		self.pads[model]=record
	end
	local function remove(model)
		self.pending[model]=nil
		local r=self.pads[model];if not r then return end
		r.gui:Destroy();self.pads[model]=nil
	end
	self.cleanup:Add(Collection:GetInstanceAddedSignal("VerityPurchasePad"):Connect(add))
	self.cleanup:Add(Collection:GetInstanceRemovedSignal("VerityPurchasePad"):Connect(remove))
	for _,model in Collection:GetTagged("VerityPurchasePad") do add(model) end
	self.cleanup:Add(RunService.Heartbeat:Connect(function(dt)
		self.elapsed+=dt;if self.elapsed<.1 then return end;self.elapsed=0;self:Render()
	end))
	self.cleanup:Add(function() for model in self.pads do remove(model) end end)
 self.cleanup:Add(ctx.net.StateChanged.Event:Connect(function()self:Render()end))
	self:Render();return self
end

function Controller:Offer(r)
	local state=self.ctx.net.state;local kind=r.model:GetAttribute("PurchaseKind")
	local plotId=r.model:GetAttribute("PlotId")
	if kind=="Ability" or kind=="Hero" then
		local id=r.model:GetAttribute("AbilityId");local item=id and Catalog.Items[id]
		if not item then return false end
		if kind=="Hero" then
   if state and state.HeroPassOwned then return false end
			return true,true,"АЛЫЙ СТРАЖ","Полёт + красные лазеры",nil,if Config.HeroPassId then nil else Locale.Text("ПРОПУСК СКОРО"),nil,GOLD
		end
		local owned=state and (state.AbilitiesOwned or {})[id]
  if owned then return false end
		local unlocked=state and state.VerityUnlocked and state.VerityLevel>=item.Level
		local enough=state and state.Cash>=item.Cost
		local reason=if not state or not state.VerityUnlocked then Locale.Text("Сначала распакуй Verity")
			elseif not unlocked then string.format(Locale.Text("Нужен уровень Verity %d"),item.Level)
			elseif not enough and not owned then Locale.Text("Не хватает $")..Locale.Number(item.Cost-state.Cash) else nil
		return true,owned or (enough and unlocked),if owned then "ВЫБРАТЬ СИЛУ" else "КУПИТЬ СИЛУ",item.Name,
			if owned then nil else item.Cost,reason,nil,if owned then BLUE elseif enough and unlocked then GREEN else RED
	end
	if kind=="Claim" then
		local free=(r.model:GetAttribute("OwnerUserId") or 0)==0
		local visible=free and not Players.LocalPlayer:GetAttribute("HousePlotId") and Players.LocalPlayer:GetAttribute("HouseSelectionReady")==true
		return visible,visible,"ЗАНЯТЬ ДОМ","Твой участок до выхода с сервера",0,nil,nil,GREEN
	end
	if not state or state.PlotId~=plotId or not state.VerityUnlocked then return false end
	if kind=="Income" then
		local nextBuild=Houses.IncomeUpgrades[(state.HouseIncomeLevel or 0)+1]
		if not nextBuild then return false end
		local levelReady=state.VerityLevel>=nextBuild.Level
		local enough=state.Cash>=nextBuild.Cost
		return true,levelReady and enough,"СТРОИТЬ ДОМ",nextBuild.Name,nextBuild.Cost,
			if not levelReady then string.format(Locale.Text("Нужен уровень Verity %d"),nextBuild.Level) elseif not enough then Locale.Text("Не хватает $")..Locale.Number(nextBuild.Cost-state.Cash) else nil,
			math.round(nextBuild.Bonus*100),if enough and levelReady then GREEN else RED
	end
	local feature=Houses.Features[if kind=="Floor" then "SecondFloor" else "Door"]
	if kind=="Floor" and state.HouseSecondFloorOwned then return false end
	if kind=="Door" and state.HouseDoorOwned then return false end
	local enough=state.Cash>=feature.Cost
	return true,enough,if kind=="Floor" then "ПОСТРОИТЬ ЭТАЖ" else "КУПИТЬ ДВЕРЬ",feature.Name,feature.Cost,
		if not enough then Locale.Text("Не хватает $")..Locale.Number(feature.Cost-state.Cash) else nil,
		math.round(feature.Bonus*100),if enough then GREEN else RED
end

function Controller:Render()
 local ownPlot=Players.LocalPlayer:GetAttribute("HousePlotId")
 for p in self.homePrompts do
  if p.Parent then p.Enabled=p:GetAttribute("HomeDecorPlotId")==ownPlot and p:GetAttribute("HomeAvailable")==true and not ActivityCard.ActivityRunning() end
 end
	local camera=workspace.CurrentCamera;local now=os.clock()
	local character=Players.LocalPlayer.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	for model,r in self.pads do
		if not model.Parent then continue end
		local prompt=r.reference.Value
		local visible,ready,title,detail,cost,reason,bonus,color=self:Offer(r)
		visible=visible and camera and (camera.CFrame.Position-r.anchor.Position).Magnitude<80 or false
		local uiAllowed=not self.ctx.active and not self.ctx.presenting and not self.ctx.forgeReveal
		local kind=model:GetAttribute("PurchaseKind")
		r.visible=visible;r.canBuy=(ready or kind=="Ability") and visible and uiAllowed
			and humanoid~=nil and humanoid.Health>0 or false
  local state=self.ctx.net.state
  local doorControl=kind=="Door" and state and state.VerityUnlocked and state.HouseDoorOwned
   and state.PlotId==model:GetAttribute("PlotId") and ownPlot==state.PlotId
   and uiAllowed and humanoid~=nil and humanoid.Health>0 or false
		if prompt then
   -- The purchase marker disappears. The native door action remains at the door.
   if doorControl then
    prompt.ActionText=Locale.Text(if state.HouseDoorLocked then "ОТКРЫТЬ ДВЕРЬ" else "ЗАКРЫТЬ ДВЕРЬ")
    prompt.UIOffset=Vector2.zero
   elseif kind=="Door" then prompt.UIOffset=Vector2.new(0,48) end
			local minZ=prompt:GetAttribute("ExteriorMinZ")
			local enabled=(r.canBuy or doorControl) and (not minZ or (root and prompt.Parent
				and prompt.Parent.CFrame:PointToObjectSpace(root.Position).Z>=minZ)) or false
			if prompt.Enabled~=enabled then prompt.Enabled=enabled end
		end
		local showLabel=visible and uiAllowed and root and (root.Position-r.anchor.Position).Magnitude<=r.gui.MaxDistance
		r.gui.Enabled=showLabel==true
		if showLabel then
			r.title.Text=Locale.Text(title);r.detail.Text=Locale.Text(detail)
   if kind=="Hero" then
    local info=self.ctx.shop and self.ctx.shop:Price(Config.HeroPassId)
    local price=info and info.PriceInRobux
    local valid=type(price)=="number" and price>=0 and price<math.huge and price%1==0
    r.price.Text=if info and info.IsForSale and valid then tostring(price).." R$"
     elseif info and not info.IsForSale then Locale.Text("Сейчас не продаётся") else Locale.Text("Цена временно недоступна")
   else r.price.Text=if cost==0 then Locale.Text("БЕСПЛАТНО") elseif cost then "$"..Locale.Number(cost) else Locale.Text("КУПЛЕНО") end
			r.status.Text=reason or (if bonus then string.format(Locale.Text("+%d%% пассивного дохода"),bonus) else Locale.Text(if prompt and prompt.HoldDuration>0 then "Подойди и удерживай кнопку" else "Подойди и нажми кнопку"))
			r.title.TextColor3=Color3.fromHex("F2FAFF");r.price.TextColor3=color;r.accent.BackgroundColor3=color

		end
		for _,entry in r.parts do
			local p=entry.part
			if not p.Parent then continue end
			p.LocalTransparencyModifier=if visible then 0 else 1
			if visible and entry.glow then
				if p.Color~=color then p.Color=color end
				p.Transparency=math.min(.98,entry.alpha+(if ready then 0 else .12))
			end
		end
		if r.light then
			r.light.Enabled=visible and not (self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics)
			if visible then r.light.Color=color;r.light.Brightness=if ready then .35 else .15 end
		end
		r.color=color
	end
end
function Controller:Destroy() self.dead=true;self.cleanup:Destroy() end
return Controller
