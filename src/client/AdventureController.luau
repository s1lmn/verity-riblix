--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local C=require(RS.Shared.AdventureConfig)
local Card=require(script.Parent.ActivityCard)
local Locale=require(script.Parent.Locale)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Cleanup=require(script.Parent.Cleanup)
local MobileHUD=require(script.Parent.MobileHUDLayout)
local Controller={};Controller.__index=Controller
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),prompts={}},Controller)
 self.card,self.title,self.detail,self.action=Card.Build(ctx.refs.Safe,"AdventureStatus","AdventureAction");self.cleanup:Add(self.card)
 self.weather=self.cleanup:Add(require(script.Parent.WeatherVisuals).new(ctx))
 self.dock=self.cleanup:Add(W.Round(W.Frame(ctx.refs.Safe,"WeatherDock",UDim2.fromOffset(228,44),T.Paper),12));self.dock.AnchorPoint=Vector2.new(1,1);self.dock.Visible=false
 self.dock.BackgroundTransparency=.08;W.Stroke(self.dock,T.Purple,1)
 self.weatherToggle=W.Button(self.dock,"WeatherToggle","",T.Purple:Lerp(T.White,.86));self.weatherToggle.Size=UDim2.new(1,0,0,44);self.weatherToggle.TextSize=11;self.weatherToggle.TextTruncate=Enum.TextTruncate.AtEnd;self.weatherToggle:SetAttribute("FixedFeedbackSize",true)
 self.weatherText=W.Text(self.dock,"WeatherDetail","",11,false,T.Ink);self.weatherText.Position=UDim2.fromOffset(12,48);self.weatherText.Size=UDim2.new(1,-24,0,37)
 self.weatherGo=W.Button(self.dock,"WeatherGo","ПОКАЗАТЬ ПУТЬ",T.Mint);self.weatherGo.Position=UDim2.fromOffset(10,91);self.weatherGo.Size=UDim2.new(1,-20,0,44);self.weatherGo.TextSize=11;self.weatherGo:SetAttribute("FixedFeedbackSize",true)
 self.cleanup:Add(self.weatherToggle.Activated:Connect(function()self.weatherExpanded=not self.weatherExpanded;self:Render()end))
 self.cleanup:Add(self.weatherGo.Activated:Connect(function()self.guide=true;self.weatherExpanded=false;ctx.close();self:Render()end))
 self.track=W.Round(W.Frame(self.card,"ProgressTrack",UDim2.new(1,-16,0,3),T.Soft),3);self.track.Position=UDim2.new(0,8,1,-5)
 self.fill=W.Round(W.Frame(self.track,"Fill",UDim2.fromScale(0,1),T.Purple),3)
 self.cleanup:Add(self.action.Activated:Connect(function()
  local m=self.message;if not m then return end
  if m.run and self.remote then self.remote:FireServer("Leave",m.run.round)
  elseif self.hint then ctx.open("ABILITIES")
  else self.guide=true;ctx.close() end
 end))
 local function add(q)self.prompts[q]=q.Enabled end
 self.cleanup:Add(Collection:GetInstanceAddedSignal("VerityAdventurePrompt"):Connect(add))
 self.cleanup:Add(Collection:GetInstanceRemovedSignal("VerityAdventurePrompt"):Connect(function(q)self.prompts[q]=nil end))
 for _,q in Collection:GetTagged("VerityAdventurePrompt") do add(q) end
 local function attach(remote)
  if not remote or remote.Name~="VerityAdventures" or not remote:IsA("RemoteEvent") or remote==self.remote then return end
  if self.link then self.link:Disconnect() end;self.remote=remote
  self.link=remote.OnClientEvent:Connect(function(m)
   if type(m)~="table" or m.version~=C.Version or type(m.sequence)~="number" or self.message and m.sequence<=self.message.sequence then return end
   local previous=self.message;self.message=m;self.weather:Set(m)
   if m.run and (not previous or not previous.run or previous.run.round~=m.run.round) then self.guide=false;self.hint=nil;ctx.close() end
   if previous and previous.run and not m.run then self.guide=false end
   self:Render()
  end)
  remote:FireServer("Sync",0)
 end
 self.cleanup:Add(RS.ChildAdded:Connect(attach));attach(RS:FindFirstChild("VerityAdventures"))
 self.cleanup:Add(RS.ChildRemoved:Connect(function(remote)
  if remote==self.remote then if self.link then self.link:Disconnect();self.link=nil end;self.remote=nil;self.message=nil;self.guide=false;self.weather:Set({weather="Clear"});self:Render() end
 end))
 self.cleanup:Add(ctx.net.Notification.Event:Connect(function(payload)
  if type(payload.code)=="string" and payload.code:match("^TRIAL_NEED_") then self.hint=payload.code:sub(12);self.hintUntil=os.clock()+12 end
 end))
 self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function()self.guide=false;self.hint=nil;self.weatherExpanded=false end))
 self.cleanup:Add(function()if self.link then self.link:Disconnect()end end)
 return self
