--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.AdventureConfig)
local Locale=require(RS.Shared.LocaleText)
local Sign=require(script.Parent.WorldSign)
local B={}
function B.Build(world,plots)
 local root=Instance.new("Folder");root.Name="NeighborhoodAdventures";root.Parent=world
 local r={root=root,trial={},stars={},runes={},jets={},parties={}}
 local function model(name,parent)
  local m=Instance.new("Model");m.Name=name;m.ModelStreamingMode=Enum.ModelStreamingMode.Atomic;m.Parent=parent or root;return m
 end
 local function p(parent,name,pos,size,color,solid,neon,shape)
  local o=Instance.new("Part");o.Name=name;o.Size=size;o.Position=pos;o.Anchored=true
  o.Color=Color3.fromHex(color);o.Material=if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
  o.CanCollide=solid==true;o.CanQuery=solid==true;o.CanTouch=false;o.CastShadow=solid==true
  if shape then o.Shape=shape end;o.Parent=parent;return o
 end
 local function prompt(part,action,title,kind,id,index,plot)
  local q=Instance.new("ProximityPrompt");q.Name="AdventurePrompt";q.MaxActivationDistance=C.Reach;q.HoldDuration=.35;q.RequiresLineOfSight=false
  Locale.SetWorld(q,"ObjectText",title);Locale.SetWorld(q,"ActionText",action)
  q:SetAttribute("AdventureKind",kind);q:SetAttribute("AdventureId",id or "");q:SetAttribute("AdventureIndex",index or 0);q:SetAttribute("AdventurePlot",plot or 0)
  q.Parent=part;q:AddTag("VerityAdventurePrompt");return q
 end
 local function sign(parent,pos,title)
  local board=p(parent,"Sign",pos,Vector3.new(8,2.5,.25),"363956",false)
  return Sign.Add(board,title)
 end
 local function circle(parent,name,pos,radius,color)
  local base=p(parent,name,pos,Vector3.new(.16,radius*2,radius*2),color,false,true,Enum.PartType.Cylinder)
  base.CFrame*=CFrame.Angles(0,0,math.pi/2);return base
 end
 local function ring(parent,pos,radius,color)
  for i=1,12 do
   local a=i*math.pi/6;local o=p(parent,"RingSegment",pos+Vector3.new(math.cos(a)*radius,math.sin(a)*radius,0),Vector3.new(.28,radius*.54,.24),color,false,true)
   o.CFrame=CFrame.new(o.Position)*CFrame.Angles(0,0,a-math.pi/2)
  end
 end
 local function gift(parent,pos,color)
  local box=p(parent,"Gift",pos,Vector3.new(1.25,1,1.25),color,false)
  p(parent,"Ribbon",pos,Vector3.new(.16,1.06,1.3),"FFF0CD",false)
  p(parent,"Lid",pos+Vector3.new(0,.57,0),Vector3.new(1.4,.18,1.4),"FFE497",false)
  return box
 end
 local plaza=world.Plaza.WelcomePad
 local desk=model("WeatherDesk")
 local station=p(desk,"Station",plaza.Position+Vector3.new(-14,1,-8),Vector3.new(2.8,2,2),"9271BE",false)
 circle(desk,"Base",station.Position-Vector3.yAxis*.85,2,"C5AAFF")
 station.Shape=Enum.PartType.Cylinder;station.Size=Vector3.new(2,2.8,2.8);station.CFrame*=CFrame.Angles(0,0,math.pi/2)
 local dome=p(desk,"WeatherDome",station.Position+Vector3.yAxis*1.6,Vector3.new(2.5,2.1,2.5),"99DDE9",false,false,Enum.PartType.Ball)
 p(desk,"DomeBand",station.Position+Vector3.yAxis*.95,Vector3.new(2.8,.22,2.8),"EAD5A2",false)
 local telescope=p(desk,"Telescope",station.Position+Vector3.new(0,3.15,0),Vector3.new(2.2,.75,.75),"68558B",false,false,Enum.PartType.Cylinder)
 telescope.CFrame*=CFrame.Angles(0,0,.38)
 local lens=p(desk,"TelescopeLens",station.Position+Vector3.new(1,3.55,0),Vector3.new(.10,.64,.64),"BCF7F5",false,true,Enum.PartType.Cylinder);lens.CFrame*=CFrame.Angles(0,0,.38)
 for _,side in {-1,1} do
  local brace=p(desk,"TelescopeBrace",station.Position+Vector3.new(side*.6,2.15,0),Vector3.new(.14,1.35,.14),"EAD5A2",false)
  brace.CFrame*=CFrame.Angles(0,0,side*-.4)
 end
 r.weatherPrompt=prompt(station,"Искать звёздные осколки","Обсерватория погоды","Weather")
 r.weatherLabels=sign(desk,station.Position+Vector3.new(0,2.4,0),"Обсерватория погоды")
 local stars=Instance.new("Folder");stars.Name="StarShards";stars.Parent=root
 for i,pos in C.StarPoints do
  local m=model("Star"..i,stars);local shard=p(m,"Core",pos,Vector3.new(.65,1.1,.65),"D7BCFF",false,true)
  shard.CFrame*=CFrame.Angles(0,0,math.pi/4);circle(m,"Halo",pos-Vector3.new(0,1.4,0),1.6,"C5AAFF")
  local q=prompt(shard,"Подобрать осколок","Звёздный дождь","Star","",i);r.stars[i]={model=m,part=shard,prompt=q}
 end
 local campus=model("AbilityCampus");local t=C.TrialCenter
 p(campus,"Terrace",t-Vector3.new(0,.4,0),Vector3.new(112,.8,106),"94B7C0",true)
 p(campus,"EntranceWalk",Vector3.new(-127,.33,t.Z+5),Vector3.new(112,.66,10),"C5B8DD",true)
 sign(campus,t+Vector3.new(0,5,48),"ИСПЫТАНИЯ СПОСОБНОСТЕЙ")
 for _,id in C.TrialOrder do
  local d=C.Trials[id];local m=model(id,campus)
  local pad=circle(m,"Start",d.Start,3.6,d.Color)
  local q=prompt(pad,"Начать испытание",d.Name,"Trial",id)
  sign(m,d.Start+Vector3.new(0,2.8,2.6),d.Name)
  r.trial[id]={start=pad,prompt=q,targets={}}
  for i,pos in d.Points do
   local target=p(m,"Target"..i,pos,Vector3.one*(if id=="laser" then 2 else .35),d.Color,false,id=="laser",Enum.PartType.Ball)
   if id=="laser" then
    target.CanQuery=true;target:SetAttribute("TrialReceiver",true)
    circle(m,"TargetStand",pos-Vector3.new(0,3,0),2,d.Color)
   else ring(m,pos,if id=="dash" then 3.3 else 4.2,d.Color) end
   r.trial[id].targets[i]=target
  end
 end
 local entrance=model("RainEntrance")
 local a=C.CaveEntrance
 p(entrance,"Landing",a-Vector3.new(0,.4,0),Vector3.new(15,.8,13),"89A4BC",true)
 for side=-1,1,2 do
  p(entrance,"StoneArch",a+Vector3.new(side*4,3,0),Vector3.new(2,7,3),"657895",true)
  p(entrance,"PortalTrim",a+Vector3.new(side*2.8,3,.1),Vector3.new(.24,5,.3),"8AE6ED",false,true)
 end
 p(entrance,"ArchCap",a+Vector3.new(0,6.8,0),Vector3.new(10,2.2,3),"8B91B6",true)
 r.portal=p(entrance,"WaterSeal",a+Vector3.new(0,2.6,0),Vector3.new(5.2,5,.25),"8AE6ED",false,true);r.portal.Transparency=.4
 r.cavePrompt=prompt(r.portal,"Войти в тайную пещеру","Откроется после ливня","Cave")
 r.caveLabels=sign(entrance,a+Vector3.new(0,8.5,0),"Откроется после ливня")
 local cave=model("RainCave");cave.ModelStreamingMode=Enum.ModelStreamingMode.Persistent;local c=C.CaveCenter
 p(cave,"Floor",c,Vector3.new(88,1,65),"426A7C",true)
 p(cave,"Roof",c+Vector3.new(0,19,0),Vector3.new(88,1,65),"495274",true)
 for side=-1,1,2 do
  p(cave,"SideWall",c+Vector3.new(side*44,9,0),Vector3.new(2,20,65),"505B7E",true)
  p(cave,"EndWall",c+Vector3.new(0,9,side*32.5),Vector3.new(88,20,2),"505B7E",true)
 end
 for i=1,12 do
  local x=if i%2==0 then -41 else 41;local z=-27+math.ceil(i/2)*8
  local gem=p(cave,"CavePrism",c+Vector3.new(x,3+i%3*2,z),Vector3.new(1.5,5+i%2*2,1.5),if i%2==0 then "80E8EB" else "B8AEFF",false,true)
  gem.CFrame*=CFrame.Angles(0,0,if x<0 then -.25 else .25)
 end
 for side=-1,1,2 do
  for i=1,5 do
   local rock=p(cave,"RockRib",c+Vector3.new(side*39,5+i%2,-27+i*10),Vector3.new(5,11+i%3,5),if i%2==0 then "65749B" else "58668A",true)
   rock.CFrame*=CFrame.Angles(.06*i,side*.17,side*.12)
   local tip=p(cave,"CeilingRock",c+Vector3.new(side*24,16,-24+i*9),Vector3.new(3,5+i%2,4),"637299",true)
   tip.CFrame*=CFrame.Angles(0,i*.3,side*.12)
  end
 end
 p(cave,"StonePillar",c+Vector3.new(0,5,7),Vector3.new(4,10,4),"596D87",true)
 local pool=p(cave,"LuminousWater",c+Vector3.new(-4,.56,-9),Vector3.new(14,.12,5),"81D5DF",false,true);pool.Transparency=.55
 for side=-1,1,2 do
  local lantern=p(cave,"CaveLantern",c+Vector3.new(side*22,7,0),Vector3.one*.8,"A1E9E6",false,true,Enum.PartType.Ball)
  local light=Instance.new("PointLight");light.Color=Color3.fromHex("A1DFEA");light.Brightness=.6;light.Range=24;light.Shadows=false;light.Parent=lantern
 end
 for i,pos in C.Runes do
  circle(cave,"RunePedestal",pos-Vector3.new(0,1.9,0),3,"7CA7BB")
  local rune=p(cave,"Rune"..i,pos,Vector3.new(1.8,2,.6),({"FFE795","B5BCFF","9FF5D7"})[i],false,true)
  rune.CFrame*=CFrame.Angles(0,0,math.pi/4)
  r.runes[i]=prompt(rune,({"Взять солнечную руну","Взять лунную руну","Взять звёздную руну"})[i],"Дождевая пещера","Rune","",i)
 end
 local chest=gift(cave,C.Chest,"8BC9E4");r.chestPrompt=prompt(chest,"Открыть сокровище","Три руны открывают сундук","Chest")
 local exit=p(cave,"ExitBeacon",C.CaveSpawn+Vector3.new(0,0,3),Vector3.new(3,3,.5),"9CEBCE",false,true)
 r.exitPrompt=prompt(exit,"Вернуться в район","Выход всегда открыт","Exit")
 for i,pos in C.Jets do
  local base=circle(cave,"GeyserBase",pos+Vector3.new(0,.65,0),3.4,"8AE4FF")
  local jet=p(cave,"WaterJet",pos+Vector3.new(0,3.5,0),Vector3.new(3.2,6,3.2),"90E5FA",false,true);jet.Transparency=1
  r.jets[i]={base=base,jet=jet}
 end
 local partyRoot=Instance.new("Folder");partyRoot.Name="HouseParties";partyRoot.Parent=root
 for plotId,record in plots do
  local m=model("Plot"..plotId,partyRoot);local pivot=record.pivot
  local board=p(m,"PartyBoard",pivot:PointToWorldSpace(Vector3.new(-8,1.6,18.2)),Vector3.new(2.8,2.2,.4),"A881D4",false)
  board.CFrame=pivot*CFrame.new(-8,1.6,18.2)
  local entry={model=m,board=board,nodes={},display={},plot=plotId}
  entry.host=prompt(board,"Устроить вечеринку","Поиск подарков","HostParty","",0,plotId)
  entry.next=prompt(board,"Сменить игру","Поиск подарков","PartyMode","",0,plotId);entry.next.KeyboardKeyCode=Enum.KeyCode.R;entry.next.GamepadKeyCode=Enum.KeyCode.ButtonY;entry.next.UIOffset=Vector2.new(0,-55)
  entry.join=prompt(board,"Присоединиться","Вечеринка у соседей","JoinParty","",0,plotId)
  entry.stop=prompt(board,"Завершить вечеринку","Моя вечеринка","StopParty","",0,plotId);entry.stop.KeyboardKeyCode=Enum.KeyCode.R;entry.stop.GamepadKeyCode=Enum.KeyCode.ButtonY
  entry.sign=p(m,"PartySign",board.Position+Vector3.new(0,3.1,0),Vector3.new(7,3.3,.25),"363956",false)
  entry.sign.CFrame=pivot*CFrame.new(-8,4.7,18.2)
  entry.labels=Sign.Add(entry.sign,"Домашние вечеринки",nil,38)
  for i,offset in C.PartyPoints do
   local giftModel=model("Gift"..i,m);local pos=pivot:PointToWorldSpace(offset)
   local box=gift(giftModel,pos,if i%2==0 then "A8EECD" else "FFB6DB")
   local q=prompt(box,"Найти подарок","Домашняя вечеринка","PartyGift","",i,plotId)
   entry.nodes[i]={model=giftModel,part=box,prompt=q}
  end
  for side=-1,1,2 do
   for i=1,2 do
    local pos=pivot:PointToWorldSpace(Vector3.new(side*(5+i),5.2+(i%2)*1.1,17.5))
    table.insert(entry.display,p(m,"Balloon",pos,Vector3.new(.9,1.2,.9),if i==1 then "FFB2D8" else "FFE295",false,false,Enum.PartType.Ball))
    table.insert(entry.display,p(m,"String",pos-Vector3.new(0,1.3,0),Vector3.new(.03,1.6,.03),"FFF0D1",false))
   end
  end
  r.parties[plotId]=entry
 end
 return r
end
return B
