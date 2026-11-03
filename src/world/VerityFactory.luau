--!nonstrict
-- Replaceable procedural mascot; no uploaded models, animation ids or scripts.
local CollectionService = game:GetService("CollectionService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared", 10)
assert(Shared, "Shared modules missing; open the complete project build")
local Levels = require(Shared.LevelConfig)
local Profile = require(Shared.VerityAnimationProfile)
local Version = require(Shared.ProjectVersion)
local Factory = {}

function Factory.Color(level)
	return Color3.fromHSV(((level - 1) * 0.61803398875 + 0.91) % 1, 0.52, 1)
end

local function part(parent, name, size, position, color, shape, tint)
	local p = Instance.new("Part")
	p.Name, p.Size, p.CFrame = name, size, CFrame.new(position)
	-- Ball parts render as round balls; native Sphere meshes retain the intended
	-- nonuniform ear/foot/body dimensions without an external asset dependency.
	p.Shape = Enum.PartType.Block
	if shape==Enum.PartType.Ball then
		local mesh=Instance.new("SpecialMesh")
		mesh.MeshType=Enum.MeshType.Sphere
		mesh.Parent=p
	elseif shape then p.Shape=shape end
	p.Material = Enum.Material.SmoothPlastic
	p.Color = color
	p.Anchored, p.CanCollide, p.CanTouch, p.CanQuery, p.CastShadow = true, false, false, false, false
	if tint then p:SetAttribute("VerityTint", true) end
	p.Parent = parent
	return p
end

function Factory.Create(parent, origin, metadata)
	metadata = metadata or {}
	local level = metadata.level or 1
	local scale = Levels.getVerityScale(level)
	local model = Instance.new("Model")
	model.Name, model.ModelStreamingMode = "Verity", Enum.ModelStreamingMode.Atomic
	local ink, white, pink = Color3.fromHex("22264B"), Color3.fromHex("FFF9FF"), Color3.fromHex("FF5CB8")
	local color = Factory.Color(level)
	local root = part(model, "Root", Vector3.one * 0.04, Vector3.zero, white)
	root.Transparency = 1
	model.PrimaryPart = root
	part(model, "Body", Vector3.new(0.62, 0.64, 0.46), Vector3.new(0, 0.39, 0), color, Enum.PartType.Ball, true)
	for _, side in {-1, 1} do
		local ear = part(model, "Ear", Vector3.new(0.15, 0.36, 0.15), Vector3.new(side * 0.21, 0.79, 0), color, Enum.PartType.Ball, true)
		ear.CFrame *= CFrame.Angles(0, 0, side * -0.18)
		part(model, "EarInner", Vector3.new(0.065, 0.23, 0.035), Vector3.new(side * 0.21, 0.80, -0.068), white, Enum.PartType.Ball)
		part(model, "Foot", Vector3.new(0.21, 0.08, 0.25), Vector3.new(side * 0.18, 0.04, -0.03), color, Enum.PartType.Ball, true)
		part(model, "Eye", Vector3.new(0.052, 0.105, 0.035), Vector3.new(side * 0.115, 0.46, -0.227), ink, Enum.PartType.Ball)
		part(model, "EyeGlint", Vector3.new(0.018, 0.025, 0.012), Vector3.new(side * 0.115 - 0.008, 0.48, -0.248), white, Enum.PartType.Ball)
		part(model, "Cheek", Vector3.new(0.10, 0.035, 0.02), Vector3.new(side * 0.19, 0.36, -0.21), pink, Enum.PartType.Ball)
	end
	part(model, "Smile", Vector3.new(0.065, 0.025, 0.022), Vector3.new(0, 0.335, -0.239), ink, Enum.PartType.Ball)
	local crown = Instance.new("Folder")
	crown.Name, crown.Parent = "Crown", model
	part(crown, "Band", Vector3.new(0.38, 0.055, 0.28), Vector3.new(0, 1.01, 0), Color3.fromHex("FFD85A"))
	for index = -1, 1 do
		local tip = part(crown, "CrownPoint", Vector3.new(0.075, 0.15 + (if index == 0 then 0.04 else 0), 0.075), Vector3.new(index * 0.14, 1.12, -0.075), Color3.fromHex("FFD85A"))
		tip.CFrame *= CFrame.Angles(0, 0, index * -0.20)
	end
	part(crown, "Gem", Vector3.new(0.055, 0.055, 0.02), Vector3.new(0, 1.025, -0.15), Color3.fromHex("9865FF"), Enum.PartType.Ball)
	Factory.SetStage(model, level)
	model:SetAttribute("OwnerUserId", metadata.ownerUserId)
	model:SetAttribute("PlotId", metadata.plotId)
	model:SetAttribute("VerityLevel", level)
	model:SetAttribute("StateRevision", metadata.stateRevision or 0)
	model:SetAttribute("PresentationVersion", Version.Presentation)
	model:SetAttribute("VerityOrigin", origin)
	model:ScaleTo(scale)
	model:PivotTo(origin)
	local gui = Instance.new("BillboardGui")
	gui.Name, gui.Adornee = "LevelLabel", root
	gui.Size, gui.MaxDistance = UDim2.fromOffset(170, 48), 120
	gui.StudsOffsetWorldSpace = Vector3.new(0, 1.25 * scale + 0.5, 0)
	local title = Instance.new("TextLabel")
	title.Name, title.Size, title.BackgroundTransparency = "Title", UDim2.fromScale(1, 1), 1
	title.Font, title.TextSize, title.TextColor3 = Enum.Font.GothamBold, 18, ink
	title.TextStrokeColor3, title.TextStrokeTransparency = white, 0.25
	title.Text = "VERITY • LVL " .. level
	title.Parent, gui.Parent = gui, root
	model.Parent = parent
	CollectionService:AddTag(model, Profile.Tag)
	return model
end

function Factory.SetStage(model, level)
	local crown = model:FindFirstChild("Crown")
	if crown then for _, p in crown:GetChildren() do if p:IsA("BasePart") then p.Transparency = if level == 100 then 0 else 1 end end end
end

return Factory
