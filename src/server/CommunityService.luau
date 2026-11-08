--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.CommunityConfig)
local Rewards=require(RS.Shared.ActivityRewards)
local Numeric=require(RS.Shared.Numeric)
local Locale=require(RS.Shared.LocaleText)
local Builder=require(RS.World.CommunityBuilder)
local Service={};Service.__index=Service
function Service.new(model,data,state,economy,players,clock,stop,notify,react)
 local self=setmetatable({model=model,data=data,state=state,economy=economy,players=players,clock=clock,
  stop=stop,notify=notify,react=react,members={},limits={},links={},lamps={},phase="Ready",round=0,readyAt=0,
  kind="light",kindIndex=1,nodeReady={0,0,0,0,0,0},delivered={0,0,0},goals={2,2,2},lastPublish=0},Service)
 local environment=model.Parent:FindFirstChild("Environment")
 if environment then for _,head in environment:GetDescendants() do
  if head:IsA("BasePart") and head.Name=="Head" and head.Parent.Name:match("^Lamp") then
   local light=head:FindFirstChildOfClass("PointLight");local created=not light
   if not light then
    light=Instance.new("PointLight");light.Name="CommunityStreetLight";light.Color=head.Color
    light.Range=14;light.Brightness=.45;light.Shadows=false;light.Enabled=false;light.Parent=head
   end
   table.insert(self.lamps,{head=head,color=head.Color,material=head.Material,light=light,enabled=light.Enabled,
    created=created,circuit=if head.Position.X<0 then 1 else 2})
  end
 end end
 self.remote=Instance.new("RemoteEvent");self.remote.Name="VerityCommunity";self.remote.Parent=RS
 table.insert(self.links,model.Join.Interact.Triggered:Connect(function(p) self:Join(p) end))
 for index=1,6 do table.insert(self.links,model["Cell"..index].Interact.Triggered:Connect(function(p) self:Pickup(p,index) end)) end
 for index=1,3 do table.insert(self.links,model["Station"..index].Interact.Triggered:Connect(function(p) self:Deposit(p,index) end)) end
 table.insert(self.links,self.remote.OnServerEvent:Connect(function(p,action,round,...)
  if select("#",...)~=0 or not Numeric.isInteger(round,0,1e12) or (action~="Sync" and action~="Leave") then return end
  if action=="Leave" then if round==self.round then self:Remove(p) end;return end
  if self:Limit(p,.5) then self:Publish(p) end
 end))
 Builder.Apply(model,self.kind,self.delivered,self.goals,self.phase)
 self:Publish();return self
end
function Service:Limit(p,seconds)
 local now=self.clock();if now<(self.limits[p] or 0) then return false end
 self.limits[p]=now+seconds;return true
end
function Service:Character(p,participating)
 local profile=self.data:Get(p.UserId);local char=p.Character
 local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 if p.Parent~=self.players or not profile or profile.Closing or not self.state.sessions[p.UserId] or not profile.Data.VerityUnlocked
  or not root or not hum or hum.Health<=0 or root.Anchored or hum.SeatPart
  or not Numeric.isFinite(root.Position.X) or not Numeric.isFinite(root.Position.Y) or not Numeric.isFinite(root.Position.Z) then return nil end
 if participating then
  local entry=self.members[p];if not entry or entry.character~=char or p:GetAttribute("VerityDiversionKind")~="Community" then return nil end
 else
  for _,name in {"VerityDiversionKind","VerityFusionSlot","VerityRaceSlot","VerityParkourStep","VerityBattleActive","VerityRiding"} do if p:GetAttribute(name) then return nil end end
 end
 return root,profile,char
end
function Service:Station()
 if C.Variants[self.kind].Sequential then for i=1,3 do if self.delivered[i]<self.goals[i] then return i end end;return nil end
 local best,ratio
 for i=1,3 do
  if self.delivered[i]<self.goals[i] then
   local r=self.delivered[i]/self.goals[i]
   if not ratio or r<ratio then best,ratio=i,r end
  end
 end
 return best
end
function Service:Publish(only,override)
 local count=0;for _ in self.members do count+=1 end
 local joinable=self.phase=="Ready" or self.phase=="Charging" and self.clock()-self.started<=C.JoinSeconds
 local function send(p)
  local e=self.members[p]
  local target=e and self.model[(if e.carrying then "Station" else "Cell")..(if e.carrying then e.station else e.node)]
  self.remote:FireClient(p,{version=C.Version,variant=self.kind,round=self.round,phase=override or self.phase,deadline=self.deadline or 0,
   readyAt=self.readyAt,joinable=joinable,count=count,joined=e~=nil,carrying=e and e.carrying or false,
   nodeReady=table.clone(self.nodeReady),nodeReadyAt=e and self.nodeReady[e.node] or 0,targetPosition=target and target.Position,contribution=e and e.contribution or 0,node=e and e.node or 1,station=e and e.station or 1,
   delivered=table.clone(self.delivered),goals=table.clone(self.goals)})
 end
 if only then send(only);return end
 for _,p in self.players:GetPlayers() do send(p) end
 self.lastPublish=self.clock()
