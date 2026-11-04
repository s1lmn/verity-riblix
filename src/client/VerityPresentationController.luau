--!nonstrict
local Locale = require(script.Parent.Locale)
-- Own confirmed purchases only. The existing world animator remains the model owner.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Celebration=require(game:GetService("ReplicatedStorage").Shared.VerityUpgradeCelebration)
local Lighting=game:GetService("Lighting")
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Model=require(script.Parent.UIModel)
local Cleanup=require(script.Parent.Cleanup)
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Profile=require(ReplicatedStorage.Shared.VerityAnimationProfile)
local Factory=require(ReplicatedStorage.World.VerityFactory)
local Presentation={}
Presentation.__index=Presentation

local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
function Presentation.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),seen={},order={},count=0},Presentation)
 local layer=W.Frame(ctx.refs.Safe,"VerityReveal");layer.BackgroundTransparency=1;layer.ZIndex=50;layer.Visible=false
 self.layer=layer;self.cleanup:Add(layer)
 local wash=W.Frame(layer,"ColorWash",UDim2.fromScale(1,1),Color3.new(1,1,1))
 wash.ZIndex=50;wash.BackgroundTransparency=1
 self.wash=wash
 self.washGradient=W.New("UIGradient",{
  Rotation=28,
  Transparency=NumberSequence.new({
   NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(.27,.24),
   NumberSequenceKeypoint.new(.53,.84),NumberSequenceKeypoint.new(.72,.34),NumberSequenceKeypoint.new(1,0),
  }),
 },wash)
 local card=W.Round(W.Frame(layer,"DiscoveryCard",UDim2.fromOffset(340,128),T.Paper),20)
 card.AnchorPoint=Vector2.new(.5,1);card.Position=UDim2.new(.5,0,1,-16);card.ZIndex=51
 self.gradient=W.New("UIGradient",{Color=ColorSequence.new(T.Paper,T.Pink:Lerp(T.Paper,.78)),Rotation=20},card)
 local stroke=W.Stroke(card,T.Purple,1.5);stroke.Transparency=.35;self.stroke=stroke
 local tag=W.Text(card,"Eyebrow","НОВАЯ СТУПЕНЬ РОСТА",10,true,T.Purple)
 tag.Position,tag.Size,tag.ZIndex=UDim2.fromOffset(16,10),UDim2.new(1,-32,0,16),52
 local title=W.Text(card,"Title","Verity растёт!",25,true)
 title.Position,title.Size,title.ZIndex=UDim2.fromOffset(16,29),UDim2.new(1,-32,0,32),52
 local detail=W.Text(card,"Detail","",12,false,T.Muted)
 detail.Position,detail.Size,detail.ZIndex=UDim2.fromOffset(16,65),UDim2.new(1,-32,0,34),52
 local track=W.Round(W.Frame(card,"Track",UDim2.new(1,-32,0,4),T.Soft),2)
 track.Position,track.ZIndex=UDim2.fromOffset(16,110),52
 local fill=W.Round(W.Frame(track,"Fill",UDim2.fromScale(0,1),T.Purple),2);fill.ZIndex=53
 self.card,self.title,self.detail,self.tag,self.fill=card,title,detail,tag,fill
 self.confetti={}
 for i=1,18 do
  local piece=W.Round(W.Frame(layer,"Spark",UDim2.fromOffset(5+i%3,9+i%4),({T.Pink,T.Gold,T.Mint,T.Blue})[i%4+1]),2)
  piece.ZIndex=50;piece.Visible=false;self.confetti[i]=piece
 end
 self.cleanup:Add(Run.RenderStepped:Connect(function()self:Tick(os.clock())end))
 self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function()self:Stop()end))
 self.cleanup:Add(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()self:Stop()end))
 self.cleanup:Add(ctx.settings.Changed.Event:Connect(function(values)
  if values.ReducedMotion then self:ReleaseCamera() end
 end))
 return self
end

function Presentation:Has(id) return self.seen[id]==true end

