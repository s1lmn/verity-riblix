--!nonstrict
-- Shared native geometry for the live companion and shop. No physics, assets or frame connections.
local Packs=require(game:GetService("ReplicatedStorage").Shared.CharacterPacks)
local Art={Version=2}
local v=Vector3.new
local BALL=Enum.PartType.Ball
local white="FFF9EE"
local function turn(z) return CFrame.Angles(0,0,z) end

function Art.Build(parent,id)
 local look=Packs.Looks[id];if not look then return end
 local root=Instance.new("Model");root.Name="CharacterPack_"..id;root.WorldPivot=CFrame.identity
 root:SetAttribute("DesignVersion",Art.Version)
 local motion={groups={},quiet=nil,nextAt=0}
 local target=root
 local count=0
 local function piece(name,pos,size,color,rotation,shape,glow,alpha)
  local p=Instance.new(if shape=="Wedge" then "WedgePart" else "Part")
  p.Name=name;p.Size=size;p.CFrame=CFrame.new(pos)*(rotation or CFrame.identity)
  p.Color=Color3.fromHex(color);p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
  p.Transparency=alpha or 0;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  if shape==BALL then local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
  elseif typeof(shape)=="EnumItem" then p.Shape=shape end
  p.Parent=target;count+=1;return p
 end
 local function link(name,a,b,width,color,glow)
  local delta=b-a;local up=if math.abs(delta.Unit.Y)>.99 then Vector3.zAxis else Vector3.yAxis
  local p=piece(name,(a+b)*.5,v(width,width,delta.Magnitude),color,nil,nil,glow)
  p.CFrame=CFrame.lookAt((a+b)*.5,b,up);return p
 end
 local function ring(name,center,rx,ry,n,color,width,glow)
  for i=1,n do
   local a,b=(i-1)*math.pi*2/n,i*math.pi*2/n
   link(name,center+v(math.cos(a)*rx,math.sin(a)*ry,0),center+v(math.cos(b)*rx,math.sin(b)*ry,0),width,color,glow)
  end
 end
 local function rig(name,center,kind,amount,speed,build)
  local group=Instance.new("Model");group.Name=name;group.WorldPivot=CFrame.new(center);group.Parent=root
  target=group;build();target=root
  table.insert(motion.groups,{model=group,center=center,kind=kind,amount=amount,speed=speed,phase=#motion.groups*.9})
 end
 local function gem(name,at,size,color,rotation,glow)
  return piece(name,at,size,color,rotation or turn(math.pi/4),nil,glow)
 end

 -- Every silhouette leaves the front eye/mouth zone open. Expressions differ by theme.
 local fierce=id=="homelander" or id=="magma_smith"
 local friendly=id=="reef_captain" or id=="amber_medic"
 for _,side in {-1,1} do
  piece("Eye",v(side*.275,1.055,-.822),v(.185,if friendly then .285 else .235,.095),"252443",turn(if fierce then side*.19 else -side*.07),BALL)
  piece("Eye",v(side*.275-.032,1.11,-.876),v(.060,.080,.025),white,nil,BALL)
  if id=="homelander" then
   piece("Eye",v(side*.275+.022,1.02,-.878),v(.067,.095,.025),"FF3B66",nil,BALL,true)
  elseif id=="polar_ranger" then
   piece("Eye",v(side*.275+.028,1.015,-.879),v(.05,.055,.02),"58BFE9",nil,BALL)
  end
  piece("Cheek",v(side*.49,.86,-.735),v(.17,.065,.035),look.Accent,turn(side*.18),BALL)
  if fierce then piece("Brow",v(side*.28,1.255,-.745),v(.25,.045,.055),look.Dark,turn(side*.20),BALL) end
 end
 for i=0,6 do
  local angle=math.pi*i/6
  local y=.705-math.sin(angle)*(if friendly then .145 else .105)
  piece("Smile",v(math.cos(angle)*.205,y,-.845),v(.068,.068,.045),"34304C",nil,BALL)
 end
 piece("ShellGlint",v(-.32,1.45,-.48),v(.25,.10,.027),white,turn(.57),BALL,false,.24)

 if id=="homelander" then
  -- A red solar knight: split ceremonial cape, gilded armour and a segmented sun behind the orb.
  for _,side in {-1,1} do
   piece("CrimsonMantle",v(side*.70,1.15,.24),v(.29,.48,.46),look.Dark,turn(-side*.47),BALL)
   piece("GildedMantle",v(side*.81,1.30,.13),v(.12,.34,.36),look.Accent,turn(-side*.47),BALL)
   for i=1,3 do
    piece("ScarletCape",v(side*(.26+i*.14),.73-i*.17,.64+i*.05),v(.24,.94-i*.10,.15),if i%2==0 then "FF3761" else look.Dark,
     CFrame.Angles(.18,side*.12,-side*(.12+i*.07)),"Wedge")
   end
   gem("SolarTemple",v(side*.55,1.51,-.34),v(.13,.32,.08),look.Accent,turn(-side*.38))
  end
  gem("SunCrest",v(0,1.70,-.31),v(.28,.36,.12),look.Accent)
  gem("CrestCore",v(0,1.71,-.385),v(.12,.19,.035),"FFF0BE",nil,true)
  rig("SolarCorona",v(0,1.02,.47),"spinZ",.10,.10,function()
   ring("SolarArc",v(0,1.02,.47),1.01,1.01,10,look.Accent,.045,true)
   for i=1,5 do
    local a=i*math.pi*2/5+.22
    gem("SolarRay",v(math.cos(a)*1.13,1.02+math.sin(a)*1.13,.47),v(.12,.28,.055),"FFC35F",turn(a-math.pi/2),true)
   end
  end)
 elseif id=="reef_captain" then
  -- An asymmetric coral crown and a spiral shell read from every direction.
  for _,side in {-1,1} do
   local x=side*.69
   link("CoralStem",v(x,1.35,.17),v(x+side*.15,1.99,.12),.14,look.Accent)
   link("CoralFork",v(x+side*.08,1.68,.15),v(x+side*.34,1.84,.13),.105,"FFB0A1")
   piece("CoralTip",v(x+side*.15,2,.12),v(.17,.19,.17),"FFE0B7",nil,BALL)
   piece("CoralTip",v(x+side*.34,1.85,.13),v(.13,.14,.13),"FFD0B9",nil,BALL)
   piece("ReefFin",v(side*.88,.63,.22),v(.37,.45,.18),look.Dark,CFrame.Angles(.18,0,-side*.58),"Wedge")
   piece("FinEdge",v(side*1.0,.73,.12),v(.10,.35,.13),"9AFFF0",turn(-side*.58),BALL)
  end
  piece("CaptainBrow",v(0,1.63,-.29),v(.73,.15,.26),"237E97",nil,BALL)
  gem("TideMedallion",v(0,1.72,-.41),v(.20,.24,.075),"FFF0BE",nil,true)
  piece("NautilusShell",v(0,.99,.69),v(.89,.89,.40),"FFE0B9",nil,BALL)
  for i=1,7 do
   local a=i*math.pi*.48;local radius=.05+i*.035
   piece("ShellSpiral",v(math.cos(a)*radius,1+math.sin(a)*radius,.906),v(.12,.12,.04),if i%2==0 then look.Accent else "FFC27F",nil,BALL)
  end
  rig("FloatingPearls",v(0,.87,0),"bob",.075,1.5,function()
   for i=1,3 do
    local a=.6+i*1.6
    piece("PearlBubble",v(math.cos(a)*1.04,.72+i*.22,math.sin(a)*.60),v(.13+i*.018,.13+i*.018,.13+i*.018),"DAFFF1",nil,BALL,true)
   end
  end)
 elseif id=="phase_courier" then
  -- Offset portal hardware, angular cyan fins and an actual miniature parcel on the back.
  for _,side in {-1,1} do
   piece("PhaseEarpiece",v(side*.79,1.17,-.04),v(.20,.37,.39),look.Dark,turn(side*.13),BALL)
   gem("PhaseWindow",v(side*.82,1.19,-.25),v(.15,.22,.06),look.Accent,turn(.3*side),true)
   for i=1,2 do
    piece("VectorFin",v(side*(.82+i*.13),.72+i*.17,.27),v(.12,.47,.18),if i==1 then "FF85DC" else look.Accent,turn(-side*.70),"Wedge")
   end
  end
  piece("PilotBrow",v(0,1.48,-.47),v(.72,.11,.17),look.Dark,nil,BALL)
  link("CourierAntenna",v(.40,1.58,.02),v(.53,1.96,.02),.07,look.Dark)
  gem("SignalStar",v(.54,2.02,.02),v(.19,.23,.12),"FFE391",nil,true)
  piece("PhaseParcel",v(.15,.91,.78),v(.57,.53,.28),"C8B4FF",CFrame.Angles(.08,.15,-.12))
  piece("ParcelSeal",v(.15,.91,.935),v(.13,.38,.045),"FFE391",turn(-.12))
  rig("PortalDial",v(-.07,1.0,.43),"spinZ",1,.38,function()
   for i=1,8 do
    local a=(i-1)*math.pi/4
    gem("PortalTile",v(-.07+math.cos(a)*1.02,1+math.sin(a)*.92,.43),v(.15,.25,.06),if i%2==0 then look.Accent else "F49DEC",turn(a),true)
   end
  end)
 elseif id=="magma_smith" then
  -- Basalt forge shell with bright molten seams and orbiting clinker stones.
  for _,side in {-1,1} do
   piece("BasaltPlate",v(side*.78,.95,.04),v(.33,.57,.47),look.Dark,turn(side*.24),BALL)
   link("MoltenCrack",v(side*.82,1.19,-.19),v(side*.93,.98,-.24),.06,"FFD572",true)
   link("MoltenCrack",v(side*.93,.98,-.24),v(side*.81,.68,-.16),.055,"FF9B39",true)
   piece("CopperRivet",v(side*.83,1.13,-.26),v(.12,.12,.055),"FFC17D",nil,BALL)
  end
  for i=-2,2 do
   gem("BasaltCrown",v(i*.24,1.70+.12*(2-math.abs(i)),.03),v(.23,.42,.24),if i%2==0 then look.Dark else "A94C55",turn(i*.17))
   gem("ForgeCrack",v(i*.24,1.74+.12*(2-math.abs(i)),-.10),v(.055,.23,.045),if i%2==0 then "FFD67A" else "FF9038",turn(i*.17),true)
  end
  piece("ForgeBack",v(0,.94,.73),v(.62,.67,.27),look.Dark,nil,BALL)
  gem("ForgeCore",v(0,.96,.90),v(.26,.34,.065),look.Accent,nil,true)
  rig("ForgeSatellites",v(0,.83,.47),"orbit",1,.42,function()
   for i=1,3 do
    local a=i*math.pi*2/3
    gem("Clinker",v(math.cos(a)*1.03,.74+.16*(i%2),.47+math.sin(a)*.57),v(.20,.26,.20),"7B4552",turn(a))
    gem("ClinkerHeart",v(math.cos(a)*1.03,.77+.16*(i%2),.47+math.sin(a)*.57-.11),v(.065,.12,.035),"FFC85C",nil,true)
   end
  end)
 elseif id=="amber_medic" then
  -- A honey-and-amber rescue lantern: mint elixir, amber ampoules and a heart-shaped emblem.
  for _,side in {-1,1} do
   piece("AmberAmpoule",v(side*.88,.76,.22),v(.23,.42,.23),"FFE1A2",turn(side*.19),BALL,false,.10)
   piece("MintElixir",v(side*.88,.75,.20),v(.12,.25,.12),"6EFFD0",turn(side*.19),BALL,true)
   piece("AmpouleCap",v(side*.92,.99,.22),v(.21,.09,.20),look.Dark,turn(side*.19),BALL)
   for i=1,2 do
    piece("HoneyPetal",v(side*(.76+i*.13),1.13+i*.09,.37),v(.20,.43,.12),if i==1 then "FFF0C1" else "9FFFF0",turn(-side*(.65+i*.20)),BALL,false,.12)
   end
  end
  piece("RescueBrow",v(0,1.59,-.27),v(.67,.18,.25),"FFF1C6",nil,BALL)
  for _,side in {-1,1} do piece("HeartLobe",v(side*.065,1.73,-.37),v(.16,.16,.07),"FF819E",nil,BALL) end
  gem("HeartPoint",v(0,1.66,-.37),v(.16,.16,.07),"FF819E")
  piece("HoneyLantern",v(0,.95,.75),v(.48,.58,.26),"FFDE99",nil,BALL)
  gem("LanternWindow",v(0,.98,.9),v(.22,.27,.06),"9CFFE3",nil,true)
  rig("HoneyHalo",v(0,1.12,.41),"rock",.09,.95,function()
   ring("Honeycomb",v(0,1.12,.41),.96,.96,6,"FFE8AA",.065,true)
   for i=1,3 do
    local a=i*math.pi*2/3+.3
    piece("AmberDrop",v(math.cos(a)*1.04,1.12+math.sin(a)*1.04,.41),v(.13,.19,.10),"FFA65C",turn(-a),BALL,true)
   end
  end)
 else
  -- Layered crystalline fans and a small aurora crown; the face stays fully exposed.
  for _,side in {-1,1} do
   for i=1,3 do
    gem("GlacierFan",v(side*(.70+i*.17),.87+i*.18,.28),v(.16,.61+i*.07,.12),if i%2==0 then look.Accent else "C2F7FF",turn(-side*(.36+i*.12)))
    gem("IceVein",v(side*(.70+i*.17),.88+i*.18,.205),v(.045,.41+i*.06,.025),if i%2==0 then "F2D5FF" else "6EEBFF",turn(-side*(.36+i*.12)),true)
   end
   piece("PolarScarf",v(side*.57,.39,-.12),v(.42,.17,.28),"BBA0FF",turn(side*.28),BALL)
  end
  for i=-1,1 do
   gem("IceCrown",v(i*.26,1.76+.13*(1-math.abs(i)),-.01),v(.17,.39,.14),if i==0 then "F5F6FF" else "A8F5FF",turn(-i*.27),true)
  end
  piece("ScarfTail",v(.45,.31,.49),v(.23,.53,.10),"CCB1FF",turn(-.38),"Wedge")
  rig("AuroraCrest",v(0,1.76,.40),"rock",.12,.80,function()
   for i=-2,2 do
    piece("AuroraRibbon",v(i*.23,1.87+.10*math.cos(i),.40),v(.17,.27,.04),({"7AFFDA","77E9F5","A9B4FF","D6A1FF","A9F7E8"})[i+3],turn(-i*.18),BALL,true)
   end
  end)
 end
 root:SetAttribute("GeometryParts",count)
 root.Parent=parent
 return root,motion
end

-- Called by the existing companion/shop tick. At most one or two small rigs per look.
function Art.Animate(motion,frame,scale,now,quiet)
 if not motion then return end
 quiet=quiet==true
 if quiet and motion.quiet then return end
 if not quiet and now<motion.nextAt and motion.quiet==false then return end
 motion.quiet=quiet;motion.nextAt=now+1/30
 for _,group in motion.groups do
  if not group.model.Parent then continue end
  local t=if quiet then 0 else now*group.speed+group.phase
  local rotation=CFrame.identity;local offset=Vector3.zero
  if group.kind=="bob" then offset=v(0,if quiet then 0 else math.sin(t)*group.amount,0)
  elseif group.kind=="rock" then rotation=turn(if quiet then 0 else math.sin(t)*group.amount)
  elseif group.kind=="spinZ" then rotation=turn(if quiet then 0 else t)
  elseif group.kind=="orbit" then rotation=CFrame.Angles(0,if quiet then 0 else t,0) end
  group.model:PivotTo(frame*CFrame.new((group.center+offset)*scale)*rotation)
 end
end
return Art
