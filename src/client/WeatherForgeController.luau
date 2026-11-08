--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local Collection=game:GetService("CollectionService")
local Gui=game:GetService("GuiService")
local F=require(RS.Shared.WeatherForgeConfig)
local Factory=require(RS.World.VerityFactory)
local Cosmetics=require(RS.World.CosmeticFactory)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Art=require(script.Parent.CollectionArt)
local Locale=require(script.Parent.Locale)
local Card=require(script.Parent.ActivityCard)
local Cleanup=require(script.Parent.Cleanup)
local Controller={};Controller.__index=Controller
local function centerText(parent,name,text,size,color)
 local label=W.Text(parent,name,text,size,true,color);label.TextXAlignment=Enum.TextXAlignment.Center;return label
end
local function preview(parent,recipe)
 local world=W.New("WorldModel",{},parent)
 local camera=W.New("Camera",{CFrame=CFrame.lookAt(Vector3.new(0,1.35,-5.3),Vector3.new(0,1.05,0)),FieldOfView=40},parent);parent.CurrentCamera=camera
 local model
 if recipe.Type=="Look" or recipe.Type=="Cosmetic" then
  local look=recipe.Look and F.Looks[recipe.Look]
  model=Factory.Create(world,CFrame.identity,{level=1,preview=true,elementalSkin=look and look.Skin})
  local label=model.PrimaryPart:FindFirstChild("LevelLabel");if label then label.Enabled=false end
  if recipe.Type=="Cosmetic" then Cosmetics.Apply(model,{Head=recipe.Item}) end
 else
  model=Instance.new("Model");model.Name="ForgedDecor";model.Parent=world
  local function p(name,size,pos,color,shape)
   local o=Instance.new("Part");o.Name=name;o.Size=size;o.Position=pos;o.Color=Color3.fromHex(color);o.Anchored=true;o.CanCollide=false;o.CastShadow=false
   o.Material=Enum.Material.Neon;if shape then o.Shape=shape end;o.Parent=model;return o
  end
  local base=p("Base",Vector3.new(1.7,.2,1.4),Vector3.new(0,.15,0),"64517F");base.Material=Enum.Material.SmoothPlastic;model.PrimaryPart=base
  local core=p("Core",Vector3.one*1.15,Vector3.new(0,1.05,0),recipe.Color,Enum.PartType.Ball)
  if recipe.Id=="brazier" then
   for i=-1,1 do p("Flame",Vector3.new(.33,.65,.33),Vector3.new(i*.3,1.45+math.abs(i)*-.12,0),if i==0 then "FFE1A0" else "FF9B59",Enum.PartType.Ball) end
   for side=-1,1,2 do p("Bowl",Vector3.new(.2,.65,1.1),Vector3.new(side*.65,.7,0),"D9B77A") end
  else for i=1,12 do
   local a=i*math.pi/6;local part=p("Orbit",Vector3.new(.10,.10,.52),Vector3.new(math.cos(a)*.95,1.05+math.sin(a)*.38,math.sin(a)*.75),"FFE5AA")
   part.CFrame*=CFrame.Angles(0,-a,0)
  end end
  local origin=Instance.new("Part");origin.Name="Pivot";origin.Transparency=1;origin.Size=Vector3.one*.01;origin.Anchored=true;origin.Parent=model;model.PrimaryPart=origin
 end
 return world,camera,model
