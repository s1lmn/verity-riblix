--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local C=require(Shared.VerityBattleConfig)
local Locale=require(Shared.LocaleText)
local Sign=require(script.Parent.WorldSign)
local B={}
function B.Build(parent)
 local old=parent:FindFirstChild("VerityBattleArena")
 if old and old:FindFirstChild("ArenaSign") then return old end
 if old then old:Destroy() end
 local m=Instance.new("Model");m.Name="VerityBattleArena";m.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 local function p(name,delta,size,color,solid,neon)
  local part=Instance.new("Part");part.Name=name;part.Anchored=true;part.Position=C.Center+delta;part.Size=size
  part.Color=Color3.fromHex(color);part.Material=if neon then Enum.Material.Neon else Enum.Material.Plastic
  part.CanCollide=solid==true;part.CanQuery=solid==true;part.CanTouch=false;part.CastShadow=solid==true;part.Parent=m;return part
 end
 p("Floor",Vector3.new(0,-.6,0),Vector3.new(92,.8,56),"51436F",true)
 p("DuelCircle",Vector3.new(0,-.12,0),Vector3.new(38,.08,38),"6D57A1",false)
 for _,x in {-46,46} do p("ArenaRim",Vector3.new(x,0,0),Vector3.new(.35,.2,56),"83E7FF",false,true) end
 for _,z in {-28,28} do p("ArenaRim",Vector3.new(0,0,z),Vector3.new(92,.2,.35),"F58FC9",false,true) end
 for _,x in {-39,39} do for _,z in {-21,21} do
  p("Pillar",Vector3.new(x,3,z),Vector3.new(2.4,6,2.4),"7C5BB7",true)
  p("Crystal",Vector3.new(x,7,z),Vector3.one*2,"B7EEFF",false,true).CFrame*=CFrame.Angles(0,0,math.pi/4)
 end end
 local entry=p("Entry",Vector3.new(0,1,-32),Vector3.new(9,2,5),"FFD35C",true)
 local q=Instance.new("ProximityPrompt");q.Name="JoinBattle";q.MaxActivationDistance=12;q.HoldDuration=.3;q.RequiresLineOfSight=false
 Locale.SetWorld(q,"ActionText","Начать битву");Locale.SetWorld(q,"ObjectText","Арена Verity • 5 волн • бесплатно");q.Parent=entry
 local board=p("ArenaSign",Vector3.new(0,6,-32),Vector3.new(17,4,.5),"3B3153",false)
 Sign.Add(board,"АРЕНА VERITY\nНужна экипированная атака")
 local enemies=Instance.new("Folder");enemies.Name="Enemies";enemies.Parent=m
 m:SetAttribute("Phase","Idle");m:SetAttribute("Wave",0);m.Parent=parent;return m
end
return B
