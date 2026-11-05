--!nonstrict
-- Only owns temporary non-glass fades. WorldSurfaceController owns glass LTM.
local Collection=game:GetService("CollectionService")
local Tween=game:GetService("TweenService")
local Cleanup=require(script.Parent.Cleanup)
local Controller={};Controller.__index=Controller
local function cancel(record,p)
 local tween=record.tweens[p]
 if not tween then return end
 record.tweens[p]=nil;tween:Cancel();tween:Destroy()
end
function Controller.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),records={}},Controller)
 local function add(house)
  if not house:IsA("Model") or self.records[house] then return end
  local record={parts={},tweens={},cleanup=Cleanup.new()};self.records[house]=record
  local function track(p)
   if p:IsA("BasePart") then record.parts[p]={visible=p:GetAttribute("ConstructionVisible")} end
  end
  for _,p in house:GetDescendants() do track(p) end
  record.cleanup:Add(house.DescendantAdded:Connect(track))
  record.cleanup:Add(house.DescendantRemoving:Connect(function(p) cancel(record,p);record.parts[p]=nil end))
  local function reconcile(animate)
   if not house.Parent then return end
   local camera=workspace.CurrentCamera
   local close=camera and (camera.CFrame.Position-house:GetPivot().Position).Magnitude<160
   local budget=48
   for p,entry in record.parts do
    local visible=p:GetAttribute("ConstructionVisible")
    if visible==nil then continue end
    local before=entry.visible;entry.visible=visible
    -- Repeated revisions must not cancel an unrelated fade or reset distant glass.
    if before==visible then continue end
    cancel(record,p)
    if p.Name:find("Glass") then continue end
    p.LocalTransparencyModifier=0
    if animate and close and before==false and visible and budget>0 and not (ctx.settings.values.ReducedEffects or ctx.settings.values.LowGraphics) then
     budget-=1;p.LocalTransparencyModifier=1
     local tween=Tween:Create(p,TweenInfo.new(if ctx.settings.values.ReducedMotion then .15 else .65,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{LocalTransparencyModifier=0})
     record.tweens[p]=tween
     tween.Completed:Once(function()
      if record.tweens[p]==tween then record.tweens[p]=nil end
      tween:Destroy()
     end)
     tween:Play()
    end
   end
  end
  record.cleanup:Add(house:GetAttributeChangedSignal("HouseBuildRevision"):Connect(function()
   if record.pending then return end
   record.pending=true
   task.delay(.1,function()
    record.pending=false
    if self.records[house]==record then reconcile(true) end
   end)
  end))
 end
 local function remove(house)
  local r=self.records[house];if not r then return end
  self.records[house]=nil;r.cleanup:Destroy()
  for p in r.tweens do cancel(r,p);if p.Parent then p.LocalTransparencyModifier=0 end end
  table.clear(r.parts)
 end
 self.cleanup:Add(Collection:GetInstanceAddedSignal("VerityGrowingHouse"):Connect(add))
 self.cleanup:Add(Collection:GetInstanceRemovedSignal("VerityGrowingHouse"):Connect(remove))
 for _,house in Collection:GetTagged("VerityGrowingHouse") do add(house) end
 self.cleanup:Add(ctx.settings.Changed.Event:Connect(function(values)
  if not (values.ReducedEffects or values.LowGraphics) and not values.ReducedMotion then return end
  for _,r in self.records do
   for p in r.tweens do cancel(r,p);if p.Parent then p.LocalTransparencyModifier=0 end end
  end
 end))
 self.cleanup:Add(function() for house in self.records do remove(house) end end)
 return self
end
function Controller:Destroy() self.cleanup:Destroy() end
return Controller