end
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),rows={},queue={},seen={},seenOrder={},prompts={},sceneOrbs={},sceneSparks={}},Controller)
 local root=W.Round(W.Frame(ctx.refs.Safe,"WeatherForgePanel",UDim2.fromOffset(420,560),T.Paper),20);root.Visible=false;root.Active=true;root.SelectionGroup=true;root.ZIndex=12;self.root=self.cleanup:Add(root)
 W.New("UIGradient",{Color=ColorSequence.new(T.Paper,Color3.fromHex("EBDFFA")),Rotation=65},root);W.Stroke(root,T.Purple,2).Transparency=.4
 local title=W.Text(root,"Title","КУЗНИЦА ПОГОДЫ",20,true,T.Purple);title.Position=UDim2.fromOffset(14,6);title.Size=UDim2.new(1,-126,0,35)
 local close=W.Button(root,"Close","×",T.Gold);close.Position=UDim2.new(1,-54,0,5);close.Size=UDim2.fromOffset(44,44)
 self.title=title;self.close=close
 local help=W.Button(root,"MaterialHelp","?",T.Purple:Lerp(T.White,.75));help.Position=UDim2.new(1,-104,0,5);help.Size=UDim2.fromOffset(44,44);help:SetAttribute("FixedFeedbackSize",true)
 self.cleanup:Add(help.Activated:Connect(function()ctx.notifications:Show("Угольки — огненное небо. Пыль — звёздный дождь. Жемчужины — пещера после ливня.","Info",7)end))
 self.materials=W.Frame(root,"Materials",UDim2.new(1,-24,0,52));self.materials.BackgroundTransparency=1
 self.materialLabels={}
 for i,id in F.MaterialOrder do
  local d=F.Materials[id];local cell=W.Round(W.Frame(self.materials,id,UDim2.new(1/3,-5,1,0),Color3.fromHex(d.Color):Lerp(T.White,.65)),10);cell.Position=UDim2.new((i-1)/3,2,0,0)
  local name=centerText(cell,"Name",d.Short,10,T.Ink);name.Position=UDim2.fromOffset(3,3);name.Size=UDim2.new(1,-6,0,17)
  local count=centerText(cell,"Amount","0",19,T.Purple);count.Position=UDim2.fromOffset(3,20);count.Size=UDim2.new(1,-6,1,-23);self.materialLabels[id]=count
  local hint=W.New("TextButton",{Name="Source",BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1),AutoButtonColor=false,Selectable=true},cell)
  self.cleanup:Add(hint.Activated:Connect(function()ctx.notifications:Show(d.Source,"Info",5)end))
 end
 self.modes=W.Frame(root,"LookModes",UDim2.new(1,-24,0,44));self.modes.BackgroundTransparency=1;self.modeButtons={}
 for i,entry in {{"Auto","ПО ПОГОДЕ"},{"Original","ПО УРОВНЮ"}} do
  local b=W.Button(self.modes,entry[1],entry[2],T.Mint:Lerp(T.White,.45));b.Position=UDim2.new((i-1)/2,2,0,0);b.Size=UDim2.new(.5,-4,1,0);b.TextSize=12;b:SetAttribute("FixedFeedbackSize",true);self.modeButtons[entry[1]]=b
  self.cleanup:Add(b.Activated:Connect(function()ctx.request("SetWeatherLook",{itemId=entry[1]})end))
 end
 self.list=W.New("ScrollingFrame",{Name="Recipes",BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4,ScrollBarImageColor3=T.Purple,ScrollingDirection=Enum.ScrollingDirection.Y},root);W.List(self.list,9)
 local subtitle=W.Text(root,"Subtitle","",1);subtitle.Visible=false
 ctx.refs.Panels.FORGE={Root=root,Title=title,Subtitle=subtitle,Body=self.list,Close=close}
 self.layer=self.cleanup:Add(W.Frame(ctx.refs.Safe,"ForgeReveal"));self.layer.BackgroundTransparency=1;self.layer.Visible=false;self.layer.Active=true;self.layer.ZIndex=60
 self.revealCard=W.Round(W.Frame(self.layer,"ForgeCreation",UDim2.fromOffset(360,440),Color3.fromHex("2C2149")),24)
 self.revealCard.AnchorPoint=Vector2.new(.5,.5);self.revealCard.Position=UDim2.fromScale(.5,.5);W.Stroke(self.revealCard,T.Gold,2).Transparency=.15
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("51376F"),Color3.fromHex("221D38")),Rotation=100},self.revealCard)
 self.revealScale=W.New("UIScale",{Scale=1},self.revealCard)
 self.revealTag=centerText(self.revealCard,"Stage","СОБИРАЕМ СТИХИИ",11,T.Gold);self.revealTag.Position=UDim2.fromScale(.05,.035);self.revealTag.Size=UDim2.fromScale(.9,.07)
 self.revealName=centerText(self.revealCard,"Name","",21,T.White);self.revealName.Position=UDim2.fromScale(.05,.12);self.revealName.Size=UDim2.fromScale(.9,.12)
 self.halos={}
 for i=1,3 do
  local halo=W.Round(W.Frame(self.revealCard,"EnergyRing",UDim2.fromScale(.67+i*.06,.58)),100);halo.BackgroundTransparency=1;halo.AnchorPoint=Vector2.new(.5,.5);halo.Position=UDim2.fromScale(.5,.51)
  W.New("UIAspectRatioConstraint",{AspectRatio=1},halo);local stroke=W.Stroke(halo,T.Gold,if i==1 then 3 else 1);stroke.Transparency=.25+i*.12;self.halos[i]={root=halo,stroke=stroke}
 end
 self.viewport=W.New("ViewportFrame",{Name="Creation",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.515),Size=UDim2.fromScale(.84,.49),BackgroundTransparency=1,Ambient=Color3.fromRGB(210,210,210),LightColor=T.White,LightDirection=Vector3.new(-1,-1,-1)},self.revealCard)
 self.creationScale=W.New("UIScale",{Scale=1},self.viewport)
 self.revealDetail=centerText(self.revealCard,"Detail","",12,T.White);self.revealDetail.Position=UDim2.fromScale(.07,.81);self.revealDetail.Size=UDim2.fromScale(.86,.12)
 self.elements={}
 for i,id in F.MaterialOrder do
  local token=W.Round(W.Frame(self.revealCard,"Element",UDim2.fromOffset(30,30),Color3.fromHex(F.Materials[id].Color)),100)
  token.AnchorPoint=Vector2.new(.5,.5);W.Stroke(token,T.White,2).Transparency=.3
  local star=centerText(token,"Symbol",if i==1 then "☀" elseif i==2 then "✦" else "◆",21,T.White);star.Size=UDim2.fromScale(1,1)
  self.elements[i]=token
 end
 self.motes={};for i=1,24 do
  local spark=W.Round(W.Frame(self.revealCard,"ForgeSpark",UDim2.fromOffset(if i%2==0 then 6 else 4,if i%2==0 then 6 else 4),T.Gold),2)
  spark.AnchorPoint=Vector2.new(.5,.5);spark.Rotation=45;self.motes[i]=spark
 end
 for _,o in self.layer:GetDescendants() do if o:IsA("GuiObject") then o.ZIndex=61 end end
 self.viewport.ZIndex=63;self.revealTag.ZIndex=64;self.revealName.ZIndex=64;self.revealDetail.ZIndex=64
 local folder=Instance.new("Folder");folder.Name="ForgeLocalFeedback";folder.Parent=workspace;self.sceneFolder=self.cleanup:Add(folder)
 for i=1,18 do
  local p=Instance.new("Part");p.Name="ForgingSpark";p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false;p.Material=Enum.Material.Neon;p.Shape=Enum.PartType.Ball;p.Size=Vector3.one*.15;p.Transparency=1;p.Parent=folder;self.sceneSparks[i]=p
 end
 local function add(q)self.prompts[q]=q.Enabled end
 self.cleanup:Add(Collection:GetInstanceAddedSignal("VerityWeatherForgePrompt"):Connect(add));self.cleanup:Add(Collection:GetInstanceRemovedSignal("VerityWeatherForgePrompt"):Connect(function(q)self.prompts[q]=nil end))
 for _,q in Collection:GetTagged("VerityWeatherForgePrompt") do add(q) end
 local function attach(remote)
  if not remote or remote.Name~="VerityWeatherForge" or not remote:IsA("RemoteEvent") or remote==self.remote then return end
  if self.link then self.link:Disconnect() end;self.remote=remote
  self.link=remote.OnClientEvent:Connect(function(m)
   if type(m)~="table" or m.version~=F.Version then return end
   if m.kind=="Open" then self.routeRequested=nil;self.visited=true;ctx.open("FORGE");self:Render()
   elseif m.kind=="Materials" then self.routeRequested=os.clock()+180
   elseif m.kind=="Crafted" and type(m.eventId)=="string" and F.Recipes[m.recipeId] and not self.seen[m.eventId] then
    self.seen[m.eventId]=true;table.insert(self.seenOrder,m.eventId);if #self.seenOrder>64 then self.seen[table.remove(self.seenOrder,1)]=nil end
    table.insert(self.queue,m.recipeId)
   end
  end)
 end
 self.cleanup:Add(RS.ChildAdded:Connect(attach));attach(RS:FindFirstChild("VerityWeatherForge"))
 self.cleanup:Add(RS.ChildRemoved:Connect(function(remote)if remote==self.remote then if self.link then self.link:Disconnect();self.link=nil end;self.remote=nil;self:EndReveal() end end))
 self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function()table.clear(self.queue);self:EndReveal();if ctx.active=="FORGE" then ctx.close() end end))
 self.cleanup:Add(Locale.Changed.Event:Connect(function()self.signature=nil;self:Render()end))
 self.cleanup:Add(function()if self.link then self.link:Disconnect()end;self:EndReveal()end)
 return self
