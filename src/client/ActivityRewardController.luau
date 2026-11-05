--!nonstrict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Actions=game:GetService("ContextActionService")
local Input=game:GetService("UserInputService")
local Gui=game:GetService("GuiService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Rewards=require(ReplicatedStorage.Shared.ActivityRewards)
local Catalog=require(ReplicatedStorage.Shared.CosmeticCatalog)
local Factory=require(ReplicatedStorage.World.VerityFactory)
local Cosmetics=require(ReplicatedStorage.World.CosmeticFactory)
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Locale=require(script.Parent.Locale)
local Controller={};Controller.__index=Controller
function Controller.new(ctx,boutique)
 local self=setmetatable({ctx=ctx,boutique=boutique,cleanup=Cleanup.new(),queue={},presented={},stars={},elapsed=0},Controller)
 local card=W.Round(W.Frame(ctx.refs.Safe,"ActivityReward",UDim2.fromOffset(360,410),T.Paper),22)
 card.AnchorPoint=Vector2.new(.5,.5);card.Position=UDim2.fromScale(.5,.5);card.Visible=false;card.Active=true;card.ZIndex=40
 self.card=card;self.cleanup:Add(card);W.Stroke(card,T.Gold,3).Transparency=.15
 self.scale=W.New("UIScale",{Scale=1},card)
 local heading=W.Text(card,"Heading","НОВАЯ НАГРАДА!",12,true,T.Purple);heading.Position=UDim2.fromOffset(16,12);heading.Size=UDim2.new(1,-78,0,20)
 self.title=W.Text(card,"AchievementTitle","",17,true,T.Ink);self.title.Position=UDim2.fromOffset(16,36);self.title.Size=UDim2.new(1,-32,0,30)
 self.closeButton=W.Button(card,"Close","×",T.Gold);self.closeButton.Position=UDim2.new(1,-52,0,8);self.closeButton.Size=UDim2.fromOffset(44,44)
 self.viewport=W.New("ViewportFrame",{Name="RewardPreview",BackgroundTransparency=1,Position=UDim2.fromOffset(12,70),Size=UDim2.new(1,-24,0,160),
  Ambient=Color3.fromRGB(210,210,210),LightColor=T.White,LightDirection=Vector3.new(-1,-1,-1)},card)
 local world=W.New("WorldModel",{},self.viewport)
 local camera=W.New("Camera",{CFrame=CFrame.lookAt(Vector3.new(0,1.2,-4.8),Vector3.new(0,1.05,0)),FieldOfView=40},self.viewport)
 self.viewport.CurrentCamera=camera
 self.preview=Factory.Create(world,CFrame.identity,{level=1,preview=true})
 local label=self.preview.PrimaryPart:FindFirstChild("LevelLabel");if label then label.Enabled=false end
 self.itemName=W.Text(card,"ItemName","",15,true,T.Purple);self.itemName.Size=UDim2.new(1,-32,0,30)
 self.proof=W.Text(card,"TrophyProof","Трофей уже на полке дома",12,false,T.Muted);self.proof.Size=UDim2.new(1,-32,0,22)
 self.equip=W.Button(card,"EquipReward","НАДЕТЬ",T.Mint);self.equip.Size=UDim2.new(1,-32,0,44)
 self.collection=W.Button(card,"Collection","ВСЕ НАГРАДЫ",T.Gold);self.collection.Size=UDim2.new(1,-32,0,44)
 for i=1,8 do
  local star=W.Text(card,"RewardStar","★",if i%2==0 then 22 else 15,true,if i%2==0 then T.Gold else T.Pink)
  star.AnchorPoint=Vector2.new(.5,.5);star.Size=UDim2.fromOffset(28,28);star.Visible=false;table.insert(self.stars,star)
 end
 for _,object in card:GetDescendants()do if object:IsA("GuiObject")then object.ZIndex=41 end end
 self.cleanup:Add(self.closeButton.Activated:Connect(function()self:Close()end))
 self.cleanup:Add(self.equip.Activated:Connect(function()
  if not self.current or self.pending or not self.equip.Interactable then return end
  self.pending=ctx.request("EquipCosmetic",{itemId=self.current.itemId,equipped=true})
 end))
 self.cleanup:Add(self.collection.Activated:Connect(function()
  local id=self.current and self.current.itemId;self:Close();ctx.open("COSMETICS")
  if id then boutique:Preview(id)end
 end))
 self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
  if self.pending and result.operationId==self.pending then
   self.pending=nil;if result.success then self:Close()end
  end
 end))
 self.cleanup:Add(ctx.net.StateChanged.Event:Connect(function(state)
  local owned=Rewards.Unlocked(state.CosmeticsOwned)
  if self.last then for _,id in Rewards.Order do if owned[id] and not self.last[id]then self:Enqueue(id)end end end
  self.last=owned
 end))
 self.cleanup:Add(ctx.net.Notification.Event:Connect(function(payload)
  if payload.code=="ACTIVITY_REWARD_UNLOCKED" then self:Enqueue(payload.achievementId)end
 end))
 if ctx.net.state then self.last=Rewards.Unlocked(ctx.net.state.CosmeticsOwned)end
 Actions:BindActionAtPriority("VerityRewardBack",function(_,state)
  if state==Enum.UserInputState.Begin and self.card.Visible and not ctx.active and not ctx.presenting and not Gui.MenuIsOpen and not Input:GetFocusedTextBox()then self:Close();return Enum.ContextActionResult.Sink end
  return Enum.ContextActionResult.Pass
 end,false,3100,Enum.KeyCode.ButtonB,Enum.KeyCode.Escape)
 self.cleanup:Add(function()Actions:UnbindAction("VerityRewardBack")end)
 self.cleanup:Add(RunService.Heartbeat:Connect(function(dt)
  self.elapsed+=dt;if self.elapsed<.1 then return end;self.elapsed=0;self:Tick()
 end))
 self.cleanup:Add(function()self:Close()end)
 return self
