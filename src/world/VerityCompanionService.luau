-- Server-owned cosmetic descriptors. Core calls Attach only after unlocking.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
assert(RunService:IsServer(), "VerityCompanionService is server-only")
local Config = require(ReplicatedStorage.Shared.VerityCompanionConfig)
local Service = {}
local tokens = {}
local previewCooldown = {}
local function folder()
    local current = ReplicatedStorage:FindFirstChild("VerityCompanions")
    if not current then
        current = Instance.new("Folder")
        current.Name = "VerityCompanions"
        current.Parent = ReplicatedStorage
    end
    return current
end
function Service.Initialize()
    return folder()
end
local function validLevel(level)
    return type(level)=="number" and level==level and level%1==0 and level>=1 and level<=10
end
function Service.SetLevel(player, level)
    assert(validLevel(level), "Only companion levels 1..10 are authored")
    local descriptor=folder():FindFirstChild(tostring(player.UserId))
    if not descriptor then return false end
    descriptor:SetAttribute("Level",level)
    return true
end
function Service.Attach(player, level)
    assert(player:IsA("Player") and player.Parent == Players, "Expected connected owner")
    assert(level == nil or validLevel(level), "Only companion levels 1..10 are authored")
    local root = folder()
    local name = tostring(player.UserId)
    local existing = root:FindFirstChild(name)
    if existing then
        if level ~= nil then Service.SetLevel(player,level) end
        return existing
    end
    local descriptor = Instance.new("Folder")
    descriptor.Name = name
    descriptor:SetAttribute("OwnerUserId", player.UserId)
    descriptor:SetAttribute("Emotion", "Joy")
    descriptor:SetAttribute("Level", level or 1)
    descriptor.Parent = root
    return descriptor
end
function Service.SetEmotion(player, emotion, seconds)
    assert(Config.Textures[emotion] ~= nil, "Unknown emotion")
    assert(seconds == nil or (type(seconds)=="number" and seconds==seconds and seconds>=0 and seconds<=10), "Invalid emotion duration")
    local descriptor = folder():FindFirstChild(tostring(player.UserId))
    if not descriptor then return false end
    local token = (tokens[player.UserId] or 0)+1
    tokens[player.UserId] = token
    descriptor:SetAttribute("Emotion", emotion)
    if seconds and seconds > 0 then
        task.delay(seconds, function()
            if tokens[player.UserId] == token and descriptor.Parent then descriptor:SetAttribute("Emotion", "Joy") end
        end)
    end
    return true
end
function Service.Detach(player)
    tokens[player.UserId] = nil
    previewCooldown[player.UserId] = nil
    local root = ReplicatedStorage:FindFirstChild("VerityCompanions")
    local descriptor = root and root:FindFirstChild(tostring(player.UserId))
    if descriptor then descriptor:Destroy() end
end
Players.PlayerRemoving:Connect(Service.Detach)
function Service.StartStudioPreview()
    if not RunService:IsStudio() or not Config.StudioPreview then return end
    local root = folder()
    if root:GetAttribute("StudioPreviewStarted") then return end
    root:SetAttribute("StudioPreviewStarted", true)
    -- Temporary visual review control. This remote never exists in live servers.
    local preview = Instance.new("RemoteEvent")
    preview.Name = "StudioSetLevel"
    preview.OnServerEvent:Connect(function(player, level)
        if not RunService:IsStudio() or not Config.StudioPreview or not validLevel(level) then return end
        local now = os.clock()
        if now-(previewCooldown[player.UserId] or -math.huge)<.2 then return end
        previewCooldown[player.UserId] = now
        local descriptor = root:FindFirstChild(tostring(player.UserId))
        if not descriptor then return end
        local previous = descriptor:GetAttribute("Level") or 1
        if Service.SetLevel(player,level) then
            Service.SetEmotion(player,if level>previous then "Stars" else "Joy",2)
        end
    end)
    preview.Parent = root
    Players.PlayerAdded:Connect(function(player) Service.Attach(player) end)
    for _, player in Players:GetPlayers() do Service.Attach(player) end
end
return Service
