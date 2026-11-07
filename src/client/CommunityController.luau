--!nonstrict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.CommunityConfig)
local Cleanup=require(script.Parent.Cleanup)
local Card=require(script.Parent.ActivityCard)
local Locale=require(script.Parent.Locale)
local Controller={};Controller.__index=Controller
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),prompts={},parts={}},Controller)
 self.card,self.title,self.detail,self.leave=Card.Build(ctx.refs.Safe,"CommunityStatus","LeaveCommunity")
 self.cleanup:Add(self.card)
 self.cleanup:Add(self.leave.Activated:Connect(function()
  if self.remote and self.message and self.message.joined then self.remote:FireServer("Leave",self.message.round) end
 end))
 local folder=Instance.new("Folder");folder.Name="CommunityPresentation";folder.Parent=workspace;self.folder=self.cleanup:Add(folder)
 local function part(name,size,color)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=Color3.fromHex(color);p.Shape=Enum.PartType.Ball
  p.Material=Enum.Material.Neon;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  p.Transparency=1;p.Parent=folder;return p
 end
 self.carry=part("CarriedEnergy",Vector3.one*.85,"83F6FC")
 for index=1,8 do self.parts[index]=part("CelebrationSpark",Vector3.one*.3,if index%2==0 then "FFE287" else "87F7D3") end
 local function attach(remote)
  if not remote or remote.Name~="VerityCommunity" or not remote:IsA("RemoteEvent") or self.remote==remote then return end
  if self.remoteLink then self.remoteLink:Disconnect() end
  self.remote=remote
  self.remoteLink=remote.OnClientEvent:Connect(function(message)
   if type(message)~="table" or message.version~=C.Version or self.message and message.round<self.message.round then return end
   local previous=self.message;self.message=message
   if message.joined and (not previous or not previous.joined) then ctx.close() end
   if previous and message.round==previous.round and message.contribution>previous.contribution then ctx.sound:Play("TaskCheckpoint") end
   self:Render()
  end)
  remote:FireServer("Sync",0)
 end
 self.cleanup:Add(RS.ChildAdded:Connect(attach))
 self.cleanup:Add(RS.ChildRemoved:Connect(function(remote)
  if self.remote==remote then
   self.remote=nil;self.message=nil
   if self.remoteLink then self.remoteLink:Disconnect();self.remoteLink=nil end
   self:Render()
  end
 end))
 self.cleanup:Add(function() if self.remoteLink then self.remoteLink:Disconnect() end end)
 attach(RS:FindFirstChild("VerityCommunity"))
 return self
end
function Controller:Model()
 local world=workspace:FindFirstChild("GeneratedWorld")
 return world and world:FindFirstChild("NeighborhoodLight")
end
function Controller:Goal()
 local m=self.message;local model=self:Model()
 if not m or not m.joined or m.phase~="Charging" then return nil end
 local target=model and model:FindFirstChild((if m.carrying then "Station" else "Cell")..(if m.carrying then m.station else m.node))
 local position=if target then target.Position else m.targetPosition
 if typeof(position)~="Vector3" then return nil end
 return {id="community:"..m.round..":"..m.contribution..":"..tostring(m.carrying)..":"..m.station..":"..m.node,
  kind="World",target="Community",object=target,position=position,
  title=if m.carrying then C.StationNames[m.station] else "Возьми энергоячейку",
  detail="",near=if m.carrying then "%s · Передать энергию" else "%s · Взять энергию",
  touch=if m.carrying then "Передать энергию" else "Взять энергию",prompt=true,radius=6}
end
function Controller:Render()
 local message=self.message
 self.card.Visible=message~=nil and message.joined and not Card.Blocked(self.ctx) or false
 if message and message.joined then
  Card.Layout(self.card,self.title,self.detail,self.ctx.refs.Safe.AbsoluteSize)
  local total,goal=0,0;for i=1,3 do total+=message.delivered[i];goal+=message.goals[i] end
  self.title.Text=string.format(Locale.Text("СВЕТ РАЙОНА • %dс"),math.max(0,math.ceil(message.deadline-workspace:GetServerTimeNow())))
  self.detail.Text=string.format(Locale.Text("Энергия %d/%d • твой вклад %d/2"),total,goal,message.contribution)
 end
 local model=self:Model();if not model then return end
 local joined=message and message.joined
 for _,child in model:GetChildren() do
  local prompt=child:FindFirstChild("Interact")
  if not prompt then continue end
  if self.prompts[prompt]==nil then self.prompts[prompt]=prompt.Enabled end
  local enabled=false
  if child.Name=="Join" then enabled=not joined and message and message.joinable and not Card.ActivityRunning()
  elseif joined then
   enabled=child.Name==(if message.carrying then "Station"..message.station else "Cell"..message.node)
  end
  prompt.Enabled=enabled==true
 end
end
function Controller:VisualTick(now)
 self.carry.Transparency=1
 for _,p in self.parts do p.Transparency=1 end
 local message=self.message;if not message then return end
 local player=Players.LocalPlayer;local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 local hidden=Card.Blocked(self.ctx) or not root or not hum or hum.Health<=0
 if message.joined and message.carrying and not hidden then
  self.carry.CFrame=root.CFrame*CFrame.new(-1.2,.1,-1.2)
  local camera=workspace.CurrentCamera
  self.carry.Transparency=if camera and (camera.CFrame.Position-camera.Focus.Position).Magnitude<1 then 1 else .05
 end
 if message.phase~="Celebrating" or hidden or self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics then return end
 local model=self:Model();local center=model and model:FindFirstChild("Station3")
 if not center or (root.Position-center.Position).Magnitude>90 then return end
 for index,p in self.parts do
  local angle=index*math.pi/4+(if self.ctx.settings.values.ReducedMotion then 0 else now*.7)
  p.Position=center.Position+Vector3.new(math.cos(angle)*4,3+math.sin(angle*2)*.8,math.sin(angle)*4)
  p.Transparency=.15
 end
end
function Controller:Destroy()
 for prompt,enabled in self.prompts do if prompt.Parent then prompt.Enabled=enabled end end
 self.cleanup:Destroy()
end
return Controller