end
function Controller:World()
 local world=workspace:FindFirstChild("GeneratedWorld");return world and world:FindFirstChild("NeighborhoodAdventures")
end
function Controller:Party(plot)
 for _,party in self.message and self.message.parties or {} do if party.plot==plot then return party end end
end
function Controller:ArcadeReserved(plot)
 local party=self:Party(plot);return party~=nil and party.mode=="Arcade" and party.phase=="Playing"
end
function Controller:CanPlayArcade(plot)
 local m=self.message;local r=m and m.run;local party=r and self:Party(r.plot)
 return r~=nil and r.kind=="Party" and r.plot==plot and not r.done and party~=nil and party.mode=="Arcade" and party.phase=="Playing"
end
function Controller:ResolveAim(ray,maximum)
 local r=self.message and self.message.run
 if not r or r.kind~="Trial" or r.id~="laser" or typeof(r.target)~="Vector3" then return nil end
 local d=r.target-ray.Origin;local length=d:Dot(ray.Direction)
 if length>0 and length<math.min(85,maximum or 85) and (ray.Origin+ray.Direction*length-r.target).Magnitude<2.5 then return r.target end
end
function Controller:Goal()
 local m=self.message;if not m then return nil end;local r=m.run
 if r and r.done then return {id="party-done:"..r.round,kind="Wait",title="Твой результат записан",detail="Дождись итогов или выйди кнопкой ×"} end
 if r and typeof(r.target)=="Vector3" and not r.done then
  local key=r.kind..r.round..":"..r.index
  local detail=""
  if r.kind=="Trial" then
   local gamepad=game:GetService("UserInputService").PreferredInput==Enum.PreferredInput.Gamepad
   detail=if r.id=="laser" then (if gamepad then "R1 · Лазер" else "G · Лазер") else (if gamepad then "L1 · Способность" else "F · Способность")
   if game:GetService("UserInputService").PreferredInput==Enum.PreferredInput.Touch then detail="Нажми кнопку способности" end
  end
  return {id="adventure:"..key,kind="World",target="Adventure",position=r.target,title=r.title or "Продолжи приключение",detail=detail,
   near=if r.prompt then "%s · Взаимодействовать" else detail,touch=if r.prompt then "Взаимодействовать" else detail,prompt=r.prompt,radius=if r.kind=="Trial" then 6 else 7,air=r.kind=="Trial" and (r.id=="flight" or r.id=="leap")}
 end
 if r then return {id="adventure-wait:"..r.round,kind="Wait",title="Продолжай приключение",detail="Следи за подсказкой события"} end
 if not self.guide or Card.ActivityRunning() or not (self.ctx.net.state and self.ctx.net.state.TutorialCompleted) then return nil end
 if self.invite then return {id="party-invite:"..self.invite.plot,kind="World",target="Adventure",position=self.invite.position,title="Присоединись к вечеринке",detail="",near="%s · Присоединиться",touch="Присоединиться",prompt=true,radius=7} end
 local world=self:World();local desk=world and world:FindFirstChild("WeatherDesk");local station=desk and desk:FindFirstChild("Station")
 local cave=m.weather=="Rainbow" or m.weather=="Storm"
 return {id="weather-guide:"..m.weatherRound,kind="World",target="Adventure",position=if cave then C.CaveEntrance+Vector3.yAxis*2.6 else station and station.Position,
  title=if m.weather=="Storm" then "После ливня откроется проход" elseif cave then "Войди в дождевую пещеру" elseif m.weather=="Fire" then "Начни поиск солнечных угольков" else "Начни поиск осколков",
  detail="",near=if m.weather=="Stars" or m.weather=="Fire" or m.weather=="Rainbow" then "%s · Начать" else "Дождись смены погоды",touch="Начать",prompt=m.weather=="Stars" or m.weather=="Fire" or m.weather=="Rainbow",radius=7}
