--!nonstrict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Collection=game:GetService("CollectionService")
local Input=game:GetService("UserInputService")
local C=require(RS.Shared.SecretsConfig)
local Catalog=require(RS.Shared.AbilityCatalog)
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Locale=require(script.Parent.Locale)
local Card=require(script.Parent.ActivityCard)
local Controller={};Controller.__index=Controller
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),buttons={},prompts={},original={}},Controller)
 local panel=ctx.refs.Panels.VERITY
 local card=W.Round(W.Frame(panel.Body,"NeighborhoodSecrets",UDim2.new(1,-6,0,202),T.Purple:Lerp(T.White,.88)),16)
 card.LayoutOrder=6;self.cleanup:Add(card)
 self.title=W.Text(card,"Title","СЕКРЕТЫ РАЙОНА • 0/3",13,true,T.Purple)
 self.title.Position=UDim2.fromOffset(12,8);self.title.Size=UDim2.new(1,-68,0,26)
 self.clear=W.Button(card,"StopSecretGuide","×",T.Pink)
 self.clear.Position=UDim2.new(1,-52,0,0);self.clear.Size=UDim2.fromOffset(44,44)
 self.cleanup:Add(self.clear.Activated:Connect(function() if self.remote then self.remote:FireServer("Clear") end end))
 self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
  if result.action=="TaskStart" and result.success and self.remote then self.remote:FireServer("Clear") end
 end))
 for i,id in C.Order do
  local item=C.Items[id]
  local b=W.Button(card,id,item.Name,Color3.fromHex(item.Color));b.Size=UDim2.new(1,-24,0,44)
  b.Position=UDim2.fromOffset(12,46+(i-1)*50);b.TextSize=13;self.buttons[id]=b
  self.cleanup:Add(b.Activated:Connect(function()
   local state=ctx.net.state
   if state and state.CosmeticsOwned[item.Item] then ctx.close();ctx.open("COSMETICS");return end
   self:Select(id)
  end))
 end
 local function add(p) self.prompts[p]=p.Enabled end
 self.cleanup:Add(Collection:GetInstanceAddedSignal("VeritySecretPrompt"):Connect(add))
 self.cleanup:Add(Collection:GetInstanceRemovedSignal("VeritySecretPrompt"):Connect(function(p)self.prompts[p]=nil end))
 for _,p in Collection:GetTagged("VeritySecretPrompt") do add(p) end
 local function attach(remote)
  if not remote or remote.Name~="VeritySecrets" or not remote:IsA("RemoteEvent") or self.remote==remote then return end
  if self.link then self.link:Disconnect() end
  self.remote=remote
  self.link=remote.OnClientEvent:Connect(function(message)
   if type(message)~="table" or message.version~=C.Version then return end
   local before=self.message;self.message=message
   if before and ((message.symbols>before.symbols) or (message.bells>before.bells) or (message.airIndex>before.airIndex)) then ctx.sound:Play("TaskCheckpoint") end
   if message.focus and (not before or before.focus~=message.focus) then
    ctx.homeRouteRequested=nil;ctx.close()
    local state=ctx.net.state
    if message.focus=="cloud" and state and not state.AbilitiesOwned.flight and not state.HeroPassOwned then
     ctx.notifications:Show(string.format(Locale.Text("Для обсерватории: полёт с ур. %d за $%s."),Catalog.Items.flight.Level,Locale.Number(Catalog.Items.flight.Cost)),"Info",5)
    else ctx.notifications:Show(Locale.Text(C.Items[message.focus].Hint),"Info",5) end
   end
   self:Render()
  end)
  remote:FireServer("Sync")
 end
 self.cleanup:Add(RS.ChildAdded:Connect(attach))
 self.cleanup:Add(RS.ChildRemoved:Connect(function(remote)
  if self.remote==remote then self.remote=nil;self.message=nil;if self.link then self.link:Disconnect();self.link=nil end end
 end))
 self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function() self.message=nil end))
 self.cleanup:Add(function() if self.link then self.link:Disconnect() end end)
 attach(RS:FindFirstChild("VeritySecrets"));return self
end
function Controller:Select(id)
 if not C.Items[id] or not self.remote or Card.ActivityRunning() then return end
 self.ctx.homeRouteRequested=nil;self.remote:FireServer("Select",id)
