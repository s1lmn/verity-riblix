local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Config = require(script.Parent.VerityVisualConfig)
local Recipes = require(script.Parent.VerityRecipe)
local Factory = {}

local function validIncome(value)
    return value == nil or (type(value) == "number" and value == value and value >= 0 and value < math.huge)
end
local function buildAppearance(level, anchor)
    local appearance = Instance.new("Model")
    appearance.Name = "Appearance"
    appearance:SetAttribute("VisualLevel", level)
    for _, data in Recipes[level] do
        local part = Instance.new("Part")
        part.Name = data.name
        part.Anchored = true
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        part.CastShadow = data.body == true
        part.Material = if data.glow then Enum.Material.Neon else Enum.Material.SmoothPlastic
        part.Color = Color3.fromHex(data.color)
        part.Reflectance = if data.body then 0.045 else 0
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
        if data.shape == "Rod" then
            local a = Vector3.new(data.a[1], data.a[2], data.a[3])
            local b = Vector3.new(data.b[1], data.b[2], data.b[3])
            part.Shape = Enum.PartType.Cylinder
            part.Size = Vector3.new((b-a).Magnitude, data.width, data.width)
            part.CFrame = CFrame.lookAt((a+b)/2, b) * CFrame.Angles(0, math.pi/2, 0)
        else
            part.Shape = Enum.PartType.Ball
            part.Size = Vector3.new(data.size[1], data.size[2], data.size[3])
            part.CFrame = CFrame.new(data.pos[1], data.pos[2], data.pos[3])
        end
        if data.optional then
            part:SetAttribute("OptionalEffect", true)
            part:SetAttribute("OrbitAngle",math.atan2(data.pos[3],data.pos[1]))
        end
        if data.eye then
            part:SetAttribute("BlinkEye",true)
            part:SetAttribute("EyeBaseSize",Vector3.new(data.size[1],data.size[2],data.size[3]))
        end
        part.Parent = appearance
        if data.body then appearance.PrimaryPart = part;part.PivotOffset = CFrame.new(0,-1.4,0) end
    end
    if Config.Get(level).Special then
        local glow = Instance.new("PointLight")
        glow.Name = "AccentGlow";glow.Color = Color3.fromRGB(126,245,255)
        glow.Brightness = 0.35;glow.Range = 7;glow.Shadows = false
        glow.Parent = appearance.PrimaryPart
    end
    appearance:ScaleTo(Config.GetScale(level))
    appearance:PivotTo(anchor)
    return appearance
end
local function label(model, level, income)
    local gui = model.Root:FindFirstChild("Label")
    if not gui then
        gui = Instance.new("BillboardGui");gui.Name = "Label";gui.Size = UDim2.fromOffset(240,64)
        gui.AlwaysOnTop = false;gui.MaxDistance = 110;gui.Parent = model.Root
        local text = Instance.new("TextLabel");text.Name = "Text";text.Size = UDim2.fromScale(1,1)
        text.BackgroundTransparency = 1;text.Font = Enum.Font.GothamBold;text.TextSize = 18
        text.TextColor3 = Color3.fromRGB(255,255,255);text.TextStrokeColor3 = Color3.fromRGB(28,34,65)
        text.TextStrokeTransparency = 0.2;text.Parent = gui
    end
    gui.StudsOffsetWorldSpace = Vector3.new(0,3.25*Config.GetScale(level),0)
    local suffix = if income ~= nil then string.format("\n$%.0f/sec",income) else ""
    gui.Text.Text = string.format("VERITY • LEVEL %d%s",level,suffix)
end

function Factory.SetState(model, level, incomePerSecond)
    assert(not RunService:IsClient(), "Core must apply confirmed visual state on the server")
    Config.Get(level)
    assert(validIncome(incomePerSecond), "Income must be finite and nonnegative, or nil")
    assert(model:IsA("Model") and model:FindFirstChild("Root"), "Expected a Verity model")
    local appearance = buildAppearance(level, model.Root.CFrame)
    local old = model:FindFirstChild("Appearance")
    if old then old:Destroy() end
    appearance.Parent = model
    model:SetAttribute("IncomePerSecond", incomePerSecond)
    label(model,level,incomePerSecond)
    model:SetAttribute("VisualLevel", level)
    CollectionService:AddTag(model,Config.Tag)
end
function Factory.Create(parent, options)
    assert(typeof(parent) == "Instance", "Verity needs a parent")
    options = options or {}
    local level = options.Level or 1;Config.Get(level)
    assert(validIncome(options.IncomePerSecond), "Invalid income")
    local anchor = options.Anchor or CFrame.identity
    assert(typeof(anchor) == "CFrame", "Anchor must be a CFrame at the floor")
    local model = Instance.new("Model");model.Name = "Verity";model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    local root = Instance.new("Part");root.Name = "Root";root.Size = Vector3.new(.1,.1,.1)
    root.Anchored = true;root.Transparency = 1;root.CanCollide = false;root.CanTouch = false;root.CanQuery = false
    root.CFrame = anchor;root.Parent = model;model.PrimaryPart = root
    if options.OwnerUserId then model:SetAttribute("OwnerUserId", options.OwnerUserId) end
    Factory.SetState(model,level,options.IncomePerSecond)
    model.Parent = parent
    return model
end
function Factory.Pulse(model)
    assert(not RunService:IsClient(), "Only server-authorised visual actions")
    model:SetAttribute("VisualPulse",(model:GetAttribute("VisualPulse") or 0)+1)
end
return Factory
