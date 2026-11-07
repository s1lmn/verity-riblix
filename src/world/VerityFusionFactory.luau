--!nonstrict
-- Client-only character art. No tag, physics, uploaded texture or extra mover.
local Factory={}
local function piece(parent,name,pos,size,hex,oval,glow)
 local p=Instance.new("Part");p.Name=name;p.Position=pos;p.Size=size;p.Color=Color3.fromHex(hex)
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=if glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
 if oval then local mesh=Instance.new("SpecialMesh");mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p end
 p.Parent=parent;return p
end
function Factory.Create(parent)
 local m=Instance.new("Model");m.Name="DoubleJellyVerity"
 local root=piece(m,"Root",Vector3.zero,Vector3.one*.1,"FFFFFF",false,false);root.Transparency=1;m.PrimaryPart=root
 for slot=1,2 do
  local x=(slot-1.5)*4.3
  local hue=if slot==1 then "FFC338" else "69E3CB"
  piece(m,"Jelly",Vector3.new(x,3.5,0),Vector3.new(7,7,7),hue,true,false)
  piece(m,"Shine",Vector3.new(x-.75,5.3,-2.63),Vector3.new(1.55,.42,.16),"FFF3D4",true,false).CFrame*=CFrame.Angles(0,0,-.45)
  for _,side in {-1,1} do
   local eye=piece(m,"Eye",Vector3.new(x+side*.83,4.23,-3.32),if slot==1 then Vector3.new(.46,.94,.16) else Vector3.new(.78,.23,.16),"2B2844",true,false)
   if slot==1 then
    piece(m,"EyeGlint",eye.Position+Vector3.new(-.07,.18,-.08),Vector3.one*.15,"FFF7E3",true,false)
   else eye.CFrame*=CFrame.Angles(0,0,side*-.28) end
   piece(m,"Cheek",Vector3.new(x+side*1.25,3.45,-3.28),Vector3.new(.57,.28,.12),"FF9FB2",true,false)
  end
  piece(m,"Smile",Vector3.new(x,2.86,-3.44),Vector3.new(1.45,.85,.18),"302740",true,false)
  piece(m,"Tongue",Vector3.new(x,2.62,-3.55),Vector3.new(.78,.29,.12),"FF8EA8",true,false)
 end
 local a=Instance.new("Attachment");a.Position=Vector3.new(0,2.7,0);a.Parent=root
 local fx=Instance.new("ParticleEmitter");fx.Name="FusionSparkles";fx.Texture="rbxasset://textures/particles/sparkles_main.dds"
 fx.Rate=0;fx.Lifetime=NumberRange.new(.45,.85);fx.Speed=NumberRange.new(6,15);fx.SpreadAngle=Vector2.new(160,160)
 fx.LightEmission=.8;fx.Color=ColorSequence.new(Color3.fromHex("FFDA71"),Color3.fromHex("7DF2DF"))
 fx.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.7),NumberSequenceKeypoint.new(.65,.4),NumberSequenceKeypoint.new(1,0)})
 fx.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.12),NumberSequenceKeypoint.new(1,1)})
 fx.Parent=a;m.Parent=parent
 return m,fx
end
return Factory
