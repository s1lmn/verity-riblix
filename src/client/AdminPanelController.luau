--!nonstrict
-- Owner-only preview and temporary server progression tools.
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local RS=game:GetService("ReplicatedStorage")
local Levels=require(RS.Shared.LevelConfig)
local Abilities=require(RS.Shared.VerityAbilities)
local Catalog=require(RS.Shared.AbilityCatalog)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Cleanup=require(script.Parent.Cleanup)
local Admin={};Admin.__index=Admin
function Admin.new(ctx,visuals)
 local self=setmetatable({ctx=ctx,visuals=visuals,cleanup=Cleanup.new(),level=1,emotion=1,soundIndex=1},Admin)
 local safe=ctx.refs.Safe
 local toggle=W.Button(safe,"AdminToggle","АДМИН",T.Gold)
 toggle.AnchorPoint=Vector2.new(1,0);toggle.Position=UDim2.new(1,-12,0,8);toggle.Size=UDim2.fromOffset(84,44);toggle.ZIndex=80
 self.toggle=self.cleanup:Add(toggle)
 local panel=W.Round(W.Frame(safe,"AdminPanel",UDim2.fromOffset(320,540),T.Paper),14)
 panel.AnchorPoint=Vector2.new(1,0);panel.Position=UDim2.new(1,-12,0,60);panel.ZIndex=80;panel.Visible=false
 self.panel=self.cleanup:Add(panel);W.Stroke(panel,T.Purple,2)
 local body=W.New("ScrollingFrame",{Name="Controls",Position=UDim2.fromOffset(10,10),Size=UDim2.new(1,-20,1,-64),
  CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,
  ScrollBarThickness=4,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=81},panel)
 W.List(body,8)
 local function text(name,value,height)
  local label=W.Line(body,name,value,height or 30,13,true);label.ZIndex=82;return label
 end
 local function button(parent,name,value,callback)
  local b=W.Button(parent,name,value,T.Soft);b.ZIndex=82
  self.cleanup:Add(b.Activated:Connect(callback));return b
 end
 local function row(entries)
  local frame=W.Frame(body,"ControlRow",UDim2.new(1,-4,0,44));frame.BackgroundTransparency=1;frame.ZIndex=81
  for i,e in entries do
   local b=button(frame,"Control"..i,e[1],e[2]);b.Size=UDim2.new(1/#entries,-5,1,0);b.Position=UDim2.new((i-1)/#entries,0,0,0)
  end
 end
 text("Heading","АДМИН VERITY · F8")
 text("Notice","Выдача меняет твой игровой профиль. «Показать» включает предпросмотр.",42)
 self.info=text("Selected","",52)
 self.status=W.Text(panel,"Status","Выбери дом и распакуй Verity.",13,true,T.Ink)
 self.status.Position=UDim2.new(0,12,1,-50);self.status.Size=UDim2.new(1,-24,0,44);self.status.ZIndex=82
 local entry=W.New("TextBox",{Name="LevelInput",Text="1",PlaceholderText="Уровень 1–100",ClearTextOnFocus=false,
  Size=UDim2.new(1,-4,0,44),Font=T.Bold,TextSize=16,BackgroundColor3=T.Soft,TextColor3=T.Ink,BorderSizePixel=0,ZIndex=82},body)
 W.Round(entry,10);self.entry=entry
 row({{"−1",function()self:SetLevel(self.level-1)end},{"Показать",function()self:SetLevel(tonumber(entry.Text))end},{"+1",function()self:SetLevel(self.level+1)end}})
 row({{"1",function()self:SetLevel(1)end},{"10",function()self:SetLevel(10)end},{"25",function()self:SetLevel(25)end}})
 row({{"50",function()self:SetLevel(50)end},{"75",function()self:SetLevel(75)end},{"100",function()self:SetLevel(100)end}})
 button(body,"SetActualLevel","ВЫСТАВИТЬ УРОВЕНЬ",function()
  self:Command("SetLevel",tonumber(entry.Text))
 end)
 text("AbilityHeading","ВЫДАТЬ И ЭКИПИРОВАТЬ")
 for _,id in Catalog.Order do
  local item=Catalog.Items[id]
  if not item.Premium then
   button(body,"Grant_"..id,string.format("%s · ур. %d",item.Name,item.Level),function()
    self:Command("GrantAbility",id)
   end)
  end
 end
 button(body,"UpgradePreview","ПОВТОРИТЬ АПГРЕЙД",function()
  if not self:Allowed() then return end
  local e=visuals:AdminLevel(self.level,true)
  if type(e)=="table" then self.upgradeId=e.eventId;ctx.sound:PlayUpgrade(e,true);self.status.Text="Анимация "..(self.level-1).." → "..self.level
  else self.status.Text="Выбери уровень 2–100. Спутник должен быть распакован." end
 end)
 button(body,"BoxPreview","ПОВТОРИТЬ РАСПАКОВКУ",function()
  if not self:SetLevel(1) then return end
  local id="admin_box_"..tostring(os.clock())
  local e={kind="VeritySpawned",eventId=id,ownerUserId=Players.LocalPlayer.UserId,plotId=Players.LocalPlayer:GetAttribute("HousePlotId")}
  if visuals:BeginSpawn(e) then self.boxId=id;ctx.sound:Play("BoxCeremony");self.status.Text="Предпросмотр распаковки"
  else self.status.Text="Подойди к месту своей коробки." end
 end)
 self.emotions={"Joy","Love","Stars","Surprise","Playful","Wink","Laugh","Confident"}
 self.faceButton=button(body,"Face","ЭМОЦИЯ: Joy",function()
  if not self:Allowed() then return end
  local name=self.emotions[self.emotion]
  if visuals:AdminEmotion(name) then self.faceButton.Text="ЭМОЦИЯ: "..name end
  self.emotion=self.emotion%#self.emotions+1
 end)
 self.soundNames={};for name,definition in require(RS.World.AudioConfig).UI do if not definition.Looped then table.insert(self.soundNames,name) end end
 table.sort(self.soundNames)
 self.soundLabel=text("SoundName","Звук: "..self.soundNames[1])
 row({{"← звук",function()self:SoundStep(-1)end},{"▶",function()
  if not self:Allowed() then return end
  if self.previewSound then ctx.sound:Stop(self.previewSound) end
  self.previewSound=self.soundNames[self.soundIndex];ctx.sound:Play(self.previewSound)
 end},{"звук →",function()self:SoundStep(1)end}})
 button(body,"Restore","ВЕРНУТЬ ИГРОВОЙ ВИД / ЗАКРЫТЬ",function()self:Close()end)
 local function layout()
  panel.Size=UDim2.fromOffset(math.max(180,math.min(320,safe.AbsoluteSize.X-24)),math.max(160,math.min(650,safe.AbsoluteSize.Y-84)))
 end
 self.cleanup:Add(safe:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout));layout()
 self.cleanup:Add(toggle.Activated:Connect(function()self:Toggle()end))
 self.cleanup:Add(Input.InputBegan:Connect(function(input,processed)
  if not processed and not Input:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.F8 then self:Toggle() end
 end))
 self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function()self:Close()end))
 self.cleanup:Add(Players.LocalPlayer:GetAttributeChangedSignal("VerityAdmin"):Connect(function()
  toggle.Visible=self:Allowed();if not toggle.Visible then self:Close() end
 end))
 self.cleanup:Add(ctx.refs.Panels.PHONE.Root:GetPropertyChangedSignal("Visible"):Connect(function()
  toggle.Visible=self:Allowed() and not ctx.refs.Panels.PHONE.Root.Visible
 end))
 toggle.Visible=self:Allowed() and not ctx.refs.Panels.PHONE.Root.Visible;self:Refresh()
 return self
