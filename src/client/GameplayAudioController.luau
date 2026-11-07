--!nonstrict
-- Audio observes confirmed Core state; it never completes tasks or grants purchases.
local Players=game:GetService("Players")
local Cleanup=require(script.Parent.Cleanup)
local ActivityCard=require(script.Parent.ActivityCard)
local Cosmetics=require(game:GetService("ReplicatedStorage").Shared.CosmeticCatalog)
local Gameplay={};Gameplay.__index=Gameplay

function Gameplay.new(ctx,visuals)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),seen={},order={}},Gameplay)
 self.cleanup:Add(ctx.net.StateChanged.Event:Connect(function(state) self:State(state) end))
 self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
  if result.success then
   if result.action=="TaskStart" then ctx.sound:Play("TaskAccepted")
   elseif result.action=="HouseDoor" then ctx.sound:Play("Success")
   elseif result.action=="EquipCosmetic" then ctx.sound:Play("Success") end
  elseif result.errorCode=="INSUFFICIENT_CASH" then ctx.sound:Play("NotEnoughCash") end
 end))
 self.cleanup:Add(ctx.net.Notification.Event:Connect(function(payload)
  if not self:Accept("note",payload.eventId) then return end
  if payload.code=="SECRET_POWERED" or payload.code=="SECRET_ARCHIVE_OPEN" then ctx.sound:Play("Success")
  elseif payload.code=="SECRET_WRONG_ORDER" then ctx.sound:Play("NotEnoughCash")
  elseif payload.code=="HOME_DECOR_PURCHASED" or payload.code=="HOME_STYLE_APPLIED" then ctx.sound:Play("DecorPurchased")
  elseif payload.code=="COMMUNITY_FAILED" then ctx.sound:Play("NotEnoughCash")
  elseif payload.code=="COMMUNITY_WIN" or payload.code=="DIVERSION_REWARD" or payload.code=="TASK_REWARD" or payload.code=="PARKOUR_FINISH" or payload.code=="RACE_WIN" or payload.code=="BATTLE_WIN" or payload.code=="FUSION_WIN" or payload.code=="FUSION_PRIZE" then ctx.sound:Play("TaskCompleted")
  elseif payload.code=="RACE_JOINED" then ctx.sound:Play("TaskAccepted")
  elseif payload.code=="RACE_STARTED" or payload.code=="RACE_FINISH" then ctx.sound:Play("TaskCheckpoint")
  elseif payload.code=="STREET_DELIVERY_DROPPED" then
   if not ActivityCard.Blocked(ctx) and not ActivityCard.ActivityRunning() then ctx.sound:Play("DeliveryArrived") end
  elseif payload.code=="STREET_DELIVERY_REWARD" then ctx.sound:Play(if payload.deliveryReward and payload.deliveryReward.rare then "ParcelRare" else "ParcelCollected")
  elseif payload.code=="BATTLE_BOSS" then ctx.sound:Play("Milestone100")
  elseif payload.code=="BATTLE_WAVE" then ctx.sound:Play("TaskCheckpoint")
  elseif payload.code=="PARKOUR_CHECKPOINT" then ctx.sound:Play("TaskCheckpoint")
  elseif payload.code=="INSUFFICIENT_CASH" then ctx.sound:Play("NotEnoughCash")
  elseif payload.code=="OK" and payload.source=="HouseFeature" then ctx.sound:Play("DecorPurchased")
  elseif payload.code=="HOUSE_UPGRADED" then ctx.sound:Play("Success") end
 end))
 self.cleanup:Add(ctx.net.World.Event:Connect(function(event)
  if event.ownerUserId~=Players.LocalPlayer.UserId or not self:Accept("world",event.eventId) then return end
  if event.kind=="VeritySpawned" then
   if visuals:BeginSpawn(event) then ctx.sound:Play("BoxCeremony")
   else ctx.sound:Play("VeritySpawn") end
  end
 end))
 self.cleanup:Add(visuals.SpawnStopped.Event:Connect(function(_,completed)
  if not completed then ctx.sound:Stop("BoxCeremony") end
 end))
 self.cleanup:Add(visuals.Emotion.Event:Connect(function(emotion) ctx.sound:Emotion(emotion) end))
 return self
end
function Gameplay:Accept(source,id)
 if type(id)~="string" then return true end
 local key=source..":"..id
 if self.seen[key] then return false end
 self.seen[key]=true;table.insert(self.order,key)
 if #self.order>256 then self.seen[table.remove(self.order,1)]=nil end
 return true
end
function Gameplay:State(state)
 if self.previous then
  if state.DeliveryState=="Delivered" and self.previous.delivery~="Delivered" and self.previous.delivery~="Opened" then
   self.ctx.sound:Play("DeliveryArrived")
  end
  if state.MoneyPassOwned and not self.previous.moneyPass then self.ctx.sound:Play("DecorPurchased") end
  -- Ownership comes from the server snapshot, never the payment prompt closing.
  for id,owned in state.CosmeticsOwned or {} do
   if owned and not self.previous.owned[id] and id:sub(1,5)~="home_" and not (Cosmetics.Items[id] and (Cosmetics.Items[id].achievement or Cosmetics.Items[id].starter or Cosmetics.Items[id].exclusive)) then self.ctx.sound:Play("DecorPurchased");break end
  end
 end
 self.previous={delivery=state.DeliveryState,moneyPass=state.MoneyPassOwned,owned=table.clone(state.CosmeticsOwned or {})}
end
function Gameplay:Destroy() self.cleanup:Destroy() end
return Gameplay