end
function Service:Join(p)
 if not self:Limit(p,.5) or self.members[p] then return end
 local root,profile,char=self:Character(p,false)
 if not root or (root.Position-self.model.Join.Position).Magnitude>C.Reach then return end
 local now=self.clock()
 if now<self.readyAt then self.notify(p.UserId,"COMMUNITY_COOLDOWN",0);return end
 if self.phase=="Charging" and now-self.started>C.JoinSeconds then self.notify(p.UserId,"COMMUNITY_LATE",0);return end
 if self.phase~="Ready" and self.phase~="Charging" then return end
 if self.phase=="Ready" then
  self.round+=1;self.started=now;self.deadline=now+C.Duration;self.phase="Charging"
  self.delivered,self.goals={0,0,0},{2,2,2};self.success=false;self.nodeReady={0,0,0,0,0,0}
 end
 self.stop(p)
 self.members[p]={character=char,level=profile.Data.VerityLevel,node=p.UserId%6+1,station=1,contribution=0,carrying=false,lastAction=now}
 p:SetAttribute("VerityDiversionKind","Community");p:SetAttribute("VerityCommunityTried",true)
 local count=0;for _ in self.members do count+=1 end
 local target=math.max(2,math.ceil(count*C.MinimumContribution/3))
 for i=1,3 do self.goals[i]=math.max(self.goals[i],target) end
 self.state:Publish(p.UserId,true);self:Publish()
end
function Service:Pickup(p,index)
 local entry=self.members[p];local root=self:Character(p,true);local now=self.clock()
 if not root or not entry or entry.carrying or entry.node~=index or self.phase~="Charging"
  or now>=self.deadline or now-entry.lastAction<.8 or (root.Position-self.model["Cell"..index].Position).Magnitude>C.Reach then return end
 if self.kind=="drones" then
  if now<(self.nodeReady[index] or 0) then return end
  self.nodeReady[index]=now+4
  local station=self:Station();if not station then return end
  self.delivered[station]+=1;entry.contribution+=1;entry.lastAction=now
  entry.node=index%6+1
  for offset=1,6 do local candidate=(index+offset-1)%6+1;if now>=(self.nodeReady[candidate] or 0) then entry.node=candidate;break end end
  self.react(p.UserId,"Confident",1.5)
  if not self:Station() then self:Finish(true) else self:Publish() end
  return
 end
 entry.carrying=true;entry.station=self:Station() or 1;entry.lastAction=now
 self.react(p.UserId,"Surprise",1.4);self:Publish(p)
end
function Service:Deposit(p,index)
 local entry=self.members[p];local root=self:Character(p,true);local now=self.clock()
 if not root or not entry or not entry.carrying or self.phase~="Charging" or now>=self.deadline
  or now-entry.lastAction<.8 or (root.Position-self.model["Station"..index].Position).Magnitude>C.Reach then return end
 if entry.station~=index or self.delivered[index]>=self.goals[index] then entry.station=self:Station() or 1;self:Publish(p);return end
 self.delivered[index]+=1;entry.contribution+=1;entry.carrying=false;entry.lastAction=now
 entry.node=(entry.node+p.UserId%3)%6+1
 self.react(p.UserId,"Confident",1.5)
 for _,other in self.members do if other.carrying and self.delivered[other.station]>=self.goals[other.station] then other.station=self:Station() or 1 end end
 if not self:Station() then self:Finish(true) else self:Publish() end
end
function Service:Finish(success)
 if self.phase~="Charging" then return end
 -- Close the round before any reward; repeated prompts cannot enter this grant again.
 self.success=success
 self.phase=if success then "Celebrating" else "Cooldown"
 self.readyAt=self.clock()+C.Cooldown;self.celebrationUntil=self.clock()+8
 local participants=self.members;self.members={}
 for p,e in participants do
  if p:GetAttribute("VerityDiversionKind")=="Community" then p:SetAttribute("VerityDiversionKind",nil) end
  local profile=self.data:Get(p.UserId);local hum=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
  local qualified=success and p.Parent==self.players and profile and self.state.sessions[p.UserId]
   and p.Character==e.character and hum and hum.Health>0 and e.contribution>=C.MinimumContribution
  if qualified then
   local amount=Rewards.Base(e.level,"Community")*(1+math.min(.3,e.contribution*.03))*self.economy:GetMultiplier(profile)
   local ok,cash=self.economy:AddCash(p.UserId,amount)
   if ok then
    profile.Data.CosmeticsOwned[C.Variants[self.kind].Reward]=true;self.data:Touch(profile);self.state:CompleteActivity(profile,"Community")
    self.notify(p.UserId,({light="COMMUNITY_WIN",van="COMMUNITY_VAN_WIN",drones="COMMUNITY_DRONES_WIN",festival="COMMUNITY_FESTIVAL_WIN"})[self.kind],cash);self.react(p.UserId,"Love",3)
   end
  elseif p.Parent==self.players then self.notify(p.UserId,if success then "COMMUNITY_LOW_CONTRIBUTION" else "COMMUNITY_FAILED",0) end
  self.state:Publish(p.UserId,true)
 end
 self:Publish()
