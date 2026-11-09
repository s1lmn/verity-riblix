--!nonstrict
-- Local rendering only: no collision, save, physics or server ownership changes.
local Run=game:GetService("RunService")
local Lighting=game:GetService("Lighting")
local Cleanup=require(script.Parent.Cleanup)
local Controller={};Controller.__index=Controller
local function decoration(p)
 local parent=p.Parent
 if p:GetAttribute("PremiumDecoration")==true then return true end
 return not p.CanCollide and p:FindFirstAncestor("Environment") and parent
  and (parent.Name:find("Tree") or parent.Name:find("Bush")) and (p.Name=="Crown" or p.Name=="Top" or p.Name:find("Leaf"))
end
function Controller.new(settings)
 local self=setmetatable({settings=settings,cleanup=Cleanup.new(),parts={},decorations={},lights={},particles={},shadow=Lighting.GlobalShadows,nextAt=0},Controller)
 local function add(object)
  if not object:FindFirstAncestor("GeneratedWorld") then return end
  if object:IsA("BasePart") and not self.parts[object] then
   local r={shadow=object.CastShadow,decor=decoration(object),alpha=object.LocalTransparencyModifier}
   self.parts[object]=r
   if r.decor then self.decorations[object]=r end
   local profile=settings.values.Graphics
   object.CastShadow=r.shadow and (not profile or profile.Shadows)
  elseif object:IsA("ParticleEmitter") and type(object:GetAttribute("PremiumRate"))=="number" then
   self.particles[object]=object:GetAttribute("PremiumRate")
  elseif object:IsA("Light") and not self.lights[object] then
   self.lights[object]={brightness=object.Brightness,shadows=object.Shadows}
  end
 end
 local function remove(object)
  local r=self.parts[object]
  if r then
   object.CastShadow=r.shadow
   if r.decor then object.LocalTransparencyModifier=r.alpha end
   self.parts[object]=nil;self.decorations[object]=nil
  end
  if self.particles[object] then object.Rate=0;object:Clear();self.particles[object]=nil end
  local light=self.lights[object]
  if light then object.Brightness=light.brightness;object.Shadows=light.shadows;self.lights[object]=nil end
 end
 self.cleanup:Add(workspace.DescendantAdded:Connect(add))
 self.cleanup:Add(workspace.DescendantRemoving:Connect(remove))
 local world=workspace:FindFirstChild("GeneratedWorld")
 if world then for _,object in world:GetDescendants() do add(object) end end
 self.cleanup:Add(settings.Changed.Event:Connect(function() self.profile=nil;self.nextAt=0;self:Tick() end))
 self.cleanup:Add(Run.Heartbeat:Connect(function() self:Tick() end))
 self:Tick()
 return self
end
function Controller:Tick()
 local now=os.clock();if now<self.nextAt then return end;self.nextAt=now+.25
 local profile=self.settings.values.Graphics;if not profile then return end
 if self.profile~=profile then
  self.profile=profile
  for p,r in self.parts do p.CastShadow=r.shadow and profile.Shadows end
 end
 local shadows=self.shadow and profile.Shadows
 if Lighting.GlobalShadows~=shadows then Lighting.GlobalShadows=shadows end
 local camera=workspace.CurrentCamera;if not camera then return end
 for p,r in self.decorations do
  local distance=(p.Position-camera.CFrame.Position).Magnitude
  local fade=if profile.Tier==3 then 0 else math.clamp((distance-profile.DecorationNear)/(profile.DecorationFar-profile.DecorationNear),0,1)
  local alpha=r.alpha+(1-r.alpha)*fade
  if math.abs(p.LocalTransparencyModifier-alpha)>.005 then p.LocalTransparencyModifier=alpha end
 end
 for emitter,baseRate in self.particles do
  local parent=emitter.Parent
  local near=parent and parent:IsA("BasePart") and (parent.Position-camera.CFrame.Position).Magnitude<profile.EffectDistance
  local rate=if near and not self.settings.values.ReducedEffects then baseRate*profile.ParticleScale else 0
  if emitter.Rate~=rate then emitter.Rate=rate;if rate==0 then emitter:Clear() end end
 end
 for light,r in self.lights do
  local parent=light.Parent
  local position=if parent and parent:IsA("BasePart") then parent.Position elseif parent and parent:IsA("Attachment") then parent.WorldPosition else nil
  local near=not position or (position-camera.CFrame.Position).Magnitude<profile.LightDistance
  local brightness=if near then r.brightness else 0
  if light.Brightness~=brightness then light.Brightness=brightness end
  local cast=r.shadows and profile.Tier==3
  if light.Shadows~=cast then light.Shadows=cast end
 end
end
function Controller:Destroy()
 self.cleanup:Destroy();Lighting.GlobalShadows=self.shadow
 for p,r in self.parts do if p.Parent then p.CastShadow=r.shadow;if r.decor then p.LocalTransparencyModifier=r.alpha end end end
 for light,r in self.lights do if light.Parent then light.Brightness=r.brightness;light.Shadows=r.shadows end end
 for emitter in self.particles do if emitter.Parent then emitter.Rate=0;emitter:Clear() end end
 table.clear(self.parts);table.clear(self.decorations);table.clear(self.lights);table.clear(self.particles)
end
return Controller