end
function Controller:Near()
 local p=Players.LocalPlayer;local c=p.Character;local root=c and c:FindFirstChild("HumanoidRootPart");local hum=c and c:FindFirstChildOfClass("Humanoid")
 return root~=nil and hum~=nil and hum.Health>0 and (root.Position-(F.Position+Vector3.yAxis*2.3)).Magnitude<=F.Reach+1 and not Card.ActivityRunning() and not p:GetAttribute("VerityRiding")
end
function Controller:Goal()
 local state=self.ctx.net.state
 if not self.visited and not self.routeRequested and state and state.TutorialCompleted then
  for _,id in F.Order do
   local recipe=F.Recipes[id];local affordable=not (state.CosmeticsOwned or {})[recipe.Item]
   for material,amount in recipe.Cost do if ((state.WeatherMaterials or {})[material] or 0)<amount then affordable=false;break end end
   if affordable then self.routeRequested=os.clock()+180;break end
  end
 end
 if self.routeRequested and os.clock()<self.routeRequested and not self.ctx.active and not self.ctx.presenting and not self.ctx.forgeReveal and not self.ctx.rewardOverlay and not Card.ActivityRunning() then
  return {id="weather-forge-route",kind="World",target="WeatherForge",position=F.Position+Vector3.yAxis*2.3,title="Создай награду в кузнице погоды",detail="",near="%s · Открыть кузницу",touch="Открыть кузницу",prompt=true,radius=8}
 end