end
function Controller:Render()
 local m=self.message;local player=Players.LocalPlayer;local busy=Card.ActivityRunning();local r=m and m.run
 if self.hint and os.clock()>(self.hintUntil or 0) then self.hint=nil end
 self.invite=nil
 if m and not busy and m.weather=="Clear" then for _,party in m.parties do
  if party.phase=="Lobby" and not party.seen and party.count<C.PartyLimit then self.invite=party;break end
 end end
 local remaining=m and math.max(0,math.ceil(m.deadline-workspace:GetServerTimeNow())) or 0
 local state=self.ctx.net.state
 local introduced=state and state.VerityUnlocked and state.TutorialCompleted
 local relevant=m and (r~=nil or self.hint~=nil or self.invite~=nil or m.weather~="Clear" or remaining<=20)
 local hidden=Card.Blocked(self.ctx) or (self.ctx.arcade and self.ctx.arcade.root.Visible) or player:GetAttribute("VerityDiversionKind")=="Arcade" or (busy and not r)
 self.card.Visible=relevant==true and (r~=nil or self.hint~=nil) and (r~=nil or introduced==true) and not hidden
 self.dock.Visible=relevant==true and introduced==true and not hidden and not r and not self.hint
 if self.dock.Visible then
  local size=self.ctx.refs.Safe.AbsoluteSize
  local touch=MobileHUD.IsTouch()
  self.dock.AnchorPoint=Vector2.new(1,if touch then 0 else 1)
  self.dock.Position=if touch then UDim2.new(1,-8,0,MobileHUD.StatusTop) else UDim2.new(1,-12,1,-12)
  local compact=touch and size.Y<228
  self.dock.Size=UDim2.fromOffset(if touch then MobileHUD.StatusWidth(size) else math.min(228,size.X-24),if not self.weatherExpanded then 44 elseif compact then 90 elseif touch then 110 else 145)
  self.weatherText.Size=UDim2.new(1,-24,0,if touch then 20 else 37)
  self.weatherGo.Position=UDim2.fromOffset(10,if compact then 44 elseif touch then 65 else 91)
  self.weatherText.Visible=self.weatherExpanded==true and not compact;self.weatherGo.Visible=self.weatherExpanded==true
  local title=if self.invite and m.weather=="Clear" then "Вечеринка у соседей" elseif m.weather=="Rainbow" then "Дождевая пещера" else C.WeatherNames[m.weather]
  self.weatherToggle.Text=Locale.Text(title).." • "..(if self.invite and m.weather=="Clear" then self.invite.count.."/6" else remaining..Locale.Text("с"))..(if self.weatherExpanded then " ▾" else " ▴")
  self.weatherText.Text=Locale.Text(if self.invite and m.weather=="Clear" then "Загляни в гости и сыграй вместе" elseif m.weather=="Fire" then "5 угольков → жар-светильник" elseif m.weather=="Stars" then "5 осколков → звёздный мобиль" elseif m.weather=="Storm" then "После ливня откроется пещера" elseif m.weather=="Rainbow" then "Три руны → сокровище пещеры" else "Погодные занятия появятся вместе с событием")
 end
 if self.card.Visible then
  Card.Layout(self.card,self.title,self.detail,self.ctx.refs.Safe.AbsoluteSize)
  local title,detail,progress,color="","",0,C.WeatherColors[m.weather]
  if r then
   local seconds=math.max(0,math.ceil(r.deadline-workspace:GetServerTimeNow()))
   title=if r.kind=="Trial" then C.Trials[r.id].Name elseif r.kind=="Cave" then "Дождевая пещера" elseif r.kind=="Stars" then (if r.id=="Fire" then "Охота за солнечными угольками" else "Охота за осколками") else "Домашняя вечеринка"
   title=Locale.Text(title).." • "..seconds..Locale.Text("с")
   progress=math.clamp(r.count/math.max(1,r.total),0,1)
   if r.kind=="Party" then
    local party=self:Party(r.plot)
    if party and party.phase=="Lobby" then detail=string.format(Locale.Text("Сбор гостей • %d/6"),party.count)
    elseif party and party.mode=="Arcade" then detail=Locale.Text(if r.done then "Попытка завершена • ждём итоги" else "Одна попытка • приз от 100 очков")
    else detail=string.format(Locale.Text("Подарки • %d/6"),r.count) end
    if party and #party.leaders>0 and party.phase=="Playing" then local top=party.leaders[1];if self.ctx.refs.Safe.AbsoluteSize.X>=640 then detail..=" • "..top.name..": "..top.score end end
   elseif r.kind=="Trial" then
    color=C.Trials[r.id].Color;detail=string.format(Locale.Text("Кольца / цели • %d/%d"),r.count,r.total)
    if r.best>0 then detail..=string.format(Locale.Text(" • рекорд %.1fс"),r.best) end
   else detail=string.format(Locale.Text("Найдено • %d/%d"),r.count,r.total) end
   W.SetButton(self.action,"×",true,false)
  elseif self.hint then title=Locale.Text("Выбери нужную способность");detail=Locale.Text("Открыть коллекцию способностей →");W.SetButton(self.action,"→",true,false)
  elseif self.invite and m.weather=="Clear" then title=Locale.Text("Соседи зовут на вечеринку!");detail=self.invite.owner.." • "..self.invite.count.."/6";W.SetButton(self.action,"→",true,false)
  else
   self.invite=nil
   title=Locale.Text(if m.weather=="Clear" then "Скоро смена погоды" elseif m.weather=="Rainbow" then "Дождевая пещера открыта" else C.WeatherNames[m.weather]).." • "..remaining..Locale.Text("с")
   detail=Locale.Text(if m.weather=="Fire" then "5 угольков → жар-светильник" elseif m.weather=="Stars" then "5 осколков → звёздный мобиль" elseif m.weather=="Storm" then "После ливня откроется пещера" elseif m.weather=="Rainbow" then "Три руны → сокровище пещеры" else C.WeatherNames[m.nextWeather])
   progress=math.clamp(1-remaining/math.max(1,m.deadline-m.since),0,1);W.SetButton(self.action,"→",true,false)
  end
  self.title.Text=title;self.detail.Text=detail;self.fill.Size=UDim2.fromScale(progress,1)
  self.fill.BackgroundColor3=Color3.fromHex(color or "B6A4FF");self.title.TextColor3=self.fill.BackgroundColor3:Lerp(T.Ink,.55)
 end
 local alive=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
 for q in self.prompts do if q.Parent then
  local kind=q:GetAttribute("AdventureKind");local index=q:GetAttribute("AdventureIndex");local plot=q:GetAttribute("AdventurePlot")
  local enabled=q:GetAttribute("AdventureEnabled")==true and alive and alive.Health>0 and state and state.VerityUnlocked and not Card.Blocked(self.ctx)
  if kind=="Trial" or kind=="Weather" or kind=="Cave" then enabled=enabled and not busy
  elseif kind=="Star" then enabled=enabled and r and r.kind=="Stars" and index==r.targetIndex
  elseif kind=="Rune" then enabled=enabled and r and r.kind=="Cave" and index==r.index
  elseif kind=="Chest" then enabled=enabled and r and r.kind=="Cave" and r.index==4
  elseif kind=="Exit" then enabled=enabled and (r and r.kind=="Cave" or player.Character and player.Character:GetPivot().Position.Y< -20)
  elseif kind=="HostParty" or kind=="PartyMode" then enabled=enabled and not busy and q:GetAttribute("PartyOwner")==player.UserId
  elseif kind=="StopParty" or kind=="PartyEffects" then enabled=enabled and q:GetAttribute("PartyOwner")==player.UserId
  elseif kind=="JoinParty" then local party=self:Party(plot);enabled=enabled and not busy and party and not party.seen
  elseif kind=="PartyGift" then enabled=enabled and r and r.kind=="Party" and r.plot==plot and r.targetIndex==index and not r.done end
  q.Enabled=enabled==true
 end end
end
function Controller:VisualTick(now,dt)
 self.weather:Tick(now,dt)
end
function Controller:Destroy()
 for q,enabled in self.prompts do if q.Parent then q.Enabled=enabled end end
 self.cleanup:Destroy()
end
return Controller
