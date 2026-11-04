"""Focused audio lifecycle checks using fake services; never launches Studio."""
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
source = (root / 'src/client/UISoundController.luau').read_text()
config = (root / 'src/world/AudioConfig.luau').read_text()
gameplay = (root / 'src/client/GameplayAudioController.luau').read_text()
harness = '''
local Config=(function() CONFIG_SOURCE end)()
local pending={}
local task={spawn=function(f) f() end,delay=function(_,f) table.insert(pending,f) end}
local function flush() local list=pending;pending={};for _,f in list do f() end end
local Instance={new=function(kind)
 local o={kind=kind,plays=0,stops=0}
 function o:Play() self.plays+=1 end
 function o:Stop() self.stops+=1 end
 function o:Destroy() self.destroyed=true end
 return o
end}
local node={};function node:WaitForChild(_) return self end
node.Shared={VerityAnimationProfile='Profile'}
local game={GetService=function(_,name)
 if name=='ReplicatedStorage' then return node end
 if name=='ContentProvider' then return {PreloadAsync=function() end} end
 return {}
end}
local script={Parent={Cleanup='Cleanup'}}
local function require(key)
 if key==node then return Config end
 if key=='Profile' then return {Bloom=.53,Duration=function(level) return if Config.UI['Milestone'..level] then 2.45 else 1.8 end} end
 return {new=function() return {Add=function(_,item) return item end,Destroy=function() end} end}
end
local Audio=(function() CONTROLLER_SOURCE end)()
local onSettings
local settings={values={UISounds=true,Volume=.6},Changed={Event={Connect=function(_,f) onSettings=f;return {} end}}}
local a=Audio.new(settings)
for level=1,100 do
 local expected=if table.find({10,25,50,75,100},level) then 'Milestone'..level elseif level%2==0 then 'LevelUp' else 'LevelUpAlternative'
 assert(Config.UpgradeCue(level)==expected,'wrong upgrade cue at '..level)
end
local count=0;for _ in a.sounds do count+=1 end;assert(count==33)
a:PlayUpgrade({eventId='first',newLevel=10},true)
assert(a.sounds.Milestone10.plays==1 and a.sounds.LevelUp.plays==0)
a:PlayUpgrade({eventId='first',newLevel=10},true)
assert(a.sounds.Milestone10.plays==1,'duplicate replay')
a:StopUpgrade('unrelated');flush();assert(a.sounds.GrowthBubble.plays==1,'unrelated cancellation')
a:PlayUpgrade({eventId='second',newLevel=25},true)
local bubbles=a.sounds.GrowthBubble.plays
a:StopUpgrade('second');flush();assert(a.sounds.GrowthBubble.plays==bubbles,'cancelled bubble fired')
a:PlayUpgrade({eventId='third',newLevel=50},true)
settings.values.UISounds=false;onSettings(settings.values);flush()
assert(a.sounds.GrowthBubble.plays==bubbles,'muted bubble fired')
settings.values.UISounds=true
-- A new event after unmuting must work; old events never replay.
a:PlayUpgrade({eventId='fourth',newLevel=75},true)
assert(a.sounds.Milestone75.plays==1)
a:Destroy();flush();assert(a.sounds.GrowthBubble.plays==bubbles,'destroyed bubble fired')
-- Emotion rate limit, foreground priority and ambience restart are separate from upgrade.
a=Audio.new(settings)
a:Emotion("Love");assert(a.sounds.EmotionHappy.plays==1)
a:Emotion("Laugh");assert(a.sounds.EmotionGiggle.plays==0,'emotion spam')
a.lastEmotion=-math.huge
a:Play("TaskCompleted");a:Emotion("Surprise")
assert(a.sounds.EmotionSurprise.plays==0,'emotion overlapped main reward')
settings.values.UISounds=false;onSettings(settings.values)
local wind=a.sounds.GardenBreeze.plays
settings.values.UISounds=true;onSettings(settings.values)
assert(a.sounds.GardenBreeze.plays==wind+1,'ambience failed to restart')
assert(a.sounds.GardenBreeze.Looped and a.sounds.NeighborhoodBirds.Looped)
for cue in Config.UI do assert(not string.find(string.lower(cue),'music'),'excluded music configured') end
a:Destroy()
a=Audio.new(settings)
a:Play("BoxCeremony")
local stops=a.sounds.BoxCeremony.stops
assert(a:IsCelebrating())
a:Play("TaskCompleted")
assert(a.sounds.BoxCeremony.stops==stops,'task interrupted ceremony')
assert(a.sounds.GardenBreeze.Volume<Config.UI.GardenBreeze.Volume*.5,'ambience not ducked')
assert(a.sounds.TaskCompleted.Volume<Config.UI.TaskCompleted.Volume*.5,'minor feature not ducked')
a:Stop("BoxCeremony")
assert(not a:IsCelebrating(),'cancel left mix suppressed')
a:Tick(os.clock()+10,.25)
a:Tick(os.clock()+10,.25)
assert(a.sounds.GardenBreeze.Volume>Config.UI.GardenBreeze.Volume*.8,'mix failed to recover')
assert(Config.MixGain('Emotion',true,false)==0)
assert(Config.MixGain('Ambience',true,false)<Config.MixGain('Ambience',false,true))
a:Destroy()
print('Audio: 100 level routes, bounded voices, milestone replacement, deduplication, cancellation, mute and teardown passed')
'''.replace('CONFIG_SOURCE', config).replace('CONTROLLER_SOURCE', source)
harness += '''
local getService=game.GetService
function game:GetService(name)
 if name=='Players' then return {LocalPlayer={UserId=42}} end
 return getService(self,name)
end
local Gameplay=(function() GAMEPLAY_SOURCE end)()
local function signal()
 local callbacks={};local ev={}
 function ev:Connect(f) table.insert(callbacks,f);return {} end
 return {Event=ev,Fire=function(_,value) for _,f in callbacks do f(value) end end}
end
local calls={}
local ctx={net={StateChanged=signal(),Result=signal(),Notification=signal(),World=signal()},sound={}}
function ctx.sound:Play(name) table.insert(calls,name) end
function ctx.sound:Stop(name) table.insert(calls,'stop:'..name) end
function ctx.sound:Emotion(name) table.insert(calls,'emotion:'..name) end
local visuals={Emotion=signal(),SpawnStopped=signal(),BeginSpawn=function() return false end}
local routing=Gameplay.new(ctx,visuals)
ctx.net.StateChanged:Fire({DeliveryState='NotDelivered',CosmeticsOwned={old=true}})
assert(#calls==0,'snapshot replayed old purchases')
ctx.net.StateChanged:Fire({DeliveryState='Delivered',CosmeticsOwned={old=true}})
assert(calls[#calls]=='DeliveryArrived')
ctx.net.Result:Fire({action='CosmeticPurchase',success=true})
assert(#calls==1,'purchase prompt played grant sound')
ctx.net.StateChanged:Fire({DeliveryState='Delivered',CosmeticsOwned={old=true,new=true}})
assert(calls[#calls]=='DecorPurchased')
local n=#calls
ctx.net.StateChanged:Fire({DeliveryState='Delivered',CosmeticsOwned={old=true,new=true}})
assert(#calls==n,'inventory replay')
ctx.net.Notification:Fire({code='TASK_REWARD',eventId='task1'})
assert(calls[#calls]=='TaskCompleted')
n=#calls;ctx.net.Notification:Fire({code='TASK_REWARD',eventId='task1'});assert(#calls==n,'notification replay')
ctx.net.World:Fire({ownerUserId=7,kind='VeritySpawned',eventId='spawn'})
assert(#calls==n,'foreign reveal audio')
ctx.net.World:Fire({ownerUserId=42,kind='VeritySpawned',eventId='spawn'})
assert(calls[#calls]=='VeritySpawn')
n=#calls;ctx.net.World:Fire({ownerUserId=42,kind='VeritySpawned',eventId='spawn'});assert(#calls==n)
ctx.net.Result:Fire({action='TaskStart',success=true});assert(calls[#calls]=='TaskAccepted')
ctx.net.Result:Fire({action='UpgradeVerity',success=false,errorCode='INSUFFICIENT_CASH'});assert(calls[#calls]=='NotEnoughCash')
visuals.BeginSpawn=function() return true end
ctx.net.World:Fire({ownerUserId=42,kind='VeritySpawned',eventId='ceremony'})
assert(calls[#calls]=='BoxCeremony','ceremony used overlapping spawn cue')
visuals.SpawnStopped:Fire(nil) -- Signal fixture is single-argument; nil means cancellation.
assert(calls[#calls]=='stop:BoxCeremony','cancelled ceremony audio remained')
routing:Destroy()
print('Gameplay audio: confirmed grants only, delivery transition, task deduplication and owner-only reveal passed')
'''.replace('GAMEPLAY_SOURCE',gameplay)
with tempfile.TemporaryDirectory(prefix='verity-audio-') as temp:
    path=Path(temp)/'audio.luau'
    path.write_text(harness)
    subprocess.run([sys.argv[1],str(path)],check=True)
