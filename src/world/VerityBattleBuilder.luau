--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local C=require(Shared.VerityBattleConfig)
local Locale=require(Shared.LocaleText)
local Sign=require(script.Parent.WorldSign)
local B={}
function B.Build(parent)
 local old=parent:FindFirstChild("VerityBattleArena")
 if old and old:FindFirstChild("ArenaCeiling") then return old end
 if old then old:Destroy() end
 local m=Instance.new("Model");m.Name="VerityBattleArena";m.ModelStreamingMode=Enum.ModelStreamingMode.Persistent
 local function p(name,delta,size,color,solid,neon)
  local part=Instance.new("Part");part.Name=name;part.Anchored=true;part.Position=C.Center+delta;part.Size=size
  part.Color=Color3.fromHex(color);part.Material=if neon then Enum.Material.Neon else Enum.Material.Plastic
  part.CanCollide=solid==true;part.CanQuery=solid==true;part.CanTouch=false;part.CastShadow=solid==true;part.Parent=m;return part
 end
 p("Floor",Vector3.new(0,-.6,0),Vector3.new(92,.8,56),"51436F",true)
 p("DuelCircle",Vector3.new(0,-.12,0),Vector3.new(38,.08,38),"6D57A1",false)
 local function boundary(position,size,color)
  local wall=p("ArenaBoundary",position+Vector3.yAxis*(C.Ceiling/2-1),size,color,true)
  wall.Transparency=1;wall.CastShadow=false
  local railSize=Vector3.new(size.X,3.4,size.Z)
  local rail=p("ArenaBarrier",position+Vector3.yAxis*.95,railSize,color,false)
  rail.Material=Enum.Material.Glass;rail.Transparency=.58
  p("ArenaRail",position+Vector3.yAxis*2.7,Vector3.new(size.X,.22,size.Z),color,false,true)
 end
 local width,length=C.HalfWidth+.8,C.HalfLength+.8
 for _,sign in {-1,1} do
  boundary(Vector3.new(width*sign,0,0),Vector3.new(.6,C.Ceiling+2,length*2+.6),"83E7FF")
  boundary(Vector3.new(0,0,length*sign),Vector3.new(width*2-.6,C.Ceiling+2,.6),"F58FC9")
 end
 local ceiling=p("ArenaCeiling",Vector3.yAxis*(C.Ceiling+.5),Vector3.new(width*2+1,1,length*2+1),"83E7FF",true)
 ceiling.Transparency=1;ceiling.CastShadow=false
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
