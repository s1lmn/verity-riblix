--!nonstrict
local Locale = require(script.Parent.Locale)
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local Model=require(script.Parent.UIModel)
local Abilities=require(game:GetService("ReplicatedStorage").Shared.VerityAbilities)
local Catalog=require(game:GetService("ReplicatedStorage").Shared.AbilityCatalog)
local Houses=require(game:GetService("ReplicatedStorage").Shared.HouseConfig)
local Verity={}
Verity.__index=Verity

function Verity.new(ctx)
	local self=setmetatable({ctx=ctx,refs=ctx.refs.Panels.VERITY,cleanup=Cleanup.new()},Verity)
	self.cleanup:Add(self.refs.Buy.Activated:Connect(function() ctx.request("UpgradeVerity") end))
 local RS=game:GetService("ReplicatedStorage")
 for _,action in {"Pet","Play"} do self.cleanup:Add(self.refs[action].Activated:Connect(function()
  if self.bond then self.bond:FireServer(action) end
 end)) end
 local function attach(remote)
  if not remote or remote.Name~="VerityBond" or not remote:IsA("RemoteEvent") or self.bond==remote then return end
  if self.bondLink then self.bondLink:Disconnect() end
  self.bond=remote
  self.bondLink=remote.OnClientEvent:Connect(function(status) if status=="OK" then ctx.close() end end)
 end
 self.cleanup:Add(RS.ChildAdded:Connect(attach))
 self.cleanup:Add(RS.ChildRemoved:Connect(function(remote)
  if self.bond==remote then self.bond=nil;if self.bondLink then self.bondLink:Disconnect();self.bondLink=nil end end
 end))
 self.cleanup:Add(function() if self.bondLink then self.bondLink:Disconnect() end end)
 attach(RS:FindFirstChild("VerityBond"))
	return self
end

function Verity:Render()
	local net=self.ctx.net
	local state=net.state
	local r=self.refs
	if not state then
		r.Pet.Interactable=false;r.Play.Interactable=false
		r.NextUnlockCard.Visible=false
		W.SetButton(r.Buy,Locale.Text("WAITING FOR SERVER"),false,false)
		return
	end
	local level=state.VerityLevel
 local player=game:GetService("Players").LocalPlayer
 for _,action in {"Pet","Play"} do
  local remaining=math.max(0,math.ceil((player:GetAttribute("Verity"..action.."ReadyAt") or 0)-workspace:GetServerTimeNow()))
  local label=if action=="Pet" then "ПОГЛАДИТЬ ♥" else "ПОИГРАТЬ"
  W.SetButton(r[action],if remaining>0 then Locale.Text("ЕЩЁ ЧЕРЕЗ ")..remaining..Locale.Text("с") else Locale.Text(label),
   self.bond~=nil and net.connected and state.VerityUnlocked and remaining==0,false)
 end
	if state.VerityUnlocked then
		local ability=Abilities.Get(level)
		r.Ability.Text=string.format(Locale.Text("Способность: %s\nСкорость %d • сила прыжка %d"),
			Locale.Text(ability.name),ability.speed,ability.jump)
		local movement=Catalog.Equipped(state,"Mobility",state.HeroPassOwned)
		local attack=Catalog.Equipped(state,"Attack",state.HeroPassOwned)
		r.Ability.Text..="\nF: "..Locale.Text(if movement then movement.Name else "Не выбрано").."\nG: "..Locale.Text(if attack then attack.Name else "Не выбрано")
	else
		r.Ability.Text=Locale.Text("Распакуй Verity, чтобы получить способность.")
	end
	local maxed=level==100
	r.Level.Text=if maxed then Locale.Text("MAX LEVEL 100 • GIANT FINAL FORM") else string.format(Locale.Text("VERITY LEVEL %d / 100"),level)
	r.Level.TextSize=if maxed then 18 else 20
	r.Level.Size=UDim2.new(1,-24,0,48)
	r.Income.Text=Locale.Text("INCOME  $")..Locale.Number(state.IncomePerSecond)..Locale.Text(" / sec")..(if maxed then "" else " → $"..Locale.Number(state.NextIncomePerSecond))
	r.Scale.Text=if maxed then Locale.Text("SCALE  15× • final evolution") else string.format(Locale.Text("SCALE  %.3f× → %.3f×"),Model.Scale(level),Model.Scale(level+1))
 local count=state.HouseIncomeLevel or 0
 local nextBuild=Houses.IncomeUpgrades[count+1]
 r.House.Text=string.format(Locale.Text("Стройка дома %d / 10 • открой мастерскую"),count)
	r.Progress.Size=UDim2.fromScale((level-1)/99,1)
	local nextStage=Model.NextMilestone(level)
	r.Milestone.Text=if nextStage then string.format(Locale.Text("NEXT • LEVEL %d  /  %s\n%s"),nextStage.level,Locale.Text(nextStage.name),Locale.Text(nextStage.reward))
		else Locale.Text("ALL DISCOVERIES UNLOCKED\nCrown, unique idle, layered aura and celebration effects.")
	local unlock=state.NextUnlock
	r.NextUnlockCard.Visible=type(unlock)=="table"
	if r.NextUnlockCard.Visible then
		local item=Catalog.Items[unlock.itemId]
		local name=Locale.Text(unlock.name or (item and item.Name) or "Способность")
		r.NextUnlock.Text=if unlock.kind=="AbilityPurchase" then string.format(Locale.Text("Покупка: %s • $%s / $%s"),name,Locale.Number(unlock.progress),Locale.Number(unlock.total))
			elseif unlock.kind=="AbilityAccess" then string.format(Locale.Text("%s • покупка с уровня %d"),name,unlock.requiredLevel)
			elseif unlock.kind=="Riding" then string.format(Locale.Text("Поездки на Verity • уровень %d"),unlock.requiredLevel)
			else string.format(Locale.Text("Новый облик • уровень %d"),unlock.requiredLevel)
		r.NextUnlockFill.Size=UDim2.fromScale(math.clamp(unlock.progress/math.max(unlock.total,1),0,1),1)
	end
	local busy=net:IsBusy("UpgradeVerity")
	local affordable=not maxed and state.NextVerityUpgradeCost~=nil and state.Cash>=state.NextVerityUpgradeCost
	local text=if maxed then Locale.Text("MAX LEVEL • 15×") elseif not state.VerityUnlocked then Locale.Text("OPEN YOUR DELIVERY BOX FIRST")
		elseif busy then Locale.Text("WAITING FOR CONFIRMATION…") elseif not affordable then Locale.Text("NEED $")..Locale.Number(state.NextVerityUpgradeCost)
		else Locale.Text("УЛУЧШИТЬ ↑ • $")..Locale.Number(state.NextVerityUpgradeCost)
	W.SetButton(r.Buy,text,net.connected and state.VerityUnlocked and not maxed and affordable and not busy,busy)
	r.Boost.Visible=false
	local boost=state.Boost
	if type(boost)=="table" and Model.IsFinite(boost.multiplier) and Model.IsFinite(boost.endsAt) then
		local remaining=math.max(0,math.ceil(boost.endsAt-workspace:GetServerTimeNow()))
		r.Boost.Visible=remaining>0
		r.Boost.Text=if remaining>0 then string.format(Locale.Text("ACTIVE BOOST  %.2f× • %ds remaining\n%s"),boost.multiplier,remaining,
			if type(boost.description)=="string" then string.sub(Locale.Text(boost.description),1,100) else Locale.Text("Server-verified earning boost.")) else Locale.Text("No active boost. Free progression remains available.")
	end
end

function Verity:Destroy() self.cleanup:Destroy() end
return Verity