end
function Controller:Goal()
 local message=self.message;local ctx=self.ctx;local state=ctx.net.state
 if not message or not message.focus or not message.goal or not state or message.found[message.focus] or Card.ActivityRunning() then return nil end
 local id=message.focus;local goal=message.goal
 -- Until flight is affordable/unlocked, leave normal growth and earning guidance in charge.
 if id=="cloud" and not state.AbilitiesOwned.flight and not state.HeroPassOwned
  and (state.VerityLevel<Catalog.Items.flight.Level or state.Cash<Catalog.Items.flight.Cost) then return nil end
 local player=Players.LocalPlayer
 if ctx.active then
  if ctx.active=="ABILITIES" and id=="cloud" and not message.airAccess then
   local itemId=if state.HeroPassOwned and not state.AbilitiesOwned.flight then "homelander" else "flight"
   return {id="secret-flight-equip",kind="UI",target="Ability."..itemId,title="Выбери полёт для маршрута",detail=""}
  end
  return {id="secret-close",kind="UI",target="Close",title=C.Items[id].Name,detail="Закрой окно"}
 end
 if id=="cloud" and player:GetAttribute("VerityRiding") then
  return {id="secret-dismount",kind="UI",target="HUD.RideButton",title="Спешься для воздушного маршрута",detail=""}
 end
 if id=="cloud" and not message.airAccess then
  return {id="secret-flight",kind="UI",target="Nav.ABILITIES",title="Выбери Небесный полёт",detail="Способность покупается за игровую валюту"}
 end
 if id=="cloud" and message.airActive and message.airIndex<3 and not message.flying then
  return {id="secret-takeoff",kind="UI",target="HUD.AbilityButton",title="Включи полёт",detail=""}
 end
 local world=workspace:FindFirstChild("GeneratedWorld");local model=world and world:FindFirstChild("NeighborhoodSecrets")
 local object
 if model and goal.path then
  local group,name=goal.path:match("^([^/]+)/(.+)$");local parent=group and model:FindFirstChild(group)
  object=parent and parent:FindFirstChild(name)
 end
 local action=goal.action or "Иди по стрелкам"
 if id=="solar" and goal.kind=="Power" then
  local item=Catalog.Equipped(state,"Attack",state.HeroPassOwned)
  local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  if item and item.Action=="laser" and root and (root.Position-(C.Solar+Vector3.new(-10,4,12.5))).Magnitude<45 then
   if model then object=model.Solar:FindFirstChild("Receiver") end
   return {id="secret-laser",kind="World",target="SecretReceiver",object=object,position=C.Solar+Vector3.new(-10,4,12.5),
    title="Наведи лазер на приёмник",detail="",near=if Input.PreferredInput==Enum.PreferredInput.Gamepad then "R1 · Лазер" elseif Input.PreferredInput==Enum.PreferredInput.Touch then "Нажми кнопку атаки" else "G · Лазер",radius=40}
  end
 end
 local isPrompt=goal.kind~="Climb" and goal.kind~="Ring"
 return {id="secret:"..id..":"..goal.kind..":"..goal.index,kind="World",target="Secret",object=object,position=goal.position,
  title=goal.title,detail=if goal.kind=="Ring" then string.format(Locale.Text("Кольцо %d/3 • держи прыжок для набора высоты"),goal.index) elseif goal.kind=="Power" then string.format(Locale.Text("Заряд приёмника %d/3"),message.manual) else "",
  near=if isPrompt then "%s · "..Locale.Text(action) else action,touch=action,prompt=isPrompt,radius=if goal.kind=="Climb" then 4 else 6,air=goal.air}
end
function Controller:Render()
 local state=self.ctx.net.state;local count=0;local message=self.message
 for id,b in self.buttons do
  local owned=state and state.CosmeticsOwned[C.Items[id].Item]==true
  if owned then count+=1 end
  local caption=Locale.Text(C.Items[id].Name)
  if id=="cloud" and not owned and state and state.VerityLevel<Catalog.Items.flight.Level and not state.HeroPassOwned then
   caption=string.format(Locale.Text("Обсерватория • полёт с ур. %d"),Catalog.Items.flight.Level)
  end
  W.SetButton(b,(if owned then "✓ " else "→ ")..caption,self.remote~=nil and state~=nil and state.VerityUnlocked and not Card.ActivityRunning(),false)
 end
 self.title.Text=string.format(Locale.Text("СЕКРЕТЫ РАЙОНА • %d/3"),count)
 self.clear.Visible=message~=nil and message.focus~=nil
 for p in self.prompts do if p.Parent then
  local id=p:GetAttribute("SecretId");local action=p:GetAttribute("SecretAction")
  local found=state and state.CosmeticsOwned[C.Items[id].Item]
  local enabled=state~=nil and state.VerityUnlocked and not Card.ActivityRunning()
  if action=="Claim" then enabled=enabled and not found end
  if action=="Dynamo" then enabled=enabled and not (message and message.power) end
  if action=="Symbol" then enabled=enabled and message~=nil and message.power end
  p.Enabled=enabled==true
 end end
 for p in self.original do if not p:IsDescendantOf(workspace) then self.original[p]=nil end end
 local world=workspace:FindFirstChild("GeneratedWorld");local model=world and world:FindFirstChild("NeighborhoodSecrets")
 if not model then return end
 for _,id in C.Order do
  local group=model:FindFirstChild(if id=="solar" then "Solar" elseif id=="canopy" then "Canopy" else "Cloud")
  local chest=group and group:FindFirstChild("Chest")
  if chest then
   if not self.original[chest] then self.original[chest]={color=chest.Color,material=chest.Material} end
   chest.Color=if state and state.CosmeticsOwned[C.Items[id].Item] then Color3.fromHex("A4BCBF") else Color3.fromHex(C.Items[id].Color)
  end
 end
end
function Controller:Destroy()
 for p,enabled in self.prompts do if p.Parent then p.Enabled=enabled end end
 for p,old in self.original do if p.Parent then p.Color=old.color;p.Material=old.material end end
 self.cleanup:Destroy()
end
return Controller

