--!nonstrict
-- Local, bounded storm geometry. WeatherVisuals remains the only owner of sky and grading.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS.Shared.StormConfig)
local V={};V.__index=V
local rainColor=Color3.fromRGB(166,200,226)
local function part(parent,name,material)
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=material or Enum.Material.SmoothPlastic;p.Size=Vector3.one*.1;p.Transparency=1;p.Parent=parent;return p
end
local function line(p,a,b,width)
 local d=b-a;if d.Magnitude<.01 then p.Transparency=1;return end
 local up=if math.abs(d.Unit.Y)>.99 then Vector3.zAxis else Vector3.yAxis
 p.Size=Vector3.new(width,width,d.Magnitude);p.CFrame=CFrame.lookAt((a+b)/2,b,up)
end
function V.new(ctx,parent)
 return setmetatable({ctx=ctx,parent=parent,rain={},splashes={},mist={},cores={},glows={},segments={},thunderDone={},lastDraw=0},V)
end
function V:Pool(tier,reduced)
 if not self.folder then local f=Instance.new("Folder");f.Name="StormV2";f.Parent=self.parent;self.folder=f end
 local folder=self.folder
 local rainBudget=if tier==1 then 24 elseif reduced then 48 elseif tier==2 then 72 else 160
 for i=#self.rain+1,rainBudget do self.rain[i]=part(folder,"WindDrivenRain",Enum.Material.Neon) end
 for i=#self.splashes+1,if tier==3 and not reduced then 12 elseif tier==2 and not reduced then 6 else 0 do
  local p=part(folder,"RainRipple");p.Shape=Enum.PartType.Cylinder;self.splashes[i]=p
 end
 local boltBudget=if tier==1 then 8 elseif reduced then (if tier==2 then 10 else 12) elseif tier==2 then 18 else 24
 for i=#self.cores+1,boltBudget do self.cores[i]=part(folder,"LightningCore",Enum.Material.Neon) end
 for i=#self.glows+1,if tier>1 and not reduced then boltBudget else 0 do
  self.glows[i]=part(folder,"LightningAura",Enum.Material.Neon)
 end
 for i=#self.mist+1,if tier==3 and not reduced then 3 elseif tier==2 and not reduced then 1 else 0 do
  local anchor=part(folder,"MistAnchor");anchor.Size=Vector3.new(1,.1,1)
  local emitter=Instance.new("ParticleEmitter");emitter.Name="GroundRainMist";emitter.Texture="rbxasset://textures/particles/smoke_main.dds"
  emitter.Rate=0;emitter.Enabled=false;emitter.Lifetime=NumberRange.new(2.5,4)
  emitter.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,2),NumberSequenceKeypoint.new(.5,6),NumberSequenceKeypoint.new(1,10)})
  emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.94),NumberSequenceKeypoint.new(.7,.97),NumberSequenceKeypoint.new(1,1)})
  emitter.Color=ColorSequence.new(Color3.fromRGB(151,177,195));emitter.LightEmission=0;emitter.LightInfluence=.55
  emitter.Speed=NumberRange.new(.5,1.3);emitter.SpreadAngle=Vector2.new(75,75);emitter.Rotation=NumberRange.new(0,360);emitter.RotSpeed=NumberRange.new(-6,6)
  emitter.Parent=anchor;self.mist[i]={anchor=anchor,emitter=emitter}
 end
 if not self.light then
  self.glowAnchor=part(folder,"LightningLightAnchor")
  self.light=Instance.new("PointLight");self.light.Color=Color3.fromRGB(194,221,255);self.light.Range=48;self.light.Brightness=0;self.light.Shadows=false;self.light.Enabled=false;self.light.Parent=self.glowAnchor
 end
end
function V:Hide()
 for _,p in self.rain do p.Transparency=1 end
 for _,p in self.splashes do p.Transparency=1 end
 for _,p in self.cores do p.Transparency=1 end
 for _,p in self.glows do p.Transparency=1 end
 for _,r in self.mist do r.emitter.Enabled=false;r.emitter:Clear() end
 if self.light then self.light.Enabled=false end
 self.signature=nil;self.groundAt=0;self.lastFlash=0
end
function V:Set(message)
 self.message=message
 local round=message.weatherRound
 if message.weather~="Storm" then self:Hide();self.round=nil;table.clear(self.thunderDone);return end
 if round~=self.round then
  self:Hide();self.round=round;self.joinedAt=workspace:GetServerTimeNow();self.boltId=nil;self.boltTier=nil;table.clear(self.thunderDone)
 end
