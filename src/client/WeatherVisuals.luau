--!nonstrict
-- One bounded local presentation pool, driven by GameplayFeedback's existing frame callback.
local Lighting=game:GetService("Lighting")
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.AdventureConfig)
local Cleanup=require(script.Parent.Cleanup)
local V={};V.__index=V
local rainbow={"FF819F","FFBD82","FFE993","A8F3BC","86DEF3","A5B4FF","D6A8F7"}
local function line(p,a,b,width)
 local delta=b-a;if delta.Magnitude<.01 then p.Transparency=1;return end
 local up=if math.abs(delta.Unit.Y)>.99 then Vector3.zAxis else Vector3.yAxis
 p.Size=Vector3.new(width,width,delta.Magnitude);p.CFrame=CFrame.lookAt((a+b)/2,b,up)
end
function V.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),streaks={},stars={},meteors={},splashes={},bolts={},beams={},rainGround={},kind="Clear",alpha=0},V)
 self.original={ClockTime=Lighting.ClockTime,OutdoorAmbient=Lighting.OutdoorAmbient}
 local folder=Instance.new("Folder");folder.Name="LocalVerityWeather";folder.Parent=workspace;self.folder=self.cleanup:Add(folder)
 local function part(name)
  local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  p.Material=Enum.Material.Neon;p.Transparency=1;p.Size=Vector3.one*.1;p.Parent=folder;return p
 end
 for i=1,96 do self.streaks[i]=part("WeatherStreak") end
 for i=1,48 do local p=part("SkyStar");p.Shape=Enum.PartType.Ball;self.stars[i]=p end
 for i=1,24 do
  local head=part("FallingStar");head.Shape=Enum.PartType.Ball
  self.meteors[i]={head=head,tail=part("MeteorTail")}
 end
 for i=1,12 do
  local splash=part("RainSplash");splash.Shape=Enum.PartType.Cylinder;self.splashes[i]=splash
 end
 for i=1,7 do self.bolts[i]=part("SkyLightning") end
 self.anchor=part("SkyAnchor")
 for i=1,6 do
  local a=Instance.new("Attachment");a.Parent=self.anchor;local b=Instance.new("Attachment");b.Parent=self.anchor
  local beam=Instance.new("Beam");beam.Name="WeatherRibbon";beam.Attachment0=a;beam.Attachment1=b;beam.FaceCamera=true;beam.Segments=18
  beam.LightEmission=1;beam.LightInfluence=0;beam.Width0=8;beam.Width1=12;beam.Transparency=NumberSequence.new(.83);beam.Enabled=false;beam.Parent=self.anchor
  self.beams[i]={a=a,b=b,beam=beam}
 end
 -- Fixed in the world above the cave, rather than following/turning with the camera.
 self.rainbowAnchor=part("RainbowAnchor");self.rainbowAnchor.CFrame=CFrame.new(C.CaveEntrance+Vector3.new(0,1,-18))
 self.rainbowBands={}
 for band,hex in rainbow do
  local radius=35-(band-1)*.72
  for half=1,2 do
   local angle=(half-1)*math.pi/2
   local first=Vector3.new(math.cos(angle)*radius,math.sin(angle)*radius,0)
   local last=Vector3.new(math.cos(angle+math.pi/2)*radius,math.sin(angle+math.pi/2)*radius,0)
   local tangent0=Vector3.new(-math.sin(angle),math.cos(angle),0)
   local tangent1=Vector3.new(-math.sin(angle+math.pi/2),math.cos(angle+math.pi/2),0)
   local a=Instance.new("Attachment");a.CFrame=CFrame.fromMatrix(first,tangent0,Vector3.zAxis);a.Parent=self.rainbowAnchor
   local b=Instance.new("Attachment");b.CFrame=CFrame.fromMatrix(last,tangent1,Vector3.zAxis);b.Parent=self.rainbowAnchor
   local beam=Instance.new("Beam");beam.Name="RainbowBand";beam.Attachment0=a;beam.Attachment1=b;beam.FaceCamera=true
   beam.CurveSize0=radius*.55228475;beam.CurveSize1=radius*.55228475;beam.Segments=28
   beam.Color=ColorSequence.new(Color3.fromHex(hex));beam.Width0=.66;beam.Width1=.66
   beam.Transparency=NumberSequence.new(.48);beam.LightEmission=.7;beam.LightInfluence=0;beam.Enabled=false;beam.Parent=self.rainbowAnchor
   table.insert(self.rainbowBands,beam)
  end
 end
 self.color=self.cleanup:Add(Instance.new("ColorCorrectionEffect"));self.color.Name="VerityWeatherGrade";self.color.Parent=Lighting
 local terrain=workspace:FindFirstChildOfClass("Terrain")
 if terrain and not terrain:FindFirstChildOfClass("Clouds") then
  self.clouds=self.cleanup:Add(Instance.new("Clouds"));self.clouds.Name="VerityWeatherClouds";self.clouds.Cover=0;self.clouds.Density=0;self.clouds.Parent=terrain
 end
 self.cleanup:Add(function()
  if not self.lastClock or math.abs(Lighting.ClockTime-self.lastClock)<.01 then Lighting.ClockTime=self.original.ClockTime end
  if not self.lastAmbient or Lighting.OutdoorAmbient==self.lastAmbient then Lighting.OutdoorAmbient=self.original.OutdoorAmbient end
  if ctx.sound.SetWeather then ctx.sound:SetWeather("Clear") end
 end)
 return self
