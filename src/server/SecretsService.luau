--!nonstrict
local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Shared.SecretsConfig)
local Catalog=require(RS.Shared.AbilityCatalog)
local Numeric=require(RS.Shared.Numeric)
local Service={};Service.__index=Service
function Service.new(model,data,state,players,clock,abilities,rewards,notify,react)
 local self=setmetatable({model=model,data=data,state=state,players=players,clock=clock,abilities=abilities,
  rewards=rewards,notify=notify,react=react,records={},limits={},links={},doorUntil=0,nextPublish=0},Service)
 self.remote=Instance.new("RemoteEvent");self.remote.Name="VeritySecrets";self.remote.Parent=RS
 for _,prompt in model:GetDescendants() do
  if prompt:IsA("ProximityPrompt") then
   table.insert(self.links,prompt.Triggered:Connect(function(p)
    self:Interact(p,prompt,prompt:GetAttribute("SecretId"),prompt:GetAttribute("SecretAction"),prompt:GetAttribute("SecretIndex"))
   end))
  end
 end
 table.insert(self.links,self.remote.OnServerEvent:Connect(function(p,action,id,...)
  if select("#",...)~=0 or (action~="Sync" and action~="Select" and action~="Clear") then return end
  if action=="Select" and not C.Items[id] or action~="Select" and id~=nil then return end
  local now=clock();if now<(self.limits[p] or 0) then return end;self.limits[p]=now+.3
  local root,profile,char=self:Character(p);if not root then return end
  local r=self:Record(p,char)
  if action=="Select" then r.focus=id elseif action=="Clear" then r.focus=nil;r.air=nil end
  self:Publish(p)
 end))
 return self
end
function Service:Character(p)
 local profile=self.data:Get(p.UserId);local char=p.Character
 local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 if p.Parent~=self.players or not profile or profile.Closing or not self.state.sessions[p.UserId] or not profile.Data.VerityUnlocked
  or not root or not hum or hum.Health<=0 or root.Anchored or not Numeric.isFinite(root.Position.X)
  or not Numeric.isFinite(root.Position.Y) or not Numeric.isFinite(root.Position.Z) then return nil end
 for _,name in {"VerityDiversionKind","VerityRaceSlot","VerityParkourStep","VerityBattleActive","VerityFusionSlot"} do if p:GetAttribute(name) then return nil end end
 return root,profile,char
end
function Service:Record(p,char)
 local r=self.records[p]
 if not r or r.character~=char then r={character=char,manual=0,power=false,symbols=0,bells=0};self.records[p]=r end
 return r
end
function Service:Flying(p)
 local a=self.abilities.active[p]
 return a~=nil and a.flight==true and not a.ride and not a.travel and a.character==p.Character and self.clock()<a.untilTime
end
function Service:AirAccess(profile)
 local item=Catalog.ProfileEquipped(profile,"Mobility")
 return item~=nil and not item.Travel and (item.Action=="flight" or item.MobilityAction=="flight")
end
function Service:Grounded(root,platform)
 local point=platform.CFrame:PointToObjectSpace(root.Position)
 if math.abs(point.X)>platform.Size.X/2+.25 or math.abs(point.Z)>platform.Size.Z/2+.25
  or point.Y<platform.Size.Y/2 or point.Y>platform.Size.Y/2+6 then return false end
 local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.FilterDescendantsInstances={platform};ray.RespectCanCollide=true
 return workspace:Raycast(root.Position,Vector3.new(0,-7,0),ray)~=nil
end
function Service:Goal(p,r,root)
 if not r.focus then return nil end
 local id=r.focus;local point,title,action,kind,air,index
 if id=="solar" then
  if not r.power then point=self.model.Solar.Dynamo;title="Запитай солнечный приёмник";action="Зарядить вручную";kind="Power"
  elseif r.symbols<3 then index=r.symbols+1;point=self.model.Solar["Symbol"..index];title="Повтори порядок символов";action=({"Солнце","Луна","Звезда"})[index];kind="Symbol"
  else point=self.model.Solar.Chest;title="Открой солнечный тайник";action="Открыть тайник";kind="Chest" end
 elseif id=="canopy" then
  if not self:Grounded(root,self.model.Canopy.Branch6) then point=self.model.Canopy.Branch6;title="Поднимись в крону";action="Взберись по ветвям или используй прыжок";kind="Climb"
  elseif r.bells<3 then index=r.bells+1;point=self.model.Canopy["Bell"..index];title="Сыграй мелодию ветра";action=({"Лист","Капля","Солнце"})[index];kind="Bell"
  else point=self.model.Canopy.Chest;title="Открой тайник кроны";action="Открыть тайник";kind="Chest" end
 else
  if not r.air then point=self.model.Cloud.Launch;title="Начни воздушный маршрут";action="Начать воздушный маршрут";kind="Start"
  elseif r.air.index<3 then
   return {kind="Ring",position=C.Rings[r.air.index+1],index=r.air.index+1,title="Пролети через кольцо",air=true}
  else point=self.model.Cloud.Chest;title="Приземлись у облачного тайника";action="Открыть тайник";kind="Chest";air=true end
 end
 return {kind=kind,position=point.Position,path=point.Parent.Name.."/"..point.Name,title=title,action=action,air=air==true,index=index or 0}
