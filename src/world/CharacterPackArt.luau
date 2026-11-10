--!nonstrict
local Packs=require(game:GetService("ReplicatedStorage").Shared.CharacterPacks)
local Art={}
local v=Vector3.new

function Art.Build(parent,id)
 local pack=Packs.Looks[id]
 if not pack then return end
 local root=Instance.new("Model")
 root.Name="CharacterPack_"..id
 local function piece(name,position,size,hex,rotation,shape,neon)
  local p=Instance.new("Part")
  p.Name=name;p.Size=size;p.CFrame=CFrame.new(position)*CFrame.Angles(0,0,rotation or 0)
  p.Color=Color3.fromHex(hex);p.Material=if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  if shape==Enum.PartType.Ball then
   local mesh=Instance.new("SpecialMesh")
   mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
  elseif shape then p.Shape=shape end
  p.Parent=root
  return p
 end
 local ball=Enum.PartType.Ball
 for _,side in {-1,1} do
  local eye=piece("Eye",v(side*.27,1.06,-.82),v(.19,.28,.1),"241932",side*.12,ball)
  piece("Eye",eye.Position+v(-.026,.05,-.05),v(.065,.078,.03),"FFF9F2",0,ball)
  piece("Eye",v(side*.49,.86,-.73),v(.14,.055,.04),pack.Accent,side*.15,ball)
 end
 piece("Smile",v(0,.66,-.85),v(.36,.23,.11),"311A31",.06,ball)
 piece("Smile",v(.025,.613,-.905),v(.19,.078,.045),"FF7191",.06,ball)
 local shine=piece("ShellGlint",v(-.30,1.48,-.47),v(.29,.11,.033),"FFF2EC",.53,ball)
 shine.Transparency=.25
 if id=="homelander" then
  for _,side in {-1,1} do
   piece("WingGuard",v(side*.79,1.08,.10),v(.24,.60,.45),pack.Dark,-side*.52,ball)
   piece("GoldCrest",v(side*.86,1.27,-.11),v(.12,.40,.18),pack.Accent,-side*.50,ball)
   piece("TailFin",v(side*.51,.52,.69),v(.20,.74,.18),pack.Dark,-side*.38)
  end
  piece("CrestGem",v(0,1.59,-.48),v(.20,.20,.12),pack.Accent,math.pi/4,nil,true)
 elseif id=="reef_captain" then
  for _,side in {-1,1} do
   for i=1,3 do
    piece("Coral",v(side*(.62+i*.10),1.12+i*.16,.17),v(.18,.37-i*.035,.18),if i==2 then pack.Accent else pack.Color,side*-.34,ball)
   end
  end
  piece("Pearl",v(0,1.72,-.36),v(.29,.29,.25),"FFF4E6",0,ball)
  for _,side in {-1,1} do
   piece("WaveFin",v(side*.74,.67,.37),v(.46,.16,.32),pack.Dark,side*.34,ball)
   piece("PearlBead",v(side*.63,.53,-.50),v(.13,.13,.13),"DDFFF3",0,ball)
  end
 elseif id=="phase_courier" then
  for _,side in {-1,1} do
   piece("VisorArm",v(side*.77,1.26,-.36),v(.24,.17,.52),"263455",side*.24)
   piece("Signal",v(side*.88,1.29,-.39),v(.08,.09,.28),pack.Accent,side*.24,nil,true)
  end
  piece("BrowVisor",v(0,1.39,-.67),v(.94,.13,.23),pack.Dark,0,ball)
  piece("CircuitStripe",v(0,1.4,-.79),v(.60,.045,.035),pack.Accent,0,ball,true)
  piece("Transmitter",v(.43,1.72,-.09),v(.14,.30,.18),pack.Dark,-.28)
  piece("SignalCrystal",v(.48,1.88,-.09),v(.15,.15,.15),pack.Accent,.79,nil,true)
 elseif id=="magma_smith" then
  for _,side in {-1,1} do
   piece("ShoulderPlate",v(side*.92,.88,.09),v(.35,.51,.52),"493137",side*.24,ball)
   piece("MoltenSeam",v(side*.98,.86,-.17),v(.1,.31,.10),pack.Color,side*.26,nil,true)
   piece("CopperRivet",v(side*1.06,1.04,-.08),v(.13,.13,.13),pack.Accent,0,ball)
  end
  piece("ForgeCrest",v(0,1.58,-.38),v(.89,.25,.39),pack.Dark,0,ball)
  piece("MoltenDiamond",v(0,1.64,-.59),v(.19,.19,.10),pack.Accent,.79,nil,true)
  for _,side in {-1,1} do
   piece("ForgeBrow",v(side*.31,1.45,-.67),v(.31,.08,.10),pack.Dark,side*.28,ball)
  end
 elseif id=="amber_medic" then
  piece("MedicBadge",v(0,1.69,-.38),v(.58,.37,.23),pack.Dark,0,ball)
  piece("MedicCrossV",v(0,1.68,-.46),v(.085,.24,.04),pack.Accent)
  piece("MedicCrossH",v(0,1.68,-.47),v(.23,.085,.04),pack.Accent)
  for _,side in {-1,1} do
   piece("AmberSatchel",v(side*.84,.65,.28),v(.3,.36,.37),pack.Color,side*.18,ball)
  end
 else
  for _,side in {-1,1} do
   for i=1,3 do
    piece("IceWing",v(side*(.79+i*.16),.96+i*.16,.31),v(.15,.59,.17),if i%2==0 then pack.Accent else "B6EEFF",side*-.59)
   end
  end
  piece("FrostGem",v(0,1.68,-.3),v(.22,.22,.13),"E7FAFF",math.pi/4,nil,true)
 end
 root.Parent=parent
 return root
end
return Art
