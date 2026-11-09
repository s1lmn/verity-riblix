--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Houses=require(Shared.HouseConfig)
local Construction={}
local function part(parent,pivot,name,position,size,color,stage,neon)
	local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanTouch=false;p.CanQuery=false;p.CanCollide=false
	p.Size=size;p.CFrame=pivot*CFrame.new(position);p.Color=Color3.fromHex(color)
	p.Material=if neon then Enum.Material.Neon else Enum.Material.SmoothPlastic
	p:SetAttribute("ConstructionStage",stage);p.Parent=parent;return p
end
function Construction.Create(house)
	local pivot=house:GetPivot()
	local geometry=house:FindFirstChild("Geometry")
	-- Split the old double-height wall so the upper storey can be built separately.
	local wall=geometry and geometry:FindFirstChild("LivingBack")
	if wall and wall.Size.Y>20 then
		local upper=wall:Clone();upper.Name="LivingBackUpper"
		upper.Size=Vector3.new(wall.Size.X,15,wall.Size.Z);upper.CFrame=wall.CFrame*CFrame.new(0,7.5,0);upper.Parent=geometry
		wall.Size=Vector3.new(wall.Size.X,15,wall.Size.Z);wall.CFrame*=CFrame.new(0,-7.5,0)
	end
	local records={}
	for _,object in house:GetDescendants() do
		if not object:IsA("BasePart") or not (object:IsDescendantOf(geometry or house)
			or object:FindFirstAncestor("Furniture")) then continue end
		local name=object.Name;local path=object:GetFullName();local stage=1
		local upper=name:find("Upper")~=nil or name:find("SideFloorBand")~=nil
			or object:FindFirstAncestor("Stairs")~=nil or path:find("Furniture.Upper",1,true)~=nil
			or pivot:PointToObjectSpace(object.Position).Y>=14.8
		if name=="Floor" or name=="LivingFloor" then stage=0
		elseif name:find("Living") or name:find("Passage") or name:find("Side") then stage=2 end
		if name=="FacadePlant" or name=="FacadePlanter" or name:find("Glass") or path:find("Furniture.Plants",1,true) or path:find("Furniture.Lamps",1,true) then stage=3 end
		if name:find("Ceiling") or name:find("RoofCap") or path:find("Furniture.Gallery",1,true) then stage=4 end
		if path:find("Furniture.Sofa",1,true) or path:find("Furniture.Media",1,true) or path:find("Furniture.CoffeeTable",1,true) then stage=2 end
		if upper then stage=0 end -- The independent, saved upstairs purchase owns these parts.
		table.insert(records,{part=object,alpha=object.Transparency,collide=object.CanCollide,query=object.CanQuery,stage=stage,upper=upper})
	end
	local additions=Instance.new("Folder");additions.Name="IncomeBuildings";additions.Parent=house
	for index,upgrade in Houses.IncomeUpgrades do
		local group=Instance.new("Folder");group.Name="Stage"..index;group.Parent=additions
		if index>=5 then
			local x=if index%2==0 then 29 else -29
			local z=-8-math.floor((index-5)/2)*15
			part(group,pivot,"ProductionBase",Vector3.new(x,.6,z),Vector3.new(6,1.2,9),"4F5777",index)
			local core=part(group,pivot,"ProductionCore",Vector3.new(x,3.6,z),Vector3.new(3.4,5,4.4),upgrade.Color,index,true)
			part(group,pivot,"ProductionCap",Vector3.new(x,6.3,z),Vector3.new(5,.5,6),"FFF2BC",index)
   if index==6 or index==8 then
    core.Shape=Enum.PartType.Cylinder;core.Size=Vector3.new(5,3.4,3.4);core.CFrame*=CFrame.Angles(0,0,math.pi/2)
    for _,y in {1.25,5.85} do
     local band=part(group,pivot,"CapsuleBand",Vector3.new(x,y,z),Vector3.new(.22,4.1,4.1),"FFF0CC",index)
     band.Shape=Enum.PartType.Cylinder;band.CFrame*=CFrame.Angles(0,0,math.pi/2)
    end
   end
			for side=-1,1,2 do part(group,pivot,"PowerRail",Vector3.new(x+side*2.1,2.4,z),Vector3.new(.25,3,.25),upgrade.Color,index,true) end
			if index==5 then
				core.Transparency=1
				for row=-1,1 do
					part(group,pivot,"GardenBed",Vector3.new(x,1.5,z+row*2.6),Vector3.new(5,.8,1.9),"86614C",index)
					for column=-1,1 do
						local leaf=part(group,pivot,"FireflyFlower",Vector3.new(x+column*1.6,2.7,z+row*2.6),Vector3.one*.8,"A9FFB2",index,true)
						leaf.Shape=Enum.PartType.Ball
					end
				end
			elseif index==6 then
				for spoke=1,5 do
					local a=spoke*math.pi*2/5
					local star=part(group,pivot,"StarArm",Vector3.new(x+math.cos(a)*1.6,4+math.sin(a)*1.6,z+2.4),Vector3.new(2,.5,.3),"FFE393",index,true)
					star.CFrame*=CFrame.Angles(0,0,a)
				end
			elseif index==7 then
				core.Material=Enum.Material.Glass;core.Transparency=.65
				for column=-1,1 do
					part(group,pivot,"MoonStem",Vector3.new(x+column,2.7,z),Vector3.new(.18,2,.18),"66B899",index)
					local leaf=part(group,pivot,"MoonBloom",Vector3.new(x+column,4,z),Vector3.one*.9,"D1C3FF",index,true);leaf.Shape=Enum.PartType.Ball
				end
			elseif index==9 then
				core.Shape=Enum.PartType.Ball;core.Size=Vector3.one*4
				for spoke=1,8 do
					local a=spoke*math.pi/4
					local blade=part(group,pivot,"TurbineBlade",Vector3.new(x+math.cos(a)*2.2,3.8+math.sin(a)*2.2,z+2.4),Vector3.new(1.6,.35,.35),"EACBFF",index,true)
					blade.CFrame*=CFrame.Angles(0,0,a+.5)
				end
			elseif index==10 then
				core.Shape=Enum.PartType.Ball;core.Size=Vector3.one*4.6
				local light=Instance.new("PointLight");light.Color=core.Color;light.Brightness=.8;light.Range=14;light.Shadows=false;light.Parent=core
				for ring=1,3 do
					for segment=1,8 do
						local a=segment*math.pi/4
						part(group,pivot,"ReactorHalo",Vector3.new(x+math.cos(a)*2.9,2+ring,z+math.sin(a)*2.9),Vector3.new(.28,.28,1.8),if ring==1 then "FFD773" elseif ring==2 then "A5FFE8" else "FF92DB",index,true).CFrame*=CFrame.Angles(0,-a,0)
					end
				end
			end
			local labelPart=part(group,pivot,"ModuleSign",Vector3.new(x,5,z+2.7),Vector3.new(4,1,.2),"252742",index)
			local gui=Instance.new("SurfaceGui");gui.Face=Enum.NormalId.Front;gui.PixelsPerStud=45;gui.Parent=labelPart
			local text=Instance.new("TextLabel");text.Size=UDim2.fromScale(1,1);text.BackgroundTransparency=1
			text.Font=Enum.Font.GothamBold;text.TextSize=18;text.TextColor3=Color3.new(1,1,1);text.TextWrapped=true;text.Parent=gui
			require(Shared.LocaleText).SetWorld(text,"Text",upgrade.Name)
		end
		if index==4 then
			local roof=part(group,pivot,"LowerWingRoof",Vector3.new(0,15.5,-34),Vector3.new(48,.6,40),"69788D",index)
			roof.CanCollide=true;roof.CanQuery=true;roof:SetAttribute("ConstructionGroundRoof",true)
			for side=-1,1,2 do part(group,pivot,"EntryLight",Vector3.new(side*6,10.7,15.2),Vector3.new(2,.22,.25),upgrade.Color,index,true) end
		elseif index==8 then
			for x=-10,10,5 do part(group,pivot,"SolarPanel",Vector3.new(x,13.5,3),Vector3.new(4,.25,9),"4F9BF5",index) end
		elseif index==10 then
			part(group,pivot,"RainbowCrown",Vector3.new(0,14.6,10),Vector3.new(20,.45,.8),"FFD773",index,true)
			for x=-8,8,4 do part(group,pivot,"CrownSpire",Vector3.new(x,15.6,10),Vector3.new(.55,2.4,.6),"FFD773",index,true) end
		end
	end
	for _,object in additions:GetDescendants() do
		if object:IsA("BasePart") then table.insert(records,{part=object,alpha=object.Transparency,collide=object.CanCollide,query=object.CanQuery,stage=object:GetAttribute("ConstructionStage"),upper=false,groundRoof=object:GetAttribute("ConstructionGroundRoof")}) end
	end
	house:AddTag("VerityGrowingHouse")
	return {house=house,parts=records,revision=0}
