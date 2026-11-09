--!nonstrict
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Collection=game:GetService("CollectionService")
local RunService=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Catalog=require(ReplicatedStorage.Shared.AbilityCatalog)
local Cleanup=require(script.Parent.Cleanup)
local Locale=require(script.Parent.Locale)
local Visuals=require(script.Parent.AbilityVisuals)
local RidePresentation=require(script.Parent.RidePresentation)
local Controller={};Controller.__index=Controller
local function part(parent,pos,size,color,ball)
	local p=Instance.new("Part");p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.CastShadow=false
	p.Material=Enum.Material.Neon;p.Color=color;p.Size=size;p.Position=pos
	if ball then p.Shape=Enum.PartType.Ball end
	p.Parent=parent;return p
end
local function line(parent,a,b,color,width)
	local p0=part(parent,a,Vector3.one*.05,color);p0.Transparency=1
	local p1=part(parent,b,Vector3.one*.05,color);p1.Transparency=1
	local at0=Instance.new("Attachment");at0.Parent=p0
	local at1=Instance.new("Attachment");at1.Parent=p1
	local beam=Instance.new("Beam");beam.Attachment0=at0;beam.Attachment1=at1
	beam.FaceCamera=true;beam.LightEmission=1;beam.LightInfluence=0;beam.Color=ColorSequence.new(color)
	beam.Width0=width;beam.Width1=width*.65;beam.Segments=1;beam.Transparency=NumberSequence.new(1);beam.Parent=p0
	local core=beam:Clone();core.Color=ColorSequence.new(Color3.fromHex("FFF4E7"));core.Width0=width*.35;core.Width1=width*.2;core.Parent=p0
	local glow=beam:Clone();glow.Width0=width*2.6;glow.Width1=width*1.9
 glow.Transparency=NumberSequence.new(1);glow.Parent=p0
 return {source=p0,finish=p1,beam=beam,core=core,glow=glow,width=width}
end
function Controller.new(ctx)
	local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),effects={},stands={},companions={},elapsed=0},Controller)
	self.folder=Instance.new("Folder");self.folder.Name="VerityAbilityEffects";self.folder.Parent=workspace;self.cleanup:Add(self.folder)
	local function companion(model) self.companions[model:GetAttribute("OwnerUserId")]=model end
	self.cleanup:Add(Collection:GetInstanceAddedSignal("VerityVisual"):Connect(companion))
	self.cleanup:Add(Collection:GetInstanceRemovedSignal("VerityVisual"):Connect(function(model)
		local id=model:GetAttribute("OwnerUserId");if self.companions[id]==model then self.companions[id]=nil end
	end))
	for _,model in Collection:GetTagged("VerityVisual") do companion(model) end
	local function stand(model)
		local orb=model:FindFirstChild("FloatingEmblem");if not orb then return end
		self.stands[model]={orb=orb,cf=orb.CFrame,light=orb:FindFirstChildOfClass("PointLight"),premium=model.Name=="homelander",emitters={}}
		for _,object in model:GetDescendants() do if object:IsA("ParticleEmitter") then table.insert(self.stands[model].emitters,object) end end
	end
	self.cleanup:Add(Collection:GetInstanceAddedSignal("VerityAbilityStand"):Connect(stand))
	self.cleanup:Add(Collection:GetInstanceRemovedSignal("VerityAbilityStand"):Connect(function(model) self.stands[model]=nil end))
	for _,model in Collection:GetTagged("VerityAbilityStand") do stand(model) end
	local remote=ReplicatedStorage:WaitForChild("UseVerityAbility",10)
	if remote then self.cleanup:Add(remote.OnClientEvent:Connect(function(event) self:Event(event) end)) end
	self.cleanup:Add(RidePresentation.new(ctx,self.companions))
 self.cleanup:Add(RunService.RenderStepped:Connect(function(dt) self:Tick(dt) end))
	self.cleanup:Add(function()
		for _,r in self.effects do if r.highlight then r.highlight:Destroy() end end
		for _,r in self.stands do
			if r.orb.Parent then r.orb.CFrame=r.cf end
			if r.light then r.light.Enabled=true;r.light.Brightness=if r.premium then 2.5 else .5 end
			for _,e in r.emitters do e.Enabled=true end
		end
	end)
	return self
end
function Controller:Eye(owner,side,fallback)
	local model=self.companions[owner];local body=model and model:FindFirstChild("Body")
	if not body or not body.Parent or body.Transparency>.8 then return fallback+Vector3.new(side*.4,.2,0) end
	return body.CFrame:PointToWorldSpace(Vector3.new(side*body.Size.X*.17,body.Size.Y*.1,-body.Size.Z*.465))