end
function V:Set(message)
 if self.kind~=message.weather then
  self.kind=message.weather;self.dirty=true;self.rainbowAlpha=nil;self.groundAt=nil
  if self.ctx.sound.SetWeather then self.ctx.sound:SetWeather(self.kind) end
 end
 self.message=message
end
function V:Hide()
 for _,p in self.streaks do p.Transparency=1 end
 for _,p in self.stars do p.Transparency=1 end
 for _,r in self.meteors do r.head.Transparency=1;r.tail.Transparency=1 end
 for _,p in self.splashes do p.Transparency=1 end
 for _,p in self.bolts do p.Transparency=1 end
 for _,r in self.beams do r.beam.Enabled=false end
 for _,beam in self.rainbowBands do beam.Enabled=false end
end
function V:Tick(now,dt)
 local camera=workspace.CurrentCamera;if not camera then return end
 local settings=self.ctx.settings.values;local low=settings.LowGraphics;local reduced=settings.ReducedMotion or settings.ReducedEffects
 local tier=if low then 1 elseif settings.Graphics then settings.Graphics.Tier else 3
 local char=Players.LocalPlayer.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
 local base=if root then root.Position else camera.Focus.Position
 local cave=base.Y< -15
 local visible=self.kind~="Clear" and not cave
 local blend=1-math.exp(-math.min(dt or .016,.1)*1.25)
 local clock=if self.kind=="Fire" then 18.1 elseif self.kind=="Stars" then 20.3 elseif self.kind=="Storm" then 16.8 else self.original.ClockTime
 Lighting.ClockTime+=(clock-Lighting.ClockTime)*blend;self.lastClock=Lighting.ClockTime
 local ambient=if self.kind=="Fire" then Color3.fromRGB(176,131,111) elseif self.kind=="Stars" then Color3.fromRGB(130,136,178) elseif self.kind=="Storm" then Color3.fromRGB(126,149,173) else self.original.OutdoorAmbient
 Lighting.OutdoorAmbient=Lighting.OutdoorAmbient:Lerp(ambient,blend);self.lastAmbient=Lighting.OutdoorAmbient
 local tint=if cave then Color3.fromRGB(225,244,255) elseif self.kind=="Fire" then Color3.fromRGB(255,211,169) elseif self.kind=="Stars" then Color3.fromRGB(230,218,255) elseif self.kind=="Storm" then Color3.fromRGB(201,225,250) else Color3.new(1,1,1)
 self.color.TintColor=self.color.TintColor:Lerp(tint,blend);self.color.Saturation=if self.kind=="Fire" then .18 elseif self.kind=="Stars" then .12 elseif self.kind=="Storm" then -.10 else .03
 self.color.Enabled=not self.ctx.presenting and not self.ctx.forgeReveal and not self.ctx.rewardOverlay
 self.color.Contrast=if self.kind=="Storm" then .04 else .015
 local lightning=(workspace:GetServerTimeNow()-(self.message and self.message.since or 0))%11
 self.color.Brightness=if visible and self.kind=="Storm" and not low and not reduced and lightning>8 and lightning<8.38 then .025*(1-(lightning-8)/.38) else 0
 if self.clouds then
  local cover=if self.kind=="Fire" then .76 elseif self.kind=="Storm" then .91 elseif self.kind=="Stars" then .14 elseif self.kind=="Rainbow" then .30 else 0
  self.clouds.Cover+=(cover-self.clouds.Cover)*blend;self.clouds.Density=if self.kind=="Fire" then .58 elseif self.kind=="Storm" then .72 else .24
  self.clouds.Color=if self.kind=="Fire" then Color3.fromRGB(159,79,68) elseif self.kind=="Storm" then Color3.fromRGB(88,111,146) else Color3.fromRGB(231,232,255)
 end
 if now<(self.frameAt or 0) and not self.dirty then return end
 self.frameAt=now+(if tier==1 then 1/20 elseif tier==2 then 1/30 else 1/45);self.dirty=false
 self:Hide();if not visible then return end
 local forward=Vector3.new(camera.CFrame.LookVector.X,0,camera.CFrame.LookVector.Z)
 if forward.Magnitude<.1 then forward=Vector3.zAxis else forward=forward.Unit end
 local right=Vector3.new(-forward.Z,0,forward.X)
 self.anchor.CFrame=CFrame.new(base)
 if self.kind=="Stars" then
  local count=if low then 16 elseif reduced then 24 else 48
  for i=1,count do
   local p=self.stars[i];local angle=i*2.39996;local radius=80+(i%5)*13
   p.Position=base+Vector3.new(math.cos(angle)*radius,35+(i*19%80),math.sin(angle)*radius)
   p.Size=Vector3.one*(.35+(i%3)*.15);p.Color=Color3.fromHex(if i%3==0 then "FFD997" else "D5C2FF")
   p.Transparency=if reduced then .18 else .15+math.sin(now*1.3+i)*.12
  end
  if not reduced then
   for i=1,if low then 2 elseif tier==2 then 10 else 24 do
    local t=(now+i*.37)%5
    if t<1.7 then
     local start=base+forward*(90+i%3*18)+right*((i*31%100)-50)+Vector3.yAxis*(80+i%4*13)
     local pos=start+(right*-30+Vector3.new(0,-24,0))*t
     local r=self.meteors[i];r.head.Position=pos;r.head.Size=Vector3.one*(.6+i%2*.25);r.head.Color=Color3.fromHex("FFF2B8");r.head.Transparency=.05
     line(r.tail,pos,pos+right*10+Vector3.yAxis*9,.15);r.tail.Color=Color3.fromHex(if i%2==0 then "DAB7FF" else "FFDEA2");r.tail.Transparency=.20+t*.25
    end
   end
  end
  if not low and not reduced then for i=1,3 do
   local r=self.beams[i];r.a.Position=forward*140+right*-105+Vector3.yAxis*(66+i*13);r.b.Position=forward*140+right*105+Vector3.yAxis*(70+i*8)
   r.beam.Color=ColorSequence.new(Color3.fromHex(({"BFA2FF","8EEEDC","FDA8DA"})[i]));r.beam.CurveSize0=38+math.sin(now*.3+i)*12;r.beam.CurveSize1=-36;r.beam.Width0=10;r.beam.Width1=16;r.beam.Enabled=true
  end end
 elseif self.kind=="Fire" then
  if now>=(self.fireRoofAt or 0) then
   self.fireRoofAt=now+.4
   local params=RaycastParams.new();params.FilterDescendantsInstances={self.folder,char or self.folder};params.RespectCanCollide=true
   self.fireCovered=workspace:Raycast(base,Vector3.yAxis*85,params)~=nil
  end
  if not self.fireCovered then
   local count=if low then 10 elseif reduced then 18 elseif tier==2 then 38 else 64
   for i=1,count do
    local time=if reduced then 0 else now
    local phase=(time*(1.3+i%3*.12)+i*.73)%18
    local angle=i*2.39996+(if reduced then 0 else time*.12)
    local radius=5+(i*11%22)
    local p=self.streaks[i];p.Size=Vector3.new(.09,.16+(i%3)*.09,.09)
    p.CFrame=CFrame.new(base+Vector3.new(math.cos(angle)*radius,phase-1,math.sin(angle)*radius))*CFrame.Angles(0,angle,phase*.12)
    p.Color=Color3.fromHex(({"FFE7A4","FFB167","FF7859"})[(i-1)%3+1]);p.Transparency=.18+math.abs(phase-8)/20
   end
  end
  if not reduced then
   for i=1,if low then 2 elseif tier==2 then 10 else 24 do
    local time=(now+i*.31)%5
    if time<1.7 then
     local start=base+forward*(100+i%3*16)+right*((i*37%120)-60)+Vector3.yAxis*(85+i%4*13)
     local pos=start+(right*-23+Vector3.new(0,-26,0))*time
     local r=self.meteors[i];r.head.Position=pos;r.head.Size=Vector3.one*(.9+i%3*.15);r.head.Color=Color3.fromHex("FFE9B2");r.head.Transparency=.06
     line(r.tail,pos,pos+right*11+Vector3.yAxis*14,.25);r.tail.Color=Color3.fromHex(if i%2==0 then "FF7D54" else "FFC276");r.tail.Transparency=.18+time*.25
    end
   end
  end
 elseif self.kind=="Storm" then
  -- Rain stays in world-space columns and ends on the exact surface sampled below each one.
  local columns=if low then 12 elseif reduced then 16 elseif tier==2 then 24 else 32
  local cell=Vector3.new(math.round(base.X/8)*8,0,math.round(base.Z/8)*8)
  if cell~=self.rainCell or columns~=self.rainColumns or now>=(self.groundAt or 0) then
   self.rainCell=cell;self.rainColumns=columns;self.groundAt=now+.4
   local params=RaycastParams.new();params.FilterDescendantsInstances={self.folder,char or self.folder};params.RespectCanCollide=true
   local world=workspace:FindFirstChild("GeneratedWorld")
   local boundary=world and world:FindFirstChild("MapBoundary")
   if boundary then params:AddToFilter(boundary) end
   local top=math.max(165,base.Y+64)
   for i=1,columns do
    local origin=cell+Vector3.new((i*17%61)-30,top,(i*29%67)-33)
    local hit=workspace:Raycast(origin,Vector3.new(0,-top-12,0),params)
    self.rainGround[i]=hit and hit.Position
   end
  end
  local layers=if low or reduced then 2 else 3
  local speed=if reduced then 23 else 43
  local length=if reduced then 2.4 else 4.6
  for i=1,columns do
   local surface=self.rainGround[i]
   if not surface then continue end
   for layer=1,layers do
    local height=44-(now*speed+i*5.37+layer*44/layers)%44
    local bottom=surface+Vector3.yAxis*(math.max(0,height-length)+.08)
    local tip=surface+Vector3.yAxis*(height+.08)
    if height>.12 then
     local p=self.streaks[(i-1)*layers+layer]
     line(p,tip,bottom,if low then .07 else .055)
     p.Color=Color3.fromHex("C2E5FF");p.Transparency=if reduced then .55 else .36
    end
   end
   local splash=self.splashes[i]
   if splash and not reduced then
    local phase=(now*speed+i*5.37)%(44/layers)
    if phase<5 then
     local fade=phase/5;local diameter=.3+fade
     splash.Size=Vector3.new(.035,diameter,diameter)
     splash.CFrame=CFrame.new(surface+Vector3.yAxis*.05)*CFrame.Angles(0,0,math.pi/2)
     splash.Color=Color3.fromHex("BEE7FA");splash.Transparency=.58+fade*.42
    end
   end
  end
  -- One gentle distant lightning stroke every 11s; reduced settings suppress it.
  local time=(workspace:GetServerTimeNow()-(self.message and self.message.since or 0))%11
  if not reduced and not low and time>8 and time<8.38 then
   local start=base+forward*130+right*32+Vector3.yAxis*125
   for i=1,7 do local a=start+Vector3.new((i%2)*4,-(i-1)*10,0);local b=start+Vector3.new(((i+1)%2)*4,-i*10,0)
    local p=self.bolts[i];line(p,a,b,.35);p.Color=Color3.fromHex("DAEEFF");p.Transparency=.12+(time-8)*2
   end
   -- Illumination is interpolated above on every frame.
  end
 elseif self.kind=="Rainbow" then
  local distance=(camera.CFrame.Position-self.rainbowAnchor.Position).Magnitude
  local range=if settings.Graphics then settings.Graphics.EffectDistance else 260
  if distance<range then
   local fade=math.clamp((distance-range*.75)/math.max(1,range*.25),0,1)
   local alpha=.48+.52*fade
   for _,beam in self.rainbowBands do
    beam.Segments=if low then 12 elseif tier==2 then 20 else 28
    if self.rainbowAlpha~=alpha then beam.Transparency=NumberSequence.new(alpha) end
    beam.Enabled=true
   end
   self.rainbowAlpha=alpha
  end
 end
end
function V:Destroy() self:Hide();self.cleanup:Destroy() end
return V
