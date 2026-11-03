--!nonstrict
-- Native cosmetic geometry in unscaled model coordinates. No physics or uploaded IDs.
local Factory={}
local function part(parent,name,size,position,color,shape)
 local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=CFrame.new(position)
 p.Color=Color3.fromHex(color);p.Material=Enum.Material.SmoothPlastic;p.Reflectance=0
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 if shape then p.Shape=shape end
 p.Parent=parent;return p
end
function Factory.Apply(model,equipped)
 local old=model:FindFirstChild("Cosmetics");if old then old:Destroy() end
 local folder=Instance.new("Folder");folder.Name="Cosmetics";folder.Parent=model
 for _,id in equipped do
  local item=Instance.new("Model");item.Name=id;item.Parent=folder
  if id=="round_glasses" then
   -- Open square frames leave the oval eyes fully visible.
   for _,side in {-1,1} do
    local x=side*0.29
    for _,y in {0.83,1.2} do part(item,"Frame",Vector3.new(.48,.055,.06),Vector3.new(x,y,-.85),"733DE8") end
    for _,dx in {-.24,.24} do part(item,"Frame",Vector3.new(.055,.37,.06),Vector3.new(x+dx,1.015,-.85),"733DE8") end
    part(item,"Temple",Vector3.new(.055,.055,.46),Vector3.new(side*.57,1.15,-.61),"733DE8")
   end
   part(item,"Bridge",Vector3.new(.15,.055,.06),Vector3.new(0,1.12,-.85),"733DE8")
  elseif id=="party_hat" then
   part(item,"Brim",Vector3.new(.9,.07,.85),Vector3.new(0,1.72,0),"FF5CB8")
   part(item,"Hat",Vector3.new(.58,.43,.58),Vector3.new(0,1.96,0),"59C9FF")
   part(item,"Pom",Vector3.one*.2,Vector3.new(0,2.27,0),"FFDE23",Enum.PartType.Ball)
  elseif id=="star_earrings" then
   for _,side in {-1,1} do
    part(item,"Stud",Vector3.one*.10,Vector3.new(side*.85,.96,0),"FFDE23",Enum.PartType.Ball)
    local p=part(item,"Charm",Vector3.new(.18,.18,.10),Vector3.new(side*.88,.75,0),"FF5CB8")
    p.CFrame*=CFrame.Angles(0,0,math.pi/4)
   end
  else item:Destroy() end
 end
end
return Factory
