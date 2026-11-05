--!nonstrict
local Rewards=require(game:GetService("ReplicatedStorage").Shared.ActivityRewards)
local Service={};Service.__index=Service
function Service.new(data,state,notify)
 return setmetatable({data=data,state=state,notify=notify},Service)
end
-- Only authoritative activity finish hooks call Grant. There is no client claim endpoint.
function Service:Grant(userId,rewardId)
 local reward=Rewards.Items[rewardId]
 local profile=self.data:Get(userId)
 if not reward or not profile or not self.state.sessions[userId] or not profile.Data.VerityUnlocked then return false end
 if profile.Data.CosmeticsOwned[reward.itemId] then return false end
 profile.Data.CosmeticsOwned[reward.itemId]=true
 self.data:Touch(profile)
 self.state:Publish(userId,true)
 self.notify(userId,rewardId,reward.itemId)
 -- Reuse normal save/session ownership; no yielding or extra payment in the activity finish path.
 task.defer(function()
  if self.data:Get(userId)==profile and profile.Dirty and not profile.Saving then self.data:SaveAsync(userId,false) end
 end)
 return true
end
return Service
