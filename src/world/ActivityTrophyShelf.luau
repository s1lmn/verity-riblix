--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Rewards=require(Shared.ActivityRewards)
local Locale=require(Shared.LocaleText)
local Shelf={}
local function part(parent,frame,name,pos,size,hex,ball)
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Material=Enum.Material.SmoothPlastic;p.Color=Color3.fromHex(hex);p.Size=size;p.CFrame=frame*CFrame.new(pos)
 if ball then p.Shape=Enum.PartType.Ball end
 p.Parent=parent;return p
end
local function label(parent,text,offset)
 local g=Instance.new("BillboardGui");g.Size=UDim2.fromOffset(130,32);g.StudsOffsetWorldSpace=Vector3.new(0,offset or 1,0);g.MaxDistance=24;g.Parent=parent
 local t=Instance.new("TextLabel");t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=.15;t.BackgroundColor3=Color3.fromHex("55416E")
 t.TextColor3=Color3.fromHex("FFF0CE");t.TextSize=11;t.Font=Enum.Font.GothamBold;t.TextWrapped=true;t.Parent=g;Locale.SetWorld(t,"Text",text)
end
function Shelf.Update(record,parent,pivot,state)
 local unlocked=state and state.ActivityTrophies or {}
 local visible=state and state.VerityUnlocked==true
 local signature=tostring(visible)
 for _,id in Rewards.Order do signature..=":"..tostring(unlocked[id]==true)end
 if record.signature==signature then return end
 record.signature=signature
 if record.model then record.model:Destroy();record.model=nil end
 if not visible then return end
 local model=Instance.new("Model");model.Name="AchievementTrophyShelf";record.model=model
 -- Freestanding cabinet against the left side of the entry room, clear of the door and kitchen.
 local frame=pivot*CFrame.new(-14.9,0,6)
 part(model,frame,"CabinetFoot",Vector3.new(0,1.2,0),Vector3.new(1.7,.4,11),"55416E")
 part(model,frame,"CabinetBack",Vector3.new(-.75,3.5,0),Vector3.new(.25,4.5,11),"9865FF")
 local top=part(model,frame,"TrophyShelf",Vector3.new(.1,3.8,0),Vector3.new(2.1,.3,11.4),"FFF0CE")
 label(top,"ТРОФЕИ VERITY",3.5)
 for index,id in Rewards.Order do
  local z=(index-2)*3.5;local reward=Rewards.Items[id]
  local earned=unlocked[id]==true
  local base=part(model,frame,id,Vector3.new(.1,4.05,z),Vector3.new(1.4,.25,2.5),if earned then reward.color else "C3BDD5")
  label(base,if earned then reward.trophy else reward.name,.1)
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