end
function V:Sample(serverNow)
 local m=self.message
 if not m or m.weather~="Storm" then return nil end
 local data=m.storm
 local since=m.since or serverNow;local deadline=m.deadline or since+95
 local sample=Config.Sample(since,deadline,serverNow)
 sample.strikes=if data and data.version==2 and data.active and data.lightning then data.lightning.strikes else {}
 sample.thunderSpeed=data and data.lightning and data.lightning.thunderSpeed or Config.ThunderSpeed
 sample.maxThunderDelay=data and data.lightning and data.lightning.maxThunderDelay or Config.ThunderMaxDelay
 return sample
end
function V:Ground(base,tier,reduced,now)
 local columns=if tier==1 then 12 elseif tier==2 or reduced then 24 else 40
 local cell=Vector3.new(math.floor(base.X/12)*12,0,math.floor(base.Z/12)*12)
 if self.cell==cell and self.columns==columns and now<(self.groundAt or 0) then return end
 self.cell=cell;self.columns=columns;self.groundAt=now+(if tier==1 then .8 else .5)
 local params=RaycastParams.new();params.RespectCanCollide=true
 local excluded={self.parent}
 for _,player in Players:GetPlayers() do if player.Character then table.insert(excluded,player.Character) end end
 local world=workspace:FindFirstChild("GeneratedWorld");local boundary=world and world:FindFirstChild("MapBoundary")
 if boundary then table.insert(excluded,boundary) end
 params.FilterDescendantsInstances=excluded
 self.covered=workspace:Raycast(base,Vector3.yAxis*90,params)~=nil
 self.surfaces={}
 for i=1,columns do
  local angle=i*2.399963
  local radius=4+((i-.5)/columns)^1.4*(if tier==1 then 30 else 48)
  local x=cell.X+math.cos(angle)*radius;local z=cell.Z+math.sin(angle)*radius
  local top=math.max(155,base.Y+90)
  local hit=workspace:Raycast(Vector3.new(x,top,z),Vector3.new(0,base.Y-35-top,0),params)
  if hit then self.surfaces[i]={position=hit.Position,normal=hit.Normal} end
 end
end
function V:BuildBolt(strike,tier,reduced)
 self.boltId=strike.id;self.boltTier=tier;self.boltReduced=reduced;self.segments={}
 local rng=Random.new(strike.seed);local count=if tier==1 then 8 elseif tier==2 then 10 else 12
 local points={strike.origin};local delta=strike.position-strike.origin
 for i=1,count-1 do
  local t=i/count;local spread=math.sin(t*math.pi)*7
  points[i+1]=strike.origin+delta*t+Vector3.new(rng:NextNumber(-spread,spread),0,rng:NextNumber(-spread,spread))
 end
 points[count+1]=strike.position
 for i=1,count do table.insert(self.segments,{points[i],points[i+1],1}) end
 if tier>1 and not reduced then
  for branch=1,if tier==3 then 3 else 2 do
   local from=points[3+branch*2]
   local direction=Vector3.new(rng:NextNumber(-14,14),-24,rng:NextNumber(-14,14))
   for j=1,4 do
    local to=from+direction/4+Vector3.new(rng:NextNumber(-2,2),0,rng:NextNumber(-2,2))
    table.insert(self.segments,{from,to,.45});from=to
   end
  end
 end
end
function V:Lightning(sample,serverNow,base,tier,reduced,blocked)
 local active,age
 for _,strike in sample.strikes do
  if strike.at>=(self.joinedAt or serverNow)-.2 then
   local t=serverNow-strike.at
   if t>=0 and t<(if reduced then .42 else .36) then active=strike;age=t end
   local distance=(base-strike.position).Magnitude
   local due=strike.at+math.clamp(distance/sample.thunderSpeed,0,sample.maxThunderDelay)
   if not self.thunderDone[strike.id] and serverNow>=due then
    self.thunderDone[strike.id]=true
    if not blocked and serverNow-due<.7 and self.ctx.sound.PlayStormThunder then
     self.ctx.sound:PlayStormThunder(math.clamp(1-distance/700,.12,1)*(if self.covered then .35 else 1))
    end
   end
  else self.thunderDone[strike.id]=true end
 end
 for _,p in self.cores do p.Transparency=1 end
 for _,p in self.glows do p.Transparency=1 end
 if self.light then self.light.Enabled=false end
 if not active or blocked or (base-active.position).Magnitude>(if tier==1 then 300 else 700) then return 0 end
 if self.boltId~=active.id or self.boltTier~=tier or self.boltReduced~=reduced then self:BuildBolt(active,tier,reduced) end
 local fade=math.clamp(age/(if reduced then .42 else .36),0,1)
 for i,segment in self.segments do
  local width=(if tier==1 then .24 else .18)*segment[3]
  line(self.cores[i],segment[1],segment[2],width)
  self.cores[i].Color=Color3.fromRGB(225,241,255);self.cores[i].Transparency=if reduced then .32+fade*.68 else .04+fade*.96
  if tier>1 and not reduced then
   line(self.glows[i],segment[1],segment[2],width*3.8)
   self.glows[i].Color=Color3.fromRGB(128,177,255);self.glows[i].Transparency=.72+fade*.28
  end
 end
 if tier==3 and not reduced then
  self.glowAnchor.Position=active.position+Vector3.yAxis*15;self.light.Brightness=2.5*(1-fade)^2;self.light.Enabled=true
 end
 return if reduced then 0 else (1-fade)^2
