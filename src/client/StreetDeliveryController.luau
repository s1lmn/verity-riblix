--!nonstrict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Config=require(ReplicatedStorage.Shared.StreetDeliveryConfig)
local Factory=require(ReplicatedStorage.World.StreetDeliveryFactory)
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local Controller={};Controller.__index=Controller
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new()},Controller)
 self.folder=Instance.new("Folder");self.folder.Name="StreetDeliveryVisuals";self.folder.Parent=workspace;self.cleanup:Add(self.folder)
 self.metadata=workspace:FindFirstChild("VerityStreetDelivery")
 self.cleanup:Add(workspace.ChildAdded:Connect(function(child)if child.Name=="VerityStreetDelivery" then self.metadata=child end end))
 self.cleanup:Add(workspace.ChildRemoved:Connect(function(child)if child==self.metadata then self.metadata=nil;self:ClearRound()end end))
 self.cleanup:Add(RunService.RenderStepped:Connect(function()self:Tick()end))
 return self
end
function Controller:ClearRound()
 if not self.round then return end
 self.truck:Destroy();self.parcel:Destroy();self.burst:Destroy()
 self.round=nil;self.won=nil;self.lastLabel=nil
end
function Controller:BuildRound(cycle,started)
 self:ClearRound();self.round=Config.Round(cycle,started)
 self.truck,self.wheels=Factory.Truck(self.folder,self.round.color)
 self.parcel,self.label=Factory.Parcel(self.folder)
 self.glow=Instance.new("Highlight");self.glow.Adornee=self.parcel;self.glow.FillTransparency=.88;self.glow.OutlineTransparency=.15
 self.glow.FillColor=Color3.fromHex("FFCE45");self.glow.OutlineColor=Color3.fromHex("FFF0CE");self.glow.DepthMode=Enum.HighlightDepthMode.Occluded;self.glow.Parent=self.parcel
 local burst=Instance.new("Part");burst.Name="PickupStars";burst.Anchored=true;burst.CanCollide=false;burst.CanQuery=false;burst.CanTouch=false;burst.Transparency=1
 burst.Size=Vector3.one*.1;burst.Position=Vector3.new(self.round.x,Config.ParcelY,self.round.z);burst.Parent=self.folder;self.burst=burst
 local emitter=Instance.new("ParticleEmitter");emitter.Texture="rbxasset://textures/particles/sparkles_main.dds";emitter.Rate=0
 emitter.Lifetime=NumberRange.new(.35,.75);emitter.Speed=NumberRange.new(3,7);emitter.SpreadAngle=Vector2.new(180,180)
 emitter.Color=ColorSequence.new(Color3.fromHex("FFCE45"),Color3.fromHex("FF81BE"));emitter.LightEmission=.8
 emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,0)});emitter.Parent=burst;self.emitter=emitter
end
function Controller:Tick()
 local metadata=self.metadata
 if not metadata or metadata:GetAttribute("Phase")=="Idle" then self:ClearRound();return end
 local cycle,started=metadata:GetAttribute("Cycle"),metadata:GetAttribute("StartedAt")
 if type(cycle)~="number" or cycle<1 or cycle%1~=0 or type(started)~="number" then return end
 if not self.round or self.round.cycle~=cycle or self.round.started~=started then self:BuildRound(cycle,started) end
 local now=workspace:GetServerTimeNow();local round=self.round;local pose=Config.Sample(round,now)
 local reduced=self.ctx.settings.values.ReducedMotion;local effects=(self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics)
 self.truck.Parent=if pose.truckVisible then self.folder else nil
 if pose.truckVisible then
  local frame=CFrame.new(Config.RoadX,.18,pose.truckZ)*CFrame.Angles(0,math.pi,0)
  self.truck:PivotTo(frame)
  if not reduced then
   local spin=CFrame.Angles(-(pose.truckZ-Config.StartZ)/1.5,0,0)
   for _,wheel in self.wheels do wheel.tire.CFrame=frame*wheel.tireCF*spin;wheel.hub.CFrame=frame*wheel.hubCF*spin end
  end
 end
 local winner=metadata:GetAttribute("WinnerUserId")
 if winner~=nil and not self.won then self.won=true;if not effects then self.emitter:Emit(22)end end
 if effects then self.emitter:Clear() end
 self.parcel.Parent=if pose.parcelVisible and not self.won then self.folder else nil
 if pose.parcelVisible and not self.won then
  local t=pose.toss
  local from=Vector3.new(Config.RoadX,5.3,round.z)
  local to=Vector3.new(round.x,Config.ParcelY,round.z)
  local position=from:Lerp(to,t)+Vector3.new(0,math.sin(t*math.pi)*5,0)
  local yaw=if reduced then 0 else t*math.pi+math.max(0,now-round.readyAt)*.5
  if pose.ready and not reduced then position+=Vector3.new(0,math.sin((now-round.readyAt)*3)*.12,0)end
  self.parcel:PivotTo(CFrame.new(position)*CFrame.Angles(0,yaw,if reduced then 0 else math.sin(t*math.pi)*.35))
  self.glow.Enabled=not effects and pose.ready
  if pose.remaining~=self.lastLabel then
   self.lastLabel=pose.remaining;self.label.Text=string.format(Locale.Text("ПОСЫЛКА! • %d с"),pose.remaining)
  end
 end
end
function Controller:Destroy()self.cleanup:Destroy();self:ClearRound()end
return Controller
