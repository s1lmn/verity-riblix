--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.VerityRaceConfig)
local Income=require(Shared.EconomyConfig)
local Numeric=require(Shared.Numeric)
local Locale=require(Shared.LocaleText)
local Service={};Service.__index=Service
local attributes={"VerityRaceSlot","VerityRaceLevel","VerityRaceStartedAt","VerityRaceFinishSeconds","VerityRaceSeed"}
function Service.new(data,state,economy,players,clock,notify,random)
 local rng=if random then nil else Random.new()
 return setmetatable({data=data,state=state,economy=economy,players=players,clock=clock,notify=notify,
  random=random or function()return rng:NextNumber()end,entries={},links={},requests={},phase="Waiting",round=0},Service)
end
function Service:Profile(player)
 local profile=self.data:Get(player.UserId)
 local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not profile or not self.state.sessions[player.UserId] or not profile.Data.VerityUnlocked or not root or not hum or hum.Health<=0 or root.Anchored or hum.SeatPart then return nil end
 if not Numeric.isFinite(root.Position.X) or not Numeric.isFinite(root.Position.Y) or not Numeric.isFinite(root.Position.Z) then return nil end
 return profile,root,char
end
function Service:Count()local n=0;for _ in self.entries do n+=1 end;return n end
function Service:Render()
 if not self.model then return end
 self.model:SetAttribute("RacePhase",self.phase);self.model:SetAttribute("RaceCount",self:Count())
 self.model:SetAttribute("RaceDeadline",self.deadline or 0)
 for slot,pad in self.pads do
  local entry=self.entries[slot]
  pad:SetAttribute("RaceOwner",entry and entry.player.UserId or nil);pad:SetAttribute("RaceLevel",entry and entry.level or nil)
  pad.JoinRace.Enabled=(self.phase=="Waiting" or self.phase=="Countdown") and not entry
  local text=pad.RaceLabel.Text
  if entry then Locale.SetWorld(text,"Text","%s • LVL %d",entry.player.DisplayName,entry.level)
  else Locale.SetWorld(text,"Text","МЕСТО %d • ЗАНЯТЬ",slot)end
 end
end
function Service:ClearPlayer(player)
 for _,name in attributes do player:SetAttribute(name,nil)end
end
function Service:Join(player,slot)
 local now=self.clock()
 if now-(self.requests[player] or -math.huge)<.5 then return false end;self.requests[player]=now
 if self.phase~="Waiting" and self.phase~="Countdown" or not self.pads[slot] or self.entries[slot] then return false end
 for _,entry in self.entries do if entry.player==player then return false end end
 local profile,root,char=self:Profile(player)
 if not profile or player:GetAttribute("VerityRiding") or player:GetAttribute("VerityParkourStep")
  or (player:GetAttribute("VerityMobilityUntil") or 0)>now or (player:GetAttribute("VerityAttackReadyAt") or 0)>now then return false end
 if (root.Position-self.pads[slot].Position).Magnitude>Config.JoinReach then return false end
 local level=profile.Data.VerityLevel
 self.entries[slot]={player=player,character=char,level=level,slot=slot,joined=now}
 player:SetAttribute("VerityRaceLevel",level);player:SetAttribute("VerityRaceSlot",slot)
 if self:Count()>=Config.MinPlayers and self.phase=="Waiting" then self.phase="Countdown";self.deadline=now+Config.Countdown end
 self:Render();self.notify(player.UserId,"RACE_JOINED",0);return true
end
function Service:Remove(player,forget)
 local removed=false
 for slot,entry in self.entries do if entry.player==player then self.entries[slot]=nil;removed=true end end
 self:ClearPlayer(player);if forget then self.requests[player]=nil end
 if not removed then return end
 if self.phase=="Countdown" and self:Count()<Config.MinPlayers then self.phase="Waiting";self.deadline=nil end
 self:Render()
end
function Service:Leave(player)
 if self.phase=="Running" or not player:GetAttribute("VerityRaceSlot") then return false end
 self:Remove(player);return true
