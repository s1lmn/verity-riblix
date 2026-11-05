--!nonstrict
-- Bounded work per frame; tile-sized surfaces keep distant Studs from shimmering.
local RunService=game:GetService("RunService")
local Cleanup=require(script.Parent.Cleanup)
local Surfaces={};Surfaces.__index=Surfaces
local BUDGET=48
function Surfaces.new()
 local self=setmetatable({cleanup=Cleanup.new(),parts={},queue={},cursor=1},Surfaces)
 local function add(object)
  if not object:IsA("BasePart") or self.parts[object] or not object:FindFirstAncestor("GeneratedWorld") then return end
  local studs=object.TopSurface==Enum.SurfaceType.Studs or object:GetAttribute("StudSurfaceDetail")==true
  local glass=object.Name:find("Glass")~=nil
  if not studs and not glass then return end
  local record={object=object,studs=studs,glass=glass,surface=object.TopSurface,smooth=object.TopSurface~=Enum.SurfaceType.Studs,
   alpha=object.LocalTransparencyModifier,baseAlpha=object.LocalTransparencyModifier,last=0}
  self.parts[object]=record;table.insert(self.queue,record)
 end
 for _,object in workspace:GetDescendants()do add(object)end
 self.cleanup:Add(workspace.DescendantAdded:Connect(add))
 self.cleanup:Add(workspace.DescendantRemoving:Connect(function(object)
  local record=self.parts[object]
  if record then
   -- Stream-out does not destroy the instance: restore only this controller's changes.
   if record.studs then object.TopSurface=record.surface end
   if record.glass then object.LocalTransparencyModifier=record.baseAlpha end
   record.removed=true;self.parts[object]=nil
  end
 end))
 self.cleanup:Add(RunService.Heartbeat:Connect(function()self:Tick(os.clock())end))
 return self
end
function Surfaces:Tick(now)
 local camera=workspace.CurrentCamera;if not camera then return end
 local processed=0
 local limit=math.min(BUDGET,#self.queue)
 while processed<limit and #self.queue>0 do
  if self.cursor>#self.queue then self.cursor=1 end
  local record=self.queue[self.cursor];local object=record.object
  processed+=1
  if record.removed or not object.Parent then
   self.queue[self.cursor]=self.queue[#self.queue];self.queue[#self.queue]=nil
   continue
  end
  self.cursor+=1
  if now-record.last<.12 then continue end
  local elapsed=math.min(.5,now-record.last);record.last=now
  local p=object.CFrame:PointToObjectSpace(camera.CFrame.Position);local half=object.Size*.5
  local dx,dy,dz=math.max(0,math.abs(p.X)-half.X),math.max(0,math.abs(p.Y)-half.Y),math.max(0,math.abs(p.Z)-half.Z)
  local distance=math.sqrt(dx*dx+dy*dy+dz*dz)
  if record.studs then
   local smooth=if record.smooth then distance>40 else distance>64
   if smooth~=record.smooth then
    record.smooth=smooth;object.TopSurface=if smooth then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
   end
  end
  if record.glass and object:GetAttribute("ConstructionVisible")~=false then
   local target=record.baseAlpha+(1-record.baseAlpha)*math.clamp((distance-90)/60,0,1)
   record.alpha+=(target-record.alpha)*(1-math.exp(-8*elapsed))
   if math.abs(record.alpha-target)<.005 then record.alpha=target end
   if math.abs(object.LocalTransparencyModifier-record.alpha)>.002 then object.LocalTransparencyModifier=record.alpha end
  end
 end
end
function Surfaces:Destroy()
 self.cleanup:Destroy()
 for object,record in self.parts do
  if object.Parent then
   if record.studs then object.TopSurface=record.surface end
   if record.glass then object.LocalTransparencyModifier=record.baseAlpha end
  end
 end
 table.clear(self.parts);table.clear(self.queue)
end
return Surfaces
