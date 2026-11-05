--!nonstrict
-- Local decorative parts only. Server StreetDeliveryService owns the collectible.
local Factory={}
local Config=require(game:GetService("ReplicatedStorage").Shared.StreetDeliveryConfig)
local function part(model,name,pos,size,hex,cylinder)
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
 p.Material=Enum.Material.SmoothPlastic;p.Color=Color3.fromHex(hex);p.Size=size;p.CFrame=CFrame.new(pos)
 if cylinder then p.Shape=Enum.PartType.Cylinder end
 p.Parent=model;return p
end
function Factory.Truck(parent,color)
 local m=Instance.new("Model");m.Name="ToyDeliveryVan";local wheels={}
 part(m,"Chassis",Vector3.new(0,1.8,0),Vector3.new(7,1,13),"64557F")
 part(m,"Cargo",Vector3.new(0,5.3,2),Vector3.new(7.2,6.4,8.6),color)
 part(m,"Cabin",Vector3.new(0,4,-4.7),Vector3.new(7,4.6,4.3),color)
 part(m,"Windscreen",Vector3.new(0,5.15,-6.87),Vector3.new(5.9,1.9,.12),"80E3F2")
 part(m,"FrontBumper",Vector3.new(0,2.2,-7),Vector3.new(7.5,.7,.6),"FFF0CE")
 part(m,"Grille",Vector3.new(0,3,-6.92),Vector3.new(2.8,.75,.15),"64557F")
 for _,x in {-2.5,2.5} do part(m,"Headlight",Vector3.new(x,3.35,-6.95),Vector3.new(1.2,.8,.18),"FFF5B0")end
 for _,x in {-3.65,3.65} do
  for _,z in {-4.5,4.2} do
   local tire=part(m,"Wheel",Vector3.new(x,1.55,z),Vector3.new(.9,3,3),"443B63",true)
   local hub=part(m,"WheelHub",Vector3.new(x+(if x>0 then .5 else -.5),1.55,z),Vector3.new(.12,1.45,1.45),"FFF0CE",true)
   table.insert(wheels,{tire=tire,hub=hub,tireCF=tire.CFrame,hubCF=hub.CFrame})
  end
 end
 for _,x in {-2,2} do for _,z in {0,4} do
  part(m,"RoofStud",Vector3.new(x,8.7,z),Vector3.new(1.3,.35,1.3),color)
 end end
 for _,x in {-3.66,3.66} do
  local badge=part(m,"VerityBadge",Vector3.new(x,5.6,1.45),Vector3.new(.12,3.4,4.7),"FFF0CE")
  local gui=Instance.new("SurfaceGui");gui.Face=if x>0 then Enum.NormalId.Right else Enum.NormalId.Left;gui.PixelsPerStud=35;gui.Parent=badge
  local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1;label.Font=Enum.Font.GothamBlack
  label.Text="VERITY\nEXPRESS";label.TextScaled=true;label.TextColor3=Color3.fromHex("64557F");label.Parent=gui
 end
 for _,x in {-3.69,3.69} do
  part(m,"ParcelHatch",Vector3.new(x,5.15,4.6),Vector3.new(.12,1.25,1.1),"443B63")
 end
 m.WorldPivot=CFrame.identity;m:ScaleTo(Config.TruckScale)
 for _,wheel in wheels do wheel.tireCF=wheel.tire.CFrame;wheel.hubCF=wheel.hub.CFrame end
 m.Parent=parent;return m,wheels
end
function Factory.Parcel(parent)
 local m=Instance.new("Model");m.Name="FallenGift"
 part(m,"Box",Vector3.zero,Vector3.new(2.3,2.3,2.3),"FFCE45")
 part(m,"RibbonX",Vector3.zero,Vector3.new(2.38,2.38,.38),"C77DFF")
 part(m,"RibbonZ",Vector3.zero,Vector3.new(.38,2.4,2.4),"C77DFF")
 for _,x in {-.45,.45} do part(m,"Bow",Vector3.new(x,1.4,0),Vector3.new(.8,.5,.6),"FF81BE")end
 local labelPart=part(m,"LabelAnchor",Vector3.new(0,1.7,0),Vector3.one*.1,"FFFFFF");labelPart.Transparency=1
 local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(154,36);gui.MaxDistance=38;gui.StudsOffsetWorldSpace=Vector3.new(0,1,0);gui.Parent=labelPart
 local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=.1;label.BackgroundColor3=Color3.fromHex("64557F")
 label.TextColor3=Color3.fromHex("FFF0CE");label.Font=Enum.Font.GothamBold;label.TextSize=14;label.TextWrapped=true;label.Parent=gui
 local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=label
 m.WorldPivot=CFrame.identity;m.Parent=parent;return m,label
end
return Factory
