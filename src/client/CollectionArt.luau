--!nonstrict
-- Native toy illustrations. No uploaded assets, scripts, frame loops or ownership state.
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local A={}
local function shape(parent,name,x,y,w,h,color,radius,rotation)
 local p=W.Round(W.Frame(parent,name,UDim2.fromScale(w,h),color),radius or 6)
 p.AnchorPoint=Vector2.new(.5,.5);p.Position=UDim2.fromScale(x,y);p.Rotation=rotation or 0;return p
end
A.Shape=shape
function A.Face(parent,color)
 local root=W.Frame(parent,"Verity",UDim2.fromScale(1,1));root.BackgroundTransparency=1
 shape(root,"Halo",.5,.53,.96,.96,color,100).BackgroundTransparency=.82
 local body=shape(root,"Jelly",.5,.51,.76,.76,color,100)
 W.New("UIGradient",{Color=ColorSequence.new(color:Lerp(T.White,.5),color),Rotation=95},body)
 shape(root,"Shine",.36,.28,.20,.085,T.White,20,-25).BackgroundTransparency=.25
 for _,side in {-1,1} do
  shape(root,"Eye",.5+side*.125,.49,.065,.12,T.Ink,20)
  shape(root,"Cheek",.5+side*.23,.59,.10,.045,T.Pink,20).BackgroundTransparency=.45
 end
 shape(root,"Smile",.5,.65,.15,.05,T.Ink,20)
 return root
end
function A.Star(parent,color)
 local root=W.Frame(parent,"StarGem",UDim2.fromScale(1,1));root.BackgroundTransparency=1
 shape(root,"Halo",.5,.5,.95,.95,color,100).BackgroundTransparency=.88
 local star=W.Text(root,"Star","★",32,true,color);star.Size=UDim2.fromScale(.88,.88);star.Position=UDim2.fromScale(.06,.06)
 star.TextScaled=true;star.TextXAlignment=Enum.TextXAlignment.Center
 W.New("UIGradient",{Color=ColorSequence.new(T.White,color),Rotation=65},star)
 shape(root,"Spark",.75,.23,.07,.07,T.White,2,45)
 return root
end
function A.Cover(parent,id,color)
 local root=W.Round(W.Frame(parent,"SetIllustration",UDim2.fromScale(1,1),color:Lerp(T.Ink,.30)),12);root.ClipsDescendants=true
 W.New("UIGradient",{Color=ColorSequence.new(color,color:Lerp(T.Ink,.48)),Rotation=65},root)
 shape(root,"BackCard",.59,.54,.6,.77,T.White,7,14).BackgroundTransparency=.35
 shape(root,"MiddleCard",.43,.53,.61,.79,color:Lerp(T.White,.65),7,-11)
 local page=shape(root,"MainCard",.5,.51,.66,.79,T.Paper,7,3)
 local art=shape(page,"Scene",.5,.42,.88,.65,color,5)
 W.New("UIGradient",{Color=ColorSequence.new(color:Lerp(T.White,.3),color),Rotation=90},art)
 if id=="friends" then
  A.Face(art,T.Gold)
 elseif id=="sky" then
  shape(art,"Moon",.57,.4,.5,.5,T.White,100)
  shape(art,"MoonCutout",.70,.32,.43,.43,color,100)
  for i=1,3 do shape(art,"Star",.14+i*.19,.71-i*.12,.10,.10,T.Gold,2,45) end
 elseif id=="gardens" then
  shape(art,"Stem",.5,.72,.055,.34,T.Mint,5)
  for i=1,5 do local a=i*math.pi*2/5;shape(art,"Petal",.5+math.cos(a)*.2,.4+math.sin(a)*.2,.3,.3,T.Pink,100) end
  shape(art,"Pollen",.5,.4,.22,.22,T.Gold,100)
 elseif id=="water" then
  shape(art,"FishTail",.25,.52,.25,.25,T.Gold,3,45)
  shape(art,"Fish",.53,.52,.48,.33,T.Gold,100)
  shape(art,"Eye",.65,.47,.065,.085,T.Ink,100)
  for i=1,3 do shape(art,"Bubble",.25+i*.18,.16+i%2*.08,.08,.08,T.White,100).BackgroundTransparency=.4 end
 elseif id=="home" then
  shape(art,"Roof",.5,.36,.43,.43,T.Purple,4,45)
  shape(art,"House",.5,.63,.52,.43,T.Paper,4)
  shape(art,"Door",.55,.7,.15,.28,T.Pink,4)
  shape(art,"Window",.36,.58,.14,.14,T.Blue,4)
 elseif id=="party" then
  shape(art,"Gift",.5,.62,.61,.46,T.Pink,4)
  shape(art,"Lid",.5,.4,.67,.14,T.Purple,3)
  shape(art,"Ribbon",.5,.58,.10,.55,T.Gold,3)
  for _,side in {-1,1} do shape(art,"Bow",.5+side*.13,.27,.29,.18,T.Gold,8,side*25) end
 elseif id=="travel" then
  shape(art,"Flame",.5,.82,.18,.24,T.Gold,100)
  for _,side in {-1,1} do shape(art,"Wing",.5+side*.2,.63,.22,.27,T.Pink,4,side*25) end
  shape(art,"Rocket",.5,.45,.34,.62,T.Paper,100)
  shape(art,"Porthole",.5,.38,.20,.20,T.Blue,100)
 else
  shape(art,"Ring",.5,.54,.87,.23,T.Pink,100,-23)
  shape(art,"Planet",.5,.45,.58,.58,T.Purple,100)
  shape(art,"Cloud",.47,.36,.27,.08,T.Mint,20,-15)
  shape(art,"Moon",.79,.16,.14,.14,T.Gold,100)
 end
 for i=1,3 do shape(page,"PrintLine",.5,.79+i*.05,.50-i*.06,.015,color,2) end
 shape(root,"Spark",.87,.12,.08,.08,T.White,2,45)
 return root
end
return A
