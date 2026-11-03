-- Client-only presentation. Never changes money, level, owner or server Root position.
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Config = require(script.Parent.VerityVisualConfig)
local Motion = require(script.Parent.VerityMotion)
local Service = {}
local records, connections = {}, {}
local options = { ReducedMotion=false, ReducedEffects=false, AnimateDistance=180 }
local effects, started, accumulator

local function burst(record, level)
    if options.ReducedEffects or options.ReducedMotion or not effects then return end
    local special=Config.Get(level).Special
    local folder=Instance.new("Folder");folder.Name="UpgradeBurst";folder.Parent=effects
    local size=Config.GetScale(level);local count=if special then 12 else 5
    for i=1,count do
        local p=Instance.new("Part");p.Shape=Enum.PartType.Ball;p.Anchored=true
        p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
        p.Material=if special then Enum.Material.Neon else Enum.Material.SmoothPlastic
        p.Color=if special then Color3.fromRGB(143,251,255) else Config.GetColor(level)
        p.Size=Vector3.one*.13*size
        p.Position=record.model.Root.Position+Vector3.new(0,1.4*size,0);p.Parent=folder
        local a=i*math.pi*2/count
        local destination=p.Position+Vector3.new(math.cos(a)*1.8, .4+(i%3)*.4, math.sin(a)*1.8)*size
        TweenService:Create(p,TweenInfo.new(.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
            {Position=destination,Transparency=1,Size=Vector3.one*.025*size}):Play()
    end
    Debris:AddItem(folder,.65)
end
local function observe(model)
    if not model:IsA("Model") or records[model] then return end
    records[model]={model=model,level=nil,scale=nil,color=nil,pulse=model:GetAttribute("VisualPulse"),elapsed=1,appearance=nil}
end
local function forget(model) records[model]=nil end
local function resetPose(record)
    local model=record.model;local a=model:FindFirstChild("Appearance");local root=model:FindFirstChild("Root")
    local level=model:GetAttribute("VisualLevel")
    if a and a:IsA("Model") and root and type(level)=="number" and level%1==0 and level>=1 and level<=10 then
        a:ScaleTo(Config.GetScale(level));a:PivotTo(root.CFrame)
        local body=a:FindFirstChild("Body");if body then body.Color=Config.GetColor(level) end
        for _,p in a:GetChildren() do
            if p:IsA("BasePart") and p:GetAttribute("OptionalEffect") then p.Transparency=0 end
            if p:IsA("BasePart") and p:GetAttribute("BlinkEye") then p.Size=p:GetAttribute("EyeBaseSize")*Config.GetScale(level) end
        end
        local glow=body and body:FindFirstChild("AccentGlow");if glow then glow.Enabled=true end
    end
end
local function step(dt)
    accumulator+=dt
    if accumulator<1/30 then return end
    local delta=math.min(accumulator,.2);accumulator=0
    local now=os.clock();local camera=workspace.CurrentCamera
    for model,record in records do
        local root=model:FindFirstChild("Root");local a=model:FindFirstChild("Appearance")
        local level=model:GetAttribute("VisualLevel")
        if not model:IsDescendantOf(workspace) then forget(model);continue end
        if not root or not a or not a:IsA("Model") or not a.PrimaryPart then continue end
        if type(level)~="number" or level%1~=0 or level<1 or level>10 or a:GetAttribute("VisualLevel")~=level then continue end
        local definition=Config.Get(level);local target=Config.GetScale(level)
        local nonce=model:GetAttribute("VisualPulse")
        if record.level~=level or record.pulse~=nonce then
            local first=record.level==nil
            record.fromScale=record.scale or target;record.fromColor=record.color or Config.GetColor(level)
            record.elapsed=if first then 1 else 0
            record.level=level;record.pulse=nonce
            if not first and (not camera or (camera.CFrame.Position-root.Position).Magnitude<options.AnimateDistance) then burst(record,level) end
        end
        if a~=record.appearance then
            record.appearance=a;record.appliedScale=nil;record.optional={};record.eyes={};record.glow=a.PrimaryPart:FindFirstChild("AccentGlow")
            for _,p in a:GetChildren() do
                if p:IsA("BasePart") and p:GetAttribute("OptionalEffect") then table.insert(record.optional,p) end
                if p:IsA("BasePart") and p:GetAttribute("BlinkEye") then table.insert(record.eyes,p) end
            end
        end
        record.elapsed+=delta
        local progress=record.elapsed/.75;local ease,pop=Motion.Transition(progress)
        record.scale=record.fromScale+(target-record.fromScale)*ease
        record.color=record.fromColor:Lerp(Config.GetColor(level),ease)
        local distant=camera and (camera.CFrame.Position-root.Position).Magnitude>options.AnimateDistance
        local reduced=options.ReducedMotion or distant
        local bob,yaw,roll=0,0,0
        if not reduced then bob,yaw,roll=Motion.Sample(definition,now+root.Position.X*.03) end
        local applied=if reduced then target else record.scale*pop
        if not record.appliedScale or math.abs(record.appliedScale-applied)>.001 then
            a:ScaleTo(applied);record.appliedScale=applied
        end
        if not reduced and progress<1 and definition.Motion=="Spin" then yaw+=math.pi*2*ease end
        local lift=if reduced then 0 else (.04+bob+1.4*(1-math.cos(roll)))*applied
        a:PivotTo(root.CFrame*CFrame.new(0,lift,0)*CFrame.Angles(0,yaw,roll))
        a.PrimaryPart.Color=if reduced then Config.GetColor(level) else record.color
        for _,p in record.optional do
            p.Transparency=if options.ReducedEffects then 1 else 0
            local angle=(p:GetAttribute("OrbitAngle") or 0)+(if reduced then 0 else now*.65)
            p.CFrame=root.CFrame*CFrame.new(0,lift,0)*CFrame.new(math.cos(angle)*1.55*applied,.12*applied,math.sin(angle)*1.55*applied)
        end
        local blinkPhase=(now+root.Position.X*.17)%4.5
        local blink=if not reduced and blinkPhase<.18 then 1-.93*math.sin(math.pi*blinkPhase/.18) else 1
        for _,p in record.eyes do
            local base=p:GetAttribute("EyeBaseSize")
            if typeof(base)=="Vector3" then p.Size=Vector3.new(base.X,base.Y*blink,base.Z)*applied end
        end
        if record.glow then record.glow.Enabled=not options.ReducedEffects and not distant end
    end
end
function Service.SetOptions(values)
    if values.ReducedMotion~=nil then options.ReducedMotion=values.ReducedMotion==true end
    if values.ReducedEffects~=nil then options.ReducedEffects=values.ReducedEffects==true end
    if type(values.AnimateDistance)=="number" and values.AnimateDistance>0 and values.AnimateDistance<math.huge then options.AnimateDistance=values.AnimateDistance end
end
function Service.Start()
    assert(RunService:IsClient(),"VerityVisualService is client-only")
    if started then return end
    started=true;accumulator=0
    effects=Instance.new("Folder");effects.Name="VerityClientEffects";effects.Parent=workspace
    for _,model in CollectionService:GetTagged(Config.Tag) do observe(model) end
    table.insert(connections,CollectionService:GetInstanceAddedSignal(Config.Tag):Connect(observe))
    table.insert(connections,CollectionService:GetInstanceRemovedSignal(Config.Tag):Connect(forget))
    table.insert(connections,RunService.RenderStepped:Connect(step))
end
function Service.Stop()
    for _,c in connections do c:Disconnect() end;table.clear(connections)
    for _,record in records do resetPose(record) end;table.clear(records)
    if effects then effects:Destroy();effects=nil end
    started=false
end
return Service
