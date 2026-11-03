-- Cosmetic local rendering for every server-owned descriptor; no position remotes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local shared = ReplicatedStorage:WaitForChild("Shared",15)
local configModule = shared and shared:WaitForChild("VerityCompanionConfig",15)
if not configModule then warn("[Verity companion] Config unavailable"); return end
local Config = require(configModule)
if Config.MeshId == "" then warn("[Verity companion] Upload mesh/textures and configure real IDs first"); return end
local source = ReplicatedStorage:WaitForChild("VerityCompanions",30)
if not source then return end
local localPlayer = Players.LocalPlayer
local visuals = Instance.new("Folder")
visuals.Name = "LocalVerityCompanions"
visuals.Parent = workspace
local entries, connections = {}, {}
local function emotion(entry)
    local name = entry.descriptor:GetAttribute("Emotion") or "Joy"
    entry.part.TextureId = Config.Textures[name] or Config.Textures.Joy
end
local function attach(descriptor)
    if not descriptor:IsA("Folder") or entries[descriptor] then return end
    local ownerId = descriptor:GetAttribute("OwnerUserId")
    if type(ownerId) ~= "number" then return end
    -- SpecialMesh holds the uploaded UV sphere; one anchored noncolliding Part.
    local part = Instance.new("Part")
    part.Name = "Verity_"..ownerId
    part.Anchored = true
    part.CanCollide,part.CanTouch,part.CanQuery,part.CastShadow = false,false,false,false
    part.Size = Vector3.new(Config.BaseDiameter,Config.BaseDiameter,Config.BaseDiameter)
    part.Transparency = 1
    part.Color = Color3.new(1,1,1)
    part.Material = Enum.Material.SmoothPlastic
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = Config.MeshId
    mesh.TextureId = Config.Textures.Joy
    mesh.Parent = part
    part.Parent = visuals
    local entry = {descriptor=descriptor,ownerId=ownerId,body=part,part=mesh,visible=false}
    entries[descriptor] = entry
    entry.changed = descriptor:GetAttributeChangedSignal("Emotion"):Connect(function() emotion(entry) end)
    emotion(entry)
end
local function remove(descriptor)
    local entry = entries[descriptor]
    if not entry then return end
    entry.changed:Disconnect()
    entry.body:Destroy()
    entries[descriptor] = nil
end
for _, descriptor in source:GetChildren() do attach(descriptor) end
connections[#connections+1] = source.ChildAdded:Connect(attach)
connections[#connections+1] = source.ChildRemoved:Connect(remove)
local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Exclude
ray.RespectCanCollide = true
local elapsed = 0
connections[#connections+1] = RunService.RenderStepped:Connect(function(dt)
    elapsed += dt
    if elapsed < 1/30 then return end
    local step = math.min(elapsed,.25); elapsed = 0
    local camera = workspace.CurrentCamera
    if not camera then return end
    local gui = localPlayer:FindFirstChildOfClass("PlayerGui")
    local settings = gui and gui:FindFirstChild("VerityUI")
    local reduced = (settings and settings:GetAttribute("ReducedMotion")==true) or workspace:GetAttribute("VerityReducedMotion")==true
    for _, entry in entries do
        local owner = Players:GetPlayerByUserId(entry.ownerId)
        local character = owner and owner.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local valid = root and humanoid and humanoid.Health>0 and (root.Position-camera.CFrame.Position).Magnitude<Config.RenderDistance
        local visible = false
        if valid then
            ray.FilterDescendantsInstances = {character,visuals}
            local origin = root.Position+Vector3.new(0,1.6,0)
            local offset = root.CFrame:VectorToWorldSpace(Config.FollowOffset)
            local target = root.Position+offset
            local direction = target-origin
            local hit = if direction.Magnitude>.01 then workspace:Spherecast(origin,1.4,direction,ray) else nil
            if hit then target = origin+direction.Unit*math.max(0,hit.Distance-.15) end
            local ground = workspace:Raycast(target+Vector3.new(0,1.5,0),Vector3.new(0,-5,0),ray)
            if ground then target = Vector3.new(target.X,math.max(target.Y,ground.Position.Y+1.5),target.Z) end
            local bob = if reduced then 0 else math.sin(os.clock()*2.4+entry.ownerId%13)*.12
            target += Vector3.new(0,bob,0)
            local forward = Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
            if forward.Magnitude<.01 then forward=Vector3.new(0,0,-1) end
            local gaze = camera.CFrame.Position-target
            gaze = Vector3.new(gaze.X,0,gaze.Z)
            if gaze.Magnitude<.01 then gaze=forward end
            local goal = CFrame.lookAt(target,target+gaze)
            if not entry.current or (entry.current.Position-target).Magnitude>Config.SnapDistance then entry.current=goal
            else entry.current=entry.current:Lerp(goal,1-math.exp(-Config.FollowSpeed*step)) end
            entry.body.CFrame = entry.current
            visible = (camera.CFrame.Position-target).Magnitude>2
            if owner==localPlayer and (camera.Focus.Position-camera.CFrame.Position).Magnitude<1 then visible=false end
        else entry.current=nil end
        if entry.visible~=visible then entry.visible=visible;entry.body.Transparency=if visible then 0 else 1 end
    end
end)
-- Studio-only review controls. Server validates each request and owns the face state.
local previewGui
if RunService:IsStudio() and Config.StudioPreview then
    local remote=source:WaitForChild("StudioEmotionRequest",10)
    if remote then
        previewGui=Instance.new("ScreenGui");previewGui.Name="VerityCompanionReview";previewGui.ResetOnSpawn=false
        local panel=Instance.new("Frame");panel.Size=UDim2.fromOffset(360,110);panel.Position=UDim2.new(.5,-180,1,-180);panel.BackgroundColor3=Color3.fromRGB(25,28,44);panel.Parent=previewGui
        local layout=Instance.new("UIGridLayout");layout.CellSize=UDim2.fromOffset(86,48);layout.CellPadding=UDim2.fromOffset(4,4);layout.Parent=panel
        for _, name in {"Joy","Love","Playful","Wink","Laugh","Surprise","Confident","Stars"} do
            local button=Instance.new("TextButton");button.Text=name;button.TextSize=14;button.BackgroundColor3=Color3.fromRGB(255,218,33);button.Parent=panel
            connections[#connections+1]=button.Activated:Connect(function() remote:FireServer(name) end)
        end
        previewGui.Parent=localPlayer:WaitForChild("PlayerGui")
    end
end
task.spawn(function()
    local assets = {Config.MeshId}
    for _, id in Config.Textures do assets[#assets+1]=id end
    local ok,err=pcall(function() ContentProvider:PreloadAsync(assets) end)
    if not ok then warn("[Verity companion] Asset preload: "..tostring(err)) end
end)
script.Destroying:Connect(function()
    for _, connection in connections do connection:Disconnect() end
    for descriptor in entries do remove(descriptor) end
    if previewGui then previewGui:Destroy() end
    visuals:Destroy()
end)
