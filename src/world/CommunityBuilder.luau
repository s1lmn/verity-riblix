--!nonstrict
local C=require(game:GetService("ReplicatedStorage").Shared.CommunityConfig)
local Locale=require(game:GetService("ReplicatedStorage").Shared.LocaleText)
local Builder={}
function Builder.Build(world)
 local m=Instance.new("Model");m.Name="NeighborhoodLight";m.Parent=world
 local plaza=world.Plaza.WelcomePad
 local walk=world.Environment:FindFirstChild("Sidewalk1")
 local function part(name,pos,size,color,ball)
  local p=Instance.new("Part");p.Name=name;p.Position=pos;p.Size=size;p.Color=Color3.fromHex(color)
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  p.Material=Enum.Material.SmoothPlastic;if ball then p.Shape=Enum.PartType.Ball end
  p.Parent=m;return p
 end
 local function prompt(p,action,title)
  local q=Instance.new("ProximityPrompt");q.Name="Interact";q.HoldDuration=.4;q.MaxActivationDistance=7
  q.RequiresLineOfSight=false;q.Style=Enum.ProximityPromptStyle.Default
  Locale.SetWorld(q,"ActionText",action);Locale.SetWorld(q,"ObjectText",title);q.Parent=p;return q
 end
 local function label(p,title)
  local g=Instance.new("BillboardGui");g.Name="Label";g.Size=UDim2.fromOffset(180,36)
  g.MaxDistance=30;g.StudsOffsetWorldSpace=Vector3.new(0,3,0);g.Parent=p
  local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Font=Enum.Font.GothamBold
  t.TextSize=13;t.TextWrapped=true;t.TextColor3=Color3.fromHex("303A57");t.TextStrokeColor3=Color3.new(1,1,1)
  t.TextStrokeTransparency=.1;t.Parent=g;Locale.SetWorld(t,"Text",title)
 end
 local hub=part("Join",plaza.Position+Vector3.new(-8,.85,0),Vector3.new(2,1.5,2),"FFD567")
 prompt(hub,"Помочь району","Вернём свет району");label(hub,"Вернём свет району")
 local positions={
  Vector3.new(-20.4,1.25,-walk.Size.Z/2+25),Vector3.new(20.4,1.25,-walk.Size.Z/2+54),
  plaza.Position+Vector3.new(8,1.6,1),
 }
 for index,pos in positions do
  local p=part("Station"..index,pos,Vector3.new(2.2,2.2,2.2),"6F739E",true)
  part("Stand"..index,pos-Vector3.new(0,1,0),Vector3.new(3.1,.5,3.1),"3B476A")
  prompt(p,"Передать энергию",C.StationNames[index])
  local glow=part("Glow"..index,pos,Vector3.one*2.4,"FFE580",true)
  glow.Material=Enum.Material.Neon;glow.Transparency=1
 end
 for index=1,6 do
  local side=if index%2==0 then 1 else -1
  local row=math.ceil(index/2)
  local z=-walk.Size.Z/2+70+row*26
  local p=part("Cell"..index,Vector3.new(side*18.5,2.2,z),Vector3.one*1.25,"80F1F7",true)
  p.Material=Enum.Material.Neon;prompt(p,"Взять энергию","Энергоячейка района")
 end
 local beacon=part("Beacon",positions[3]+Vector3.new(0,6,0),Vector3.new(.9,10,.9),"FFE580")
 beacon.Material=Enum.Material.Neon;beacon.Transparency=1
 return m
end
return Builder
