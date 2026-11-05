--!nonstrict
-- Only authoritative position/ordered touches advance a run; no completion remote.
local Shared=game:GetService("ReplicatedStorage").Shared
local Config=require(Shared.ParkourConfig)
local Income=require(Shared.EconomyConfig)
local Service={};Service.__index=Service
function Service.new(data,state,economy,clock,notify,resetMovement)
 return setmetatable({data=data,state=state,economy=economy,clock=clock,notify=notify,resetMovement=resetMovement,runs={},ready={},links={}},Service)
end
function Service:Character(player)
 local c=player.Character;local r=c and c:FindFirstChild("HumanoidRootPart");local h=c and c:FindFirstChildOfClass("Humanoid")
 return if r and h and h.Health>0 and not r.Anchored and not h.SeatPart then c else nil,r
end
function Service:SetRun(player,run)
 self.runs[player]=run
 player:SetAttribute("VerityParkourStep",if run then run.index else nil)
 player:SetAttribute("VerityParkourCheckpoint",if run then run.checkpoint else nil)
end
function Service:Touch(player,index)
 if player:GetAttribute("VerityRiding") or player:GetAttribute("VerityRaceSlot") then return false end
 local profile=self.data:Get(player.UserId)
 local character,root=self:Character(player)
 local pad=Config.Pads[index]
 if not profile or not self.state.sessions[player.UserId] or not profile.Data.VerityUnlocked or not character or not pad then return false end
 local p=root.Position
 if math.abs(p.X-pad.x)>pad.w/2+3 or math.abs(p.Z-pad.z)>pad.d/2+3 or p.Y<pad.y or p.Y>pad.y+7 then return false end
 local now=self.clock();local run=self.runs[player]
 if index==1 then
  if run then return false end
  self:SetRun(player,{character=character,index=1,checkpoint=1,started=now});return true
 end
 if not run or run.character~=character or index~=run.index+1 or now-run.started>Config.MaximumRunSeconds then return false end
 if pad.finish then
  if now-run.started<Config.MinimumRunSeconds then return false end
  if now<(self.ready[player] or 0) then
   self:SetRun(player,nil);self.notify(player.UserId,"PARKOUR_PRACTICE",0);return true
  end
  -- Lock before granting: repeated/multiple limb touches cannot pay twice.
  self.ready[player]=now+Config.Cooldown;self:SetRun(player,nil)
  player:SetAttribute("VerityParkourReadyAt",self.ready[player])
  local amount=Income.getIncome(profile.Data.VerityLevel)*Config.RewardSeconds*self.economy:GetMultiplier(profile)
  local ok,reward=self.economy:AddCash(player.UserId,amount)
  if ok then self.state:Publish(player.UserId,true);self.notify(player.UserId,"PARKOUR_FINISH",reward) end
  return ok
 end
 run.index=index
 if pad.checkpoint then run.checkpoint=index;self.notify(player.UserId,"PARKOUR_CHECKPOINT",0) end
 self:SetRun(player,run);return true
end
function Service:Return(player,exit)
 local c,r=self:Character(player);local run=self.runs[player]
 if not c then self:SetRun(player,nil);return end
 if self.resetMovement then self.resetMovement(player) end
 r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
 if exit then
  self:SetRun(player,nil);c:PivotTo(CFrame.new(164,4,300+Config.ZOffset))
 elseif run then
  local p=Config.Pads[run.checkpoint];run.index=run.checkpoint
  c:PivotTo(CFrame.new(p.x,p.y+4,p.z));self:SetRun(player,run)
 end
end
function Service:Tick()
 for player,run in self.runs do
  local c,r=self:Character(player)
  if not c or c~=run.character or not self.state.sessions[player.UserId] or self.clock()-run.started>Config.MaximumRunSeconds then self:SetRun(player,nil)
  elseif not Config.Contains(r.Position.X,r.Position.Z) then self:SetRun(player,nil)
  elseif r.Position.Y<Config.ResetBelow then self:Return(player,false) end
 end
end
function Service:Bind(model,players)
 for index in Config.Pads do
  local p=model:FindFirstChild(string.format("Pad%02d",index))
  if p then table.insert(self.links,p.Touched:Connect(function(hit)
   local c=hit:FindFirstAncestorOfClass("Model");local player=c and players:GetPlayerFromCharacter(c)
   if player then self:Touch(player,index) end
  end)) end
 end
 for _,name in {"ExitCourse","ReturnToStart"} do
  local prompt=model:FindFirstChild(name,true)
  if prompt then table.insert(self.links,prompt.Triggered:Connect(function(player)
   local _,r=self:Character(player);local p=prompt.Parent
   if r and (r.Position-p.Position).Magnitude<=prompt.MaxActivationDistance+2 then self:Return(player,true) end
  end)) end
 end
end
function Service:Remove(player)self:SetRun(player,nil);self.ready[player]=nil end
function Service:Destroy()for _,link in self.links do link:Disconnect()end;self.links={} end
return Service
