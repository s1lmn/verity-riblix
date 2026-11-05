
--!nonstrict
-- Local detail fades preserve nearby Studs and avoid distant subpixel shimmer.
local RunService=game:GetService("RunService")
local Cleanup=require(script.Parent.Cleanup)
local Surfaces={}
Surfaces.__index=Surfaces

function Surfaces.new()
	local self=setmetatable({cleanup=Cleanup.new(),parts={},nextUpdate=0},Surfaces)
	local function add(object)
		if not object:IsA("BasePart") or not object:FindFirstAncestor("GeneratedWorld") then return end
		local studs=object.TopSurface==Enum.SurfaceType.Studs
		local glass=object.Name:find("Glass")~=nil
		if studs or glass then
			self.parts[object]={studs=studs,glass=glass,smooth=false,alpha=object.LocalTransparencyModifier,baseAlpha=object.LocalTransparencyModifier}
		end
	end
	for _,object in workspace:GetDescendants() do add(object) end
	self.cleanup:Add(workspace.DescendantAdded:Connect(add))
	self.cleanup:Add(workspace.DescendantRemoving:Connect(function(object) self.parts[object]=nil end))
	self.cleanup:Add(RunService.Heartbeat:Connect(function() self:Tick(os.clock()) end))
	return self
end

function Surfaces:Tick(now)
	if now<self.nextUpdate then return end
	self.nextUpdate=now+.2
	local camera=workspace.CurrentCamera
	if not camera then return end
	for object,record in self.parts do
		local p=object.CFrame:PointToObjectSpace(camera.CFrame.Position)
		local half=object.Size*.5
		local distance=Vector3.new(math.max(0,math.abs(p.X)-half.X),math.max(0,math.abs(p.Y)-half.Y),
			math.max(0,math.abs(p.Z)-half.Z)).Magnitude
		if record.studs then
			local smooth=if record.smooth then distance>65 else distance>90
			if smooth~=record.smooth then
				record.smooth=smooth
				object.TopSurface=if smooth then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
			end
		end
		if record.glass and object:GetAttribute("ConstructionVisible")~=false then
			local target=math.clamp((distance-100)/100,0,1)
			local alpha=record.baseAlpha+(1-record.baseAlpha)*target
			record.alpha+=(alpha-record.alpha)*.65
			if math.abs(record.alpha-alpha)<.005 then record.alpha=alpha end
			object.LocalTransparencyModifier=record.alpha
		end
	end
end

function Surfaces:Destroy()
	self.cleanup:Destroy()
	for object,record in self.parts do
		if object.Parent then
			if record.studs then object.TopSurface=Enum.SurfaceType.Studs end
			if record.glass then object.LocalTransparencyModifier=record.baseAlpha end
		end
	end
	table.clear(self.parts)
end
return Surfaces
