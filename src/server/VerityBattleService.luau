--!nonstrict
local Shared=game:GetService("ReplicatedStorage").Shared
local C=require(Shared.VerityBattleConfig)
local Rewards=require(Shared.ActivityRewards)
local Catalog=require(Shared.AbilityCatalog)
local Locale=require(Shared.LocaleText)
local Motion=require(Shared.EnemyMotion)
local Numeric=require(Shared.Numeric)
local Factory=require(game:GetService("ReplicatedStorage").World.VerityFactory)
local Service={};Service.__index=Service
function Service.new(model,data,state,economy,players,clock,targets,abilities,notify)
 local self=setmetatable({model=model,data=data,state=state,economy=economy,players=players,clock=clock,targets=targets,abilities=abilities,notify=notify,members={},enemies={},ready={},phase="Idle",sequence=0,links={}},Service)
 local remote=Instance.new("RemoteEvent");remote.Name="VerityEnemyMotion";remote.Parent=game:GetService("ReplicatedStorage");self.motionRemote=remote
 table.insert(self.links,model.Entry.JoinBattle.Triggered:Connect(function(player) self:Join(player) end))
 return self
end
function Service:PlanMotion(r,to,now)
 local from=r.model:GetPivot()
 r.motionSequence=(r.motionSequence or 0)+1
 r.motion=Motion.Plan(r.model:GetAttribute("EnemyId"),r.motionSequence,from,to,now)
 -- One reliable, coherent packet. No separate property/attribute ordering assumptions.
 for _,player in self.players:GetPlayers() do
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if self.members[player] or root and (root.Position-C.Center).Magnitude<=260 then self.motionRemote:FireClient(player,r.motion) end
 end
end
function Service:UpdateMotion(now)
 for _,r in self.enemies do
  if r.motion and r.part.Parent then r.model:PivotTo(Motion.Sample(r.motion,now)) end
 end
end
function Service:Valid(player)
 local member=self.members[player];local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not member or member.character~=char or not root or not hum or hum.Health<=0 or not self.data:Get(player.UserId) or not self.state.sessions[player.UserId] then return nil end
 local p=root.Position
 if not Numeric.isFinite(p.X) or not Numeric.isFinite(p.Y) or not Numeric.isFinite(p.Z) then return nil end
 return root,hum
end
function Service:IsParticipant(player) local root=self:Valid(player);return self.phase=="Fighting" and root~=nil and C.Contains(root.Position) end
function Service:SetPhase(phase,seconds)
 self.phase=phase;self.at=self.clock()+(seconds or 0)
 self.model:SetAttribute("Phase",phase);self.model:SetAttribute("Deadline",self.at)
 for player in self.members do player:SetAttribute("VerityBattleFighting",phase=="Fighting");self.state:Publish(player.UserId,true) end
end
function Service:Join(player)
 local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 local profile=self.data:Get(player.UserId)
 if self.members[player] or not root or not hum or hum.Health<=0 or root.Anchored or hum.SeatPart or not profile or not self.state.sessions[player.UserId] or not profile.Data.VerityUnlocked then return end
 local p=root.Position
 if not Numeric.isFinite(p.X) or not Numeric.isFinite(p.Y) or not Numeric.isFinite(p.Z) or (p-self.model.Entry.Position).Magnitude>12 then return end
 if player:GetAttribute("VerityRaceSlot") or player:GetAttribute("VerityParkourStep") or player:GetAttribute("VerityFusionSlot") or player:GetAttribute("VerityRiding") then self.notify(player.UserId,"BATTLE_OTHER_ACTIVITY",0);return end
 if self.phase~="Idle" and self.phase~="Countdown" then self.notify(player.UserId,"BATTLE_BUSY",0);return end
 if self.clock()<(self.ready[player] or 0) then self.notify(player.UserId,"BATTLE_COOLDOWN",0);return end
 local used={};for _,member in self.members do used[member.seat]=true end
 local seat;for i=1,C.MaxPlayers do if not used[i] then seat=i;break end end
 if not seat then self.notify(player.UserId,"BATTLE_BUSY",0);return end
 self.abilities:Stop(player)
 self.members[player]={character=char,seat=seat}
 player:SetAttribute("VerityBattleActive",true);player:SetAttribute("VerityBattleFighting",false);player:SetAttribute("VerityBattleWave",0)
 char:PivotTo(CFrame.new(C.Center+Vector3.new((seat-2.5)*9,4,-18)))
 root.AssemblyLinearVelocity=Vector3.zero
 if self.phase=="Idle" then self.wave=0;self:SetPhase("Countdown",C.Countdown) end
 self.state:Publish(player.UserId,true)
 self.notify(player.UserId,"BATTLE_JOINED",0)