end
function Admin:Command(action,value)
 if not self:Allowed() or self.pending or self.ctx.presenting or self.ctx.forgeReveal or self.ctx.rewardOverlay then return end
 if action=="SetLevel" and (not value or value%1~=0 or value<1 or value>100) then
  self.status.Text="Введи целый уровень от 1 до 100.";return
 end
 local remote=RS:FindFirstChild("VerityAdminCommand")
 if not remote or not remote:IsA("RemoteFunction") then self.status.Text="Команды сервера пока недоступны.";return end
 self.pending=true
 self.status.Text="Применяю изменение…"
 local ok,result,required=pcall(function()return remote:InvokeServer(action,value)end)
 self.pending=false
 if self.dead or not self:Allowed() then return end
 if not ok then self.status.Text="Сервер не подтвердил команду.";return end
 if result=="OK" then
  if action=="SetLevel" then
   self.visuals:AdminClear()
   if self.upgradeId then self.ctx.sound:StopUpgrade(self.upgradeId);self.upgradeId=nil end
   self.level=value;self:Refresh()
  end
  self.status.Text=if action=="SetLevel" then "Игровой уровень установлен." else Catalog.Items[value].Name.." экипирована."
 elseif result=="HOUSE_LEVEL" or result=="ABILITY_LEVEL" then
  self.status.Text=string.format("Минимальный уровень %d (%s).",required,if result=="HOUSE_LEVEL" then "постройка дома" else "способность")
 elseif result=="BOX_NOT_OPENED" or result=="NOT_READY" then self.status.Text="Выбери дом и распакуй Verity."
 elseif result=="IN_ACTIVITY" then self.status.Text="Сначала заверши активность."
 else self.status.Text="Команда отклонена. Повтори чуть позже." end
