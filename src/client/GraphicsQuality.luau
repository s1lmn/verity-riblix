--!nonstrict
-- Read Roblox's saved graphics setting. Never overwrite the user's engine setting.
local Run=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Gui=game:GetService("GuiService")
local Cleanup=require(script.Parent.Cleanup)
local Quality={};Quality.__index=Quality
local profiles={
 table.freeze({Tier=1,ParticleScale=0,EffectDistance=90,AbilityDistance=110,StandDistance=70,VFXInterval=1/20,AbilityInterval=1/20,
  RemoteInterval=.1,StudsNear=20,StudsFar=35,GlassNear=45,GlassFar=85,LightDistance=55,DecorationNear=65,DecorationFar=95,MaxAbilityEffects=8,CardDistance=28,Shadows=false}),
 table.freeze({Tier=2,ParticleScale=.5,EffectDistance=160,AbilityDistance=180,StandDistance=110,VFXInterval=1/30,AbilityInterval=1/30,
  RemoteInterval=1/30,StudsNear=45,StudsFar=65,GlassNear=80,GlassFar=140,LightDistance=110,DecorationNear=130,DecorationFar=190,MaxAbilityEffects=14,CardDistance=40,Shadows=true}),
 table.freeze({Tier=3,ParticleScale=1,EffectDistance=260,AbilityDistance=240,StandDistance=160,VFXInterval=0,AbilityInterval=1/30,
  RemoteInterval=0,StudsNear=65,StudsFar=90,GlassNear=100,GlassFar=200,LightDistance=300,DecorationNear=math.huge,DecorationFar=math.huge,MaxAbilityEffects=24,CardDistance=55,Shadows=true}),
}
function Quality.new(changed)
 local self=setmetatable({cleanup=Cleanup.new(),changed=changed,level=0,autoTier=2,focused=true,average=1/45,slow=0,fast=0,warmUntil=os.clock()+3},Quality)
 local ok,settings=pcall(function() return UserSettings():GetService("UserGameSettings") end)
 if ok then
  self.userSettings=settings
  local function read()
   local readOK,value=pcall(function() return settings.SavedQualityLevel.Value end)
   self.level=if readOK then value else 0
   self.autoTier=2;self:ResetSample();self:Apply()
  end
  self.cleanup:Add(settings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(read))
  read()
 else self:Apply() end
 self.cleanup:Add(Input.WindowFocusReleased:Connect(function() self.focused=false;self:ResetSample() end))
 self.cleanup:Add(Input.WindowFocused:Connect(function() self.focused=true;self:ResetSample() end))
 self.cleanup:Add(Run.RenderStepped:Connect(function(dt) self:Sample(dt) end))
 return self
end
function Quality:ResetSample()
 self.slow=0;self.fast=0;self.average=1/45;self.warmUntil=os.clock()+3
end
function Quality:Apply()
 local tier=if self.level==0 then self.autoTier elseif self.level<=3 then 1 elseif self.level<=7 then 2 else 3
 local profile=profiles[tier]
 if self.profile==profile then return end
 self.profile=profile;self.changed(profile)
end
function Quality:Sample(dt)
 if self.level~=0 or not self.focused or Gui.MenuIsOpen then return end
 if dt<=0 or dt>.25 then self.slow=0;self.fast=0;return end
 if os.clock()<self.warmUntil then return end
 self.average+=(dt-self.average)*(1-math.exp(-dt/3))
 local slowLimit=if self.autoTier==3 then 1/35 else 1/28
 local fastLimit=if self.autoTier==1 then 1/38 else 1/55
 self.slow=if self.average>slowLimit then self.slow+dt else 0
 self.fast=if self.average<fastLimit then self.fast+dt else 0
 if self.slow>=5 and self.autoTier>1 then
  self.autoTier-=1;self:ResetSample();self:Apply()
 elseif self.fast>=20 and self.autoTier<3 then
  self.autoTier+=1;self:ResetSample();self:Apply()
 end
end
function Quality:Destroy() self.cleanup:Destroy() end
return Quality