end
function Service:ClearEnemies()
 for part,r in self.enemies do self.targets.records[part]=nil;r.model:Destroy() end
 table.clear(self.enemies)
end
function Service:Remove(player,move)
 local member=self.members[player];if not member then return end
 self.members[player]=nil;self.abilities:Stop(player)
 player:SetAttribute("VerityBattleActive",nil);player:SetAttribute("VerityBattleFighting",nil);player:SetAttribute("VerityBattleWave",nil)
 if move and player.Character==member.character then
  local root=member.character:FindFirstChild("HumanoidRootPart");local hum=member.character:FindFirstChildOfClass("Humanoid")
  if root and hum and hum.Health>0 then member.character:PivotTo(CFrame.new(C.Exit+Vector3.new((member.seat-2.5)*4,0,0)));root.AssemblyLinearVelocity=Vector3.zero end
 end
 self.state:Publish(player.UserId,true)
end
function Service:Finish(won)
 if self.phase=="Idle" then self:ClearEnemies();return end
 -- End the round before any notification/publish or reward processing.
 self:SetPhase("Results")
 self:ClearEnemies()
 for player in self.members do
  local root=self:Valid(player);local profile=self.data:Get(player.UserId)
  if won and root and profile then
   if self.onCompleted then self.onCompleted(player.UserId) end
   self.ready[player]=self.clock()+C.Cooldown;player:SetAttribute("VerityBattleReadyAt",self.ready[player])
   local ok,reward=self.economy:AddCash(player.UserId,Rewards.Base(profile.Data.VerityLevel,"Battle")*self.economy:GetMultiplier(profile))
   if ok then self.state:CompleteActivity(profile,"Battle");self.state:Publish(player.UserId,true);self.notify(player.UserId,"BATTLE_WIN",reward) end
  else self.notify(player.UserId,"BATTLE_FAILED",0) end
  self:Remove(player,true)
 end
 self.model:SetAttribute("Wave",0);self:SetPhase("Idle")
end
function Service:Damage(r,amount,userId)
 if not Numeric.isFinite(amount) or amount<=0 then return 0 end
 local player=self.players:GetPlayerByUserId(userId);local root=player and self:Valid(player)
 if self.phase~="Fighting" or not root or not C.Contains(root.Position) or self.enemies[r.part]~=r or r.health<=0 then return 0 end
 local profile=self.data:Get(userId)
 local owned=profile and Catalog.Equipped(profile.Data,"Attack",profile.HeroPassOwned)
 local damage=math.min(r.health,math.max(0,amount)*(if owned then 1.5 else 1));r.health-=damage
 r.model:SetAttribute("EnemyHealth",r.health)
 Locale.SetWorld(r.label,"Text","%s • %d / %d",Locale.Get("ru",r.definition.Name),math.ceil(r.health),r.maximum)
 r.label:SetAttribute("Text_locale_en",string.format("%s • %d / %d",Locale.Get("en",r.definition.Name),math.ceil(r.health),r.maximum))
 if r.health<=0 then
  self.enemies[r.part]=nil;self.targets.records[r.part]=nil;r.part.CanQuery=false;r.model:SetAttribute("EnemyDead",true)
  task.delay(.65,function()r.model:Destroy()end)
 end
 return damage
