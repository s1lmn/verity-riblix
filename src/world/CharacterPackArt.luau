--!nonstrict
local Packs=require(game:GetService("ReplicatedStorage").Shared.CharacterPacks)
local Art={}
local v=Vector3.new

function Art.Build(parent,id)
 local pack=Packs.Items[id]
 if not pack then return end
 local root=Instance.new("Model")
 root.Name="CharacterPack_"..id
 local function piece(name,position,size,hex,rotation,shape,neon)
  local p=Instance.new("Part")
  p.Name=name;p.Size=size;p.CFrame=CFrame.new(position)*CFrame.Angles(0,0,rotation or 0)
  p.Color=Color3.fromHex(hex);p.Material=if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
  if shape then p.Shape=shape end
  p.Parent=root
  return p
 end
 local ball=Enum.PartType.Ball
 if id=="reef_captain" then
  for _,side in {-1,1} do
   for i=1,3 do
    piece("Coral",v(side*(.62+i*.10),1.12+i*.16,.17),v(.18,.37-i*.035,.18),if i==2 then pack.Accent else pack.Color,side*-.34,ball)
   end
  end
  piece("Pearl",v(0,1.7,-.36),v(.25,.25,.23),"FFF4E6",0,ball)
 elseif id=="phase_courier" then
  for _,side in {-1,1} do
   piece("VisorArm",v(side*.77,1.26,-.36),v(.24,.17,.52),"263455",side*.24)
   piece("Signal",v(side*.88,1.29,-.39),v(.08,.09,.28),pack.Accent,side*.24,nil,true)
  end
  piece("BrowVisor",v(0,1.43,-.65),v(.94,.09,.18),"263455")
 elseif id=="magma_smith" then
  for _,side in {-1,1} do
   piece("ShoulderPlate",v(side*.92,.88,.09),v(.35,.51,.52),"493137",side*.24,ball)
   piece("MoltenSeam",v(side*.98,.86,-.17),v(.1,.31,.10),pack.Color,side*.26,nil,true)
   piece("CopperRivet",v(side*1.06,1.04,-.08),v(.13,.13,.13),pack.Accent,0,ball)
  end
 elseif id=="amber_medic" then
  piece("MedicBadge",v(0,1.68,-.36),v(.52,.35,.16),"A45A34",0,ball)
  piece("MedicCrossV",v(0,1.68,-.46),v(.085,.24,.04),pack.Accent)
  piece("MedicCrossH",v(0,1.68,-.47),v(.23,.085,.04),pack.Accent)
  for _,side in {-1,1} do
   piece("AmberSatchel",v(side*.84,.65,.28),v(.3,.36,.37),pack.Color,side*.18,ball)
  end
 else
  for _,side in {-1,1} do
   for i=1,3 do
    piece("IceWing",v(side*(.79+i*.16),.96+i*.16,.31),v(.12,.49,.16),if i%2==0 then pack.Accent else pack.Color,side*-.51)
   end
  end
  piece("FrostGem",v(0,1.68,-.3),v(.22,.22,.13),"E7FAFF",math.pi/4,nil,true)
 end
 root.Parent=parent
 return root
end
return Art
