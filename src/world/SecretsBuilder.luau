--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local C=require(Shared.SecretsConfig)
local Locale=require(Shared.LocaleText)
local Builder={}
function Builder.Build(world)
 local root=Instance.new("Model");root.Name="NeighborhoodSecrets";root.Parent=world
 local function model(name)
  local m=Instance.new("Model");m.Name=name;m.Parent=root;return m
 end
 local function part(parent,name,pos,size,hex,solid,neon,shape)
  local p=Instance.new("Part");p.Name=name;p.Position=pos;p.Size=size;p.Anchored=true
  p.Color=Color3.fromHex(hex);p.Material=if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
  p.CanCollide=solid==true;p.CanQuery=solid==true;p.CanTouch=false;p.CastShadow=solid==true
  if shape then p.Shape=shape end
  p.Parent=parent;return p
 end
 local function prompt(p,id,action,index,caption)
  local q=Instance.new("ProximityPrompt");q.Name="Interact";q.HoldDuration=if action=="Dynamo" then 1 else .35
  q.MaxActivationDistance=C.Reach;q.RequiresLineOfSight=false;q.Style=Enum.ProximityPromptStyle.Default
  q:SetAttribute("SecretId",id);q:SetAttribute("SecretAction",action);q:SetAttribute("SecretIndex",index or 0)
  Locale.SetWorld(q,"ObjectText",C.Items[id].Name);Locale.SetWorld(q,"ActionText",caption)
  q.Parent=p;q:AddTag("VeritySecretPrompt");return q
 end
 local function sign(parent,pos,text)
  local p=part(parent,"CluePlaque",pos,Vector3.new(11,2.8,.25),"37435F",false)
  local g=Instance.new("SurfaceGui");g.Face=Enum.NormalId.Back;g.PixelsPerStud=35;g.Parent=p
  local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
  label.TextColor3=Color3.fromHex("FFF4CE");label.Font=Enum.Font.GothamBold;label.TextSize=18;label.TextWrapped=true
  label.Parent=g;Locale.SetWorld(label,"Text",text)
 end
 local function chest(parent,pos,id)
  local base=part(parent,"Chest",pos,Vector3.new(2.7,1.8,2),C.Items[id].Color,false)
  part(parent,"ChestBand",pos,Vector3.new(.3,1.85,2.06),"FFF2C6",false)
  local lid=part(parent,"ChestLid",pos+Vector3.new(0,1,0),Vector3.new(2.9,.35,2.2),"FFF2C6",false)
  prompt(base,id,"Claim",0,"Открыть тайник");return base
 end
 local solar=model("Solar");local a=C.Solar
 local floor=part(solar,"Floor",a,Vector3.new(29,.6,25),"C9BCA6",true);solar.PrimaryPart=floor
 part(solar,"LeftWall",a+Vector3.new(-14,5,0),Vector3.new(.7,10,25),"7986AD",true)
 part(solar,"RightWall",a+Vector3.new(14,5,0),Vector3.new(.7,10,25),"7986AD",true)
 part(solar,"BackWall",a+Vector3.new(0,5,-12),Vector3.new(28,10,.7),"7986AD",true)
 part(solar,"Roof",a+Vector3.new(0,10,0),Vector3.new(29,.6,25),"BBA4E7",true)
 for _,side in {-1,1} do part(solar,"FrontWall",a+Vector3.new(side*9.3,5,12),Vector3.new(9.4,10,.7),"7986AD",true) end
 part(solar,"Lintel",a+Vector3.new(0,9.2,12),Vector3.new(9.4,1.7,.7),"FFD875",true)
 local gate=part(solar,"Door",a+Vector3.new(0,4,12),Vector3.new(9.2,8,.5),"FFE29A",true,true);gate.Transparency=.3
 prompt(part(solar,"Hint",a+Vector3.new(-10,1.5,19),Vector3.new(2,2.5,2),"FFD875",false),"solar","Hint",0,"Прочитать подсказку")
 local receiver=part(solar,"Receiver",a+Vector3.new(-10,4,12.5),Vector3.one*2.5,"6DDDEA",false,true,Enum.PartType.Ball)
 receiver.CanQuery=true;receiver:SetAttribute("SecretReceiver",true)
 prompt(part(solar,"Dynamo",a+Vector3.new(-10,1.4,15),Vector3.new(2.1,2.3,2),"E3B969",false),"solar","Dynamo",0,"Зарядить вручную")
 local names={"Солнце","Луна","Звезда"};local hues={"FFD875","A7BAFF","FFA6DE"}
 for i=1,3 do
  local p=part(solar,"Symbol"..i,a+Vector3.new((i-2)*6.8,1.3,19),Vector3.new(2.7,2.1,2.7),hues[i],false)
  part(solar,"SymbolGlow"..i,p.Position+Vector3.new(0,1.25,0),Vector3.one*.65,hues[i],false,true,Enum.PartType.Ball)
  prompt(p,"solar","Symbol",i,names[i])
 end
 sign(solar,a+Vector3.new(0,6.8,12.5),[[День → ночь → звезда
Лазер питает приёмник. Ручная зарядка тоже работает.]])
 chest(solar,a+Vector3.new(0,1.5,-6),"solar")
 prompt(part(solar,"Exit",a+Vector3.new(5,2,7),Vector3.new(.4,.4,.4),"8FEAFF",false),"solar","Exit",0,"Открыть выход")
 for _,x in {-9,9} do part(solar,"ArchiveShelf",a+Vector3.new(x,2,-5),Vector3.new(3,4,8),"AB9ACA",true) end

 local tree=model("Canopy");local b=C.Tree
 part(tree,"Trunk",b+Vector3.new(-5,11,0),Vector3.new(2.5,22,2.5),"B68D67",true)
 local steps={Vector3.new(-7,4,6),Vector3.new(-7,8,-4),Vector3.new(0,12,-11),Vector3.new(7,16,-4),Vector3.new(7,20,6),Vector3.new(0,24,0)}
 for i,pos in steps do part(tree,"Branch"..i,b+pos,Vector3.new(if i==6 then 17 else 8,.65,if i==6 then 15 else 8),"87CB97",true) end
 for _,side in {-1,1} do
  local crown=part(tree,"Leaves",b+Vector3.new(side*6,29,0),Vector3.new(10,3,11),"65C985",false,false,Enum.PartType.Ball);crown.Transparency=.12
 end
 prompt(part(tree,"Hint",b+Vector3.new(0,1.6,14),Vector3.new(2.5,2.5,2.5),"9AF5A9",false),"canopy","Hint",0,"Прочитать подсказку")
 local bellNames={"Лист","Капля","Солнце"};local bellColors={"91F2A5","80DEFF","FFE188"}
 for i=1,3 do
  local p=part(tree,"Bell"..i,b+Vector3.new((i-2)*5,25.7,2.7),Vector3.one*1.2,bellColors[i],false,true,Enum.PartType.Ball)
  prompt(p,"canopy","Bell",i,bellNames[i])
 end
 sign(tree,b+Vector3.new(0,27,-6.4),"Мелодия ветра: лист → капля → солнце")
 chest(tree,b+Vector3.new(0,25.6,-2.5),"canopy")
 prompt(part(tree,"Return",b+Vector3.new(6,25.8,1),Vector3.one*.8,"8FEAFF",false),"canopy","Return",0,"Спуститься")

 local cloud=model("Cloud");local c=C.Cloud
 local launch=part(cloud,"Launch",C.Launch,Vector3.new(9,.5,9),"8ACFEA",true)
 prompt(launch,"cloud","Start",0,"Начать воздушный маршрут")
 part(cloud,"SkyFloor",c,Vector3.new(18,.8,16),"D8EEF5",true)
 for _,side in {-1,1} do
  part(cloud,"Rail",c+Vector3.new(0,1.3,side*7.7),Vector3.new(17,2,.35),"A3DCE8",true)
 end
 for i,center in C.Rings do
  local ring=Instance.new("Model");ring.Name="Ring"..i;ring.Parent=cloud
  for segment=1,12 do
   local angle=segment*math.pi/6
   local p=part(ring,"Arc",center+Vector3.new(math.cos(angle)*5.7,math.sin(angle)*5.7,0),Vector3.new(2.9,.23,.25),"A6F1FB",false,true)
   p.CFrame*=CFrame.Angles(0,0,angle+math.pi/2);p.Transparency=.45
  end
 end
 sign(cloud,C.Launch+Vector3.new(0,3.2,-3.4),[[Три кольца ведут к облачной обсерватории.
Небесный полёт — за игровую валюту.]])
 chest(cloud,c+Vector3.new(0,1.5,0),"cloud")
 prompt(part(cloud,"Return",c+Vector3.new(5,1.7,1),Vector3.one*.8,"8FEAFF",false),"cloud","Return",0,"Вернуться на землю")
 return root
end
return Builder
