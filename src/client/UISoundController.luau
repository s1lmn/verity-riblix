--!nonstrict
-- Client feedback only; confirmed upgrade events share one bounded audio channel.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local Cleanup = require(script.Parent.Cleanup)
local Config = require(ReplicatedStorage:WaitForChild("World"):WaitForChild("AudioConfig"))
local Profile = require(ReplicatedStorage.Shared.VerityAnimationProfile)
local Audio = {}
Audio.__index = Audio

function Audio.new(settings)
 local self = setmetatable({settings=settings, cleanup=Cleanup.new(), sounds={}, last={}, seen={}, order={}, generation=0, channels={}, lastEmotion=-math.huge, emotionCount=0}, Audio)
 local group = Instance.new("SoundGroup")
 group.Name, group.Volume, group.Parent = "VerityUISounds", if settings.values.UISounds then settings.values.Volume else 0, SoundService
 self.group = self.cleanup:Add(group)
 for name,entry in Config.UI do
  local sound=Instance.new("Sound")
  sound.Name, sound.SoundId="UI_"..name, entry.SoundId
  sound.SoundGroup, sound.Volume=group, math.clamp(entry.Volume,0,1)
  sound.Looped=entry.Looped==true
  if entry.Looped then sound.Volume=0 end
  sound.Parent=SoundService
  self.sounds[name]=self.cleanup:Add(sound)
 end
 local wind=self.sounds.GardenBreeze
 if wind then
  self.windSpeed=wind.PlaybackSpeed
  self.windEQ=Instance.new("EqualizerSoundEffect");self.windEQ.Name="StormWindTone";self.windEQ.Enabled=false;self.windEQ.Parent=wind
 end
 self.cleanup:Add(settings.Changed.Event:Connect(function(values)
  group.Volume=if values.UISounds then values.Volume else 0
  if not values.UISounds or values.Volume<=0 then
   self:StopUpgrade();self.celebrationUntil=0;self.featureUntil=0
   for _,sound in self.sounds do sound:Stop() end
  else self:StartAmbience() end
 end))
 -- Preload away from input/startup; denied or unmoderated assets never block gameplay.
 local sounds={};for _,sound in self.sounds do table.insert(sounds,sound) end
 task.spawn(function()
  local ok,err=pcall(function() ContentProvider:PreloadAsync(sounds) end)
  if not ok and not self.dead then warn("Verity audio preload unavailable: "..tostring(err)) end
  if not self.dead then self:StartAmbience() end
 end)
 return self
end

function Audio:Play(name)
 if self.dead or not self.settings.values.UISounds or self.settings.values.Volume<=0 then return end
 local sound=self.sounds[name]
 local entry=Config.UI[name]
 if not sound or os.clock()-(self.last[name] or -math.huge)<(entry.Cooldown or .12) then return end
 self.last[name]=os.clock()
 if entry.Category=="Celebration" then
  self.celebrationUntil=os.clock()+(entry.Duration or 3)
  if self.channels.Emotion then self.channels.Emotion:Stop() end
 end
 if entry.Channel=="Feature" then
  self.featureUntil=os.clock()+(entry.Duration or 1)
  if self.channels.Emotion then self.channels.Emotion:Stop() end
 end
 if entry.Channel and entry.Channel~="Ambience" then
  local previous=self.channels[entry.Channel]
  if previous and previous~=sound then previous:Stop() end
  self.channels[entry.Channel]=sound
 end
 -- One reusable voice per cue: rapid swipes/rewards cannot pile up instances.
 self:Tick(os.clock(),.12)
 sound:Stop();sound:Play()
 return true
end

function Audio:Stop(name)
 local sound=self.sounds[name];if sound then sound:Stop() end
 if sound and self.channels.Celebration==sound then self.celebrationUntil=0 end
 if sound and self.channels.Feature==sound then self.featureUntil=0 end
end

function Audio:StopUpgrade(eventId)
 if eventId and self.upgradeId~=eventId then return end
 self.generation+=1
 self.upgradeId=nil
 self.upgradeUntil=0
 if self.upgradeCue then self:Stop(self.upgradeCue);self.upgradeCue=nil end
 self.sounds.GrowthBubble:Stop()
end