function Presentation:Start(event,model)
 if event.ownerUserId~=Players.LocalPlayer.UserId or self:Has(event.eventId) then return false end
 self:Stop()
 self.seen[event.eventId]=true;table.insert(self.order,event.eventId)
 if #self.order>256 then self.seen[table.remove(self.order,1)]=nil end
 local char=Players.LocalPlayer.Character
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health<=0 or not model:IsDescendantOf(workspace) then return false end
 local now=os.clock()
 local oldColor,newColor=Factory.Color(event.oldLevel),Factory.Color(event.newLevel)
 self.active={event=event,model=model,started=now,oldColor=oldColor,newColor=newColor}
 self.washGradient.Color=ColorSequence.new(newColor,newColor:Lerp(T.Paper,.28))
 self.gradient.Color=ColorSequence.new(oldColor:Lerp(T.Paper,.86),newColor:Lerp(T.Paper,.7))
 self.stroke.Color=newColor:Lerp(T.Ink,.28)
 self.fill.BackgroundColor3=oldColor
 for index,piece in self.confetti do
  piece.BackgroundColor3=({oldColor,newColor,T.Gold,newColor:Lerp(T.Paper,.45)})[index%4+1]
 end
 self.active.look=Celebration.Get(event.newLevel)
 self.ctx.presenting=true;self.ctx.close();self.ctx.refs.Banner.Visible=false
 self.layer.Visible=true;self.count+=1
 self.ctx.refs.Gui:SetAttribute("RevealCount",self.count)
 self.ctx.refs.Gui:SetAttribute("RevealEventId",event.eventId)
 self.ctx.refs.Gui:SetAttribute("RevealActive",true)
 local milestone=Model.NextMilestone(event.oldLevel)
 local special=milestone and milestone.level==event.newLevel
 self:RenderCopy()
 self.ctx.sound:PlayUpgrade(event,true)
 if not self.ctx.settings.values.ReducedEffects and not self.ctx.settings.values.ReducedMotion then
  local glow=Instance.new("Highlight")
  glow.Name="UpgradeGlow";glow.Adornee=model;glow.DepthMode=Enum.HighlightDepthMode.Occluded
  glow.FillColor=newColor;glow.FillTransparency=.8;glow.OutlineColor=T.Paper;glow.OutlineTransparency=.15;glow.Parent=model
  self.active.glow=glow
  if self.active.look.special then
   local color=Instance.new("ColorCorrectionEffect");color.Name="VerityUpgradeColor";color.Parent=Lighting
   self.active.color=color
  end
 end
 local camera=workspace.CurrentCamera
 if camera and not self.ctx.settings.values.ReducedMotion and not game:GetService("VRService").VREnabled and camera.CameraType==Enum.CameraType.Custom then
  self.camera={instance=camera,kind=camera.CameraType,subject=camera.CameraSubject,cf=camera.CFrame,fov=camera.FieldOfView}
  camera.CameraType=Enum.CameraType.Scriptable
  -- Front facing candidates, with an elevated fallback for large rooftop companions.
  self.active.angle=self:ChooseAngle(camera,model,event.newScale)
 end
 self:Tick(now)
 return true
end

function Presentation:CameraPose(camera,model,scale,angle,progress)
 local pivot=model:GetPivot()
 local center=pivot:PointToWorldSpace(Vector3.new(0,.85*model:GetScale(),0))
 local aspect=math.max(.3,camera.ViewportSize.X/math.max(1,camera.ViewportSize.Y))
 local fov=50
 local half=math.min(math.rad(fov/2),math.atan(math.tan(math.rad(fov/2))*aspect))
 local radius=scale*(1.95-.7*smooth((progress-.69)/.31))
 local distance=math.max(5,radius/math.sin(half))*1.18
 local height=math.max(1,camera.ViewportSize.Y)
 distance*=1+.25*math.clamp((500-height)/250,0,1)
 local arc=angle+(smooth(progress)-.5)*.22
 local direction=pivot:VectorToWorldSpace(Vector3.new(math.sin(arc),if angle==math.pi then 1.6 else .22,-math.cos(arc))).Unit
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 local ignore={model};local char=Players.LocalPlayer.Character;if char then table.insert(ignore,char)end
 local effects=workspace:FindFirstChild("VerityEffects");if effects then table.insert(ignore,effects)end
 params.FilterDescendantsInstances=ignore
 local hit=workspace:Raycast(center,direction*distance,params)
 local clearance=if hit then math.max(.25,hit.Distance-.4) else distance
 local position=center+direction*math.min(distance,clearance)
 -- Keep the face above the caption, including on short landscape viewports.
 local drop=(position-center).Magnitude*math.tan(math.rad(fov/2))*math.min(.34,112/height)
 return CFrame.lookAt(position,center-Vector3.new(0,drop,0)),clearance/distance,fov
end

function Presentation:ChooseAngle(camera,model,scale)
 local best,bestScore=0,-math.huge
 for i,angle in {0,-.6,.6,-1.15,1.15,math.pi} do
  local _,clearance=self:CameraPose(camera,model,scale,angle,0)
  local score=clearance-(i-1)*.025
  if score>bestScore then best,bestScore=angle,score end
 end
 return best
end

function Presentation:Complete(event)
 local a=self.active
 if not a or a.event.eventId~=event.eventId then return end
 a.completed=os.clock()
 self:RenderCopy()
end

function Presentation:RenderCopy()
 local active=self.active
 if not active then return end
 local event=active.event
 local milestone=Model.NextMilestone(event.oldLevel)
 local special=milestone and milestone.level==event.newLevel
 self.tag.Text=Locale.Text(if special then "ОТКРЫТА НОВАЯ СТУПЕНЬ" else "ТВОЙ СПУТНИК СТАНОВИТСЯ БОЛЬШЕ")
 if active.completed then
  self.title.Text=Locale.Text("Знакомься: Verity ")..event.newLevel.."!"
  self.detail.Text=string.format(Locale.Text("УРОВЕНЬ %d   •   РАЗМЕР %.2f×\nЕщё больше радости. Ещё больше дохода."),event.newLevel,event.newScale)
 else
  self.title.Text=Locale.Text("Verity растёт!")
  self.detail.Text=string.format(Locale.Text("Уровень %d → %d   •   Размер %.2f× → %.2f×"),event.oldLevel,event.newLevel,event.oldScale,event.newScale)
 end
