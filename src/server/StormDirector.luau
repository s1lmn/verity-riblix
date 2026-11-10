--!nonstrict
-- A bounded server timeline. Every client, including a late joiner, gets the same lightning cues.
local C=require(game:GetService("ReplicatedStorage").Shared.StormConfig)
local Director={};Director.__index=Director
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
 local timeline=self:Timeline(round,since,deadline);local data=C.Sample(since,deadline,now)
 local strikes={};for _,strike in timeline.strikes do table.insert(strikes,table.clone(strike)) end
 data.version=C.Version;data.active=true;data.cosmeticOnly=true;data.round=round;data.serverTime=now;data.since=since;data.deadline=deadline
 data.cloudHeight=C.CloudHeight;data.shelter={respectRoofs=true,indoorRainGain=.12,indoorWindGain=.2}
 data.lightning={strikes=strikes,thunderSpeed=C.ThunderSpeed,maxThunderDelay=C.ThunderMaxDelay,fullScreenFlash=false}
 data.presentation={rendererVersion=2,requiresNewRenderer=false,allowCameraShake=false,reduceFlashesForAccessibility=true}
 return data
end
function Director:Destroy() self:Reset() end
return Director
