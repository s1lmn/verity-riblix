--!nonstrict
-- Bounded native decoration owned by AbilityEffectsController's effect folders.
local Visuals={}
local WHITE=Color3.fromHex("FFF6E8")
local function piece(r,position,color,size)
	local p=Instance.new("Part");p.Name="AbilityAccent";p.Anchored=true
	p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
	p.Material=Enum.Material.Neon;p.Color=color;p.Size=size or Vector3.one*.15;p.Position=position
	p.Parent=r.folder;return p
end
local function ring(r,center,radius,color,normal,life,delay,mode,tilt)
	local parts={};local count=if r.reduced then 8 elseif r.particleScale<1 then 10 else 14
	for _=1,count do
		local p=piece(r,center,color);p.Name="EnergyArc";p.Transparency=1;table.insert(parts,p)
	end
	table.insert(r.rings,{parts=parts,center=center,radius=radius,color=color,normal=normal or Vector3.yAxis,
		life=life,delay=delay or 0,mode=mode,tilt=tilt})
end
local function burst(r,center,color,count,delay)
	if r.reduced then return end
	local anchor=piece(r,center,color);anchor.Transparency=1
	local attachment=Instance.new("Attachment");attachment.Parent=anchor
	local e=Instance.new("ParticleEmitter");e.Texture="rbxasset://textures/particles/sparkles_main.dds"
	e.Rate=0;e.LightEmission=1;e.LightInfluence=0;e.Drag=3
	e.Color=ColorSequence.new(WHITE,color);e.SpreadAngle=Vector2.new(180,180)
	e.Speed=NumberRange.new(4,12);e.Lifetime=NumberRange.new(.25,.65)
	e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.3),NumberSequenceKeypoint.new(.35,.2),NumberSequenceKeypoint.new(1,0)})
	e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.05),NumberSequenceKeypoint.new(.65,.25),NumberSequenceKeypoint.new(1,1)})
	e.Parent=attachment
	table.insert(r.bursts,{emitter=e,count=math.max(1,math.floor(count*r.particleScale)),delay=delay or 0})
end
local function trail(r,source,side,color,lifetime)
	local a=Instance.new("Attachment");a.Position=Vector3.new(side*.8,.35,0);a.Parent=source
	local b=Instance.new("Attachment");b.Position=Vector3.new(side*.8,-1.5,0);b.Parent=source
	local t=Instance.new("Trail");t.Attachment0=a;t.Attachment1=b;t.FaceCamera=true
	t.LightEmission=1;t.LightInfluence=0;t.Brightness=1.6;t.Lifetime=lifetime;t.MinLength=.08;t.MaxLength=18
	t.Color=ColorSequence.new(WHITE,color)
	t.WidthScale=NumberSequence.new({NumberSequenceKeypoint.new(0,.9),NumberSequenceKeypoint.new(.6,.5),NumberSequenceKeypoint.new(1,0)})
	t.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.12),NumberSequenceKeypoint.new(.7,.45),NumberSequenceKeypoint.new(1,1)})
	t.Parent=source;table.insert(r.motionTrails,t)
end
local function jet(r,source,color)
	if r.reduced then return end
	local attach=Instance.new("Attachment");attach.Parent=source
	local e=Instance.new("ParticleEmitter");e.Texture="rbxasset://textures/particles/sparkles_main.dds"
	e.Rate=22*r.particleScale;e.EmissionDirection=Enum.NormalId.Bottom;e.Speed=NumberRange.new(5,11)
	e.SpreadAngle=Vector2.new(16,16);e.Lifetime=NumberRange.new(.12,.3);e.Acceleration=Vector3.new(0,-14,0)
	e.Color=ColorSequence.new(WHITE,color);e.LightEmission=1;e.LightInfluence=0
	e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.55),NumberSequenceKeypoint.new(1,0)})
	e.Parent=attach;table.insert(r.emitters,e)
end

function Visuals.Prepare(r,reduced,particleScale)
	r.particleScale=particleScale or 1
	r.reduced=reduced;r.rings={};r.bursts={};r.emitters={};r.motionTrails={};r.motes={}
	r.channelDuration=r.duration;r.color=Color3.fromHex(r.item.Color)
