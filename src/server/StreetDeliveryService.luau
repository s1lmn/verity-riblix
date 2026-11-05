--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.StreetDeliveryConfig)
local Income=require(Shared.EconomyConfig)
local Numeric=require(Shared.Numeric)
local Locale=require(Shared.LocaleText)
local Service={};Service.__index=Service
function Service.new(data,state,economy,players,clock,notify,parent)
 local self=setmetatable({data=data,state=state,economy=economy,players=players,clock=clock,notify=notify,random=Random.new(),cycle=0,nextAt=clock()+Config.FirstDelay},Service)
 local folder=Instance.new("Folder");folder.Name="VerityStreetDelivery";folder:SetAttribute("Phase","Idle");folder.Parent=parent;self.folder=folder
 local description="Обычная награда 70% • ×2 22% • ×5 6% • украшение 2%. Все украшения собраны — компенсация ×5."
 folder:SetAttribute("RewardDescription_ru",description);folder:SetAttribute("RewardDescription_en",Locale.Get("en",description))
 folder:SetAttribute("RewardOdds","70 / 22 / 6 / 2");folder:SetAttribute("CosmeticCompensationMultiplier",Config.CosmeticCompensationMultiplier)
 local anchor=Instance.new("Part");anchor.Name="ParcelClaim";anchor.Size=Vector3.one*.5;anchor.Anchored=true;anchor.Transparency=1
 anchor.CanCollide=false;anchor.CanTouch=false;anchor.CanQuery=false;anchor.Parent=folder;self.anchor=anchor
 local prompt=Instance.new("ProximityPrompt");prompt.Name="CollectParcel";prompt.MaxActivationDistance=Config.Reach
 prompt.HoldDuration=.2;prompt.RequiresLineOfSight=false;prompt.Enabled=false
 Locale.SetWorld(prompt,"ObjectText","Упавшая посылка");Locale.SetWorld(prompt,"ActionText","Подобрать")
 prompt.Parent=anchor;self.prompt=prompt
 self.link=prompt.Triggered:Connect(function(player)self:Claim(player)end)
 return self
end
function Service:Eligible(player)
 local profile=self.data:Get(player.UserId)
 return profile and player.Parent==self.players and self.state.sessions[player.UserId] and profile.Data.VerityUnlocked and profile or nil
end
function Service:Announce(code)
 for _,player in self.players:GetPlayers() do if self:Eligible(player) then self.notify(player.UserId,code,0) end end
end
function Service:Start(now)
 self.cycle+=1;local round=Config.Round(self.cycle,now);self.active=round
 -- Exactly one hidden server roll per parcel, before anybody interacts.
 round.prize=Config.PickReward(self.random:NextNumber());round.cosmeticUnit=self.random:NextNumber()
 self.nextAt=now+Config.Interval;self.prompt.Enabled=false
 self.anchor.Position=Config.PickupPosition(round)
 for _,key in {"RewardKind","RewardItemId","RewardCash","RewardMultiplier","RewardCompensation"} do self.folder:SetAttribute(key,nil) end
 self.folder:SetAttribute("Cycle",self.cycle);self.folder:SetAttribute("StartedAt",now);self.folder:SetAttribute("WinnerUserId",nil)
 self.folder:SetAttribute("Phase","Driving");self:Announce("STREET_DELIVERY_STARTED")
end
function Service:Claim(player)
 local round=self.active;local now=self.clock()
 if not round or round.claimed or now<round.readyAt or now>=round.expiresAt then return false end
 local profile=self:Eligible(player);if not profile then return false end
 local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not root or not hum or hum.Health<=0 or root.Anchored or hum.SeatPart or player:GetAttribute("VerityRiding")
  or player:GetAttribute("VerityRaceSlot") or player:GetAttribute("VerityParkourStep") or player:GetAttribute("VerityBattleActive") then return false end
 local p=root.Position
 if not Numeric.isFinite(p.X) or not Numeric.isFinite(p.Y) or not Numeric.isFinite(p.Z) or (p-self.anchor.Position).Magnitude>Config.Reach then return false end
 local ray=RaycastParams.new();ray.FilterDescendantsInstances={char};ray.RespectCanCollide=true
 if workspace:Raycast(p,self.anchor.Position-p,ray) then return false end
 -- Grant below is synchronous. Lock permanently; another claimant cannot reroll a failure.
 round.claimed=true;self.prompt.Enabled=false
 local prize=round.prize;local itemId;local multiplier=prize.multiplier;local compensation=false
 if prize.id=="Cosmetic" then
  local missing={}
  for _,id in Config.Cosmetics do if not profile.Data.CosmeticsOwned[id] then table.insert(missing,id) end end
  if #missing>0 then itemId=missing[math.min(#missing,math.floor(round.cosmeticUnit*#missing)+1)]
  else multiplier=Config.CosmeticCompensationMultiplier;compensation=true end
 end
 local base=Income.getIncome(profile.Data.VerityLevel)*Config.RewardSeconds*self.economy:GetMultiplier(profile)
 local ok,reward=self.economy:AddCash(player.UserId,base*multiplier)
 if not ok then self.folder:SetAttribute("Phase","Expired");return false end
 if itemId then profile.Data.CosmeticsOwned[itemId]=true;self.data:Touch(profile) end
 self.state:CompleteActivity(profile,"StreetDelivery")
 local result={version=1,cycle=round.cycle,kind=prize.id,itemId=itemId,cash=reward,multiplier=multiplier,
  compensation=compensation,rare=prize.id=="JackpotCash" or prize.id=="Cosmetic"}
 round.result=result
 self.folder:SetAttribute("WinnerUserId",player.UserId)
 self.folder:SetAttribute("RewardKind",result.kind);self.folder:SetAttribute("RewardItemId",itemId)
 self.folder:SetAttribute("RewardCash",reward);self.folder:SetAttribute("RewardMultiplier",multiplier)
 self.folder:SetAttribute("RewardCompensation",compensation);self.folder:SetAttribute("Phase","Claimed")
 self.state:Publish(player.UserId,true);self.notify(player.UserId,"STREET_DELIVERY_REWARD",reward,result)
 return true
end
function Service:Tick()
 local now=self.clock();local round=self.active
 if round then
  if now>=round.expiresAt then
   self.active=nil;self.prompt.Enabled=false;self.folder:SetAttribute("Phase","Idle")
  elseif now>=round.readyAt and not round.claimed and not round.announced then
   round.announced=true;self.prompt.Enabled=true;self.folder:SetAttribute("Phase","Collect")
   self:Announce("STREET_DELIVERY_DROPPED")
  end
 elseif now>=self.nextAt then
  for _,player in self.players:GetPlayers() do if self:Eligible(player) then self:Start(now);break end end
 end
end
function Service:Destroy()self.link:Disconnect();self.folder:Destroy();self.active=nil end
return Service