end
function Admin:Allowed()return Players.LocalPlayer:GetAttribute("VerityAdmin")==true end
function Admin:Refresh()
 local aura=require(RS.Shared.VerityAnimationProfile).Aura(self.level)
 self.entry.Text=tostring(self.level)
 self.info.Text=string.format("Уровень %d · размер %.2f×\n%s · огонь: %s · следов: %d",self.level,Levels.getVerityScale(self.level),Abilities.Get(self.level).name,if aura.fire then "да" else "нет",aura.trails)
end
function Admin:SetLevel(level)
 if not self:Allowed() or type(level)~="number" or level~=level or level%1~=0 or level<1 or level>100 then
  self.status.Text="Введи целый уровень от 1 до 100.";return false
 end
 if not self.visuals:AdminLevel(level,false) then self.status.Text="Сначала распакуй Verity. Дождись конца игрового апгрейда.";return false end
 if self.upgradeId then self.ctx.sound:StopUpgrade(self.upgradeId);self.upgradeId=nil end
 self.level=level;self:Refresh();self.status.Text="Просмотр включён. Реальный прогресс сохранён."
 return true
end
function Admin:SoundStep(delta)
 self.soundIndex=(self.soundIndex-1+delta)%#self.soundNames+1
 self.soundLabel.Text="Звук: "..self.soundNames[self.soundIndex]
end
function Admin:Toggle()
 if not self:Allowed() or self.ctx.presenting or self.ctx.forgeReveal or self.ctx.rewardOverlay then return end
 if self.panel.Visible then self:Close() else self.ctx.close();self.panel.Visible=true;self:Refresh() end
end
function Admin:Close()
 self.panel.Visible=false
 self.visuals:AdminClear()
 if self.upgradeId then self.ctx.sound:StopUpgrade(self.upgradeId);self.upgradeId=nil end
 if self.previewSound then self.ctx.sound:Stop(self.previewSound);self.previewSound=nil end
 local a=self.visuals.spawn.active
 if a and a.event.eventId==self.boxId then self.visuals.spawn:Stop(false) end
 self.boxId=nil
end
function Admin:Destroy()self.dead=true;self:Close();self.cleanup:Destroy()end
return Admin
