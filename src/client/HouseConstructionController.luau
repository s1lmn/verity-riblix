--!nonstrict
local Collection=game:GetService("CollectionService")
local Tween=game:GetService("TweenService")
local Cleanup=require(script.Parent.Cleanup)
local Controller={};Controller.__index=Controller
function Controller.new(ctx)
	local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),records={}},Controller)
	local function add(house)
		if self.records[house] then return end
		local record={parts={},tweens={},cleanup=Cleanup.new()};self.records[house]=record
		local function reconcile(animate)
			if not house.Parent then return end
			local camera=workspace.CurrentCamera
			local close=camera and (camera.CFrame.Position-house:GetPivot().Position).Magnitude<160
			local budget=48
			for _,p in house:GetDescendants() do
				if not p:IsA("BasePart") or p:GetAttribute("ConstructionVisible")==nil then continue end
				local visible=p:GetAttribute("ConstructionVisible")
				local before=record.parts[p];record.parts[p]=visible
				if record.tweens[p] then record.tweens[p]:Cancel();record.tweens[p]=nil end
				p.LocalTransparencyModifier=0
				if animate and close and before==false and visible and not p.Name:find("Glass") and budget>0 and not ctx.settings.values.ReducedEffects then
					budget-=1;p.LocalTransparencyModifier=1
					local tween=Tween:Create(p,TweenInfo.new(if ctx.settings.values.ReducedMotion then .15 else .65,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{LocalTransparencyModifier=0})
					record.tweens[p]=tween;tween:Play()
					tween.Completed:Once(function()
						if record.tweens[p]==tween then record.tweens[p]=nil end
						tween:Destroy()
					end)
				end
			end
		end
		reconcile(false)
		record.cleanup:Add(house:GetAttributeChangedSignal("HouseBuildRevision"):Connect(function()
			task.delay(.1,function() if self.records[house]==record then reconcile(true) end end)
		end))
	end
	local function remove(house)
		local r=self.records[house];if not r then return end
		for p,tween in r.tweens do tween:Cancel();if p.Parent then p.LocalTransparencyModifier=0 end end
		r.cleanup:Destroy();self.records[house]=nil
	end
	self.cleanup:Add(Collection:GetInstanceAddedSignal("VerityGrowingHouse"):Connect(add))
	self.cleanup:Add(Collection:GetInstanceRemovedSignal("VerityGrowingHouse"):Connect(remove))
	for _,house in Collection:GetTagged("VerityGrowingHouse") do add(house) end
	self.cleanup:Add(function() for house in self.records do remove(house) end end)
	return self
end
function Controller:Destroy() self.cleanup:Destroy() end
return Controller
