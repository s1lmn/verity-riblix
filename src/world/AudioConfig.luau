--!strict
-- User-approved WAV pack, uploaded to creator JSER42 on 2026-11-04.
-- Experience: Verity / Universe 10774627481. Music #23 intentionally excluded.
local Config = {}
Config.UI = {
 Reward = {SoundId="rbxassetid://137024601928769", Volume=.48},
 SwipeWhoosh = {SoundId="rbxassetid://70807545380362", Volume=.42},
 UpgradeSwipe = {SoundId="rbxassetid://137024601928769", Volume=.45},
 LevelUp = {SoundId="rbxassetid://71378631901703", Volume=.64},
 LevelUpAlternative = {SoundId="rbxassetid://73468342554869", Volume=.64},
 GrowthBubble = {SoundId="rbxassetid://73081489492354", Volume=.22},
 Milestone10 = {SoundId="rbxassetid://84315984463330", Volume=.72},
 Milestone25 = {SoundId="rbxassetid://100994504709577", Volume=.74},
 Milestone50 = {SoundId="rbxassetid://125138246779810", Volume=.76},
 Milestone75 = {SoundId="rbxassetid://73336906780239", Volume=.78},
 Milestone100 = {SoundId="rbxassetid://71920256749777", Volume=.80},
}
-- V3: separate source files, no duplicate OGG uploads.
Config.UI.BoxRustle = {SoundId="rbxassetid://116306089460704", Volume=0.4, Duration=1.73}
Config.UI.BoxAnticipation = {SoundId="rbxassetid://131485968518674", Volume=0.45, Duration=2.25, Channel="Feature"}
Config.UI.VeritySpawn = {SoundId="rbxassetid://109298535572522", Volume=0.6, Duration=2.72, Channel="Feature"}
Config.UI.BoxCeremony = {SoundId="rbxassetid://132782174447662", Volume=0.6, Duration=5.03, Channel="Feature"}
Config.UI.Click = {SoundId="rbxassetid://126703121379160", Volume=0.16, Duration=0.2}
Config.UI.PhoneOpen = {SoundId="rbxassetid://72839650066231", Volume=0.27, Duration=0.63}
Config.UI.PhoneClose = {SoundId="rbxassetid://84435508420776", Volume=0.24, Duration=0.55}
Config.UI.NotEnoughCash = {SoundId="rbxassetid://85415347359680", Volume=0.3, Duration=0.75}
Config.UI.Success = {SoundId="rbxassetid://93023753263103", Volume=0.34, Duration=0.7, Channel="Feature"}
Config.UI.TaskAccepted = {SoundId="rbxassetid://117439463331498", Volume=0.32, Duration=1.13, Channel="Feature"}
Config.UI.DeliveryArrived = {SoundId="rbxassetid://133429553361538", Volume=0.4, Duration=2.11, Channel="Feature"}
Config.UI.ParcelCollected = {SoundId="rbxassetid://93591987243531", Volume=0.32, Duration=0.85}
Config.UI.ParcelRare = {SoundId="rbxassetid://121612787120900", Volume=0.37, Duration=1.46, Channel="Feature"}
Config.UI.TaskCompleted = {SoundId="rbxassetid://100780862076235", Volume=0.48, Duration=2.67, Channel="Feature"}
Config.UI.TaskCheckpoint = {SoundId="rbxassetid://109200213826462", Volume=0.28, Duration=0.62}
Config.UI.EmotionHappy = {SoundId="rbxassetid://108870682323012", Volume=0.22, Duration=0.95, Channel="Emotion"}
Config.UI.EmotionSurprise = {SoundId="rbxassetid://86817349212593", Volume=0.22, Duration=1.03, Channel="Emotion"}
Config.UI.EmotionPlayful = {SoundId="rbxassetid://120127272323017", Volume=0.22, Duration=0.88, Channel="Emotion"}
Config.UI.EmotionGiggle = {SoundId="rbxassetid://109419869496302", Volume=0.2, Duration=1.12, Channel="Emotion"}
Config.UI.DecorTryOn = {SoundId="rbxassetid://71069356750196", Volume=0.25, Duration=0.77}
Config.UI.DecorPurchased = {SoundId="rbxassetid://121612787120900", Volume=0.44, Duration=1.46, Channel="Feature"}
Config.UI.GardenBreeze = {SoundId="rbxassetid://82493042090681", Volume=0.1, Duration=24, Looped=true, Channel="Ambience"}
Config.UI.NeighborhoodBirds = {SoundId="rbxassetid://94504848592312", Volume=0.12, Duration=24, Looped=true, Channel="Ambience"}
Config.UI.UpgradeSwipe = Config.UI.Success
-- Explicit mix categories keep long reveals separate from ordinary acknowledgements.
for name,entry in Config.UI do
 entry.Category=if entry.Looped then "Ambience" elseif entry.Channel=="Emotion" then "Emotion"
  elseif name=="Reward" then "Reward" elseif name=="GrowthBubble" then "Layer"
  elseif name=="BoxCeremony" or name=="BoxAnticipation" or name=="VeritySpawn"
   or name=="LevelUp" or name=="LevelUpAlternative" or name:match("^Milestone") then "Celebration"
  elseif entry.Channel=="Feature" then "Feature" else "UI"
 if entry.Category=="Celebration" then entry.Channel="Celebration" end
 if name=="PhoneOpen" or name=="PhoneClose" then entry.Channel="Phone" end
 entry.Cooldown=if name=="NotEnoughCash" then .9 elseif name=="DecorTryOn" then .4
  elseif entry.Category=="Feature" then .3 elseif name=="Reward" then .22 else .12
end
Config.UI.LevelUp.Duration=2.4
Config.UI.LevelUpAlternative.Duration=2.6
Config.UI.GrowthBubble.Duration=.78
for level,duration in {[10]=3.15,[25]=3.25,[50]=3.35,[75]=3.5,[100]=3.65} do
 Config.UI["Milestone"..level].Duration=duration
end
-- Gains are relative to the player's unchanged master Volume setting.
function Config.MixGain(category: string,celebrating: boolean,feature: boolean): number
 if celebrating then
  return ({Ambience=.25,UI=.55,Reward=.35,Feature=.3,Emotion=0,Layer=1,Celebration=1})[category] or 1
 elseif feature then
  return ({Ambience=.55,UI=.8,Reward=.7,Emotion=0})[category] or 1
 end
 return 1
end
-- Ceremony alternatives and TaskCheckpoint are available to future animation/logic.
-- No music asset configured.
function Config.UpgradeCue(level: number): string
 local milestone="Milestone"..tostring(level)
 if Config.UI[milestone] then return milestone end
 return if level%2==0 then "LevelUp" else "LevelUpAlternative"
end
return Config