end
function Service:Wave()
 self.wave+=1;self.model:SetAttribute("Wave",self.wave)
 local count=0;for _ in self.members do count+=1 end
 for i,kind in C.Waves[self.wave] do
  local d=C.Types[kind]
  local model=Factory.Create(self.model.Enemies,CFrame.new(C.Center+Vector3.new((i-2)*16,3,11)),{level=1,preview=true})
  model.Name="EnemyVerity";model:ScaleTo(d.Size)
  local body=model.Body;body.Color=Color3.fromHex(d.Color);body.CanQuery=true
  local face=body:FindFirstChild("FaceGui");if face then face:Destroy() end
  self.sequence+=1;model:SetAttribute("EnemyKind",kind);model:SetAttribute("EnemyId",self.sequence);model:SetAttribute("EnemyRadius",d.Radius)
  local health=math.round(d.Health*(1+.45*math.max(0,count-1)))
  local label=model.PrimaryPart.LevelLabel.Title;label.TextColor3=Color3.fromHex("FFF0CA");label.TextSize=13
  local r={model=model,part=body,label=label,health=health,maximum=health,definition=d,nextAt=self.clock()+2+i*.6,arenaOnly=true}
  r.onDamage=function(amount,userId)return self:Damage(r,amount,userId)end
  self.enemies[body]=r;self.targets.records[body]=r
  model:SetAttribute("EnemyHealth",health);model:SetAttribute("EnemyMaximum",health)
  self:PlanMotion(r,model:GetPivot(),self.clock())
  Locale.SetWorld(label,"Text","%s • %d / %d",Locale.Get("ru",d.Name),health,health)
  label:SetAttribute("Text_locale_en",string.format("%s • %d / %d",Locale.Get("en",d.Name),health,health))
 end
 for player in self.members do player:SetAttribute("VerityBattleWave",self.wave);self.notify(player.UserId,if self.wave==#C.Waves then "BATTLE_BOSS" else "BATTLE_WAVE",0) end
 self:SetPhase("Fighting")
end
function Service:Strike(r)
 local d=r.definition
 for player in self.members do
  local root,hum=self:Valid(player)
  if not root or (root.Position-r.target).Magnitude>d.Radius or player.Character:FindFirstChildOfClass("ForceField") or (player:GetAttribute("VerityProtectedUntil") or 0)>self.clock() then continue end
  local ray=RaycastParams.new();ray.FilterDescendantsInstances={r.model,player.Character};ray.RespectCanCollide=true
  if workspace:Raycast(r.part.Position,root.Position-r.part.Position,ray) then continue end
  local shield=(player:GetAttribute("VerityShieldUntil") or 0)>self.clock()
  hum:TakeDamage(d.Damage*(if shield then .25 else 1))
 end
 r.strikeAt=nil;r.nextAt=self.clock()+d.Delay;r.model:SetAttribute("StrikeAt",nil)
end
function Service:Tick(dt)
 if self.phase=="Idle" then return end
 for player in self.members do
  local root=self:Valid(player)
  if not root or not C.Contains(root.Position) then self:Remove(player,false) end
 end
 if next(self.members)==nil then self:Finish(false);return end
 local now=self.clock()
 if self.phase=="Countdown" and now>=self.at then self.endsAt=now+C.Timeout;self:Wave();return end
 if self.phase=="Intermission" and now>=self.at then self:Wave();return end
 if self.phase~="Fighting" then return end
 if now>=self.endsAt then self:Finish(false);return end
 if next(self.enemies)==nil then
  if self.wave==#C.Waves then self:Finish(true)
  else
   for player in self.members do local _,hum=self:Valid(player);if hum then hum.Health=math.min(hum.MaxHealth,hum.Health+20) end end
   self:SetPhase("Intermission",C.BreakSeconds)
  end
  return
 end
 for _,r in self.enemies do
  if r.strikeAt then if now>=r.strikeAt then self:Strike(r) end;continue end
  local nearest,distance;local best=math.huge
  for player in self.members do local root=self:Valid(player);if root then local delta=root.Position-r.part.Position;local n=Vector3.new(delta.X,0,delta.Z).Magnitude;if n<best then best=n;nearest=root end end end
  if not nearest then continue end
  local d=r.definition
  local pivot=r.model:GetPivot();local to=pivot
  local delta=nearest.Position-r.part.Position;delta=Vector3.new(delta.X,0,delta.Z)
  if delta.Magnitude>.1 then
   local pos=pivot.Position
   if best>d.Range*.7 then pos+=delta.Unit*math.min(math.max(0,best-d.Range*.7),d.Speed*Motion.Step) end
   local rotation=pivot.Rotation:Lerp(CFrame.lookAt(Vector3.zero,delta).Rotation,Motion.TurnFraction)
   to=CFrame.new(pos)*rotation
  end
  if now>=r.nextAt and best<=d.Range then
   r.target=nearest.Position;r.strikeAt=now+d.Windup
   to=pivot -- Freeze for the whole warning; damage stays at the advertised target.
   r.model:SetAttribute("StrikeTarget",r.target);r.model:SetAttribute("StrikeAt",r.strikeAt)
  end
  self:PlanMotion(r,to,now)
 end
end
function Service:Forget(player) self:Remove(player,false);self.ready[player]=nil end
function Service:Destroy()
 for _,link in self.links do link:Disconnect() end
 self:Finish(false);self.motionRemote:Destroy();table.clear(self.links)
end
return Service
