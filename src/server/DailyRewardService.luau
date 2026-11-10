--!nonstrict
-- Profile-local, one-per-UTC-day grant. The future UI reads snapshots; it cannot supply a reward.
local Shared=game:GetService("ReplicatedStorage").Shared
local Daily=require(Shared.DailyRewardsConfig)
local Economy=require(Shared.EconomyConfig)
local Config=require(Shared.GameConfig)
local Forge=require(Shared.WeatherForgeConfig)
local Service={};Service.__index=Service
function Service.new(data,state,economy,players,clock,premium)
 return setmetatable({data=data,state=state,economy=economy,players=players,clock=clock,premium=premium,records={},dead=false},Service)
end
function Service:Record(userId)
 local r=self.records[userId];local profile=self.data:Get(userId)
 if self.dead or not r or r.profile~=profile or r.player.Parent~=self.players then return nil end
 return profile,r
end
function Service:Day()
 local now=self.clock()
 if type(now)~="number" or now~=now or now<0 or now>=Daily.MaxUtcDay*Daily.DaySeconds then return nil end
 return math.floor(now/Daily.DaySeconds),now
end
function Service:MultiplierReady(userId,profile)
 if not self.premium or not self.premium.enabled or not Config.MoneyPassId or profile.MoneyPassOwned==true then return true end
 local _,record=self.premium:Record(userId)
 local status=record and record.statuses.money_x3
 return status=="Owned" or status=="Unowned"
end
function Service:Quote(profile,slot)
 local definition=Daily.Days[slot];local data=profile.Data
 local income=Economy.getIncome(data.VerityLevel);local cost=Economy.LevelCost[data.VerityLevel] or 0
 local base=math.max(definition.Minimum,income*definition.Seconds,math.min(cost*definition.Fraction,income*Daily.MaxCashSeconds))
 local cash=base*self.economy:GetMultiplier(profile)
 local materials=table.clone(definition.Materials)
 local look=definition.Look and Forge.Looks[definition.Look]
 local duplicate=look~=nil and data.CosmeticsOwned[look.Item]==true
 if duplicate then for id,amount in definition.Duplicate do materials[id]=(materials[id] or 0)+amount end end
 local actual={}
 for id,amount in materials do actual[id]=math.min(amount,math.max(0,Forge.MaxMaterial-(data.WeatherMaterials[id] or 0))) end
 return {slot=slot,name=definition.Name,cash=math.max(0,math.min(cash,Config.MaxMoney-data.Cash,Config.MaxMoney-data.TotalEarned)),
  materials=actual,look=definition.Look,lookItem=look and look.Item,lookName=look and look.Name,duplicate=duplicate}
end
function Service:Claim(userId)
 local profile,r=self:Record(userId);if not profile then return "NOT_READY",0 end
 local day,now=self:Day();if not day then return "CLOCK_UNAVAILABLE",0 end
 local ledger=profile.Data.DailyRewards
 if day<=ledger.LastDay then r.pending=false;return "ALREADY_CLAIMED",0 end
 if ledger.Claims>=Daily.MaxUtcDay then return "MAX_REWARDS",0 end
 local session=self.state.sessions[userId]
 if session and session.ReceiptBusy then return "BUSY",0 end
 if not self:MultiplierReady(userId,profile) then return "DAILY_OWNERSHIP_PENDING",0 end
 local slot=ledger.Claims%#Daily.Days+1;local quote=self:Quote(profile,slot)
 local ok,cash=self.economy:AddCash(userId,quote.cash);if not ok then return "NOT_READY",0 end
 -- No yield between cash, materials, permanent look and the durable day marker.
 for id,amount in quote.materials do profile.Data.WeatherMaterials[id]=(profile.Data.WeatherMaterials[id] or 0)+amount end
 if quote.lookItem and not quote.duplicate then profile.Data.CosmeticsOwned[quote.lookItem]=true end
 ledger.Claims+=1;ledger.LastDay=day
 ledger.Last={Id=tostring(day)..":"..tostring(ledger.Claims),Day=day,Slot=slot,At=now,Cash=cash,
  Materials=quote.materials,Look=quote.look,Duplicate=quote.duplicate}
 self.data:Touch(profile);r.pending=false;r.freshGrantId=ledger.Last.Id
 if session then self.state:Publish(userId,true) end
 task.defer(function()
  if self.data:Get(userId)==profile and profile.Dirty and not profile.Saving then self.data:SaveAsync(userId,false) end
 end)
 return "OK",cash
end
function Service:Attach(player)
 local profile=self.data:Get(player.UserId)
 if not profile or self.dead then return end
 local old=self.records[player.UserId];if old and old.profile==profile then return end
 local day=self:Day()
 self.records[player.UserId]={profile=profile,player=player,pending=true,observedDay=day}
 self:Claim(player.UserId)
end
function Service:Projection(userId)
 local profile,r=self:Record(userId);if not profile then return nil end
 local day,now=self:Day();if not day then return nil end
 local ledger=profile.Data.DailyRewards;local ready=self:MultiplierReady(userId,profile)
 local claimed=day<=ledger.LastDay;local rewards={}
 for slot=1,#Daily.Days do table.insert(rewards,self:Quote(profile,slot)) end
 local last=ledger.Last and Daily.Copy(ledger).Last
 return {version=Daily.Version,calendar="UTC",serverTime=now,nextResetAt=(day+1)*Daily.DaySeconds,
  totalClaims=ledger.Claims,nextSlot=ledger.Claims%#Daily.Days+1,nextCycle=math.floor(ledger.Claims/#Daily.Days)+1,
  claimedToday=claimed,canClaim=not claimed and ready and not ((self.state.sessions[userId] or {}).ReceiptBusy),
  blockedReason=if not ready then "DAILY_OWNERSHIP_PENDING" elseif claimed then "ALREADY_CLAIMED" else nil,
  autoClaim=true,missedDaysResetProgress=false,rewards=rewards,lastClaim=last,
  freshGrantId=last and r.freshGrantId==last.Id and last.Id or nil}
end
function Service:Tick()
 local day=self:Day()
 for id,r in self.records do
  local profile=self:Record(id)
  if not profile then self.records[id]=nil;continue end
  if day and day~=r.observedDay then r.observedDay=day;r.pending=true end
  if r.pending then self:Claim(id) end
 end
end
function Service:Remove(player) self.records[player.UserId]=nil end
function Service:Destroy() self.dead=true;table.clear(self.records) end
return Service