end
function Service:Publish(p)
 local root,profile,char=self:Character(p)
 if not root then return end
 local r=self:Record(p,char);local found={}
 for id,item in C.Items do found[id]=profile.Data.CosmeticsOwned[item.Item]==true end
 self.remote:FireClient(p,{version=C.Version,focus=r.focus,power=r.power,manual=r.manual,symbols=r.symbols,bells=r.bells,
  found=found,airIndex=r.air and r.air.index or 0,airActive=r.air~=nil,airDeadline=r.air and r.air.deadline or 0,
  flying=self:Flying(p),airAccess=self:AirAccess(profile)==true,goal=self:Goal(p,r,root)})
end
function Service:CanAimMechanism(p,item)
 local root=self:Character(p)
 return root~=nil and item~=nil and item.Action=="laser" and (root.Position-self.model.Solar.Receiver.Position).Magnitude<=math.min(90,item.Range)
end
function Service:TryLaser(p,item,character,root,direction)
 if not self:CanAimMechanism(p,item) then return nil end
 local head=character:FindFirstChild("Head");local origin=if head then head.Position else root.Position+Vector3.yAxis*2
 local receiver=self.model.Solar.Receiver;local delta=receiver.Position-origin
 if delta.Magnitude<.1 or delta.Magnitude>item.Range or direction:Dot(delta.Unit)<.982 then return nil end
 local ray=RaycastParams.new();ray.FilterDescendantsInstances={character,receiver};ray.RespectCanCollide=true
 if workspace:Raycast(origin,delta,ray) then return nil end
 local r=self:Record(p,character);r.power=true;r.manual=3;r.focus="solar"
 self.react(p.UserId,"Stars",2);self.notify(p.UserId,"SECRET_POWERED");self:Publish(p)
 return receiver.Position
end
function Service:Claim(p,id,r,profile)
 if profile.Data.CosmeticsOwned[C.Items[id].Item] then self.notify(p.UserId,"SECRET_ALREADY_FOUND");r.focus=nil;self:Publish(p);return end
 local ready=if id=="solar" then r.power and r.symbols==3 elseif id=="canopy" then r.bells==3 else r.air and r.air.index==3 and self.clock()<r.air.deadline
 if not ready then self.notify(p.UserId,"SECRET_NOT_SOLVED");return end
 if self:Flying(p) then self.abilities:Stop(p) end
 if self.rewards:Grant(p.UserId,C.Items[id].Reward) then
  r.focus=nil;if id=="cloud" then r.air=nil end
  self.react(p.UserId,"Stars",3);self:Publish(p)
 end
