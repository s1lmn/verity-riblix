--!nonstrict
-- Contextual affection is cosmetic; never grants cash, stats or a second mover.
local RS=game:GetService("ReplicatedStorage")
local Numeric=require(RS.Shared.Numeric)
local Service={};Service.__index=Service
function Service.new(world,data,state,players,clock)
 local self=setmetatable({world=world,data=data,state=state,players=players,clock=clock,records={},limits={},nextTick=0},Service)
 self.remote=Instance.new("RemoteEvent");self.remote.Name="VerityBond";self.remote.Parent=RS
 self.link=self.remote.OnServerEvent:Connect(function(p,action,...)
  if select("#",...)~=0 or (action~="Pet" and action~="Play") then return end
  local now=clock();if now<(self.limits[p] or 0) then return end;self.limits[p]=now+.5
  if not self:Eligible(p) then return end
  local name="Verity"..action.."ReadyAt"
  if now<(p:GetAttribute(name) or 0) then self.remote:FireClient(p,"Cooldown",action);return end
  p:SetAttribute(name,now+(if action=="Pet" then 12 else 20))
  self:React(p.UserId,if action=="Pet" then "Love" else "Laugh",action,3)
  self.remote:FireClient(p,"OK",action)
 end)
 return self
end
function Service:Eligible(p)
 local profile=self.data:Get(p.UserId)
 if p.Parent~=self.players or not profile or profile.Closing or not self.state.sessions[p.UserId]
  or not profile.Data.VerityUnlocked or not self.world.verities[p.UserId] then return false end
 local root=self.world:GetCharacter(p.UserId)
 if not root or root.Anchored or not Numeric.isFinite(root.Position.X) or not Numeric.isFinite(root.Position.Y)
  or not Numeric.isFinite(root.Position.Z) then return false end
 for _,name in {"VerityDiversionKind","VerityRaceSlot","VerityParkourStep","VerityBattleActive","VerityFusionSlot","VerityRiding"} do if p:GetAttribute(name) then return false end end
 return root
end
function Service:React(id,emotion,gesture,seconds)
 local model=self.world.verities[id]
 if not model then return end
 self.world:React(id,emotion,seconds)
 model:SetAttribute("LifeGesture",gesture);model:SetAttribute("LifeGestureAt",self.clock())
 model:SetAttribute("LifeGestureUntil",self.clock()+seconds)
end
function Service:Stage(id,taskId,prop)
 local p=self.players:GetPlayerByUserId(id);if not p or not self:Eligible(p) then return end
 self:React(id,if prop=="Flower" then "Love" elseif prop=="Drone" then "Stars" else "Confident","Helping",2)
end
function Service:Tick()
 local now=self.clock();if now<self.nextTick then return end;self.nextTick=now+1
 for _,p in self.players:GetPlayers() do
  local root=self:Eligible(p)
  if not root then self.records[p]=nil;continue end
  local record=self.records[p]
  if not record then record={position=root.Position,still=now,nextReaction=now+12};self.records[p]=record end
  if (root.Position-record.position).Magnitude>1.2 then record.still=now end
  record.position=root.Position
  local session=self.state.sessions[p.UserId]
  local plot=session.PlotId and self.world.houseProgression.plots[session.PlotId]
  local localPoint=plot and plot.pivot:PointToObjectSpace(root.Position)
  local home=localPoint and math.abs(localPoint.X)<23 and localPoint.Z<14 and localPoint.Z> -54 and localPoint.Y<31
  local model=self.world.verities[p.UserId]
  local free=now>=(model:GetAttribute("LifeGestureUntil") or 0) and now>=(model:GetAttribute("EmotionUntil") or 0)
  if home and record.home==false and now>=record.nextReaction and free then
   self:React(p.UserId,"Love","Home",2.5);record.nextReaction=now+25
  elseif now-record.still>18 and now>=record.nextReaction and free then
   self:React(p.UserId,"Playful","Curious",2.5);record.nextReaction=now+40
  end
  record.home=home==true
 end
end
function Service:Remove(p) self.records[p],self.limits[p]=nil,nil end
function Service:Destroy() self.link:Disconnect();self.remote:Destroy();table.clear(self.records);table.clear(self.limits) end
return Service