end
function Controller:Enqueue(id)
 if not Rewards.Items[id] or self.presented[id]then return end
 self.presented[id]=true;table.insert(self.queue,id)
end
function Controller:Close()
 self.card.Visible=false;self.current=nil;self.pending=nil
 self.ctx.animation:Cancel(self.scale)
 for _,star in self.stars do self.ctx.animation:Cancel(star);star.Visible=false end
 if Gui.SelectedObject and Gui.SelectedObject:IsDescendantOf(self.card)then Gui.SelectedObject=self.previousFocus end
end
function Controller:Tick()
 local ctx=self.ctx;local player=Players.LocalPlayer
 local char=player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 local blocked=ctx.active or ctx.presenting or Gui.MenuIsOpen or not hum or hum.Health<=0
  or player:GetAttribute("VerityParkourStep") or player:GetAttribute("VerityRaceSlot") or player:GetAttribute("VerityBattleActive")
 if not self.current and not blocked and #self.queue>0 then
  local reward=Rewards.Items[self.queue[1]];local state=ctx.net.state
  if not state or not (state.CosmeticsOwned or {})[reward.itemId]then return end
  table.remove(self.queue,1);self.current=reward
  Cosmetics.Apply(self.preview,{[Catalog.Items[reward.itemId].slot]=reward.itemId})
  Locale.Bind(self.title,reward.name);Locale.Bind(self.itemName,Catalog.Items[reward.itemId].name)
  self.scale.Scale=if ctx.settings.values.ReducedMotion then 1 else .9
  ctx.animation:Tween(self.scale,.3,{Scale=1})
  if not ctx.settings.values.ReducedEffects and not ctx.settings.values.LowGraphics and not ctx.settings.values.ReducedMotion then
   for i,star in self.stars do
    local angle=(i-1)*math.pi/4
    star.Visible=true;star.TextTransparency=0;star.Position=UDim2.fromScale(.5,.4)
    ctx.animation:Tween(star,.9,{Position=UDim2.new(.5,math.cos(angle)*130,.4,math.sin(angle)*80),TextTransparency=1})
   end
  end
  self.card.Visible=true
  if Input.PreferredInput==Enum.PreferredInput.Gamepad then self.previousFocus=Gui.SelectedObject;Gui.SelectedObject=self.equip end
 end
 self.card.Visible=self.current~=nil and not blocked
 if not self.card.Visible then return end
 local size=ctx.refs.Safe.AbsoluteSize;local height=math.min(410,size.Y-24)
 self.card.Size=UDim2.fromOffset(math.min(360,size.X-24),height)
 self.viewport.Visible=height>=300;self.viewport.Size=UDim2.new(1,-24,0,math.max(24,height-250))
 self.itemName.Position=UDim2.fromOffset(16,height-160);self.proof.Position=UDim2.fromOffset(16,height-130)
 self.equip.Position=UDim2.fromOffset(16,height-106);self.collection.Position=UDim2.fromOffset(16,height-54)
 local state=ctx.net.state;local owned=state and (state.CosmeticsOwned or {})[self.current.itemId]
 local busy=self.pending~=nil or ctx.net:IsBusy()
 W.SetButton(self.equip,if busy then Locale.Text("WAIT…")else Locale.Text("НАДЕТЬ"),owned==true and ctx.net.connected and not busy,busy)
end
function Controller:Destroy()self.cleanup:Destroy()end
return Controller
