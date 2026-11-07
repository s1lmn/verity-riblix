--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.DiversionsConfig)
local Locale = require(Shared.LocaleText)
local Builder = {}

function Builder.Build(parent)
    local existing = parent:FindFirstChild("VerityDiversions")
    if existing then return existing end
    local model = Instance.new("Model")
    model.Name = "VerityDiversions"
    model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
    local function part(name, position, size, color, round)
        local object = Instance.new("Part")
        object.Name, object.Position, object.Size = name, position, size
        object.Anchored, object.CanCollide, object.CanTouch, object.CanQuery = true, false, false, false
        object.CastShadow = false
        object.Color, object.Material = Color3.fromHex(color), Enum.Material.Neon
        if round then object.Shape = Enum.PartType.Ball end
        object.Parent = model
        return object
    end
    for _, kind in {"Hunt", "Rhythm"} do
        local position = Config.Station(kind)
        local color = if kind == "Hunt" then "FFE458" else "C398FF"
        local base = part(kind.."Station", position, Vector3.new(.18, 8, 8), color)
        base.Shape = Enum.PartType.Cylinder
        base.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
        local inset = part(kind.."Inset", position + Vector3.yAxis * .13, Vector3.new(.12, 6.7, 6.7), "302742")
        inset.Shape = Enum.PartType.Cylinder
        inset.CFrame = CFrame.new(inset.Position) * CFrame.Angles(0, 0, math.pi / 2)
        local gem = part(kind.."Gem", position + Vector3.yAxis * 3.2, Vector3.one * 1.7, color, kind == "Hunt")
        if kind == "Rhythm" then gem.CFrame *= CFrame.Angles(0, 0, math.pi / 4) end
        for index = 1, 6 do
            local angle = index * math.pi / 3
            part(kind.."Spark", position + Vector3.new(math.cos(angle) * 2.5, 2, math.sin(angle) * 2.5), Vector3.one * .28, color, true)
        end
        local prompt = Instance.new("ProximityPrompt")
        prompt.Name = "Start"..kind
        prompt.MaxActivationDistance, prompt.HoldDuration, prompt.RequiresLineOfSight = Config.JoinReach, .2, false
        Locale.SetWorld(prompt, "ActionText", "Начать")
        Locale.SetWorld(prompt, "ObjectText", if kind == "Hunt" then "Охота за искрами • 60 с" else "Реакторный ритм")
        prompt.Parent = base
        local label = Instance.new("BillboardGui")
        label.Size, label.StudsOffsetWorldSpace = UDim2.fromOffset(180, 30), Vector3.new(0, 5.1, 0)
        label.MaxDistance = 30
        label.Parent = base
        local text = Instance.new("TextLabel")
        text.Size, text.BackgroundTransparency = UDim2.fromScale(1, 1), 1
        text.Font, text.TextSize = Enum.Font.GothamBold, 14
        text.TextColor3, text.TextStrokeTransparency = Color3.fromHex(color), .25
        Locale.SetWorld(text, "Text", if kind == "Hunt" then "ОХОТА ЗА ИСКРАМИ" else "РЕАКТОРНЫЙ РИТМ")
        text.Parent = label
    end
    model.Parent = parent
    return model
end
return Builder
