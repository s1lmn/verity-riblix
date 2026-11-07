--!nonstrict
-- Presentation only. AbilityService remains the sole owner of movement and ride eligibility.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Shared=game:GetService("ReplicatedStorage").Shared
local Skins=require(Shared.VerityElementalSkins)
local Cleanup=require(script.Parent.Cleanup)
local Presentation={};Presentation.__index=Presentation
local angles={LeftHip=-68,RightHip=-68,LeftKnee=92,RightKnee=92,Waist=-9,["Left Hip"]=-68,["Right Hip"]=-68}
local function release(record)
 for _,joint in record.joints do
  if joint.motor.Parent and joint.motor.C0==joint.last then joint.motor.C0=joint.base end
 end
 record.cleanup:Destroy()
end
function Presentation.new(ctx,companions)
 local self=setmetatable({ctx=ctx,companions=companions,records={},seen={},cleanup=Cleanup.new()},Presentation)
 self.cleanup:Add(RunService.PreSimulation:Connect(function(dt) self:Tick(math.min(dt,.1)) end))
 return self
end
function Presentation:Record(player,character,root)
 local record={character=character,root=root,joints={},cleanup=Cleanup.new(),blend=0}
 for _,motor in character:GetDescendants() do
  if motor:IsA("Motor6D") and angles[motor.Name] then
   table.insert(record.joints,{motor=motor,base=motor.C0,last=motor.C0,angle=math.rad(angles[motor.Name])})
  end
 end
 local origin=Instance.new("Attachment");origin.Name="VerityRideSparkles";origin.Position=Vector3.new(0,-2,0);origin.Parent=root
 record.cleanup:Add(origin)
 local a=Instance.new("Attachment");a.Name="VerityRideRibbonLeft";a.Position=Vector3.new(-.8,-1.7,0);a.Parent=root;record.cleanup:Add(a)
 local b=Instance.new("Attachment");b.Name="VerityRideRibbonRight";b.Position=Vector3.new(.8,-1.7,0);b.Parent=root;record.cleanup:Add(b)
 local emitter=Instance.new("ParticleEmitter");emitter.Name="RideStars";emitter.Texture="rbxasset://textures/particles/sparkles_main.dds"
 emitter.Rate=14;emitter.Lifetime=NumberRange.new(.35,.65);emitter.Speed=NumberRange.new(3,7)
 emitter.SpreadAngle=Vector2.new(65,65);emitter.Drag=3;emitter.LightEmission=.8
 emitter.Rotation=NumberRange.new(-180,180);emitter.RotSpeed=NumberRange.new(-80,80)
 emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.45),NumberSequenceKeypoint.new(.3,.6),NumberSequenceKeypoint.new(1,0)})
 emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.7,.3),NumberSequenceKeypoint.new(1,1)})
 emitter.Enabled=false;emitter.Parent=origin;record.emitter=emitter
 local trail=Instance.new("Trail");trail.Name="RideRibbon";trail.Attachment0=a;trail.Attachment1=b;trail.Lifetime=.28
 trail.LightEmission=.7;trail.FaceCamera=true;trail.MinLength=.15
 trail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(1,1)})
 trail.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
 trail.Enabled=false;trail.Parent=origin;record.trail=trail
 local light=Instance.new("PointLight");light.Range=9;light.Brightness=.35;light.Shadows=false;light.Enabled=false;light.Parent=origin;record.light=light
 self.records[player]=record
 return record
end
function Presentation:Tick(dt)
 local camera=workspace.CurrentCamera
 local effects=(self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics)
 local graphics=self.ctx.settings.values.Graphics
 local reducedMotion=self.ctx.settings.values.ReducedMotion
 local seen=self.seen;table.clear(seen)
 for _,player in Players:GetPlayers() do
  local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  local nearby=root and camera and (root.Position-camera.CFrame.Position).Magnitude<(graphics and graphics.EffectDistance or 160)
  local fused=player:GetAttribute("VerityFusionActive")==true
  local riding=root and hum and hum.Health>0 and nearby and (fused or player:GetAttribute("VerityRiding")==true)
  local muted=effects or fused
  local record=self.records[player]
  if record and (record.character~=char or not root or not nearby or not hum or hum.Health<=0) then
   release(record);self.records[player]=nil;record=nil
  end
  if riding and not record then record=self:Record(player,char,root) end
  if not record then continue end
  seen[player]=true
  local phase=player:GetAttribute("VerityRidePhase")
  local target=if riding and phase~="Landing" then 1 else 0
  record.blend+=(target-record.blend)*(1-math.exp(-9*dt))
  for _,joint in record.joints do
   local motor=joint.motor
   if not motor.Parent then continue end
   -- Preserve a new base if another feature deliberately edits the joint.
   if motor.C0~=joint.last then joint.base=motor.C0 end
   local pose=CFrame.new(joint.base.Position)*CFrame.Angles(joint.angle*record.blend,0,0)*joint.base.Rotation
   motor.C0=pose;joint.last=pose
  end
  local model=self.companions[player.UserId]
  local level=model and model:GetAttribute("VerityLevel") or 50
  local skin=Skins.Get(level)
  local color=Color3.fromHex(skin and skin.Hex or "FFC338")
  if record.color~=color then
   record.color=color;record.emitter.Color=ColorSequence.new(color,Color3.new(1,1,1));record.trail.Color=ColorSequence.new(color);record.light.Color=color
  end
  local moving=root.AssemblyLinearVelocity.Magnitude>5
  record.emitter.Enabled=riding and not muted and (moving or phase=="Takeoff")
  record.trail.Enabled=riding and moving and phase=="Cruise" and not muted and not reducedMotion
  record.light.Enabled=riding and not muted
  if muted and not record.effectsMuted then record.emitter:Clear();record.trail:Clear() end
  record.effectsMuted=muted
  if phase~=record.phase then
   if not muted and riding and (record.phase or phase=="Takeoff") then
    record.emitter:Emit(if phase=="Takeoff" then 24 elseif phase=="Landing" then 18 else 10)
   end
   record.phase=phase
  end
  if not riding and record.blend<.005 then release(record);self.records[player]=nil end
 end
 for player,record in self.records do if not seen[player] then release(record);self.records[player]=nil end end
end
function Presentation:Destroy()
 self.cleanup:Destroy();table.clear(self.seen)
 for player,record in self.records do release(record);self.records[player]=nil end
end
return Presentation