end
function Visuals.Attack(r,target)
	local action=r.item.Action;local color=r.color
	local delta=r.origin-target
	local normal=if delta.Magnitude>.01 then delta.Unit else Vector3.zAxis
	if action=="laser" then
		r.duration=r.channelDuration+.3
		ring(r,target,2.6,color,normal,.55,.14)
		if not r.reduced then ring(r,target,4,color,normal,.65,.28) end
		burst(r,target,color,18,.15)
	elseif action=="lightning" then
		r.duration=.8
		ring(r,target,3.4,color,Vector3.yAxis,.55,.13)
		burst(r,target,color,20,.12)
	elseif action=="gravity" then
		r.duration=1.2
		ring(r,target,r.item.Radius,color,Vector3.yAxis,.85,.14)
		if not r.reduced then ring(r,target,r.item.Radius*.65,WHITE,Vector3.zAxis,.8,.18) end
		for i=1,(if r.reduced then 4 else 10) do
			local p=piece(r,target,color,Vector3.one*.22);p.Shape=Enum.PartType.Ball
			table.insert(r.motes,{part=p,angle=i*math.pi*2/(if r.reduced then 4 else 10)})
		end
		burst(r,target,color,24,.36)
	elseif action=="nova" then
		r.duration=1.35
		ring(r,target,r.item.Radius,color,Vector3.yAxis,1,.15)
		if not r.reduced then
			ring(r,target,r.item.Radius*.8,WHITE,Vector3.yAxis,.9,.25)
			ring(r,target,r.item.Radius*.55,color,Vector3.zAxis,.9,.2)
		end
		burst(r,target,color,36,.17)
	else
		r.duration=.8
		ring(r,target,4.6,color,normal,.55,.13)
		burst(r,target,color,16,.14)
		local bolt=piece(r,r.origin,color,Vector3.one*.65);bolt.Shape=Enum.PartType.Ball;r.bolt=bolt
	end
	r.target=target
	local source=piece(r,target,color);source.Transparency=1
	local light=Instance.new("PointLight");light.Color=color;light.Range=if action=="nova" then 24 else 12
	light.Brightness=0;light.Shadows=false;light.Parent=source;r.impactLight=light
end
function Visuals.Mobility(r,root,humanoid)
	local item=r.item;local action=item.MobilityAction or item.Action;local color=r.color
	r.duration=r.channelDuration+.4
	local feet=root.Position-Vector3.new(0,humanoid.HipHeight+root.Size.Y/2-.12,0)
	if action=="shield" then
		ring(r,root.Position,4.2,color,Vector3.yAxis,r.channelDuration,0,"Shield",.45)
		if not r.reduced then ring(r,root.Position,4.2,WHITE,Vector3.zAxis,r.channelDuration,0,"Shield",-.45) end
	else
		local scarletFlight=action=="flight" and item.PvEDamage~=nil
		ring(r,feet,if action=="leap" or scarletFlight then 6 else 4,color,Vector3.yAxis,.6,0)
		if scarletFlight and not r.reduced then
			ring(r,feet,4.8,Color3.fromHex("FFC580"),Vector3.yAxis,.52,.08)
		end
		burst(r,feet,color,if action=="leap" then 18 else 10,0)
		if not r.reduced then
			r.motionSource=piece(r,root.Position,color);r.motionSource.Transparency=1
			trail(r,r.motionSource,-1,color,if action=="dash" then .22 else .35)
			trail(r,r.motionSource,1,if scarletFlight then Color3.fromHex("FFC580") else color,if action=="dash" then .22 else .35)
		end
	end
	if action=="flight" then
		if r.leftJet then jet(r,r.leftJet,color) end
		if r.rightJet then jet(r,r.rightJet,color) end
	elseif action=="sprint" or action=="leap" then
		for i=1,(if r.reduced then 0 else 6) do
			local p=piece(r,root.Position,color,Vector3.new(.07,.07,if action=="sprint" then 1.8 else .5))
			table.insert(r.motes,{part=p,angle=i*math.pi/3})
		end
	end
