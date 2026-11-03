-- Server-owned cosmetic descriptors. Core calls Attach only after unlocking.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
assert(RunService:IsServer(), "VerityCompanionService is server-only")
local Config = require(ReplicatedStorage.Shared.VerityCompanionConfig)
local Service = {}
local tokens = {}
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
function Service.Attach(player)
    assert(player:IsA("Player") and player.Parent == Players, "Expected connected owner")
    local root = folder()
    local name = tostring(player.UserId)
    local existing = root:FindFirstChild(name)
    if existing then return existing end
    local descriptor = Instance.new("Folder")
    descriptor.Name = name
    descriptor:SetAttribute("OwnerUserId", player.UserId)
    descriptor:SetAttribute("Emotion", "Joy")
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
    local root = ReplicatedStorage:FindFirstChild("VerityCompanions")
    local descriptor = root and root:FindFirstChild(tostring(player.UserId))
    if descriptor then descriptor:Destroy() end
end
Players.PlayerRemoving:Connect(Service.Detach)
function Service.StartStudioPreview()
    if not RunService:IsStudio() or not Config.StudioPreview then return end
    local root = folder()
    if root:FindFirstChild("StudioEmotionRequest") then return end
    local remote = Instance.new("RemoteEvent")
    remote.Name = "StudioEmotionRequest"
    remote.Parent = root
    local last = {}
    remote.OnServerEvent:Connect(function(player, emotion)
        if type(emotion) ~= "string" or Config.Textures[emotion] == nil then return end
        local now = os.clock()
        if now - (last[player] or -1) < .25 then return end
        last[player] = now
        Service.SetEmotion(player, emotion)
    end)
    Players.PlayerRemoving:Connect(function(player) last[player] = nil end)
    Players.PlayerAdded:Connect(Service.Attach)
    for _, player in Players:GetPlayers() do Service.Attach(player) end
end
return Service
