--!nonstrict
local A=require(game:GetService("ReplicatedStorage").Shared.AlbumConfig)
local Service={};Service.__index=Service
function Service.new(data,state,rewards,notify) return setmetatable({data=data,state=state,rewards=rewards,notify=notify},Service) end
function Service:CheckMaster(id)
 local profile=self.data:Get(id)
 if profile and self.state.sessions[id] and profile.Data.VerityUnlocked and A.Complete(profile.Data.FeedCollection) then self.rewards:Grant(id,"album_master") end
end
function Service:Claim(id,setId)
 local set=A.Sets[setId];local profile=self.data:Get(id)
 if not set or not profile or not self.state.sessions[id] then return "NOT_READY" end
 if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
 if profile.Data.CosmeticsOwned[set.Decor] then return "OK" end
 if A.Count(profile.Data.FeedCollection,setId)<#set.Cards then return "ALBUM_INCOMPLETE" end
 profile.Data.CosmeticsOwned[set.Decor]=true;self.data:Touch(profile)
 self:CheckMaster(id);self.notify(id,"ALBUM_SET_CLAIMED")
 return "OK"
end
return Service
