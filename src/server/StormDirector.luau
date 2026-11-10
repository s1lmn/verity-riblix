--!nonstrict
-- A bounded server timeline. Every client, including a late joiner, gets the same lightning cues.
local C=require(game:GetService("ReplicatedStorage").Shared.StormConfig)
local Director={};Director.__index=Director
local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
function Director.new() return setmetatable({},Director) end
function Director:Reset() self.timeline=nil end
function Director:Timeline(round,since,deadline)
 local old=self.timeline
 if old and old.round==round and old.since==since and old.deadline==deadline then return old end
 local duration=math.max(1,deadline-since);local rng=Random.new(round*7919%2147483647);local strikes={};local previous=0
 for index,fraction in C.StrikeFractions do
  local anchor=rng:NextInteger(1,#C.Anchors)
  if anchor==previous then anchor=anchor%#C.Anchors+1 end;previous=anchor
  local position=C.Anchors[anchor]+Vector3.new(rng:NextNumber(-6,6),0,rng:NextNumber(-6,6))
  local at=since+duration*fraction
  strikes[index]={id=tostring(round)..":"..index,at=at,warningAt=math.max(since,at-C.WarningSeconds),
   position=position,origin=position+Vector3.new(0,C.StrikeHeight,0),seed=rng:NextInteger(1,2147483646),
   energy=if fraction>=.46 and fraction<.86 then 1 else .7,flashSeconds=.12,flashCount=1,damage=0}
 end
 self.timeline={round=round,since=since,deadline=deadline,strikes=strikes};return self.timeline
end
function Director:Projection(weather,round,since,deadline,now)
 if weather~="Storm" then self:Reset();return {version=C.Version,active=false,round=round,blendOutSeconds=4} end
 local timeline=self:Timeline(round,since,deadline);local duration=math.max(1,deadline-since)
 local fraction=math.clamp((now-since)/duration,0,1);local phase=C.Phases[#C.Phases];local index=#C.Phases
 for i,candidate in C.Phases do if fraction<candidate.Until then phase=candidate;index=i;break end end
 local t=smooth((fraction-phase.From)/math.max(.001,phase.Until-phase.From))
 local intensity=phase.IntensityFrom+(phase.IntensityTo-phase.IntensityFrom)*t
 local previous=C.Phases[index-1]
 local function mix(key,initial)
  local from=if previous then previous[key] else initial
  return from+(phase[key]-from)*t
 end
 local strikes={}
 for _,strike in timeline.strikes do table.insert(strikes,table.clone(strike)) end
 return {version=C.Version,active=true,cosmeticOnly=true,round=round,serverTime=now,since=since,deadline=deadline,
  phase=phase.Id,phaseName=phase.Name,phaseSince=since+duration*phase.From,phaseDeadline=since+duration*phase.Until,
  intensity=intensity,rain=mix("Rain",.02),windSpeed=mix("Wind",0),
  windDirection=Vector3.new(.82,0,-.57),darkness=mix("Darkness",.05),cloudCoverage=mix("Clouds",.3),
  cloudHeight=C.CloudHeight,haze=.24*intensity,wetness=intensity,groundMist=.55*intensity,
  shelter={respectRoofs=true,indoorRainGain=.12,indoorWindGain=.2},
  lightning={strikes=strikes,thunderSpeed=C.ThunderSpeed,maxThunderDelay=C.ThunderMaxDelay,fullScreenFlash=false},
  presentation={requiresNewRenderer=true,allowCameraShake=false,reduceFlashesForAccessibility=true}}
end
function Director:Destroy() self:Reset() end
return Director
