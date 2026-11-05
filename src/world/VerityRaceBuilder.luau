--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.VerityRaceConfig)
local Locale=require(Shared.LocaleText)
local Builder={}
function Builder.Build(parent)
 local old=parent:FindFirstChild("VerityRaceTrack")
 if old then assert(old:GetAttribute("RaceVersion")==Config.Version,"Race version mismatch");return old end
 local model=Instance.new("Model");model.Name="VerityRaceTrack";model:SetAttribute("RaceVersion",Config.Version)
 local function part(name,pos,size,color,collide)
  local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Position=pos;p.Size=size;p.Color=Color3.fromHex(color)
  p.Material=Enum.Material.Plastic;p.TopSurface=Enum.SurfaceType.Studs;p.BottomSurface=Enum.SurfaceType.Smooth
  p.CanCollide=collide~=false;p.CanQuery=p.CanCollide;p.CanTouch=false;p.Parent=model;return p
 end
 local function label(p,text,width)
  local g=Instance.new("BillboardGui");g.Name="RaceLabel";g.Size=UDim2.fromOffset(width or 170,52);g.StudsOffsetWorldSpace=Vector3.new(0,3,0)
  g.MaxDistance=160;g.Parent=p
  local t=Instance.new("TextLabel");t.Name="Text";t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=.1
  t.BackgroundColor3=Color3.fromHex("55416E");t.TextColor3=Color3.fromHex("FFF0CE");t.Font=Enum.Font.GothamBold;t.TextSize=14;t.TextWrapped=true;t.Parent=g
  local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=t
  Locale.SetWorld(t,"Text",text);return t
 end
 part("RaceIsland",Vector3.new(-248,-1,180),Vector3.new(156,2,240),"72D74E")
 part("AccessPath",Vector3.new(-178,.10,90),Vector3.new(40,.20,12),"FFF0CE")
 part("SpectatorWalk",Vector3.new(-248,.12,80),Vector3.new(148,.24,14),"FFE3A4")
 local sign=part("RaceSign",Vector3.new(-185,5,104),Vector3.new(1,6,8),"A78AF8")
 label(sign,"ГОНКИ VERITY\nБесплатно • 2–4 игрока",230)
 local board=part("RaceBoard",Vector3.new(-247,5,66),Vector3.new(18,6,.5),"55416E")
 label(board,"Займите свободные места!",250)
 for slot,x in Config.LaneX do
  local color=Config.Colors[slot]
  part("Lane"..slot,Vector3.new(x,.10,204),Vector3.new(30,.2,176),color)
  local pad=part("QueuePad"..slot,Vector3.new(x,.25,Config.PadZ),Vector3.new(10,.5,10),color)
  local t=label(pad,"МЕСТО %d • ЗАНЯТЬ");Locale.SetWorld(t,"Text","МЕСТО %d • ЗАНЯТЬ",slot)
  local prompt=Instance.new("ProximityPrompt");prompt.Name="JoinRace";prompt.MaxActivationDistance=Config.JoinReach;prompt.HoldDuration=.3;prompt.RequiresLineOfSight=false
  Locale.SetWorld(prompt,"ActionText","Занять место");Locale.SetWorld(prompt,"ObjectText","Гонки Verity");prompt.Parent=pad
  for _,side in {-1,1} do
   part("StartPost",Vector3.new(x+side*14,4,144),Vector3.new(.6,8,.6),"FFF0CE")
  end
  local gate=part("StartGate"..slot,Vector3.new(x,3,144),Vector3.new(27,3,.4),"FFF0CE",false)
  gate:SetAttribute("RaceSlot",slot)
  for z=140,260,24 do part("LaneStud",Vector3.new(x,.24,z),Vector3.new(1.1,.08,3),"FFF0CE",false)end
  for tile=1,6 do part("FinishTile",Vector3.new(x-15+(tile-.5)*5,.25,276),Vector3.new(5,.1,3),if tile%2==0 then "FFF0CE" else "55416E",false)end
 end
 for _,x in {-323,-173} do
  part("OuterRail",Vector3.new(x,1.5,207),Vector3.new(.6,3,180),"FFF0CE")
 end
 for _,x in {-322,-178} do part("FinishPost",Vector3.new(x,17,279),Vector3.new(1.2,34,1.2),"A78AF8")end
 part("FinishArch",Vector3.new(-250,34,279),Vector3.new(145,1.2,1.2),"FFD44F")
 model.Parent=parent;return model
end
return Builder