end
function Service:Remove(p)
 local entry=self.members[p];self.members[p]=nil;self.limits[p]=nil
 if entry then
  if p:GetAttribute("VerityDiversionKind")=="Community" then p:SetAttribute("VerityDiversionKind",nil) end
  self.state:Publish(p.UserId,true)
  if p.Parent==self.players then self:Publish(p,"Left") end
  if self.phase=="Charging" and not next(self.members) then
   self.phase="Cooldown";self.readyAt=self.clock()+20
  end
  self:Publish()
 end
end
function Service:Tick()
 local now=self.clock()
 if self.phase=="Charging" then
  for p in self.members do if not self:Character(p,true) then self:Remove(p) end end
  if self.phase=="Charging" and now>=self.deadline then self:Finish(false) end
 elseif self.phase=="Celebrating" and now>=self.celebrationUntil then self.phase="Cooldown" end
 if self.phase=="Cooldown" and now>=self.readyAt then
  self.phase="Ready";self.kindIndex=self.kindIndex%#C.Order+1;self.kind=C.Order[self.kindIndex];self.nodeReady={0,0,0,0,0,0}
  self.delivered,self.goals={0,0,0},{2,2,2};self.success=false
 end
 Builder.Apply(self.model,self.kind,self.delivered,self.goals,self.phase)
 for _,lamp in self.lamps do
  local mode=if self.kind~="light" then "Original" elseif self.phase=="Charging" then (if self.delivered[lamp.circuit]>=self.goals[lamp.circuit] then "On" else "Off")
   elseif self.success and self.phase~="Ready" then "On" else "Original"
  if lamp.mode~=mode and lamp.head.Parent then
   lamp.mode=mode
   lamp.head.Color=if mode=="Off" then lamp.color:Lerp(Color3.fromHex("4F5777"),.7) else lamp.color
   lamp.head.Material=if mode=="On" then Enum.Material.Neon else lamp.material
   lamp.light.Enabled=if mode=="Original" then lamp.enabled else mode=="On"
  end
 end
 local remaining=math.max(0,math.ceil(self.readyAt-now))
 local labelKey=self.kind..self.phase..":"..remaining
 if self.labelKey~=labelKey then
  self.labelKey=labelKey
  local label=self.model.Join.Label:FindFirstChildOfClass("TextLabel")
  if self.phase=="Cooldown" then
   local nextVariant=C.Variants[C.Order[self.kindIndex%#C.Order+1]]
   Locale.SetWorld(label,"Text","%s • через %dс",Locale.Get("ru",nextVariant.Name),remaining)
   label:SetAttribute("Text_locale_en",string.format("%s • in %ds",Locale.Get("en",nextVariant.Name),remaining))
  elseif self.phase=="Celebrating" then Locale.SetWorld(label,"Text","Район благодарит вас!")
  else Locale.SetWorld(label,"Text",C.Variants[self.kind].Name) end
 end
 self.model:SetAttribute("Phase",self.phase);self.model:SetAttribute("ReadyAt",self.readyAt)
 self.model.Join.Interact.Enabled=self.phase=="Ready" or (self.phase=="Charging" and now-self.started<=C.JoinSeconds)
 for i=1,3 do
  self.model["Station"..i].Interact.Enabled=self.phase=="Charging" and self.kind~="drones"
  self.model["Glow"..i].Transparency=if self.kind~="drones" and self.delivered[i]>=self.goals[i] then .5 else 1
 end
 for i=1,6 do self.model["Cell"..i].Interact.Enabled=self.phase=="Charging" and now>=(self.nodeReady[i] or 0) end
 self.model.Beacon.Transparency=if self.phase=="Celebrating" then .35 else 1
 if now-self.lastPublish>=1 then self:Publish() end
end
function Service:Destroy()
 for _,lamp in self.lamps do
  if lamp.head.Parent then lamp.head.Color=lamp.color;lamp.head.Material=lamp.material end
  if lamp.created then lamp.light:Destroy() elseif lamp.light.Parent then lamp.light.Enabled=lamp.enabled end
 end
 for p in self.members do self:Remove(p) end
 for _,link in self.links do link:Disconnect() end
 self.remote:Destroy()
end
return Service
