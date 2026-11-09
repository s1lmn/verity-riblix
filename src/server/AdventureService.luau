--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.AdventureConfig)
local Catalog=require(RS.Shared.AbilityCatalog)
local Numeric=require(RS.Shared.Numeric)
local Rewards=require(RS.Shared.ActivityRewards)
local Locale=require(RS.Shared.LocaleText)
local Service={};Service.__index=Service
local function segmentDistance(a,b,p)
 local d=b-a;if d.Magnitude<.01 then return (a-p).Magnitude end
 return (a+d*math.clamp((p-a):Dot(d)/d:Dot(d),0,1)-p).Magnitude
end
local function shuffled(size,seed)
 local a={};for i=1,size do a[i]=i end;local rng=Random.new(seed)
 for i=size,2,-1 do local j=rng:NextInteger(1,i);a[i],a[j]=a[j],a[i] end;return a
end
function Service.new(world,model,data,state,economy,players,clock,abilities,arcade,notify)
 local self=setmetatable({world=world,model=model,data=data,state=state,economy=economy,players=players,clock=clock,abilities=abilities,arcade=arcade,notify=notify,
  runs={},parties={},modes={},hostReady={},ready={},trialRewards={},claimed={stars={},fire={},cave={}},prompts={},limits={},links={},serial=0,packet=0,cycle=1,weatherRound=1,weather="Clear",since=clock(),deadline=clock()+C.WeatherCycle[1].Seconds,lastPublish=0,closed=false},Service)
 self.remote=Instance.new("RemoteEvent");self.remote.Name="VerityAdventures";self.remote.Parent=RS
 for _,q in model.root:GetDescendants() do if q:IsA("ProximityPrompt") then
  table.insert(self.prompts,q)
  table.insert(self.links,q.Triggered:Connect(function(p)self:Interact(p,q)end))
 end end
 table.insert(self.links,self.remote.OnServerEvent:Connect(function(p,action,round,...)
  if select("#",...)~=0 or not Numeric.isInteger(round,0,1e12) or (action~="Sync" and action~="Leave") then return end
  if action=="Leave" then local r=self.runs[p];if r and r.round==round then self:End(p,false,true) end;return end
  if self:Limit(p,.5) then self:Publish(p) end
 end))
 self:RenderWorld();return self
end
function Service:Limit(p,seconds)
 local now=self.clock();if now<(self.limits[p] or 0) then return false end;self.limits[p]=now+seconds;return true
end
function Service:Character(p)
 local profile=self.data:Get(p.UserId);local char=p.Character;local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 if p.Parent~=self.players or not profile or not self.state.sessions[p.UserId] or not profile.Data.VerityUnlocked or not root or not hum or hum.Health<=0 or hum.SeatPart or root.Anchored
  or not Numeric.isFinite(root.Position.Magnitude) then return nil end
 return root,profile,char
end
function Service:Idle(p)
 if self.closed or self.runs[p] then return nil end
 local root,profile,char=self:Character(p);if not root then return nil end
 for _,a in {"VerityDiversionKind","VerityRaceSlot","VerityParkourStep","VerityFusionSlot","VerityBattleActive","VerityRiding"} do if p:GetAttribute(a) then return nil end end
 return root,profile,char
end
function Service:Begin(p,kind,id,seconds)
 local root,profile,char=self:Idle(p);if not root then return nil end
 self.abilities:Stop(p);self.serial+=1
 local r={round=self.serial,kind=kind,id=id or "",char=char,started=self.clock(),deadline=self.clock()+seconds,index=1,count=0,lastPosition=root.Position,sampledAt=self.clock(),lastAction=self.clock()-.5,level=profile.Data.VerityLevel}
 self.runs[p]=r;p:SetAttribute("VerityDiversionKind","Adventure");p:SetAttribute("VerityAdventureKind",kind)
 self.state:Publish(p.UserId,true);return r