end
function Service:Start()
 if self:Count()<Config.MinPlayers then return end
 local entries={}
 for _,entry in self.entries do
  local profile=self:Profile(entry.player);if not profile then return end
  entry.level=profile.Data.VerityLevel;table.insert(entries,entry)
 end
 -- Iterate slots in a stable order before drawing. The server alone samples the result.
 table.sort(entries,function(a,b)return a.slot<b.slot end)
 local finishes=Config.Rank(entries,self.random)
 self.phase="Running";self.startedCount=#entries;self.started=self.clock();self.round+=1;self.deadline=nil;self.endsAt=self.started
 for _,entry in entries do
  entry.finish=finishes[entry.slot];entry.seed=self.random()*2*math.pi
  self.endsAt=math.max(self.endsAt,self.started+entry.finish+.5)
  entry.player:SetAttribute("VerityRaceLevel",entry.level);entry.player:SetAttribute("VerityRaceSeed",entry.seed)
  entry.player:SetAttribute("VerityRaceFinishSeconds",entry.finish);entry.player:SetAttribute("VerityRaceStartedAt",self.started)
  self.notify(entry.player.UserId,"RACE_STARTED",0)
 end
 self:Render()
end
function Service:Finish(cancelled)
 if self.phase~="Running" or not cancelled and self.clock()<self.endsAt then return end
 local winner
 if not cancelled and (self.startedCount or 0)>=Config.MinPlayers and self:Count()>0 then
  for _,entry in self.entries do
   if self:Profile(entry.player) and self.players:GetPlayerByUserId(entry.player.UserId)==entry.player and (not winner or entry.finish<winner.finish) then winner=entry end
  end
 end
 -- Enter results before any grant; a second Tick/Finish can never pay again.
 self.phase="Results";self.deadline=self.clock()+Config.Intermission
 self.model:SetAttribute("RaceWinner",winner and winner.player.DisplayName or nil)
 for _,entry in self.entries do self:ClearPlayer(entry.player)end
 if winner then
  local profile=self.data:Get(winner.player.UserId)
  local amount=Income.getIncome(winner.level)*Config.RewardSeconds*self.economy:GetMultiplier(profile)
  local ok,reward=self.economy:AddCash(winner.player.UserId,amount)
  if ok then self.state:Publish(winner.player.UserId,true);self.notify(winner.player.UserId,"RACE_WIN",reward)end
 end
 for _,entry in self.entries do if entry~=winner then self.notify(entry.player.UserId,if winner then "RACE_FINISH" else "RACE_CANCELLED",0)end end
 self:Render()
end
function Service:Tick()
 local now=self.clock()
 if self.phase=="Results" then
  if now>=self.deadline then self.entries={};self.phase="Waiting";self.deadline=nil;self.model:SetAttribute("RaceWinner",nil);self:Render()end
  return
 end
 local removed={}
 for _,entry in self.entries do
  local profile,root,char=self:Profile(entry.player)
  if not profile or char~=entry.character or self.players:GetPlayerByUserId(entry.player.UserId)~=entry.player
   or self.phase~="Running" and ((root.Position-self.pads[entry.slot].Position).Magnitude>Config.QueueRadius or now-entry.joined>Config.QueueTimeout) then
   table.insert(removed,entry.player)
  end
 end
 for _,player in removed do self:Remove(player)end
 if self.phase=="Running" then
  if self:Count()==0 then self:Finish(true)
  elseif now>=self.endsAt then self:Finish(false)end
 elseif self.phase=="Countdown" and now>=self.deadline then self:Start()end
end
function Service:Bind(model)
 self.model=model;self.pads={}
 for slot=1,Config.MaxPlayers do
  local pad=assert(model:FindFirstChild("QueuePad"..slot));self.pads[slot]=pad
  table.insert(self.links,pad.JoinRace.Triggered:Connect(function(player)self:Join(player,slot)end))
 end
 local leave=Instance.new("RemoteEvent");leave.Name="LeaveRaceQueue";leave.Parent=model
 table.insert(self.links,leave.OnServerEvent:Connect(function(player,...)
  if select("#",...)==0 then self:Leave(player)end
 end))
 self:Render()
end
function Service:Destroy()
 for _,entry in self.entries do self:ClearPlayer(entry.player)end
 for _,link in self.links do link:Disconnect()end
 if self.model then local remote=self.model:FindFirstChild("LeaveRaceQueue");if remote then remote:Destroy()end end
 self.entries={};self.links={};self.requests={};self.phase="Waiting";self.deadline=nil
 if self.model then self.model:SetAttribute("RaceWinner",nil);self:Render()end
end
return Service
