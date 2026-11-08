--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Rewards=require(Shared.ActivityRewards)
local Shelf={}
local function part(parent,frame,name,pos,size,hex,ball)
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Material=Enum.Material.SmoothPlastic;p.Color=Color3.fromHex(hex);p.Size=size;p.CFrame=frame*CFrame.new(pos)
 if ball then p.Shape=Enum.PartType.Ball end
 p.Parent=parent;return p
end
function Shelf.Update(record,parent,pivot,state)
 local unlocked=state and state.ActivityTrophies or {}
 local visible=state and state.VerityUnlocked==true and (state.HouseIncomeLevel or 0)>=1
 local signature=tostring(visible)
 for _,id in Rewards.Order do signature..=":"..tostring(unlocked[id]==true)end
 if record.signature==signature then return end
 record.signature=signature
 if record.model then record.model:Destroy();record.model=nil end
 if not visible then return end
 local model=Instance.new("Model");model.Name="AchievementTrophyShelf";record.model=model
 -- A shallow wall-mounted cup, with the existing earned rewards on the shelf below.
 local frame=pivot*CFrame.new(-15.3,0,6)
 part(model,frame,"TrophyShelf",Vector3.new(.05,3.8,0),Vector3.new(2,.26,11.4),"FFF0CE")
 part(model,frame,"ShelfGoldEdge",Vector3.new(1.06,3.76,0),Vector3.new(.10,.22,11.4),"D9B570")
 for _,z in {-4.5,4.5} do
  part(model,frame,"WallBracket",Vector3.new(-.66,3.28,z),Vector3.new(.22,1.1,.25),"8F76B4")
  part(model,frame,"ShelfBracket",Vector3.new(.02,3.38,z),Vector3.new(1.5,.18,.25),"8F76B4")
 end
 local emblem=Instance.new("Model");emblem.Name="WallTrophyEmblem";emblem.Parent=model
 local gold="EBC774"
 part(emblem,frame,"CupFoot",Vector3.new(-.47,7.35,0),Vector3.new(.48,.26,1.85),gold)
 part(emblem,frame,"CupStem",Vector3.new(-.49,7.9,0),Vector3.new(.38,.9,.34),gold)
 part(emblem,frame,"CupLowerBowl",Vector3.new(-.49,8.4,0),Vector3.new(.42,.48,1.35),gold)
 part(emblem,frame,"CupBowl",Vector3.new(-.49,8.84,0),Vector3.new(.42,.40,2.15),gold)
 part(emblem,frame,"CupRim",Vector3.new(-.46,9.15,0),Vector3.new(.50,.22,2.65),"FFE8AE")
 for _,side in {-1,1} do
  part(emblem,frame,"HandleTop",Vector3.new(-.50,8.92,side*1.4),Vector3.new(.30,.19,.65),gold)
  part(emblem,frame,"HandleOuter",Vector3.new(-.50,8.57,side*1.7),Vector3.new(.30,.85,.19),gold)
  part(emblem,frame,"HandleBottom",Vector3.new(-.50,8.18,side*1.4),Vector3.new(.30,.19,.65),gold)
 end
 local gem=part(emblem,frame,"CupGem",Vector3.new(-.24,8.62,0),Vector3.new(.13,.34,.34),"FFF5CD")
 gem.CFrame*=CFrame.Angles(math.pi/4,0,0)
 for index,id in Rewards.Order do
  local z=(index-2)*3.5;local reward=Rewards.Items[id]
  local earned=unlocked[id]==true
  part(model,frame,id,Vector3.new(.1,4.05,z),Vector3.new(1.4,.25,2.5),if earned then reward.color else "C3BDD5")
  if not earned then continue end
  if id=="parkour_clear" then
   local star=part(model,frame,"StarMedal",Vector3.new(.1,5.1,z),Vector3.new(.4,1.4,1.4),"FFCE45")
   star.CFrame*=CFrame.Angles(math.pi/4,0,0)
   part(model,frame,"StarCore",Vector3.new(.35,5.1,z),Vector3.new(.2,.5,.5),"FFF0AE",true)
   part(model,frame,"Ribbon",Vector3.new(.1,4.45,z),Vector3.new(.3,.6,.65),"9865FF")
  elseif id=="race_champion" then
   part(model,frame,"CupStem",Vector3.new(.1,4.6,z),Vector3.new(.4,.9,.4),"FFCE45")
   part(model,frame,"Cup",Vector3.new(.1,5.3,z),Vector3.new(1.1,.85,1.4),"FFCE45")
   for _,side in {-1,1}do part(model,frame,"CupHandle",Vector3.new(.1,5.3,z+side*.9),Vector3.new(.45,.5,.3),"FFEBA0")end
  else
   local titan=part(model,frame,"Titan",Vector3.new(.1,5,z),Vector3.new(1.3,1.3,1.3),"A78AFF",true)
   for _,side in {-1,1}do part(model,frame,"TitanEye",Vector3.new(.76,5.1,z+side*.28),Vector3.new(.06,.18,.2),"FFCE45")end
  end
 end
 model.Parent=parent
end
return Shelf
