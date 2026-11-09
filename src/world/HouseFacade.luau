--!nonstrict
local Facade={}
function Facade.Build(geometry,accent)
 local function p(name,pos,size,color,ball)
  local o=Instance.new("Part");o.Name=name;o.Size=size;o.Position=pos;o.Color=color;o.Material=Enum.Material.SmoothPlastic
  o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false
  if ball then o.Shape=Enum.PartType.Ball end;o.Parent=geometry;return o
 end
 local cream=Color3.fromHex("FFF0D9");local hue=accent or Color3.fromHex("A28BD4")
 for _,side in {-1,1} do
  p("FacadePilaster",Vector3.new(side*15.8,6,14.85),Vector3.new(.6,11.7,.55),cream)
  p("FacadeFoot",Vector3.new(side*15.8,.6,14.85),Vector3.new(.95,1.2,.9),hue)
  p("FacadeBelt",Vector3.new(side*10,2.2,14.8),Vector3.new(9.8,.3,.55),cream)
  p("FacadeDoorTrim",Vector3.new(side*4.05,4.9,14.9),Vector3.new(.27,9.5,.4),hue)
  local pot=p("FacadePlanter",Vector3.new(side*12.8,.7,16),Vector3.new(2,1.4,2),hue)
  for i=-1,1 do p("FacadePlant",Vector3.new(side*12.8+i*.48,1.9+(if i==0 then .3 else 0),16),Vector3.new(1.1,1.5,1.1),Color3.fromHex("7DCEA3"),true) end
 end
 p("FacadeDoorLintel",Vector3.new(0,9.7,14.9),Vector3.new(8.5,.3,.4),hue)
 p("RoofCapFrontCornice",Vector3.new(0,12.85,14.9),Vector3.new(33.4,.35,1.4),cream)
 p("RoofCapFrontAccent",Vector3.new(0,13.15,14.9),Vector3.new(33.8,.24,1.7),hue)
 for _,side in {-1,1} do p("RoofCapSideCornice",Vector3.new(side*16.2,12.85,.5),Vector3.new(.7,.35,28.6),cream) end
end
return Facade