end

function Presentation:Tick(now)
 local a=self.active;if not a then return end
 local char=Players.LocalPlayer.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health<=0 or not a.model:IsDescendantOf(workspace) or now-a.started>5 then self:Stop();return end
 local age=now-a.started
 local impactAge=age-a.look.duration*Profile.Bloom
 local subtle=self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.ReducedMotion
 local pulse=if subtle then 0 else Celebration.Pulse(impactAge)
 if a.completed and now-a.completed>1.25 then self:Stop();return end
 local size=self.ctx.refs.Safe.AbsoluteSize
 local short=size.Y<400
 self.card.Size=UDim2.fromOffset(math.max(120,math.min(size.X-24,380)),if short then 110 else 128)
 self.card.Position=UDim2.new(.5,0,1,-(if short then 6 else 16))
 self.title.TextSize=if short then 20 else 25
 self.detail.Position=UDim2.fromOffset(16,if short then 60 else 65)
 self.fill.Parent.Position=UDim2.new(0,16,1,-14)
 local progress=math.clamp(age/Profile.Duration(a.event.newLevel),0,1)
 local hue=smooth((progress-.16)/.53)
 local glow=Profile.Glow(progress)
 local reduced=self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.ReducedMotion
 self.wash.Visible=not reduced
 self.wash.BackgroundTransparency=1-glow*.32-(if a.look.special then pulse*.06 else 0)
 self.washGradient.Rotation=24+smooth(progress)*34
 self.fill.Size=UDim2.fromScale(if a.completed then 1 else progress,1)
 self.fill.BackgroundColor3=a.oldColor:Lerp(a.newColor,hue)
 if self.camera then
  local saved=self.camera;local camera=saved.instance
  if camera.CameraType~=Enum.CameraType.Scriptable then self.camera=nil;self:Stop();return end
  local pose,_,fov=self:CameraPose(camera,a.model,a.event.newScale,a.angle or 0,progress)
  local x,y,roll=Celebration.Shake(impactAge,a.event.newLevel,subtle)
  camera.FieldOfView=fov-(if a.look.special then pulse*2 else 0)
  -- Apply to a fresh pose: never accumulate shake or fight another camera owner.
  camera.CFrame=pose*CFrame.new(x,y,0)*CFrame.Angles(0,0,roll);camera.Focus=a.model:GetPivot()
 end
 if a.glow then
  if self.ctx.settings.values.ReducedEffects or self.ctx.settings.values.ReducedMotion then
   a.glow:Destroy();a.glow=nil
  else
   local flare=glow
   a.glow.OutlineColor=a.newColor:Lerp(T.Paper,.48)
   a.glow.FillTransparency=.96-flare*.18
   a.glow.OutlineTransparency=.82-flare*.55
  end
 end
 if a.color then
  a.color.TintColor=Color3.new(1,1,1):Lerp(a.newColor,pulse*.12)
  a.color.Saturation=pulse*.15
  a.color.Brightness=pulse*.035
 end
 local burstAge=a.completed and now-a.completed
 for i,piece in self.confetti do
  piece.Visible=burstAge~=nil and burstAge<1.1 and not self.ctx.settings.values.ReducedEffects and not self.ctx.settings.values.ReducedMotion
  if piece.Visible then
   local x=(i/19-.5)*.8
   piece.Position=UDim2.fromScale(.5+x*(.3+burstAge),.3+burstAge*.24+(i%3)*.04)
   piece.Rotation=i*37+burstAge*90;piece.BackgroundTransparency=math.clamp((burstAge-.55)/.55,0,1)
  end
 end
end

function Presentation:ReleaseCamera()
 local saved=self.camera;self.camera=nil;if not saved then return end
 local camera=saved.instance
 if workspace.CurrentCamera~=camera or camera.CameraType~=Enum.CameraType.Scriptable then return end
 local char=Players.LocalPlayer.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
 camera.FieldOfView=saved.fov;camera.CFrame=saved.cf
 camera.CameraSubject=hum or saved.subject;camera.CameraType=saved.kind
end

function Presentation:Stop()
 self:ReleaseCamera()
 local a=self.active
 if a then self.ctx.sound:StopUpgrade(a.event.eventId) end
 if a and a.glow then a.glow:Destroy()end
 if a and a.color then a.color:Destroy()end
 self.active=nil;self.ctx.presenting=false;self.layer.Visible=false
 self.ctx.refs.Gui:SetAttribute("RevealActive",false)
end
function Presentation:Destroy()self:Stop();self.cleanup:Destroy()end
return Presentation