end
function Service:Interact(p,prompt,id,action,index)
 local now=self.clock();if now<(self.limits[p] or 0) then return end;self.limits[p]=now+.3
 local root,profile,char=self:Character(p)
 if not root or not C.Items[id] or not prompt:IsDescendantOf(self.model) then return end
 local distance=(root.Position-prompt.Parent.Position).Magnitude
 if not Numeric.isFinite(distance) or distance>C.Reach+.5 then return end
 local r=self:Record(p,char);r.focus=id
 if action=="Hint" then self.notify(p.UserId,"SECRET_HINT_"..id)
 elseif action=="Dynamo" and id=="solar" then
  if not r.lastCharge or now-r.lastCharge>=1 then
   r.lastCharge=now;r.manual=math.min(3,r.manual+1);r.power=r.manual==3
   if r.power then self.notify(p.UserId,"SECRET_POWERED") end
  end
 elseif action=="Symbol" and id=="solar" then
  if not r.power then self.notify(p.UserId,"SECRET_NO_POWER")
  elseif r.symbols<3 then
   r.symbols=if index==r.symbols+1 then r.symbols+1 else 0
   if r.symbols==0 then self.notify(p.UserId,"SECRET_WRONG_ORDER")
   elseif r.symbols==3 then self.doorUntil=now+30;self.notify(p.UserId,"SECRET_ARCHIVE_OPEN") end
  else self.doorUntil=now+30 end
 elseif action=="Bell" and id=="canopy" then
  if not self:Grounded(root,self.model.Canopy.Branch6) then return end
  if r.bells<3 then r.bells=if index==r.bells+1 then r.bells+1 else 0 end
  if r.bells==0 then self.notify(p.UserId,"SECRET_WRONG_ORDER") end
 elseif action=="Start" and id=="cloud" then
  if not self:AirAccess(profile) then self.notify(p.UserId,"SECRET_NEED_FLIGHT")
  elseif profile.Data.CosmeticsOwned[C.Items.cloud.Item] then self.notify(p.UserId,"SECRET_ALREADY_FOUND")
  else r.air={index=0,deadline=now+C.AirSeconds,character=char,lastPosition=root.Position,lastAt=now,progressAt=now} end
 elseif action=="Claim" then
  if id=="canopy" and not self:Grounded(root,self.model.Canopy.Branch6) then return end
  if id=="cloud" and not self:Grounded(root,self.model.Cloud.SkyFloor) then return end
  self:Claim(p,id,r,profile);return
 elseif action=="Exit" and id=="solar" then
  local localPoint=root.Position-C.Solar
  if math.abs(localPoint.X)<=13 and math.abs(localPoint.Z)<=12 then self.doorUntil=now+6 end
 elseif action=="Return" and (id=="cloud" or id=="canopy") then
  self.abilities:Stop(p)
  char:PivotTo(CFrame.new((if id=="cloud" then C.Launch else C.Tree+Vector3.new(0,0,14))+Vector3.new(0,4,0)))
  root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero;r.air=nil;r.focus=nil
 end
 self:Publish(p)
end
local function nearSegment(point,a,b,radius)
 local segment=b-a;local t=if segment.Magnitude>.01 then math.clamp((point-a):Dot(segment)/segment:Dot(segment),0,1) else 0
 return (point-(a+segment*t)).Magnitude<=radius
end
function Service:Tick()
 local now=self.clock();local inside=false
 for _,p in self.players:GetPlayers() do
  local char=p.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  local hum=char and char:FindFirstChildOfClass("Humanoid")
  if root and hum and hum.Health>0 then local d=root.Position-C.Solar;if math.abs(d.X)<13.5 and d.Z> -12 and d.Z<10.7 and d.Y>0 and d.Y<11 then inside=true end end
 end
 local open=inside or now<self.doorUntil
 local door=self.model.Solar.Door
 door.CanCollide=not open;door.CanQuery=not open;door.Transparency=if open then .95 else .3
 self.model:SetAttribute("ArchiveOpen",open)
 for p,r in self.records do
  local root=self:Character(p)
  if not root or p.Character~=r.character then
   if r.air then r.air=nil end
   continue
  end
  local air=r.air
  if air then
   local elapsed=now-air.lastAt
   if now>=air.deadline or (root.Position-air.lastPosition).Magnitude>math.max(28,elapsed*85) then
    r.air=nil;self.notify(p.UserId,"SECRET_AIR_RESET");self:Publish(p)
   else
    if air.index<3 and self:Flying(p) and now-air.progressAt>=.4 and nearSegment(C.Rings[air.index+1],air.lastPosition,root.Position,C.RingRadius) then
     air.index+=1;air.progressAt=now;self.react(p.UserId,"Confident",1);self:Publish(p)
    end
    if air.index==3 and self:Flying(p) then
     local deck=self.model.Cloud.SkyFloor;local d=deck.CFrame:PointToObjectSpace(root.Position)
     if math.abs(d.X)<deck.Size.X/2-1 and math.abs(d.Z)<deck.Size.Z/2-1 and d.Y>1 and d.Y<18 then
      self.abilities:Stop(p);self.notify(p.UserId,"SECRET_LANDING")
     end
    end
    air.lastPosition,air.lastAt=root.Position,now
   end
  end
  if r.focus and now>=self.nextPublish then self:Publish(p) end
 end
 if now>=self.nextPublish then self.nextPublish=now+.5 end
end
function Service:Remove(p) self.records[p],self.limits[p]=nil,nil end
function Service:Destroy()
 for _,link in self.links do link:Disconnect() end
 self.remote:Destroy();table.clear(self.records);table.clear(self.limits)
end
return Service