function Audio:PlayUpgrade(event, withBubble)
 if self.dead or self.seen[event.eventId] then return end
 self.seen[event.eventId]=true;table.insert(self.order,event.eventId)
 if #self.order>256 then self.seen[table.remove(self.order,1)]=nil end
 self:StopUpgrade()
 self.upgradeId=event.eventId
 self.upgradeCue=Config.UpgradeCue(event.newLevel)
 self.upgradeUntil=os.clock()+4
 if self.channels.Emotion then self.channels.Emotion:Stop() end
 self:Play(self.upgradeCue)
 if withBubble and self.settings.values.UISounds and self.settings.values.Volume>0 then
  local generation=self.generation
  -- Bubble begins 120 ms before the mastered impact; main cue starts with the storm.
  task.delay(math.max(0,Profile.Duration(event.newLevel)*Profile.Bloom-.12),function()
   if not self.dead and self.generation==generation then self:Play("GrowthBubble") end
  end)
 end
end

function Audio:IsCelebrating(now)
 return (now or os.clock())<(self.celebrationUntil or 0)
end

function Audio:SetWeather(kind,intensity,sheltered)
 self.weatherKind=kind;self.weatherIntensity=math.clamp(intensity or 0,0,1);self.weatherSheltered=sheltered==true
end
function Audio:PlayStormThunder(gain)
 -- No unapproved asset ID: this hook becomes audible only after a team Thunder cue is configured.
 if not Config.UI.StormThunder then return false end
 self.thunderGain=math.clamp(gain or 1,0,1)
 if not self:Play("StormThunder") then return false end
 return true
end

function Audio:Tick(now,dt)
 if self.dead then return end
 local celebrating=self:IsCelebrating(now)
 local feature=now<(self.featureUntil or 0)
 for name,entry in Config.UI do
  local sound=self.sounds[name]
  local target=entry.Volume*Config.MixGain(entry.Category,celebrating,feature)
  if name=="GardenBreeze" then
   local storm=self.weatherKind=="Storm";local strength=self.weatherIntensity or 0
   target*=if storm then (1+2*strength)*(if self.weatherSheltered then .28 else 1) elseif self.weatherKind=="Stars" then .65 else 1
   if self.windEQ then
    self.windEQ.Enabled=storm;self.windEQ.LowGain=3*strength;self.windEQ.MidGain=-strength;self.windEQ.HighGain=-5*strength
    sound.PlaybackSpeed=if storm then (self.windSpeed or 1)*(.88+.08*(1-strength)) else self.windSpeed or 1
   end
  elseif name=="StormThunder" then target*=self.thunderGain or 1
  elseif name=="NeighborhoodBirds" then target*=if self.weatherKind=="Storm" then .05 elseif self.weatherKind=="Stars" then .12 else 1 end
  -- Fast attenuation, gentle recovery. No additional frame connection or delayed queue.
  local speed=if target<sound.Volume then 24 else 5
  local volume=sound.Volume+(target-sound.Volume)*(1-math.exp(-math.clamp(dt,0,.25)*speed))
  if math.abs(volume-target)<.002 then volume=target end
  sound.Volume=volume
 end
end

function Audio:StartAmbience()
 if self.dead or not self.settings.values.UISounds or self.settings.values.Volume<=0 then return end
 for name,entry in Config.UI do
  local sound=self.sounds[name]
  if entry.Looped and not sound.IsPlaying then sound:Play() end
 end
end

function Audio:Emotion(emotion)
 local now=os.clock()
 if now-self.lastEmotion<35 or now<(self.upgradeUntil or 0) or now<(self.featureUntil or 0) or self:IsCelebrating(now) then return end
 local cues={Love="EmotionHappy",Confident="EmotionHappy",Joy="EmotionHappy",Stars="EmotionSurprise",
  Surprise="EmotionSurprise",Playful="EmotionPlayful",Wink="EmotionPlayful",Laugh="EmotionGiggle"}
 local cue=cues[emotion]
 if not cue then return end
 -- Variety follows real earning reactions; never random idle noises.
 if emotion=="Love" and self.emotionCount%3==2 then cue="EmotionGiggle" end
 if self:Play(cue) then self.lastEmotion=now;self.emotionCount+=1 end
end

function Audio:StopFeedback()
 self:StopUpgrade();self.celebrationUntil=0;self.featureUntil=0
 for name,entry in Config.UI do if not entry.Looped then self.sounds[name]:Stop() end end
end

function Audio:Destroy()
 self:StopUpgrade();self.dead=true;self.cleanup:Destroy()
end
return Audio
