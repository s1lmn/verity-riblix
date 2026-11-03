-- Isolated art review only. Do not enable this script in the production map.
local World=game:GetService("ReplicatedStorage"):WaitForChild("World")
local Factory=require(World.VerityPrototypeFactory)
local Config=require(World.VerityVisualConfig)
local old=workspace:FindFirstChild("VerityGallery")
if old then old:Destroy() end
local gallery=Instance.new("Folder");gallery.Name="VerityGallery";gallery.Parent=workspace
local function part(name,pos,size,color)
    local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.Size=size;p.Position=pos
    p.Material=Enum.Material.SmoothPlastic;p.Color=color;p.Parent=gallery;return p
end
part("Floor",Vector3.new(-6,-.5,8),Vector3.new(112,1,80),Color3.fromRGB(44,53,84))
local spawn=Instance.new("SpawnLocation");spawn.Name="GallerySpawn";spawn.Anchored=true
spawn.Size=Vector3.new(6,1,6);spawn.CFrame=CFrame.new(0,.5,-24)*CFrame.Angles(0,math.pi,0)
spawn.Transparency=1;spawn.CanCollide=false;spawn.Neutral=true;spawn.Duration=0;spawn.Parent=gallery
local function prompt(parent,text,callback)
    local p=Instance.new("ProximityPrompt");p.ActionText=text;p.ObjectText="VERITY VISUAL REVIEW"
    p.MaxActivationDistance=12;p.RequiresLineOfSight=false;p.HoldDuration=0;p.Parent=parent
    local last=0
    p.Triggered:Connect(function() if os.clock()-last>.4 then last=os.clock();callback() end end)
end
for level=1,10 do
    local x=((level-1)%5-2)*16;local z=math.floor((level-1)/5)*24
    local pad=part("Pad"..level,Vector3.new(x,.25,z),Vector3.new(11,.5,11),Config.GetColor(level))
    local model=Factory.Create(gallery,{Level=level,Anchor=CFrame.new(x,.5,z)})
    model.Name=string.format("Verity_%02d",level)
    prompt(pad,"Показать апгрейд",function() Factory.Pulse(model) end)
end
local testPad=part("UpgradeReviewPad",Vector3.new(-50,.25,10),Vector3.new(11,.5,11),Color3.fromRGB(255,224,55))
local test=Factory.Create(gallery,{Level=1,Anchor=CFrame.new(-50,.5,10)});test.Name="UpgradeReview"
local current=1
prompt(testPad,"Следующий уровень 1–10",function()
    current=current%10+1
    Factory.SetState(test,current,nil)
end)
for i,spec in {{"ReducedMotion",Vector3.new(-16,1,-20),"VerityReducedMotion"},{"ReducedEffects",Vector3.new(16,1,-20),"VerityReducedEffects"}} do
    local p=part(spec[1],spec[2],Vector3.new(6,2,3),Color3.fromRGB(125,91,255))
    prompt(p,"Переключить "..spec[1],function() workspace:SetAttribute(spec[3],workspace:GetAttribute(spec[3])~=true) end)
end
local Lighting=game:GetService("Lighting")
Lighting.ClockTime=13.5;Lighting.Brightness=2
Lighting.Ambient=Color3.fromRGB(150,155,174);Lighting.OutdoorAmbient=Color3.fromRGB(160,170,188)
local bloom=Lighting:FindFirstChild("VerityReviewBloom")
if not bloom then bloom=Instance.new("BloomEffect");bloom.Name="VerityReviewBloom";bloom.Parent=Lighting end
bloom.Intensity=.16;bloom.Threshold=1.2;bloom.Size=16
