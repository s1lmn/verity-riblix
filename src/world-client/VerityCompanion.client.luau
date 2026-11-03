-- Prevent stale Rojo preview/game scripts from starting a second runtime.
if game:GetService("ReplicatedStorage"):GetAttribute("VerityRuntimeMode")=="Core" then return end
-- Cosmetic local rendering for every server-owned descriptor; no position remotes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local shared = ReplicatedStorage:WaitForChild("Shared",15)
local configModule = shared and shared:WaitForChild("VerityCompanionConfig",15)
if not configModule then warn("[Verity companion] Config unavailable"); return end
local Config = require(configModule)
local Levels = require(shared:WaitForChild("VerityCompanionLevels",15))
local FaceUI = require(ReplicatedStorage:WaitForChild("World"):WaitForChild("VerityFaceUI"))
local templates = ReplicatedStorage:WaitForChild("VerityCompanionAssets",15)
if not templates or not templates:FindFirstChild("Joy") then
    warn("[Verity companion] Sync VerityCompanionAssets with the updated Rojo project")
    return
end
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
    local template = templates:FindFirstChild(name) or templates.Joy
    local appearance = template:FindFirstChildOfClass("SurfaceGui")
    if entry.appearance then entry.appearance:Destroy() end
    -- The authored image face uses no PBR texture pack or imported UV coordinates.
    entry.appearance = appearance:Clone()
    FaceUI.Configure(entry.appearance,entry.body)
    entry.appearance.Enabled = entry.visible
    entry.appearance.Parent = entry.body
end
local function readLevel(descriptor)
    local level=descriptor:GetAttribute("Level") or 1
    return if Levels.IsValid(level) then level else nil
end
local function setImmediate(entry, level)
    local look=Levels.Get(level)
    entry.scale=look.Scale
    entry.color=Color3.fromHex(look.Hex)
    entry.look=look
    entry.queue={}
    entry.transition=nil
    entry.requested=level