end
function Controller:Render()
 local ctx=self.ctx
 for q in self.prompts do if q.Parent then q.Enabled=not ctx.active and not ctx.presenting and not ctx.forgeReveal and not ctx.rewardOverlay and self:Near() end end
 if ctx.active~="FORGE" then return end
 local compact=self.root.AbsoluteSize.Y<360
 self.materials.Position=UDim2.fromOffset(12,if compact then 43 else 52);self.materials.Size=UDim2.new(1,-24,0,if compact then 42 else 52)
 self.modes.Position=UDim2.fromOffset(12,if compact then 91 else 112)
 local top=if compact then 143 else 166;self.list.Position=UDim2.fromOffset(8,top);self.list.Size=UDim2.new(1,-16,1,-top-8)
 local state=ctx.net.state;local materials=state and state.WeatherMaterials or {};local owned=state and state.CosmeticsOwned or {};local selection=state and state.WeatherLook or "Auto"
 for id,label in self.materialLabels do label.Text=tostring(materials[id] or 0) end
 local near=self:Near();local parts={tostring(state and state.HouseIncomeLevel),tostring(compact),tostring(near),tostring(ctx.net:IsBusy()),tostring(ctx.net.connected),selection}
 for _,id in F.MaterialOrder do table.insert(parts,tostring(materials[id] or 0)) end
 for _,id in F.Order do table.insert(parts,tostring(owned[F.Recipes[id].Item])) end
 for id,b in self.modeButtons do W.SetButton(b,Locale.Text(if id=="Auto" then "ПО ПОГОДЕ" else "ПО УРОВНЮ")..(if selection==id then " ✓" else ""),near and ctx.net.connected and not ctx.net:IsBusy() and selection~=id,false) end
 local signature=table.concat(parts,":");if signature==self.signature then return end;self.signature=signature
 if Gui.SelectedObject and Gui.SelectedObject:IsDescendantOf(self.list) then Gui.SelectedObject=self.close end
 for _,row in self.rows do row:Destroy() end;table.clear(self.rows)
 for order,id in F.Order do
  local recipe=F.Recipes[id];local color=Color3.fromHex(recipe.Color);local has=owned[recipe.Item]==true
  local row=W.Round(W.Frame(self.list,id,UDim2.new(1,-6,0,if compact then 137 else 187),T.Paper),14);row.LayoutOrder=order;table.insert(self.rows,row)
  W.New("UIGradient",{Color=ColorSequence.new(T.White,color:Lerp(T.White,.74)),Rotation=28},row);W.Stroke(row,color,1).Transparency=.35
  local art=W.Frame(row,"Illustration",UDim2.fromOffset(if compact then 48 else 65,if compact then 48 else 65),color);W.Round(art,12);art.Position=UDim2.fromOffset(10,10)
  if recipe.Type=="Look" then Art.Face(art,color) else Art.Star(art,color) end
  local title=W.Text(row,"Name",recipe.Name,if compact then 13 else 15,true,T.Ink);title.Position=UDim2.fromOffset(if compact then 70 else 88,6);title.Size=UDim2.new(1,if compact then -82 else -100,0,if compact then 27 else 35)
  local description=W.Text(row,"Description",recipe.Description,if compact then 10 else 11,false,T.Muted);description.Position=UDim2.fromOffset(if compact then 70 else 88,if compact then 33 else 43);description.Size=UDim2.new(1,if compact then -82 else -100,0,if compact then 27 else 46)
  local affordable=true
  for index,material in F.MaterialOrder do
   local cost=recipe.Cost[material] or 0;if (materials[material] or 0)<cost then affordable=false end
   if cost>0 then
    local price=centerText(row,"Cost"..material,Locale.Text(F.Materials[material].Short).." "..(materials[material] or 0).."/"..cost,if compact then 9 else 10,if (materials[material] or 0)>=cost then Color3.fromHex("338769") else Color3.fromHex("B94C76"))
    price.Position=UDim2.new((index-1)/3,4,0,if compact then 63 else 99);price.Size=UDim2.new(1/3,-8,0,if compact then 22 else 30)
   end
  end
  local selected=recipe.Type=="Look" and selection==recipe.Look
  local button=W.Button(row,"Create","",if has then T.Mint else color:Lerp(T.White,.35));button.Position=UDim2.new(0,10,1,-50);button.Size=UDim2.new(1,-20,0,44);button.TextSize=12;button:SetAttribute("FixedFeedbackSize",true)
  local label=if not near then "ПОДОЙДИ К КУЗНИЦЕ" elseif selected then "✓ ОБЛИК ВЫБРАН" elseif has and recipe.Type=="Look" then "НАДЕТЬ ОБЛИК" elseif has and recipe.Type=="Cosmetic" then "НАДЕТЬ ВЕНЕЦ" elseif has then (if (state.HouseIncomeLevel or 0)>=2 then "✓ У ТЕБЯ ДОМА" else "СОХРАНЕНО • СТРОЙКА 2") elseif affordable then "СОЗДАТЬ" else "НУЖНЫ МАТЕРИАЛЫ"
  local enabled=near and ctx.net.connected and not ctx.net:IsBusy() and not selected and (not has and affordable or has and recipe.Type~="Decor")
  W.SetButton(button,Locale.Text(label),enabled,false)
  button.Activated:Connect(function()
   ctx.sound:Play("Click")
   if has and recipe.Type=="Look" then ctx.request("SetWeatherLook",{itemId=recipe.Look})
   elseif has and recipe.Type=="Cosmetic" then ctx.request("EquipCosmetic",{itemId=recipe.Item,equipped=true})
   else ctx.request("CraftWeatherItem",{itemId=id}) end
  end)
 end
