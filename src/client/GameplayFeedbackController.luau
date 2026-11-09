--!nonstrict
-- Presentation only. Server targets/collisions, task completion and navigation stay unchanged.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Profile=require(Shared.GameplayFeedbackProfile)
local Cleanup=require(script.Parent.Cleanup)
local Feedback={};Feedback.__index=Feedback
local gold=Color3.fromHex("FFD84B")
local pink=Color3.fromHex("FF65B9")
local mint=Color3.fromHex("79F5BE")
local colors={gold,pink,Color3.fromHex("6FE5FF"),Color3.fromHex("BB83FF")}
local function part(parent,name,size,color)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=color
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=Enum.Material.Neon;p.Transparency=1;p.Parent=parent;return p
end
local function root()
 local char=Players.LocalPlayer.Character
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 return if hum and hum.Health>0 then char:FindFirstChild("HumanoidRootPart") else nil
end
function Feedback.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),tasks={},highlights={},pulses={},seen={},order={},bursts={}},Feedback)
 local folder=Instance.new("Folder");folder.Name="VerityGameplayFeedback";folder.Parent=workspace
 self.folder=self.cleanup:Add(folder)
 for slot=1,Profile.MaxBursts do
  local burst={stars={},ring={}}
  for i=1,Profile.Stars do
   local a=part(folder,"RewardStar",Vector3.new(.09,.36,.07),colors[(i-1)%4+1])
   local b=part(folder,"RewardStar",Vector3.new(.36,.09,.07),a.Color)
   table.insert(burst.stars,{a,b})
  end
  for _=1,Profile.Segments do table.insert(burst.ring,part(folder,"RewardRing",Vector3.new(.08,.06,.5),gold)) end
  self.bursts[slot]=burst
 end
 self.cleanup:Add(ctx.net.StateChanged.Event:Connect(function(state) self:State(state) end))
 self.cleanup:Add(ctx.net.Notification.Event:Connect(function(payload)
  if payload.code~="TASK_REWARD" or type(payload.eventId)~="string" or self.seen[payload.eventId] then return end
  self.seen[payload.eventId]=true;table.insert(self.order,payload.eventId)
  if #self.order>256 then self.seen[table.remove(self.order,1)]=nil end
  local r=root();if r then self:Burst(r.Position+Vector3.new(0,.5,0),os.clock()) end
 end))
 -- Connected before GameplayAudioController: release the arrival proxy before opening the gift.
 self.cleanup:Add(ctx.net.World.Event:Connect(function(event)
  if event.ownerUserId==Players.LocalPlayer.UserId and (event.kind=="BoxOpened" or event.kind=="VeritySpawned" or event.kind=="PlotReleased") then self:StopArrival() end
 end))
 self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function() self:Reset() end))
 self.cleanup:Add(ctx.settings.Changed.Event:Connect(function() self:Reset() end))
 self.cleanup:Add(Run.RenderStepped:Connect(function() self:Tick(os.clock()) end))
 return self
end
function Feedback:HideBurst(burst)
 for _,star in burst.stars do for _,p in star do p.Transparency=1 end end
 for _,p in burst.ring do p.Transparency=1 end
 burst.started=nil
end
function Feedback:Burst(position,now)
 if now-(self.lastBurst or -math.huge)<Profile.BurstCooldown then return end
 if (self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics) or self.ctx.sound:IsCelebrating() or not root() then return end
 self.lastBurst=now
 local slot=self.bursts[1]
 for _,candidate in self.bursts do
  if not candidate.started then slot=candidate;break end
  if candidate.started<slot.started then slot=candidate end
 end
 slot.position,slot.started=position,now
end
function Feedback:StopArrival()
 local a=self.arrival;if not a then return end
 self.arrival=nil
 if a.source.Parent then a.source.LocalTransparencyModifier=a.visibility end
 a.folder:Destroy()
end
function Feedback:Arrival(state,now)
 self:StopArrival()
 if self.ctx.settings.values.ReducedMotion or (self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics) then return end
 local plots=workspace:FindFirstChild("CorePlots")
 local plot=plots and type(state.PlotId)=="number" and plots:FindFirstChild(string.format("Plot_%02d",state.PlotId))
 local source=plot and plot:FindFirstChild("CoreDeliveryBox")
 local r=root()
 if not source or not source:IsA("BasePart") or not r or (r.Position-source.Position).Magnitude>70 then return end
 local folder=Instance.new("Folder");folder.Name="ParcelArrival";folder.Parent=self.folder
 local body=part(folder,"Gift",source.Size,gold);body.Material=Enum.Material.SmoothPlastic;body.Transparency=0
 local ribbon=part(folder,"Ribbon",Vector3.new(.45,source.Size.Y+.025,source.Size.Z+.025),pink)
 ribbon.Material=Enum.Material.SmoothPlastic;ribbon.Transparency=0
 self.arrival={source=source,visibility=source.LocalTransparencyModifier,origin=source.CFrame,started=now,folder=folder,body=body,ribbon=ribbon}
 source.LocalTransparencyModifier=1
 self:TickArrival(now)