end
function Controller:Event(event)
	if type(event)~="table" then return end
	if event.kind=="Blocked" then
  local messages={DIVERSION_POWER="Сначала заверши текущую активность.",RACE_POWER="Способности недоступны во время гонки.",RIDING_POWER="Сначала спешься с Verity.",BATTLE_OTHER_ACTIVITY="Сначала выйди с арены.",PARKOUR_POWER="На маршруте используй прыжки. Способности доступны после выхода.",RIDE_LANDING="Подлети к свободному месту для приземления.",RIDE_SPACE="Для посадки на Verity выйди на просторное место.",RIDE_PARKOUR="Сначала заверши паркур или выйди из него.",SAFE_ZONE="Дома и после возрождения действует защита.",OBSTACLE="Перед тобой препятствие — отойди от стены.",FLIGHT_UNAVAILABLE="Сейчас полёт недоступен. Попробуй после приземления.",MOVEMENT_UNAVAILABLE="Сейчас способность недоступна. Попробуй после приземления."}
  self.ctx.notifications:Show(Locale.Text(messages[event.code] or messages.SAFE_ZONE));return
 end
	if event.kind=="CombatResult" then
		if event.damage>0 then self.ctx.notifications:Show(string.format(Locale.Text("Попадание • %s урона"),Locale.Number(event.damage)))
		else self.ctx.notifications:Show(Locale.Text("Промах. Наведи прицел на цель без укрытия.")) end
		return
	end
	local item=Catalog.Items[event.itemId]
	local player=Players:GetPlayerByUserId(event.ownerUserId)
	if not item or not player or not player.Character then return end
 local humanoid=player.Character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health<=0 then return end
	local camera=workspace.CurrentCamera
	local graphics=self.ctx.settings.values.Graphics
	if not camera or (camera.CFrame.Position-event.origin).Magnitude>(graphics and graphics.AbilityDistance or 240) then return end
	while #self.effects>=(graphics and graphics.MaxAbilityEffects or 24) do local old=table.remove(self.effects,1);old.folder:Destroy();if old.highlight then old.highlight:Destroy() end end
	local folder=Instance.new("Folder");folder.Name=event.itemId;folder.Parent=self.folder
	local color=Color3.fromHex(item.Color);local reduced=(self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics)
	local duration=if reduced and event.kind=="Attack" then math.min(event.duration,.4) else event.duration
	local r={folder=folder,character=player.Character,owner=event.ownerUserId,started=os.clock(),duration=duration,lines={},item=item,kind=event.kind,origin=event.origin}
	r.serverEndsAt=event.endsAt or (workspace:GetServerTimeNow()+event.duration)
	Visuals.Prepare(r,reduced,graphics and graphics.ParticleScale or 1)
	table.insert(self.effects,r)
	if event.kind=="Attack" then
		local target=event.points[1]
		Visuals.Attack(r,target)
		if self.ctx.visuals then self.ctx.visuals:AimAbility(event.ownerUserId,target,duration) end
		if item.Action=="laser" then
			for side=-1,1,2 do
				local beam=line(folder,self:Eye(event.ownerUserId,side,event.origin),target,color,if reduced then .16 else .5)
				beam.side=side;table.insert(r.lines,beam)
				local eye=part(folder,beam.source.Position,Vector3.one*.5,color,true);beam.eye=eye
				local light=Instance.new("PointLight");light.Color=color;light.Brightness=if reduced then .4 else 1.5;light.Range=10;light.Parent=eye
			end
		else
			local from=r.origin
			for _,point in event.points do
				if item.Action=="lightning" and not reduced then
					for segment=1,6 do
						local to=from:Lerp(point,segment/6)
						if segment<6 then to+=Vector3.new(math.sin(segment*7)*1.2,math.cos(segment*4)*1.2,0) end
						local previous=if segment==1 then from else r.lines[#r.lines].finish.Position
						local bolt=line(folder,previous,to,color,.36)
      bolt.lightning=true;bolt.baseA=previous;bolt.baseB=to;bolt.seed=segment
      bolt.jitterStart=segment>1;bolt.jitterEnd=segment<6
      table.insert(r.lines,bolt)
					end
				else table.insert(r.lines,line(folder,from,point,color,.45)) end
				from=point
			end
		end
		local impact=part(folder,target,Vector3.one*.4,color:Lerp(Color3.new(1,1,1),.25),true);impact.Transparency=.72
		local diameter=if item.Radius then math.min(8,item.Radius*.5) else 3.5
		Tween:Create(impact,TweenInfo.new(math.min(duration,.65),Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.one*diameter,Transparency=1}):Play()

	else
		local root=player.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local h=Instance.new("Highlight");h.Adornee=player.Character;h.FillColor=color;h.OutlineColor=color
		h.FillTransparency=.85;h.OutlineTransparency=.15;h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Parent=folder;r.highlight=h
		if item.Action=="shield" then
			r.shield=part(folder,root.Position,Vector3.one*8,color,true);r.shield.Transparency=.91
		end
		if item.Action=="flight" or item.MobilityAction then
			for side=-1,1,2 do
				local glow=part(folder,root.Position,Vector3.one*.5,color,true)
				local light=Instance.new("PointLight");light.Color=color;light.Range=8;light.Brightness=1;light.Parent=glow
				r[if side<0 then "leftJet" else "rightJet"]=glow
			end
		end
		Visuals.Mobility(r,root,player.Character:FindFirstChildOfClass("Humanoid"))
	end
	if event.ownerUserId==Players.LocalPlayer.UserId then
		self.ctx.sound:Play(if event.kind=="Mobility" then "SwipeWhoosh" elseif item.Action=="nova" then "Milestone100" elseif item.Action=="lightning" then "Milestone50" else "Milestone25")
	end
end
function Controller:Tick(dt)
	local graphics=self.ctx.settings.values.Graphics
	self.elapsed+=dt;if self.elapsed<(graphics and graphics.AbilityInterval or 1/30) then return end;self.elapsed=0
	while #self.effects>(graphics and graphics.MaxAbilityEffects or 24) do local r=table.remove(self.effects,1);r.folder:Destroy() end
	local now=os.clock();local camera=workspace.CurrentCamera
	for index=#self.effects,1,-1 do
		local r=self.effects[index];local player=Players:GetPlayerByUserId(r.owner)
		local root=r.character:FindFirstChild("HumanoidRootPart");local humanoid=r.character:FindFirstChildOfClass("Humanoid")
		if now-r.started>=r.duration or not player or player.Character~=r.character or not root or not humanoid or humanoid.Health<=0
			or (r.stoppedAt and now-r.stoppedAt>.4) then
			r.folder:Destroy();table.remove(self.effects,index);continue
		end
		local age=now-r.started
  if r.kind=="Mobility" then
   local activeUntil=player:GetAttribute("VerityMobilityUntil")
   if activeUntil and activeUntil>=r.serverEndsAt-.1 then r.sawActive=true end
   if not r.stoppedAt and (workspace:GetServerTimeNow()>=r.serverEndsAt
    or (r.sawActive and (not activeUntil or activeUntil<workspace:GetServerTimeNow()))) then r.stoppedAt=now end
  end
  local alpha=math.clamp(age/r.channelDuration,0,1)
  Visuals.Tick(r,age,root,humanoid,self.ctx.settings.values)
		for _,beam in r.lines do
			if beam.side then
				local p=self:Eye(r.owner,beam.side,root.Position+Vector3.new(0,2,0))
				beam.source.Position=p
    if beam.eye then
     beam.eye.Position=p;beam.eye.Transparency=math.clamp((alpha-.8)/.2,0,1)
     local charge=math.clamp(age/.12,0,1)
     beam.eye.Size=Vector3.one*(.35+.45*charge)*(1+.08*math.sin(age*24))
     local eyeLight=beam.eye:FindFirstChildOfClass("PointLight")
     if eyeLight then eyeLight.Brightness=(if (self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics) then .4 else 1.5)*(1-math.clamp((alpha-.7)/.3,0,1)) end
    end
			end
   if beam.lightning and not self.ctx.settings.values.ReducedMotion then
    local t=age*24
    local a=if beam.jitterStart then Vector3.new(math.sin(t+beam.seed-1)*.55,math.cos(t*1.3+beam.seed-1)*.55,0) else Vector3.zero
    local b=if beam.jitterEnd then Vector3.new(math.sin(t+beam.seed)*.55,math.cos(t*1.3+beam.seed)*.55,0) else Vector3.zero
    beam.source.Position=beam.baseA+a;beam.finish.Position=beam.baseB+b
   end
   local charge=math.clamp((age-.06)/.08,0,1)
   local fade=math.max(1-charge,math.clamp((alpha-.6)/.4,0,1))
   local width=beam.width*charge*(if self.ctx.settings.values.ReducedMotion then 1 else 1+.08*math.sin(age*24))
   beam.beam.Width0=width;beam.beam.Width1=width*.7
   beam.core.Width0=width*.33;beam.core.Width1=width*.22
   beam.glow.Width0=width*2.6;beam.glow.Width1=width*1.9
   beam.beam.Transparency=NumberSequence.new(fade);beam.core.Transparency=NumberSequence.new(fade)
   beam.glow.Transparency=NumberSequence.new(.75+.25*fade)
		end
		if r.shield then r.shield.CFrame=root.CFrame end
		if r.leftJet then r.leftJet.Position=root.Position-root.CFrame.RightVector*.6-Vector3.yAxis*2 end
		if r.rightJet then r.rightJet.Position=root.Position+root.CFrame.RightVector*.6-Vector3.yAxis*2 end
	end
	for model,r in self.stands do
		if not model.Parent or not r.orb.Parent then self.stands[model]=nil;continue end
		local close=camera and (camera.CFrame.Position-r.cf.Position).Magnitude<(graphics and graphics.StandDistance or 160)
		local reduced=(self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.LowGraphics)
		if r.light then r.light.Enabled=close;r.light.Brightness=(if r.premium then 2.5 else .5)*(1+.15*math.sin(now*2)) end
		for _,e in r.emitters do e.Enabled=close and not reduced end
		if close and not self.ctx.settings.values.ReducedMotion then r.orb.CFrame=r.cf*CFrame.new(0,math.sin(now*1.5)*(if r.premium then .3 else .12),0) end
	end
end
function Controller:Destroy() self.cleanup:Destroy() end
return Controller