end
function Controller:EndReveal()
 self.ctx.forgeReveal=false;self.active=nil;self.layer.Visible=false
 if self.previewWorld then self.previewWorld:Destroy();self.previewWorld=nil end
 if self.previewCamera then self.previewCamera:Destroy();self.previewCamera=nil end
 self.preview=nil;self.viewport.CurrentCamera=nil
end
function Controller:StartReveal(id,now)
 self.ctx.close();self.ctx.forgeReveal=true;self.layer.Visible=true;self.active={id=id,started=now}
 local recipe=F.Recipes[id];self.revealName.Text=Locale.Text(recipe.Name);self.revealDetail.Text=Locale.Text(if recipe.Type=="Look" then "Постоянный облик уже выбран" elseif recipe.Type=="Cosmetic" then "Венец уже надет на Verity" else "Украшение сохранено для твоего дома")
 self.previewWorld,self.previewCamera,self.preview=preview(self.viewport,recipe)
 for _,halo in self.halos do halo.stroke.Color=Color3.fromHex(recipe.Color) end
 self.ctx.sound:Play("BoxAnticipation")
end
function Controller:VisualTick(now,dt)
 local ctx=self.ctx
 if self.active and (ctx.presenting or ctx.rewardOverlay) then local id=self.active.id;self:EndReveal();table.insert(self.queue,1,id) end
 if not self.active and #self.queue>0 and not ctx.presenting and not ctx.rewardOverlay and not Card.ActivityRunning() then self:StartReveal(table.remove(self.queue,1),now) end
 local settings=ctx.settings.values;local reduced=settings.ReducedMotion;local low=settings.LowGraphics or settings.ReducedEffects
 local medium=settings.Graphics and settings.Graphics.Tier==2
 if self.active then
  local a=self.active;local age=now-a.started;local recipe=F.Recipes[a.id];local size=ctx.refs.Safe.AbsoluteSize
  local wide=size.X>size.Y and size.Y<400
  self.revealCard.Size=UDim2.fromOffset(math.min(if wide then 460 else 360,size.X-24),math.min(440,size.Y-24))
  self.revealTag.Text=Locale.Text(if age<1 then "СОБИРАЕМ СТИХИИ" elseif age<1.8 then "СЛИВАЕМ ЭНЕРГИЮ" else "НОВОЕ ТВОРЕНИЕ!")
  self.viewport.Visible=age>=1.65
  self.creationScale.Scale=if reduced then 1 else math.clamp((age-1.55)/.5,.05,1)
  self.revealScale.Scale=if reduced then 1 else .97+.03*math.min(1,age/.25)
  if self.preview then self.preview:PivotTo(CFrame.Angles(0,if reduced then 0 else math.sin(age*1.1)*.32,0)) end
  if age>=1.8 and not a.impact then a.impact=true;ctx.sound:Play("VeritySpawn") end
  for i,element in self.elements do
   local angle=(i-1)*math.pi*2/3+(if reduced then 0 else age*1.1)
   local radius=if reduced then .29 elseif age<1.8 then .33*(1-math.clamp((age-.4)/1.4,0,1)) else .31
   element.Position=UDim2.fromScale(.5+math.cos(angle)*radius,.51+math.sin(angle)*radius*.66)
   element.Visible=age<1.8 or age>2.1;element.BackgroundTransparency=if age>1.8 then .35 else 0
  end
  for i,halo in self.halos do halo.root.Rotation=if reduced then 0 else age*(if i%2==0 then -22 else 16);halo.stroke.Transparency=if low then .7 else .25+i*.12 end
  for i,spark in self.motes do
   spark.Visible=not low and not reduced and (not medium or i<=12)
   local angle=i*2.39996+age*.8;local radius=if age<1.8 then .42*(1-math.clamp(age/1.8,0,1)) else .10+math.min(.37,(age-1.8)*.5)
   spark.Position=UDim2.fromScale(.5+math.cos(angle)*radius,.51+math.sin(angle)*radius*.74);spark.BackgroundColor3=Color3.fromHex(if i%3==0 then "FFF2CF" else recipe.Color)
   spark.BackgroundTransparency=if age<1.8 then .1 else math.clamp((age-2.1)/1.5,0,1)
  end
  if age>=F.RevealSeconds then self:EndReveal() end
 end
 for _,spark in self.sceneSparks do spark.Transparency=1 end
 local world=workspace:FindFirstChild("GeneratedWorld");local forge=world and world:FindFirstChild("WeatherForge");local core=forge and forge:FindFirstChild("ForgeCore")
 if not core then return end
 if self.sceneModel~=forge then
  self.sceneModel=forge;self.sceneOrbs={};local orbs=forge:FindFirstChild("WeatherOrbs")
  for _,p in orbs and orbs:GetChildren() or {} do if p:IsA("BasePart") then table.insert(self.sceneOrbs,{p=p,base=p:GetAttribute("ForgeBase") or p.CFrame,index=p:GetAttribute("ForgeOrb") or 1,orbit=p:GetAttribute("ForgeOrbitCenter"),angle=p:GetAttribute("ForgeOrbitAngle"),beam=p:FindFirstChild("ElementFlow")}) end end
 end
 local camera=workspace.CurrentCamera;local near=camera and (camera.CFrame.Position-core.Position).Magnitude<70
 local glow=core:FindFirstChild("ForgeGlow");if glow then glow.Enabled=near and not low end
 if now>=(self.sceneAt or 0) then
  self.sceneAt=now+(if medium then 1/20 else 1/30)
  for _,entry in self.sceneOrbs do if entry.p.Parent then
   local offset=if near and not low and not reduced then math.sin(now*.9+entry.index)*.17 else 0
   local cf=entry.base+Vector3.yAxis*offset
   if entry.orbit and near and not low and not reduced then
    local angle=entry.angle+now*.55
    cf=CFrame.new(entry.orbit+Vector3.new(math.cos(angle)*1.25,math.sin(angle*2)*.23+offset,math.sin(angle)*1.25))
   end
   if entry.beam then entry.beam.Enabled=near and not low and not reduced end
   if entry.p.CFrame~=cf then entry.p.CFrame=cf end
  end end
 end
 local age=workspace:GetServerTimeNow()-(core:GetAttribute("ForgeCastAt") or -100)
 if near and not low and not reduced and age>=0 and age<3.2 then
  local recipe=F.Recipes[core:GetAttribute("ForgeRecipe")];local color=Color3.fromHex(recipe and recipe.Color or "FFE4A1")
  for i,p in self.sceneSparks do
   local angle=i*2.39996+age*2;local radius=if age<1.6 then 3.8*(1-age/1.8) else 1+(age-1.6)*2.5
   if not medium or i<=9 then
    p.Position=core.Position+Vector3.new(math.cos(angle)*radius,.4+math.sin(angle*.5)*.5+age*.6,math.sin(angle)*radius)
    p.Color=color:Lerp(T.White,(i%3)*.12);p.Transparency=math.clamp((age-2)/1.2,0,.9)
   end
  end
 end
end
function Controller:Destroy()
 for _,entry in self.sceneOrbs do if entry.p.Parent then entry.p.CFrame=entry.base;if entry.beam then entry.beam.Enabled=false end end end
 if self.sceneModel and self.sceneModel.Parent then local core=self.sceneModel:FindFirstChild("ForgeCore");local glow=core and core:FindFirstChild("ForgeGlow");if glow then glow.Enabled=false end end
 for q,enabled in self.prompts do if q.Parent then q.Enabled=enabled end end
 self.cleanup:Destroy()
end
return Controller