end
function Feedback:TickArrival(now)
 local a=self.arrival;if not a then return end
 local age=now-a.started
 if age>=Profile.ArrivalDuration or not a.source.Parent or not root() then self:StopArrival();return end
 local fall=Profile.Smooth(age/.45)
 local settle=if age>.45 then math.sin((age-.45)*math.pi*6)*math.exp(-(age-.45)*9)*.25 else 0
 local cf=a.origin+Vector3.new(0,(1-fall)*4+settle,0)
 a.body.CFrame=cf;a.ribbon.CFrame=cf
 a.ribbon.Transparency=Profile.Smooth((age-.55)/.3)
end
function Feedback:State(state)
 local changes=Profile.Transitions(self.previous,state)
 if self.previous and self.previous.PlotId~=state.PlotId then self:Reset() end
 self.tasks={}
 for _,entry in state.Tasks or {} do self.tasks[entry.taskId]=entry end
 local now=os.clock()
 if self.previous then
  local before={}
  for _,old in self.previous.Tasks or {} do before[old.taskId]=old end
  for id,entry in self.tasks do
   local old=before[id]
   if old and old.status=="Active" and entry.status=="Active" and (entry.step or 1)>(old.step or 1) then
    if typeof(old.targetPosition)=="Vector3" then self:Burst(old.targetPosition+Vector3.new(0,1,0),now) end
    self.ctx.sound:Play("TaskCheckpoint")
   end
  end
 end
 for _,id in changes.completed do
  self.pulses[id]=now
  -- Narrative jobs use restored props instead of the old button depression.
 end
 if changes.delivery then
  self:Arrival(state,now)
  if typeof(state.DeliveryPosition)=="Vector3" then self:Burst(state.DeliveryPosition+Vector3.new(0,.2,0),now) end
 end
 -- Keep the full confirmed snapshot; UIModel already clones per-task records.
 self.previous=state
end
function Feedback:TaskHighlights(now)
 local folder=workspace:FindFirstChild("GameplayInteractions")
 local r=root()
 for id,entry in self.tasks do
  local target=folder and folder:FindFirstChild(id..":"..tostring(entry.step or 1))
  local pulse=self.pulses[id]
  local active=entry.status=="Active"
  local near=r and target and target:IsA("BasePart") and (r.Position-target.Position).Magnitude<55
  local visible=near and not (self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics) and (active or pulse and now-pulse<.65)
  local glow=self.highlights[id]
  if not glow and visible then
   glow=Instance.new("Highlight");glow.Name="TaskFeedback_"..id
   glow.DepthMode=Enum.HighlightDepthMode.Occluded;glow.Parent=self.folder;self.highlights[id]=glow
  end
  if glow then
   glow.Enabled=visible==true;glow.Adornee=target
   glow.FillColor=if pulse and now-pulse<.65 then gold else mint
   glow.OutlineColor=glow.FillColor
   local strength=if pulse and now-pulse<.65 then 1-Profile.Smooth((now-pulse)/.65) else .18
   glow.FillTransparency=1-.28*strength;glow.OutlineTransparency=1-.65*strength
  end
  if pulse and now-pulse>=.65 then self.pulses[id]=nil end
 end
end
function Feedback:Tick(now)
 if self.ctx.shop then self.ctx.shop:Step(now) end
 if self.ctx.upgradeAttention then self.ctx.upgradeAttention:Tick(now) end
 if self.ctx.community then self.ctx.community:VisualTick(now) end
 if self.ctx.adventures then self.ctx.adventures:VisualTick(now,now-(self.arcadeFrame or now)) end
 if self.ctx.arcade then self.ctx.arcade:VisualTick(now,now-(self.arcadeFrame or now)) end
 if self.ctx.forge then self.ctx.forge:VisualTick(now,now-(self.arcadeFrame or now)) end
 self.arcadeFrame=now
 self:TickArrival(now)
 if now>=(self.highlightAt or 0) then self.highlightAt=now+.1;self:TaskHighlights(now) end
 local reduced=self.ctx.settings.values.ReducedMotion
 local muted=(self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics) or self.ctx.sound:IsCelebrating() or not root()
 local camera=workspace.CurrentCamera
 for _,burst in self.bursts do
  if not burst.started then continue end
  local pose=Profile.Burst(now-burst.started,reduced)
  if pose.done or muted then self:HideBurst(burst);continue end
  for i,p in burst.ring do
   local angle=i*math.pi*2/Profile.Segments
   p.CFrame=CFrame.new(burst.position+Vector3.new(math.cos(angle)*pose.radius,-.4,math.sin(angle)*pose.radius))*CFrame.Angles(0,-angle,0)
   p.Size=Vector3.new(.09,.06,2*pose.radius*math.sin(math.pi/Profile.Segments)*1.04)
   p.Transparency=1-.48*pose.alpha
  end
  for i,star in burst.stars do
   local angle=i*2.4
   local pos=burst.position+Vector3.new(math.cos(angle)*pose.radius*.7,pose.height+(i%3)*.35,math.sin(angle)*pose.radius*.7)
   local cf=if camera then CFrame.lookAt(pos,camera.CFrame.Position) else CFrame.new(pos)
   for _,p in star do
    p.CFrame=cf*CFrame.Angles(0,0,if reduced then 0 else (now-burst.started)*2+i)
    p.Transparency=1-pose.alpha
   end
  end
 end
end
function Feedback:Reset()
 self:StopArrival();table.clear(self.pulses)
 for _,burst in self.bursts do self:HideBurst(burst) end
 for _,glow in self.highlights do glow.Enabled=false end
end
function Feedback:Destroy() self:Reset();self.cleanup:Destroy() end

return Feedback