end
function Construction.Apply(record,state)
	local count=if state then state.HouseIncomeLevel else 0
	local upper=state~=nil and state.HouseSecondFloorOwned==true
	-- Preserve functionality of previously purchased floors/doors on existing profiles.
	local physical=math.max(count,if upper then 4 elseif state and state.HouseDoorOwned then 1 else 0)
	local signature=tostring(count)..":"..tostring(upper)..":"..tostring(physical)
	if signature==record.signature then return end
	record.signature=signature
	for _,r in record.parts do
		local visible=if r.upper then upper else physical>=r.stage
		if r.groundRoof and upper then visible=false end
		r.part.Transparency=if visible then r.alpha else 1
		r.part.CanCollide=visible and r.collide;r.part.CanQuery=visible and r.query
		r.part:SetAttribute("ConstructionVisible",visible==true)
		r.part:SetAttribute("ConstructionOriginalAlpha",r.alpha)
		for _,child in r.part:GetDescendants() do
			if child:IsA("Light") then child.Enabled=visible
			elseif child:IsA("SurfaceGui") then child.Enabled=visible end
		end
	end
	record.revision+=1
	record.house:SetAttribute("HouseBuildLevel",count)
	record.house:SetAttribute("HouseBuildRevision",record.revision)
end
return Construction