end
function Service:Pay(p,r,activity,prize,multiplier)
 if r.paid then return false end;r.paid=true
 local root,profile=self:Character(p);if not root or p.Character~=r.char then return false end
 local ok,cash=self.economy:AddCash(p.UserId,Rewards.Base(r.level,activity)*self.economy:GetMultiplier(profile)*(multiplier or 1))
 if not ok then return false end
 if self.forge then self.forge:SeedLegacy(p.UserId) end
 if prize then profile.Data.CosmeticsOwned[prize]=true;self.data:Touch(profile) end
 if self.forge then self.forge:GrantHarvest(p.UserId,activity) end
 self.state:CompleteActivity(profile,activity);self.state:Publish(p.UserId,true)
 self.notify(p.UserId,"ADVENTURE_REWARD",cash);return true
end
function Service:Goal(p,r)
 if r.kind=="Stars" then local i=r.order[r.index];return i and C.StarPoints[i],if r.id=="Fire" then "Собери солнечный уголёк" else "Подбери звёздный осколок",true,i
 elseif r.kind=="Cave" then
  if r.index<=3 then return C.Runes[r.index],({"Найди солнечную руну","Найди лунную руну","Найди звёздную руну"})[r.index],true,r.index end
  return C.Chest,"Открой сокровище пещеры",true,4
 elseif r.kind=="Trial" then
  local d=C.Trials[r.id];local pos=d.Points[r.index]
  if r.id=="laser" then return pos,"Наведи лазер на подсвеченную мишень",false,r.index end
  return pos,if (r.armedUntil or 0)<self.clock() then "Используй способность и пройди кольца" else "Пройди следующее кольцо",false,r.index
 elseif r.kind=="Party" then
  local party=self.parties[r.plot];local record=self.world.houseProgression.plots[r.plot]
  if not party or not record then return nil end
  if party.phase=="Lobby" then return record.pivot:PointToWorldSpace(Vector3.new(0,3,-24)),"Заходи в дом: скоро начало",false,0 end
  if party.mode=="Arcade" then return record.homeDecor.arcadePrompt.Parent.Position,"Сыграй на автомате и поставь рекорд",true,0 end
  local i=r.order[r.index];return i and record.pivot:PointToWorldSpace(C.PartyPoints[i]),"Найди подарок в доме",true,i
 end
