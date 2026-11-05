--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Catalog=require(Shared.AbilityCatalog)
local Config=require(Shared.GameConfig)
local Locale=require(Shared.LocaleText)
local PadFactory=require(game:GetService("ReplicatedStorage").World.PurchasePadFactory)
local Stands={}
local function piece(parent,name,cf,size,color,neon,shape)
	local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanTouch=false
	p.CanCollide=false;p.CanQuery=false;p.CastShadow=not neon
	p.Size=size;p.CFrame=cf;p.Color=Color3.fromHex(color)
	p.Material=if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	if shape then p.Shape=shape end
	p.Parent=parent;return p
end
local function label(parent,source,size,y)
	local gui=Instance.new("BillboardGui");gui.Size=UDim2.fromOffset(size,76)
	gui.StudsOffsetWorldSpace=Vector3.new(0,y,0);gui.MaxDistance=95;gui.Parent=parent
	local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=.12
	text.BackgroundColor3=Color3.fromHex("211C40");text.TextColor3=Color3.fromHex("FFF3CB")
	text.Font=Enum.Font.GothamBold;text.TextSize=16;text.TextWrapped=true;text.AutoLocalize=false
	Locale.SetWorld(text,"Text",source);text.Parent=gui
	local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,12);corner.Parent=text
	return text
end
function Stands.Build(world,open)
	local folder=Instance.new("Folder");folder.Name="VerityAbilityMarket";folder.Parent=workspace
	-- The map's welcome plaza is at Z=-326 on the 340x740 ground.
	local center=Vector3.new(0,0,-326)
	for index,id in Catalog.Order do
		local item=Catalog.Items[id]
		local model=Instance.new("Model");model.Name=id;model:SetAttribute("AbilityId",id)
		model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
		local premium=item.Premium==true
		local column=(index-1)%5
		local row=math.floor((index-1)/5)
		local pos=if premium then center+Vector3.new(0,0,-28)
			else center+Vector3.new((column-2)*45,0,if row==0 then 26 else -18)
		-- Leave the central welcome spawn and road clear.
		if not premium and column==2 then pos+=Vector3.new(if row==0 then -125 else 125,0,0) end
		local pivot=CFrame.new(pos)
  if premium then
   local base=piece(model,"Pedestal",pivot*CFrame.new(0,.6,0)*CFrame.Angles(0,0,math.pi/2),Vector3.new(1.2,18,18),"28203E",false,Enum.PartType.Cylinder)
   base.CanCollide=true;base.CanQuery=true
   piece(model,"LightRim",pivot*CFrame.new(0,1.25,0)*CFrame.Angles(0,0,math.pi/2),Vector3.new(.18,18.2,18.2),"FFD369",true,Enum.PartType.Cylinder)
  end
		local orb=piece(model,"FloatingEmblem",pivot*CFrame.new(0,if premium then 7 else 4,0),Vector3.one*(if premium then 3.8 else 2.2),item.Color,true,Enum.PartType.Ball)
		orb:SetAttribute("AbilityFloat",true);orb:SetAttribute("PremiumStand",premium)
		local light=Instance.new("PointLight");light.Color=orb.Color;light.Range=if premium then 34 else 10
		light.Brightness=if premium then 2.5 else .5;light.Shadows=false;light.Parent=orb
		local source=piece(model,"PromptAnchor",pivot*CFrame.new(0,2,5),Vector3.one*.2,"FFFFFF")
		source.Transparency=1
		local prompt=Instance.new("ProximityPrompt");prompt.MaxActivationDistance=10
		prompt.RequiresLineOfSight=false;prompt.HoldDuration=.2;prompt:SetAttribute("AbilityId",id)
		Locale.SetWorld(prompt,"ObjectText",item.Name);Locale.SetWorld(prompt,"ActionText","Открыть способности")
		prompt.Parent=source
		prompt.Triggered:Connect(function(player)
			local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position-source.Position).Magnitude<=11 then open(player,id) end
		end)
		local circle=PadFactory.Create(model,pivot*CFrame.new(0,if premium then 1.5 else .14,0),if premium then "Hero" else "Ability",0,prompt)
  circle:SetAttribute("AbilityId",id);circle:SetAttribute("LabelHeight",if premium then 12 else 6)
  circle:SetAttribute("OfferPrice",Config.HeroPassPrice)
  local text=label(orb,item.Name,if premium then 260 else 180,if premium then 5 else 3)
  text.Parent.Enabled=false -- The circle owns one compact, consistent label.
		if not premium then
			Locale.SetWorld(text,"Text","%s\nУровень %d • $%d",item.Name,item.Level,item.Cost)
			text:SetAttribute("Text_locale_en",string.format("%s\nLevel %d • $%d",Locale.Get("en",item.Name),item.Level,item.Cost))
		end
		if premium then
			Locale.SetWorld(text,"Text",if Config.HeroPassId then "ХОУМЛЕНДЕР\nПОЛЁТ + ЛАЗЕРЫ • %d R$" else "ХОУМЛЕНДЕР\nПОЛЁТ + ЛАЗЕРЫ • %d R$ • СКОРО",Config.HeroPassPrice)
			if Config.HeroPassId then task.spawn(function()
				local ok,offer=pcall(function() return game:GetService("MarketplaceService"):GetProductInfoAsync(Config.HeroPassId,Enum.InfoType.GamePass) end)
				if not text.Parent then return end
				if ok and type(offer)=="table" and offer.IsForSale and type(offer.PriceInRobux)=="number" then
					Locale.SetWorld(text,"Text","ХОУМЛЕНДЕР\nПОЛЁТ + ЛАЗЕРЫ • %d R$",offer.PriceInRobux)
     circle:SetAttribute("OfferPrice",offer.PriceInRobux)
				else Locale.SetWorld(text,"Text","ХОУМЛЕНДЕР\nПРОПУСК ВРЕМЕННО НЕДОСТУПЕН") end
			end) end
			text.TextColor3=Color3.fromHex("FFE39C")
			for side=-1,1,2 do
				piece(model,"GoldPillar",pivot*CFrame.new(side*7,4,0),Vector3.new(.7,7,.7),"FFD369",true)
				piece(model,"RedEye",pivot*CFrame.new(side*.68,7.4,-1.73),Vector3.new(.5,.38,.22),"FF244A",true)
				local a=piece(model,"EyeRay",pivot*CFrame.new(side*.68,7.4,-3.1),Vector3.new(.12,.12,2.6),"FF244A",true)
				a:SetAttribute("PremiumStand",true)
			end
			for i=1,12 do
				local angle=i*math.pi/6
				piece(model,"HaloSegment",pivot*CFrame.new(math.cos(angle)*4.7,7+math.sin(angle)*4.7,1.4)*CFrame.Angles(0,0,angle),Vector3.new(.2,1.8,.2),"FFD369",true)
			end
			local attach=Instance.new("Attachment");attach.Parent=orb
			local particles=Instance.new("ParticleEmitter");particles.Texture="rbxasset://textures/particles/sparkles_main.dds"
			particles.Color=ColorSequence.new(Color3.fromHex("FFD369"),Color3.fromHex("FF476D"))
			particles.LightEmission=1;particles.Rate=10;particles.Lifetime=NumberRange.new(1,2)
			particles.Speed=NumberRange.new(1,3);particles.SpreadAngle=Vector2.new(180,180)
			particles.Size=NumberSequence.new(.22);particles.Parent=attach
			model:SetAttribute("HeroPassId",Config.HeroPassId)
		end
		model.Parent=folder;model:AddTag("VerityAbilityStand")
	end
	return folder
end
return Stands