end
function Visuals.Tick(r,age,root,humanoid,settings)
	local reduced=(settings.ReducedEffects or settings.LowGraphics);local motion=settings.ReducedMotion
	for _,b in r.bursts do
		if not b.done and age>=b.delay then b.done=true;if not reduced and not motion then b.emitter:Emit(b.count) end end
	end
	for _,e in r.emitters do e.Enabled=not reduced and not motion and not r.stoppedAt and age<r.channelDuration end
	for _,ringData in r.rings do
		local elapsed=age-ringData.delay;local t=math.clamp(elapsed/ringData.life,0,1)
		local center=ringData.center;local radius=ringData.radius;local cf
		local sustained=ringData.mode=="Shield"
		if sustained then
			center=root.Position
			cf=CFrame.new(center)*CFrame.Angles(if motion then 0 else age*.7,if motion then 0 else age*.55,ringData.tilt or 0)
			if ringData.normal==Vector3.yAxis then cf*=CFrame.Angles(math.pi/2,0,0) end
			radius*=1+(if motion then 0 else .025*math.sin(age*4))
		else
			local up=if math.abs(ringData.normal:Dot(Vector3.yAxis))>.98 then Vector3.zAxis else Vector3.yAxis
			cf=CFrame.lookAt(center,center+ringData.normal,up)
			radius*=if motion then 1 else .15+.85*(1-(1-t)^3)
		end
		local fade=if sustained then math.clamp((t-.8)/.2,0,1) else t*t
		local appearance=math.clamp(elapsed/.065,0,1)
		for index,p in ringData.parts do
			local a=(index-1)*math.pi*2/#ringData.parts;local b=index*math.pi*2/#ringData.parts
			local start=cf:PointToWorldSpace(Vector3.new(math.cos(a)*radius,math.sin(a)*radius,0))
			local finish=cf:PointToWorldSpace(Vector3.new(math.cos(b)*radius,math.sin(b)*radius,0))
			p.Size=Vector3.new(if sustained then .055 else .13,if sustained then .055 else .13,(finish-start).Magnitude+.04)
			local direction=(finish-start).Unit
			local up=if math.abs(direction:Dot(Vector3.yAxis))>.98 then Vector3.zAxis else Vector3.yAxis
			p.CFrame=CFrame.lookAt((start+finish)/2,finish,up)
			local opacity=(1-fade)*appearance*(if reduced then .44 else .85)
			p.Transparency=1-opacity
		end
	end
	local action=r.item.MobilityAction or r.item.Action
	if r.motionSource then
		if r.lastRoot and (root.Position-r.lastRoot).Magnitude>30 then for _,trail in r.motionTrails do trail:Clear() end end
		r.motionSource.CFrame=root.CFrame;r.lastRoot=root.Position
		for _,trail in r.motionTrails do trail.Enabled=not reduced and not motion and not r.stoppedAt and age<r.channelDuration and root.AssemblyLinearVelocity.Magnitude>4 end
	end
	for index,m in r.motes do
		local p=m.part
		if r.kind=="Attack" then
			local progress=math.clamp(age/.65,0,1)
			local time=if motion then 0 else age
			local radius=if motion then 2 else (1-progress)*(r.item.Radius or 8)*.7
			p.Position=r.target+Vector3.new(math.cos(m.angle+time*7)*radius,math.sin(time*5+index)*2,math.sin(m.angle+time*7)*radius)
			p.Transparency=if reduced or motion then 1 else progress
		else
			local time=if motion then 0 else age
			local y=if action=="leap" then math.sin(time*3+index)*2 else math.sin(m.angle)*1.8
			p.CFrame=root.CFrame*CFrame.new(math.cos(m.angle+time*3)*1.6,y,2+index*.2)
			p.Transparency=if reduced or motion then 1 else .25+.45*math.clamp(age/r.duration,0,1)
		end
	end
	if r.bolt then
		local t=math.clamp(age/.15,0,1);r.bolt.Position=r.origin:Lerp(r.target,t);r.bolt.Transparency=if t>=1 then 1 else .08
	end
	if r.impactLight then
		local t=age-.13
		r.impactLight.Brightness=if reduced or motion or t<0 then 0 else 1.8*math.clamp(t/.045,0,1)*math.exp(-t*7)
	end
	if r.shield then
		local fade=if r.stoppedAt then math.clamp((os.clock()-r.stoppedAt)/.35,0,1) else 0
		r.shield.Transparency=.91+.09*fade+(if reduced or motion then 0 else .025*math.sin(age*4)*(1-fade))
	end
	if r.highlight and r.stoppedAt then
		local fade=math.clamp((os.clock()-r.stoppedAt)/.35,0,1)
		r.highlight.FillTransparency=.85+.15*fade;r.highlight.OutlineTransparency=.15+.85*fade
	end
end
return Visuals