end
local function levelChanged(entry)
    local level=readLevel(entry.descriptor)
    if not level then warn("[Verity companion] Ignoring unauthored level");return end
    if not entry.visible or level<entry.requested then setImmediate(entry,level);return end
    for nextLevel=entry.requested+1,level do entry.queue[#entry.queue+1]=nextLevel end
    entry.requested=level
end
local function updateLook(entry, dt, reduced)
    if not entry.transition and #entry.queue>0 then
        local look=Levels.Get(table.remove(entry.queue,1))
        entry.transition={elapsed=0,look=look,fromScale=entry.scale,fromColor=entry.color}
    end
    local transition=entry.transition
    if not transition then return end
    transition.elapsed+=dt
    local t=math.min(1,transition.elapsed/transition.look.Duration)
    local alpha=if reduced then t else 1-(1-t)^3
    local pulse=if reduced then 1 else 1+transition.look.Bounce*math.sin(math.pi*t)^2
    entry.scale=(transition.fromScale+(transition.look.Scale-transition.fromScale)*alpha)*pulse
    entry.color=transition.fromColor:Lerp(Color3.fromHex(transition.look.Hex),alpha)
    if t==1 then
        entry.scale=transition.look.Scale
        entry.color=Color3.fromHex(transition.look.Hex)
        entry.look=transition.look
        entry.transition=nil
    end
end
local function attach(descriptor)
    if not descriptor:IsA("Folder") or entries[descriptor] then return end
    local ownerId = descriptor:GetAttribute("OwnerUserId")
    if type(ownerId) ~= "number" then return end
    -- One solid-colour mesh and a camera-facing image face on its front surface.
    local part = templates.Joy:Clone()
    part.Name = "Verity_"..ownerId
    part.Anchored = true
    part.CanCollide,part.CanTouch,part.CanQuery,part.CastShadow = false,false,false,false
    part.Size = Vector3.new(Config.BaseDiameter,Config.BaseDiameter,Config.BaseDiameter)
    part.Transparency = 1
    part.Color = Color3.new(1,1,1)
    part.Material = Enum.Material.SmoothPlastic
    part.Parent = visuals
    local entry = {descriptor=descriptor,ownerId=ownerId,body=part,appearance=part:FindFirstChildOfClass("SurfaceGui"),visible=false}
    setImmediate(entry,readLevel(descriptor) or 1)
    entries[descriptor] = entry
    entry.changed = descriptor:GetAttributeChangedSignal("Emotion"):Connect(function() emotion(entry) end)
    entry.levelChanged=descriptor:GetAttributeChangedSignal("Level"):Connect(function() levelChanged(entry) end)
    emotion(entry)
end
local function remove(descriptor)
    local entry = entries[descriptor]
    if not entry then return end
    entry.changed:Disconnect()
    entry.levelChanged:Disconnect()
    entry.body:Destroy()
    entries[descriptor] = nil
end
for _, descriptor in source:GetChildren() do attach(descriptor) end
connections[#connections+1] = source.ChildAdded:Connect(attach)
connections[#connections+1] = source.ChildRemoved:Connect(remove)
local ray = RaycastParams.new()
ray.FilterType = Enum.RaycastFilterType.Exclude
ray.RespectCanCollide = true
connections[#connections+1] = RunService.RenderStepped:Connect(function(dt)
    -- Render every display frame; a 30 Hz transform cap visibly steps on 60+ Hz screens.
    local step = math.min(dt,.1)
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
            updateLook(entry,step,reduced)
            local radius=Config.BaseDiameter*entry.scale/2
            entry.body.Size=Vector3.new(1,1,1)*(radius*2)
            entry.body.Color=entry.color
            ray.FilterDescendantsInstances = {character,visuals}
            local origin = root.Position+Vector3.new(0,1.6,0)
            local snap = not entry.position or (entry.rootPosition and (root.Position-entry.rootPosition).Magnitude>Config.SnapDistance)
            entry.rootPosition = root.Position
            local heading = root.CFrame.Rotation
            if snap or not entry.heading then entry.heading=heading
            else entry.heading=entry.heading:Lerp(heading,1-math.exp(-Config.HeadingSpeed*step)) end
            local spread=math.max(0,radius-Config.BaseDiameter/2)
            local base=Config.FollowOffset
            local horizontal=Vector3.new(base.X,0,base.Z)
            local offset = entry.heading:VectorToWorldSpace(base+horizontal.Unit*spread+Vector3.new(0,spread,0))
            local target = root.Position+offset
            local direction = target-origin
            local hit = if direction.Magnitude>.01 then workspace:Spherecast(origin,radius,direction,ray) else nil
            if hit then target = origin+direction.Unit*math.max(0,hit.Distance-.15) end
            local ground = workspace:Raycast(target+Vector3.new(0,radius+.2,0),Vector3.new(0,-(radius*2+3),0),ray)
            if ground then target = Vector3.new(target.X,math.max(target.Y,ground.Position.Y+radius+.18),target.Z) end
            local bob = if reduced then 0 else math.sin(os.clock()*2.4+entry.ownerId%13)*entry.look.Bob
            local forward = Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z)
            if forward.Magnitude<.01 then forward=Vector3.new(0,0,-1) end
            if snap or (entry.position-target).Magnitude>Config.SnapDistance then entry.position=target
            else entry.position=entry.position:Lerp(target,1-math.exp(-Config.FollowSpeed*step)) end
            -- Idle is an additive visual offset, never fed back into the follow filter.
            local position = entry.position+Vector3.new(0,bob,0)
            local gaze = camera.CFrame.Position-position
            gaze = Vector3.new(gaze.X,0,gaze.Z)
            if gaze.Magnitude<.01 then gaze=forward end
            local facing = CFrame.lookAt(position,position+gaze).Rotation
            if snap or not entry.facing then entry.facing=facing
            else entry.facing=entry.facing:Lerp(facing,1-math.exp(-Config.FacingSpeed*step)) end
            entry.body.CFrame = CFrame.new(position)*entry.facing
            visible = (camera.CFrame.Position-position).Magnitude>2
            if owner==localPlayer and (camera.Focus.Position-camera.CFrame.Position).Magnitude<1 then visible=false end
        else
            entry.position,entry.heading,entry.facing,entry.rootPosition=nil,nil,nil,nil
            if entry.transition or #entry.queue>0 then setImmediate(entry,entry.requested) end
        end
        if entry.visible~=visible then
            entry.visible=visible
            entry.body.Transparency=if visible then 0 else 1
            entry.appearance.Enabled=visible
        end
        if visible then FaceUI.Refresh(entry.appearance,0) end
    end
end)
task.spawn(function()
    -- Preload typed instances; a bare mesh ID can be mistaken for an image request.
    local ok,err=pcall(function() ContentProvider:PreloadAsync({templates}) end)
    if not ok then warn("[Verity companion] Asset preload: "..tostring(err)) end
end)
script.Destroying:Connect(function()
    for _, connection in connections do connection:Disconnect() end
    for descriptor in entries do remove(descriptor) end
    visuals:Destroy()
end)
