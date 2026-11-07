--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local C=require(Shared.HomeStyleConfig)
local Numeric=require(Shared.Numeric)
local Builder=require(game:GetService("ReplicatedStorage").World.HomeDecorBuilder)
local Service={};Service.__index=Service
function Service.new(world,data,state,economy,clock,notify)
 local self=setmetatable({world=world,data=data,state=state,economy=economy,clock=clock,notify=notify,limits={},links={}},Service)
 state.HomeStylePosition=function(id)
  local session=state.sessions[id];local record=session and world.houseProgression.plots[session.PlotId]
  return record and record.homeDecor.apply.Parent.Position
 end
 for plotId,record in world.houseProgression.plots do
  local r=record.homeDecor
  table.insert(self.links,r.browse.Triggered:Connect(function(player) self:Act(player,plotId,"Browse") end))
  table.insert(self.links,r.apply.Triggered:Connect(function(player) self:Act(player,plotId,"Theme") end))
  for id,prompt in r.prompts do table.insert(self.links,prompt.Triggered:Connect(function(player) self:Act(player,plotId,id) end)) end
 end
 return self
end
function Service:Act(player,plotId,action)
 local now=self.clock()
 if now<(self.limits[player] or 0) then return end
 self.limits[player]=now+.45
 local profile=self.data:Get(player.UserId);local record=self.world.houseProgression.plots[plotId]
 local root=self.world:GetCharacter(player.UserId)
 if not profile or profile.Closing or not self.state.sessions[player.UserId] or not record or not record.state
  or record.state.ownerUserId~=player.UserId or not profile.Data.VerityUnlocked or not root then return end
 for _,name in {"VerityDiversionKind","VerityParkourStep","VerityRaceSlot","VerityBattleActive","VerityFusionSlot","VerityRiding"} do if player:GetAttribute(name) then return end end
 local r=record.homeDecor
 local prompt=if action=="Browse" then r.browse elseif action=="Theme" then r.apply else r.prompts[action]
 if not prompt then return end
 local distance=(root.Position-prompt.Parent.Position).Magnitude
 if not Numeric.isFinite(distance) or distance>7 then return end
 if profile.Data.HouseIncomeLevel<1 then self.notify(player.UserId,"HOME_BUILD_FIRST");return end
 if action=="Browse" then
  local index=table.find(C.ThemeOrder,r.themeChoice) or 1
  r.themeChoice=C.ThemeOrder[index%#C.ThemeOrder+1]
  Builder.Update(r,record.house,record.pivot,self.state:Snapshot(player.UserId));return
 end
 local item,id,owned
 if action=="Theme" then id=r.themeChoice;item=C.Themes[id];owned=C.ThemeOwned(profile.Data.CosmeticsOwned,id)
 else id=action;item=C.Decor[id];owned=profile.Data.CosmeticsOwned[id]==true end
 if not item or item.Earned then return end
 if profile.Data.VerityLevel<item.Level or profile.Data.HouseIncomeLevel<(item.Build or 1) then self.notify(player.UserId,"HOME_LEVEL_REQUIRED");return end
 if not owned then
  if not self.economy:TrySpendCash(player.UserId,item.Cost) then self.notify(player.UserId,"INSUFFICIENT_CASH");return end
  profile.Data.CosmeticsOwned[if action=="Theme" then "home_theme_"..id else id]=true
 end
 if action=="Theme" then profile.Data.HouseTheme=id end
 self.data:Touch(profile);self.state:Publish(player.UserId,true)
 self.notify(player.UserId,if owned then "HOME_STYLE_APPLIED" else "HOME_DECOR_PURCHASED")
end
function Service:Remove(player) self.limits[player]=nil end
function Service:Destroy() for _,link in self.links do link:Disconnect() end;table.clear(self.limits) end
return Service