end
function Service:Publish(only)
 local list={}
 for plot,party in self.parties do
  local scores={};for player,e in party.entries do table.insert(scores,{name=player.DisplayName,userId=player.UserId,score=if party.mode=="Arcade" then e.score or 0 else e.count or 0,done=e.done==true}) end
  table.sort(scores,function(a,b)if a.score==b.score then return a.userId<b.userId end;return a.score>b.score end)
  while #scores>3 do table.remove(scores) end
  table.insert(list,{round=party.round,position=self.model.parties[plot].board.Position,plot=plot,premiumStyle=((self.world.houseProgression.plots[plot].state or {}).PremiumStyles or {}).PartyStyle or "default",owner=party.owner.DisplayName,mode=party.mode,phase=party.phase,deadline=party.deadline,count=party.count,leaders=scores})
 end
 table.sort(list,function(a,b)return a.plot<b.plot end)
 local function send(p)
  self.packet+=1;local r=self.runs[p];local run
  if r then
   local pos,title,prompt,index=self:Goal(p,r)
   local d=r.kind=="Trial" and C.Trials[r.id]
   local party=r.kind=="Party" and self.parties[r.plot];local entry=party and party.entries[p]
   local profile=self.data:Get(p.UserId)
   run={round=r.round,kind=r.kind,id=r.id,plot=r.plot or 0,started=r.started,deadline=if party then party.deadline else r.deadline,index=r.index,count=r.count,
    done=entry and entry.done==true or false,target=pos,title=title,prompt=prompt,targetIndex=index or 0,armedUntil=r.armedUntil or 0,weatherRound=r.weatherRound,
    best=d and profile and profile.Data.AdventureRecords[r.id] or 0,total=if r.kind=="Stars" then 5 elseif r.kind=="Cave" then 4 elseif d then #d.Points else 6}
  end
  local choices={}
  for _,entry in list do local copy=table.clone(entry);local party=self.parties[entry.plot];copy.seen=party and party.entries[p]~=nil;table.insert(choices,copy) end
  self.remote:FireClient(p,{version=C.Version,sequence=self.packet,weather=self.weather,weatherRound=self.weatherRound,since=self.since,deadline=self.deadline,
   nextWeather=C.WeatherCycle[self.cycle%#C.WeatherCycle+1].Kind,run=run,parties=choices})
 end
 if only then if only.Parent==self.players then send(only) end else for _,p in self.players:GetPlayers() do send(p) end;self.lastPublish=self.clock() end
end
function Service:End(p,success,returnHome)
 local r=self.runs[p];if not r then return end
 self.runs[p]=nil
 if p:GetAttribute("VerityDiversionKind")=="Adventure" then p:SetAttribute("VerityDiversionKind",nil) end
 p:SetAttribute("VerityAdventureKind",nil)
 local root,profile=self:Character(p)
 if r.kind=="Trial" or r.kind=="Cave" then self.abilities:Stop(p) end
 if returnHome and root and p.Character==r.char then
  local pos=if r.kind=="Cave" then C.CaveEntrance+Vector3.new(0,3,7) elseif r.kind=="Trial" then C.Trials[r.id].Start+Vector3.new(0,3,4) else nil
  if pos then root.CFrame=CFrame.new(pos);root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
 end
 if success and root and profile and r.char==p.Character then
  if r.kind=="Stars" then
   if r.id=="Fire" then self.claimed.fire[p.UserId]=r.weatherRound;self:Pay(p,r,"Fire","home_ember_lantern")
   else self.claimed.stars[p.UserId]=r.weatherRound;self:Pay(p,r,"Stars","home_star_mobile") end
  elseif r.kind=="Cave" then
   self.claimed.cave[p.UserId]=r.weatherRound;self:Pay(p,r,"Cave","home_rain_relic")
  elseif r.kind=="Trial" then
   local time=math.max(.1,math.floor((self.clock()-r.started)*10+.5)/10)
   local best=profile.Data.AdventureRecords[r.id];profile.Data.AdventureRecords[r.id]=math.min(best or time,time);self.data:Touch(profile)
   local d=C.Trials[r.id];local medal=if time<=d.Gold then "TRIAL_GOLD" elseif time<=d.Silver then "TRIAL_SILVER" else "TRIAL_BRONZE"
   self.notify(p.UserId,medal,0)
   local ready=self.trialRewards[p.UserId] or {};self.trialRewards[p.UserId]=ready
   if self.clock()>=(ready[r.id] or 0) then
    if self:Pay(p,r,"Trial","home_trial_"..r.id) then ready[r.id]=self.clock()+90 end
   else
    profile.Data.CosmeticsOwned["home_trial_"..r.id]=true;self.data:Touch(profile);self.notify(p.UserId,"TRIAL_PRACTICE",0)
   end
  end
 elseif p.Parent==self.players and r.kind~="Party" then self.notify(p.UserId,"ADVENTURE_ENDED",0) end
 if r.kind=="Party" then
  local party=self.parties[r.plot];local e=party and party.entries[p]
  if e and not e.done and not e.left then e.left=true;party.count=math.max(0,party.count-1) end
  if self.arcade.runs[p] then self.arcade:Remove(p) end
 end
 self.state:Publish(p.UserId,true);self:Publish(p)
end
function Service:TrialItem(p,id)
 local profile=self.data:Get(p.UserId);local d=C.Trials[id];if not profile or not d then return nil end
 local item=Catalog.ProfileEquipped(profile,d.Slot)
 return if item and (if d.Slot=="Mobility" then item.MobilityAction or item.Action else item.Action)==d.Action then item else nil
end
function Service:AllowsPower(p,slot)
 local r=self.runs[p];return r~=nil and r.kind=="Trial" and C.Trials[r.id].Slot==slot and self:TrialItem(p,r.id)~=nil
end
function Service:ObserveMobility(p,item,action,duration)
 local r=self.runs[p];if not r or r.kind~="Trial" or C.Trials[r.id].Action~=action then return end
 r.armedUntil=self.clock()+(if action=="leap" then 5 else duration+.4)
 local root=self:Character(p);if root then r.lastPosition=root.Position;r.sampledAt=self.clock() end
 self:Publish(p)
end
function Service:CanAimMechanism(p,item)
 local r=self.runs[p];local root=self:Character(p)
 return r~=nil and r.kind=="Trial" and r.id=="laser" and root~=nil and C.TrialContains(root.Position) and item~=nil and item.Action=="laser"
end
function Service:TryLaser(p,item,char,root,direction)
 if not self:CanAimMechanism(p,item) then return nil end
 local r=self.runs[p];local target=C.Trials.laser.Points[r.index];if not target then return nil end
 local head=char:FindFirstChild("Head");local origin=if head then head.Position else root.Position+Vector3.yAxis*2
 local delta=target-origin
 if delta.Magnitude<.1 or delta.Magnitude>math.min(85,item.Range) or direction:Dot(delta.Unit)<.985 then return nil end
 local params=RaycastParams.new();params.FilterDescendantsInstances={char,self.model.trial.laser.targets[r.index]};params.RespectCanCollide=true
 local wall=workspace:Raycast(origin,delta,params);if wall and wall.Distance<delta.Magnitude-.6 then return nil end
 r.count+=1;r.index+=1;self.notify(p.UserId,"ADVENTURE_STEP",0)
 if r.index>#C.Trials.laser.Points then task.defer(function()if self.runs[p]==r then self:End(p,true,false)end end) else self:Publish(p) end
 return target
end
function Service:StartTrial(p,id)
 if not C.Trials[id] then return end
 if not self:TrialItem(p,id) then self.notify(p.UserId,"TRIAL_NEED_"..id,0);return end
 local r=self:Begin(p,"Trial",id,C.TrialSeconds);if not r then return end
 self:Publish(p)
end
function Service:StartStars(p)
 if self.weather~="Stars" and self.weather~="Fire" then self.notify(p.UserId,"WEATHER_WAIT_STARS",0);return end
 local claims=if self.weather=="Fire" then self.claimed.fire else self.claimed.stars
 if claims[p.UserId]==self.weatherRound then self.notify(p.UserId,"WEATHER_ALREADY",0);return end
 local r=self:Begin(p,"Stars",self.weather,math.max(1,self.deadline-self.clock()));if not r then return end
 r.order=shuffled(#C.StarPoints,p.UserId%100000+self.weatherRound*43);r.weatherRound=self.weatherRound;self:Publish(p)
end
function Service:StartCave(p)
 if self.weather~="Rainbow" then self.notify(p.UserId,"WEATHER_WAIT_CAVE",0);return end
 if self.claimed.cave[p.UserId]==self.weatherRound then self.notify(p.UserId,"WEATHER_ALREADY",0);return end
 local r=self:Begin(p,"Cave","",C.CaveSeconds);if not r then return end;r.weatherRound=self.weatherRound
 local root=self:Character(p);root.CFrame=CFrame.new(C.CaveSpawn);root.AssemblyLinearVelocity=Vector3.zero;r.lastPosition=root.Position
 self:Publish(p)
end
function Service:PartyAccess(p,plot)
 local record=self.world.houseProgression.plots[plot]
 return record and record.state and record.state.VerityUnlocked and record.state.HouseIncomeLevel>=2 and not record.state.HouseDoorLocked
end
function Service:Host(p,plot)
 local root=self:Idle(p);local record=self.world.houseProgression.plots[plot]
 if not root or not record or not record.state or record.state.ownerUserId~=p.UserId then return end
 if not self:PartyAccess(p,plot) then self.notify(p.UserId,"PARTY_OPEN_HOUSE",0);return end
 if self.parties[plot] or self.clock()<(self.hostReady[p.UserId] or 0) then self.notify(p.UserId,"ADVENTURE_COOLDOWN",0);return end
 local count=0;for _ in self.parties do count+=1 end;if count>=4 then self.notify(p.UserId,"PARTY_SERVER_BUSY",0);return end
 local mode=self.modes[plot] or "Gifts"
 if mode=="Arcade" and not record.state.HomeStyle.owned.home_arcade then self.notify(p.UserId,"PARTY_NEED_ARCADE",0);return end
 self.serial+=1;local party={round=self.serial,owner=p,mode=mode,phase="Lobby",deadline=self.clock()+C.PartyLobby,count=0,entries={}}
 self.parties[plot]=party;self.hostReady[p.UserId]=self.clock()+180;self:JoinParty(p,plot);self:RenderWorld();self:Publish()
end
function Service:JoinParty(p,plot)
 local party=self.parties[plot]
 if not party or party.phase~="Lobby" or party.entries[p] or party.count>=C.PartyLimit or not self:PartyAccess(p,plot) then return end
 local r=self:Begin(p,"Party","",C.PartyLobby+(if party.mode=="Arcade" then C.ArcadePartySeconds else C.PartySeconds));if not r then return end
 r.plot=plot;r.order=shuffled(#C.PartyPoints,p.UserId%100000+party.round*97)
 party.entries[p]={count=0,score=0,char=r.char,run=r,joined=self.clock()};party.count+=1;self:Publish()
end
function Service:StopParty(plot,awardWinner)
 local party=self.parties[plot];if not party then return end
 self.parties[plot]=nil
 local winner,best,finished
 if awardWinner then for p,e in party.entries do
  local score=if party.mode=="Arcade" then e.score else e.count
  if e.done and not e.left and (party.mode~="Arcade" or score>=100) and (not best or score>best or score==best and e.finished<(finished or math.huge)) then winner,best,finished=p,score,e.finished end
 end end
 if winner then
  local profile=self.data:Get(winner.UserId)
  if profile then profile.Data.CosmeticsOwned.home_party_cup=true;self.data:Touch(profile);self.state:Publish(winner.UserId,true);self.notify(winner.UserId,"PARTY_WINNER",0) end
 end
 for p,e in party.entries do if self.runs[p]==e.run then self:End(p,false,false) end end
 self:RenderWorld();self:Publish()
end
function Service:ArcadeReserved(plot)
 local party=self.parties[plot];return party~=nil and party.mode=="Arcade" and party.phase=="Playing"
end
function Service:CanUsePartyArcade(p,plot)
 local r=self.runs[p];local party=r and r.kind=="Party" and self.parties[r.plot]
 local e=party and party.entries[p]
 return party~=nil and r.plot==plot and party.mode=="Arcade" and party.phase=="Playing" and e~=nil and not e.done and not e.left and self:PartyAccess(p,plot)==true
end
function Service:ArcadeFinished(p,arcade,award)
 local r=self.runs[p];local party=r and r.kind=="Party" and self.parties[r.plot];local e=party and party.entries[p]
 if not party or not e or party.mode~="Arcade" or r.plot~=arcade.plot then return end
 if award then
  e.score=arcade.score;e.done=true;e.finished=self.clock();r.count=arcade.score
  if arcade.score>=100 then self:Pay(p,r,"Party","home_party_badge") else self.notify(p.UserId,"PARTY_SCORE_LOW",0) end
 end
 if self.runs[p]==r then p:SetAttribute("VerityDiversionKind","Adventure") end
 self:Publish()
end
function Service:Interact(p,q)
 if not self:Limit(p,.3) or not q:IsDescendantOf(self.model.root) then return end
 local root,profile=self:Character(p);if not root or (root.Position-q.Parent.Position).Magnitude>C.Reach+.5 then return end
 local kind=q:GetAttribute("AdventureKind");local id=q:GetAttribute("AdventureId");local index=q:GetAttribute("AdventureIndex");local plot=q:GetAttribute("AdventurePlot")
 if kind=="Trial" then self:StartTrial(p,id);return elseif kind=="Weather" then self:StartStars(p);return elseif kind=="Cave" then self:StartCave(p);return
 elseif kind=="HostParty" then self:Host(p,plot);return elseif kind=="JoinParty" then self:JoinParty(p,plot);return
 elseif kind=="PartyMode" or kind=="StopParty" then
  local record=self.world.houseProgression.plots[plot];if not record or not record.state or record.state.ownerUserId~=p.UserId then return end
  if kind=="StopParty" then self:StopParty(plot,false) elseif not self.parties[plot] then self.modes[plot]=if self.modes[plot]=="Arcade" then "Gifts" else "Arcade";self:RenderWorld() end;return
 elseif kind=="Exit" then
  local r=self.runs[p];if r and r.kind=="Cave" then self:End(p,false,true) elseif C.CaveContains(root.Position) then root.CFrame=CFrame.new(C.CaveEntrance+Vector3.new(0,3,7)) end;return
 end
 local r=self.runs[p];local now=self.clock();if not r or r.char~=p.Character or now>=r.deadline or now-r.lastAction<.7 then return end
 if kind=="Star" and r.kind=="Stars" and self.weather==r.id and self.weatherRound==r.weatherRound and r.order[r.index]==index then
  r.index+=1;r.count+=1;r.lastAction=now;self.notify(p.UserId,"ADVENTURE_STEP",0)
  if r.count>=5 then self:End(p,true,false) else self:Publish(p) end
 elseif kind=="Rune" and r.kind=="Cave" and index==r.index then
  r.index+=1;r.count+=1;r.lastAction=now;self.notify(p.UserId,"ADVENTURE_STEP",0);self:Publish(p)
 elseif kind=="Chest" and r.kind=="Cave" and r.index==4 then r.count=4;self:End(p,true,true)
 elseif kind=="PartyGift" and r.kind=="Party" and r.plot==plot and r.order[r.index]==index then
  local party=self.parties[plot];local e=party and party.entries[p]
  if not party or party.mode~="Gifts" or party.phase~="Playing" or not e or e.done or e.left then return end
  r.index+=1;r.count+=1;r.lastAction=now;e.count=r.count;self.notify(p.UserId,"ADVENTURE_STEP",0)
  if r.count>=#C.PartyPoints then e.done=true;e.finished=now;self:Pay(p,r,"Party","home_party_badge") end
  self:Publish()
 end
end
local function show(model,visible)
 for _,p in model:GetDescendants() do if p:IsA("BasePart") then p.Transparency=if visible then 0 else 1 elseif p:IsA("SurfaceGui") then p.Enabled=visible end end
end
function Service:RenderWorld()
 local now=self.clock();local fire=self.weather=="Fire";local stars=self.weather=="Stars" or fire;local open=self.weather=="Rainbow"
 local key=self.weather..self.weatherRound
 if self.worldKey~=key then
  self.worldKey=key
  for _,node in self.model.stars do
   show(node.model,stars);node.prompt.Enabled=stars
   for _,part in node.model:GetChildren() do if part:IsA("BasePart") then part.Color=Color3.fromHex(if fire then (if part==node.part then "FFBC68" else "FF805A") else "C5AAFF") end end
   Locale.SetWorld(node.prompt,"ActionText",if fire then "Собрать уголёк" else "Подобрать осколок")
   Locale.SetWorld(node.prompt,"ObjectText",if fire then "Огненное небо" else "Звёздный дождь")
  end
  Locale.SetWorld(self.model.weatherPrompt,"ActionText",if fire then "Собирать солнечные угольки" else "Искать звёздные осколки")
  self.model.portal.Transparency=if open then .8 else .25;self.model.cavePrompt.Enabled=open
  for _,label in self.model.caveLabels do
   Locale.SetWorld(label,"Text",if open then "Дождевая пещера открыта!" else "Откроется после ливня")
  end
  Locale.SetWorld(self.model.cavePrompt,"ObjectText",if open then "Дождевая пещера" else "Откроется после ливня")
  self.model.weatherPrompt.Enabled=stars
  self.model.root:SetAttribute("WeatherKind",self.weather)
  RS:SetAttribute("VerityWeatherKind",self.weather)
 end
 local remaining=math.max(0,math.ceil(self.deadline-now))
 for _,label in self.model.weatherLabels do
  Locale.SetWorld(label,"Text","%s • %dс",Locale.Get("ru",C.WeatherNames[self.weather]),remaining)
  label:SetAttribute("Text_locale_en",string.format("%s • %ds",Locale.Get("en",C.WeatherNames[self.weather]),remaining))
 end
 for plot,entry in self.model.parties do
  local record=self.world.houseProgression.plots[plot];local party=self.parties[plot];local state=record.state
  local available=state~=nil and state.VerityUnlocked==true and state.HouseIncomeLevel>=2
  local mode=if party then party.mode else self.modes[plot] or "Gifts"
  local title=if mode=="Arcade" then "Турнир на автомате" else "Поиск подарков"
  entry.host.Enabled=available and not party;entry.next.Enabled=entry.host.Enabled
  entry.join.Enabled=party~=nil and party.phase=="Lobby" and party.count<C.PartyLimit;entry.stop.Enabled=party~=nil
  for _,q in {entry.host,entry.next,entry.stop,entry.join} do q:SetAttribute("PartyOwner",state and state.ownerUserId or 0);q:SetAttribute("PartyAvailable",q.Enabled) end
  local signature=tostring(available)..mode..tostring(party and party.phase)
  if entry.signature~=signature then
   entry.signature=signature
   entry.board.Transparency=if available then 0 else 1
   entry.sign.Transparency=entry.board.Transparency
   for _,label in entry.labels do label.Parent.Enabled=available end
   Locale.SetWorld(entry.host,"ObjectText",title);Locale.SetWorld(entry.next,"ObjectText",title)
   for _,part in entry.display do part.Transparency=if party then 0 else 1 end
   for _,node in entry.nodes do show(node.model,party~=nil and mode=="Gifts" and party.phase=="Playing");node.prompt.Enabled=party~=nil and mode=="Gifts" and party.phase=="Playing" end
  end
  if available then
   if party then
    local leaders={}
    for player,e in party.entries do if not e.left then table.insert(leaders,{name=player.DisplayName,score=if party.mode=="Arcade" then e.score or 0 else e.count or 0}) end end
    table.sort(leaders,function(a,b)if a.score==b.score then return a.name<b.name end;return a.score>b.score end)
    local lines={}
    for i=1,math.min(3,#leaders) do table.insert(lines,i..". "..leaders[i].name.." • "..leaders[i].score) end
    local suffix=if #lines>0 then "\n"..table.concat(lines,"\n") else ""
    local seconds=math.max(0,math.ceil(party.deadline-now))
    for _,label in entry.labels do
     local ru=string.format("%s • %dс",Locale.Get("ru",title),seconds)..suffix
     local en=string.format("%s • %ds",Locale.Get("en",title),seconds)..suffix
     label:SetAttribute("Text_locale_ru",ru);label:SetAttribute("Text_locale_en",en);label.Text=ru
    end
   else
    for _,label in entry.labels do Locale.SetWorld(label,"Text",title) end
   end
  end
 end
 for _,q in self.prompts do if q.Parent then q:SetAttribute("AdventureEnabled",q.Enabled) end end
end
function Service:Tick()
 if self.closed then return end;local now=self.clock()
 if now>=self.deadline then
  self.cycle=self.cycle%#C.WeatherCycle+1;self.weather=C.WeatherCycle[self.cycle].Kind;self.weatherRound+=1;self.since=now;self.deadline=now+C.WeatherCycle[self.cycle].Seconds
  if self.weather=="Stars" then self.claimed.stars={} elseif self.weather=="Fire" then self.claimed.fire={} elseif self.weather=="Rainbow" then self.claimed.cave={} end
 end
 for plot,party in self.parties do
  local record=self.world.houseProgression.plots[plot]
  if party.owner.Parent~=self.players or not record.state or record.state.ownerUserId~=party.owner.UserId or not self:PartyAccess(party.owner,plot) then self:StopParty(plot,false)
  elseif now>=party.deadline then
   if party.phase=="Lobby" then
    party.phase="Playing";party.deadline=now+(if party.mode=="Arcade" then C.ArcadePartySeconds else C.PartySeconds)
    for p,e in party.entries do if self.runs[p]==e.run then e.run.deadline=party.deadline;e.run.started=now;e.run.lastAction=now end end
    self:Publish()
   else self:StopParty(plot,true) end
  end
 end
 for p,r in self.runs do
  local root,profile=self:Character(p);local activity=p:GetAttribute("VerityDiversionKind")
  local arcadeAllowed=r.kind=="Party" and activity=="Arcade" and self.arcade.runs[p]~=nil
  if not root or p.Character~=r.char or (activity~="Adventure" and not arcadeAllowed) or now>=r.deadline then self:End(p,false,r.kind~="Party");continue end
  local dt=now-r.sampledAt
  if (root.Position-r.lastPosition).Magnitude>160*math.max(.05,dt)+8 then self:End(p,false,true);continue end
  if r.kind=="Stars" then
   if self.weather~=r.id or r.weatherRound~=self.weatherRound then self:End(p,false,false) end
  elseif r.kind=="Cave" then
   if not C.CaveContains(root.Position) then self:End(p,false,true)
   else for i,pos in C.Jets do
    local phase=C.JetPhase(now,i);local d=root.Position-pos
    if phase>=2.3 and phase<=3.6 and math.abs(d.X)<3 and math.abs(d.Z)<3 and d.Y<8 and now-(r.lastTrap or -100)>1.5 then
     r.lastTrap=now;local checkpoint=if r.index<=1 then C.CaveSpawn else C.Runes[math.min(3,r.index-1)]+Vector3.yAxis*2
     root.CFrame=CFrame.new(checkpoint);root.AssemblyLinearVelocity=Vector3.zero;self.notify(p.UserId,"CAVE_RETRY",0)
    end
   end end
  elseif r.kind=="Trial" then
   local d=C.Trials[r.id];local item=self:TrialItem(p,r.id)
   if not item or not C.TrialContains(root.Position) then self:End(p,false,true)
   elseif r.id~="laser" and now<=(r.armedUntil or 0) then
    local current=self.abilities.active[p];local eligible=r.id~="flight" or current and current.flight
    if eligible then
     while d.Points[r.index] and segmentDistance(r.lastPosition,root.Position,d.Points[r.index])<=(if r.id=="dash" then 3.5 else 4.8) do r.index+=1;r.count+=1;self.notify(p.UserId,"ADVENTURE_STEP",0) end
     if not d.Points[r.index] then self:End(p,true,r.id=="leap" or r.id=="flight") end
    end
   end
  elseif r.kind=="Party" then
   local party=self.parties[r.plot];local record=self.world.houseProgression.plots[r.plot]
   if not party or not record.state then self:End(p,false,false)
   elseif (root.Position-record.pivot.Position).Magnitude>100 then self:End(p,false,false) end
  end
  if self.runs[p]==r then r.lastPosition=root.Position;r.sampledAt=now end
 end
 for i,jet in self.model.jets do
  local phase=C.JetPhase(now,i)
  local state=if phase<1.4 then "Calm" elseif phase<2.3 then "Warning" elseif phase<=3.6 then "Active" else "Calm"
  if jet.state~=state then jet.state=state;jet.base.Color=Color3.fromHex(if state=="Warning" then "FFD36A" elseif state=="Active" then "86E4FC" else "547A8E");jet.jet.Transparency=if state=="Active" then .5 else 1 end
 end
 if now-self.lastPublish>=1 then self:RenderWorld();self:Publish() end
end
function Service:Remove(p)
 for plot,party in self.parties do if party.owner==p then self:StopParty(plot,false) end end
 self:End(p,false,false);self.limits[p]=nil;self.ready[p]=nil
 for _,party in self.parties do local e=party.entries[p];if e then e.left=true end end
end
function Service:Destroy()
 self.closed=true;for plot in self.parties do self:StopParty(plot,false) end
 for p in self.runs do self:End(p,false,true) end
 for _,link in self.links do link:Disconnect() end;self.remote:Destroy()
end
return Service