end
function V:Render(sample,now,serverNow,camera,base,tier,reduced,blocked)
 if blocked then self:Hide();self:Lightning(sample,serverNow,base,tier,reduced,true);return 0 end
 self:Pool(tier,reduced)
 if now-self.lastDraw<(if tier==1 then 1/20 elseif tier==2 then 1/30 else 1/45) then return self.lastFlash or 0 end
 self.lastDraw=now
 local signature=tostring(tier)..":"..tostring(reduced)
 if signature~=self.signature then self:Hide();self.signature=signature end
 self:Ground(base,tier,reduced,now)
 local layers=if tier==1 or reduced then 2 elseif tier==2 then 3 else 4
 local count=math.max(1,math.ceil(self.columns*sample.rain))
 local gust=1+(if reduced then .08 else .2)*math.sin(serverNow*.75)
 local drift=sample.windDirection*(sample.windSpeed*.42*gust)
 local falling=Vector3.new(drift.X,-(if reduced then 36 else 62),drift.Z)
 local direction=falling.Unit
 for _,p in self.rain do p.Transparency=1 end
 for _,p in self.splashes do p.Transparency=1 end
 for i=1,count do
  local surface=self.surfaces[i]
  if not surface then continue end
  local roof=surface.position;local top=math.max(base.Y+37,roof.Y+2)
  if self.covered and Vector3.new(roof.X-base.X,0,roof.Z-base.Z).Magnitude<18 then continue end
  local span=math.max(1,top-math.max(roof.Y,base.Y-14))
  for layer=1,layers do
   local phase=(serverNow*(if reduced then 36 else 62)+i*9.371+layer*span/layers)%span
   local height=top-phase
   local length=if reduced then 2.4 else 2.5+(i%3)*.7
   local a=Vector3.new(roof.X,height,roof.Z)-drift*(phase/62)
   local b=a+direction*math.min(length,math.max(0,height-roof.Y-.08))
   if b.Y>roof.Y+.05 and height>roof.Y+.2 then
    local p=self.rain[(i-1)*layers+layer];line(p,a,b,if tier==1 then .055 else .035)
    p.Color=rainColor;p.Transparency=if reduced then .63 elseif i%3==0 then .36 else .51
   end
  end
  if i<=#self.splashes and not reduced and surface.normal.Y>.85 then
   local age=(serverNow*2.3+i*.317)%1
   if age<.65 then
    local p=self.splashes[i];local size=.22+age*1.45;p.Size=Vector3.new(.025,size,size)
    p.CFrame=CFrame.new(roof+Vector3.yAxis*.065)*CFrame.Angles(0,0,math.pi/2);p.Color=rainColor;p.Transparency=.67+age*.5
   end
  end
 end
 local source=1
 for index,r in self.mist do
  local desired=tier>1 and not reduced and not self.covered and index<=(if tier==3 then 3 else 1) and sample.rain>.35
  local surface
  if desired then
   while source<=self.columns do
    local candidate=self.surfaces[source];source+=1
    if candidate and candidate.normal.Y>.85 and candidate.position.Y<base.Y-1 and (candidate.position-base).Magnitude<40 then surface=candidate;break end
   end
  end
  if surface then
   r.anchor.Position=surface.position+Vector3.yAxis*.25;r.emitter.Acceleration=Vector3.new(drift.X*.22,.15,drift.Z*.22)
   r.emitter.Rate=(if tier==3 then 5 else 3)*sample.groundMist;r.emitter.Enabled=true
  else r.emitter.Enabled=false;r.emitter:Clear() end
 end
 self.lastFlash=self:Lightning(sample,serverNow,base,tier,reduced,false)
 return self.lastFlash
end
function V:Destroy() self:Hide();if self.folder then self.folder:Destroy() end end
return V
