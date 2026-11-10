--!nonstrict
local Locale = require(script.Parent.Locale)
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Pathfinding=game:GetService("PathfindingService")
local CollectionService=game:GetService("CollectionService")
local MobileHUD=require(script.Parent.MobileHUDLayout)
local ActivityCard=require(script.Parent.ActivityCard)
local CommunityConfig=require(game:GetService("ReplicatedStorage").Shared.CommunityConfig)
local GUIDE_COLOR=Color3.fromHex("FFEB00")
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Goals=require(script.Parent.GuidanceModel)
local Tutorial={};Tutorial.__index=Tutorial
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function validPosition(v)
 return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z and v.Magnitude<1e7
end
local function piece(parent,name)
 local p=Instance.new("Part");p.Name=name;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=Enum.Material.Neon;p.Color=GUIDE_COLOR;p.Transparency=1;p.Size=Vector3.new(.2,.07,1.3);p.Parent=parent;return p
end
local function visible(object,ignoreClip)
 local node=object
 while node do
  if node:IsA("GuiObject") and not node.Visible then return false end
  if node:IsA("ScrollingFrame") and not ignoreClip then
   local center=object.AbsolutePosition+object.AbsoluteSize/2
   local a,b=node.AbsolutePosition,node.AbsolutePosition+node.AbsoluteSize
   if center.X<a.X or center.X>b.X or center.Y<a.Y or center.Y>b.Y then return false end
  end
  node=node.Parent
 end
 return object:IsDescendantOf(Players.LocalPlayer.PlayerGui)
end
function Tutorial.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),arrows={},indicators={},nextPathAt=0,generation=0,dead=false},Tutorial)
 for _,panel in ctx.refs.Panels do panel.Subtitle.Visible=false end
 self.folder=self.cleanup:Add(Instance.new("Folder"));self.folder.Name="VerityGuidance";self.folder.Parent=workspace
 self.anchor=piece(self.folder,"GoalMarker");self.anchor.Size=Vector3.one*.1
 self.pin=Instance.new("BillboardGui");self.pin.Name="GoalPin";self.pin.Size=UDim2.fromOffset(200,104)
 self.pin.StudsOffsetWorldSpace=Vector3.new(0,4,0);self.pin.AlwaysOnTop=true;self.pin.MaxDistance=1500;self.pin.Enabled=false;self.pin.Parent=self.anchor
 self.pinTitle=W.Text(self.pin,"Target","",13,true,T.Ink);self.pinTitle.Size=UDim2.new(1,0,0,27)
 self.pinTitle.TextXAlignment=Enum.TextXAlignment.Center;self.pinTitle.TextStrokeColor3=T.White;self.pinTitle.TextStrokeTransparency=.1
 local down=W.Text(self.pin,"Arrow","▼",66,true,GUIDE_COLOR);down.Position=UDim2.fromOffset(0,25);down.Size=UDim2.new(1,0,0,76)
 down.TextXAlignment=Enum.TextXAlignment.Center;down.TextStrokeColor3=T.Ink;down.TextStrokeTransparency=.25
 self.highlight=Instance.new("Highlight");self.highlight.Name="CurrentGoal";self.highlight.FillColor=GUIDE_COLOR;self.highlight.OutlineColor=GUIDE_COLOR
 self.highlight.FillTransparency=.78;self.highlight.OutlineTransparency=0;self.highlight.Enabled=false;self.highlight.Parent=self.folder
 self.compass=W.Text(ctx.refs.Tutorial,"Compass","↑",34,true,GUIDE_COLOR)
 self.compass.AnchorPoint=Vector2.new(.5,.5);self.compass.Position=UDim2.new(1,-22,.5,0);self.compass.Size=UDim2.fromOffset(32,32);self.compass.Visible=false
 ctx.refs.Direction.Visible=false
 self.pointer=self.cleanup:Add(W.Frame(ctx.refs.Safe,"ButtonGuide"))
 self.pointer.BackgroundTransparency=1;self.pointer.ZIndex=40;self.pointer.Visible=false
 self.focusGlow=W.Round(W.Frame(self.pointer,"SoftFocus"),17)
 self.focusGlow.BackgroundTransparency=1;self.focusGlow.AnchorPoint=Vector2.new(.5,.5)
 self.focusGlow.ZIndex=1
 self.focusGlowStroke=W.Stroke(self.focusGlow,T.Gold,5);self.focusGlowStroke.Transparency=.78
 self.focus=W.Round(W.Frame(self.pointer,"Focus"),14)
 self.focus.BackgroundTransparency=1;self.focus.AnchorPoint=Vector2.new(.5,.5);self.focus.ZIndex=2
 self.focusStroke=W.Stroke(self.focus,T.Gold,2.5);self.focusStroke.Transparency=.05

 self.markerShadow=W.Round(W.Frame(self.pointer,"MarkerShadow",UDim2.fromOffset(34,28),T.Purple),14)
 self.markerShadow.AnchorPoint=Vector2.new(.5,.5);self.markerShadow.BackgroundTransparency=.82;self.markerShadow.ZIndex=3
 self.marker=W.Round(W.Frame(self.pointer,"Marker",UDim2.fromOffset(34,28),T.Paper),14)
 self.marker.AnchorPoint=Vector2.new(.5,.5);self.marker.ZIndex=4
 W.Stroke(self.marker,T.Gold,1.5).Transparency=.08
 W.New("UIGradient",{Color=ColorSequence.new(T.White,Color3.fromHex("FFE89A")),Rotation=95},self.marker)
 self.markerScale=W.New("UIScale",{Scale=1},self.marker)
 self.chevron=W.Frame(self.marker,"Chevron",UDim2.fromOffset(14,14))
 self.chevron.AnchorPoint=Vector2.new(.5,.5);self.chevron.Position=UDim2.fromScale(.5,.5)
 self.chevron.BackgroundTransparency=1;self.chevron.ZIndex=5
 for index,angle in {-45,45} do
  local arm=W.Round(W.Frame(self.chevron,"Arm",UDim2.fromOffset(10,3),T.Ink),2)
  arm.AnchorPoint=Vector2.new(.5,.5);arm.Position=UDim2.fromOffset(7,if index==1 then 4 else 10)
  arm.Rotation=angle;arm.ZIndex=6
 end
 local elapsed=0
 self.cleanup:Add(RunService.RenderStepped:Connect(function(dt)
  elapsed+=dt;if elapsed<1/30 then return end;elapsed=0;self:Update(os.clock())
 end))
 return self
end
function Tutorial:SetButton(button)
 if self.button==button then return end
 self.button=button
 if button then
  local node=button.Parent
  while node and node~=self.ctx.refs.Gui do
   if node:IsA("ScrollingFrame") then
    local top=button.AbsolutePosition.Y-node.AbsolutePosition.Y
    if top<0 or top+button.AbsoluteSize.Y>node.AbsoluteSize.Y then
     local maximum=math.max(0,node.AbsoluteCanvasSize.Y-node.AbsoluteSize.Y)
     node.CanvasPosition=Vector2.new(node.CanvasPosition.X,math.clamp(node.CanvasPosition.Y+top-node.AbsoluteSize.Y*.35,0,maximum))
    end
   end
   node=node.Parent
  end
 end
end
function Tutorial:ShowButtonGuide(button,now)
 local safe=self.ctx.refs.Safe
 local position=button.AbsolutePosition-safe.AbsolutePosition
 local size=button.AbsoluteSize
 local center=position+size/2
 local reduced=self.ctx.settings.values.ReducedMotion
 local pulse=if reduced then 0 else .5+.5*math.sin(now*3)

 self.focus.Position=UDim2.fromOffset(center.X,center.Y)
 self.focus.Size=UDim2.fromOffset(size.X+6,size.Y+6)
 self.focusGlow.Position=self.focus.Position
 self.focusGlow.Size=UDim2.fromOffset(size.X+14+pulse*2,size.Y+14+pulse*2)
 self.focusGlowStroke.Transparency=.82-pulse*.09

 local x,y,rotation
 if size.X<=64 then
  self.marker.Size=UDim2.fromOffset(24,24)
  x,y=position.X+size.X-4,position.Y+size.Y-4
  rotation=45
 else
  self.marker.Size=UDim2.fromOffset(34,28)
  y=center.Y
  if position.X+size.X+42<safe.AbsoluteSize.X then
   x=position.X+size.X+24;rotation=0
  elseif position.X>=42 then
   x=position.X-24;rotation=180
  else
   x=position.X+size.X-16;y=position.Y+size.Y-8;rotation=45
  end
  x+=if reduced then 0 elseif rotation==180 then -pulse*2 else pulse*2
 end
 self.marker.Position=UDim2.fromOffset(x,y)
 self.markerShadow.Position=UDim2.fromOffset(x,y+2)
 self.markerShadow.Size=self.marker.Size
 self.markerScale.Scale=1+pulse*.035
 self.chevron.Rotation=rotation
 self.pointer.Visible=true
end

function Tutorial:UIButton(key)
 local refs=self.ctx.refs;local group,name=key:match("^([^%.]+)%.(.+)$")
 if group=="Nav" then
  if (name=="WORKSHOP" or name=="ABILITIES" or name=="COSMETICS") and self.ctx.active~="MORE" then return refs.Nav.MORE end
  return refs.Nav[name]
 end
 if group=="HUD" then return refs[name] end
 if group=="Phone" then return refs.Panels.PHONE[name] end
 if group=="Verity" then return refs.Panels.VERITY.Buy end
 if group=="Task" then return refs.Panels.TASKS.Rows[name].Button end
 if group=="Ability" then
  local rows=refs.Panels.ABILITIES.Rows
  return rows and rows[name] and rows[name].button
 end
 if key=="Close" and self.ctx.active then return refs.Panels[self.ctx.active].Close end
end
function Tutorial:ClosestHouse(root,now)
 local cached=self.houseGoal
 local available=cached and cached.object.Parent and (cached.object:GetAttribute("OwnerUserId") or 0)==0
  and cached.prompt.Parent and cached.prompt.Enabled
 if available and now<(self.houseScanAt or 0) then return cached end
 self.houseScanAt=now+.5
 local nearest,best=nil,math.huge
 for _,pad in CollectionService:GetTagged("VerityPurchasePad") do
  if pad:IsA("Model") and pad:GetAttribute("PurchaseKind")=="Claim" and pad.PrimaryPart
   and pad:IsDescendantOf(workspace) and (pad:GetAttribute("OwnerUserId") or 0)==0 then
   local reference=pad:FindFirstChild("Prompt")
   local prompt=reference and reference.Value
   if prompt and prompt:IsA("ProximityPrompt") and prompt.Enabled then
    local position=pad.PrimaryPart.Position
    local distance=flat(position-root.Position).Magnitude
    if distance<best then
     best=distance
     nearest={id="house:"..tostring(pad:GetAttribute("PlotId")),kind="World",target="House",
      title="Займи дом",detail="",near="%s · Занять дом",touch="Занять дом",
      radius=7,prompt=prompt,position=position,object=pad}
    end
   end
  end
 end
 self.houseGoal=nearest
 return nearest
end

function Tutorial:Attention(button,enabled,symbol,now)
 local indicator=self.indicators[button]
 if not indicator and not enabled then return end
 if not indicator then
  local badge=W.Text(button,"ActionReady",symbol,15,true,T.Ink)
  badge.AnchorPoint=Vector2.new(1,0);badge.Position=UDim2.new(1,-2,0,2)
  badge.Size=UDim2.fromOffset(20,20);badge.TextXAlignment=Enum.TextXAlignment.Center
  badge.BackgroundColor3=GUIDE_COLOR;badge.BackgroundTransparency=0
  badge.ZIndex=button.ZIndex+3;W.Round(badge,10)
  local stroke=W.Stroke(button,GUIDE_COLOR,3);stroke.Transparency=0
  self.cleanup:Add(badge);self.cleanup:Add(stroke)
  indicator={badge=badge,stroke=stroke};self.indicators[button]=indicator
 end
 indicator.badge.Visible=enabled
 indicator.stroke.Enabled=enabled
 if enabled then
  indicator.badge.Text=symbol
  indicator.stroke.Thickness=if self.ctx.settings.values.ReducedMotion then 3.5 else 3.5+.7*math.sin(now*3)
 end
end

function Tutorial:RefreshAttention(now,blocked)
 local ctx=self.ctx;local state=ctx.net.state
 local ready=not blocked and state and state.VerityUnlocked and ctx.net.connected and not ctx.net:IsBusy()
 local canGrow=ready and state.VerityLevel<100 and state.NextVerityUpgradeCost and state.Cash>=state.NextVerityUpgradeCost or false
 self:Attention(ctx.refs.Nav.VERITY,canGrow,"↑",now)
 self:Attention(ctx.refs.Panels.VERITY.Buy,canGrow,"↑",now)
 self:Attention(ctx.refs.Panels.PHONE.Grow,canGrow,"↑",now)

 local canBuild=ready and state.TutorialCompleted and Goals.ReadyHomeUpgrade(state)~=nil or false
 local canChoose=ready and state.TutorialCompleted and Goals.ReadyAbility(state)~=nil or false
 self:Attention(ctx.refs.Nav.WORKSHOP,canBuild,"↑",now)
 self:Attention(ctx.refs.Nav.ABILITIES,canChoose,"!",now)
end

function Tutorial:Target(goal)
 if goal.target=="HousePurchase" then
  local state=self.ctx.net.state
  for _,pad in CollectionService:GetTagged("VerityPurchasePad") do
   if pad:GetAttribute("PlotId")==state.PlotId and pad:GetAttribute("PurchaseKind")==goal.purchaseKind and pad.PrimaryPart then
    return pad.PrimaryPart.Position,pad
   end
  end
  return nil
 end
 if goal.object and goal.object.Parent then return goal.position,goal.object end
 if goal.target=="StreetParcel" then
  local folder=workspace:FindFirstChild("VerityStreetDelivery")
  local anchor=folder and folder:FindFirstChild("ParcelClaim")
  local visuals=workspace:FindFirstChild("StreetDeliveryVisuals")
  local parcel=visuals and visuals:FindFirstChild("FallenGift")
  if anchor then return anchor.Position,parcel end
  return nil
 end
 if goal.target=="Delivery" then
  local state=self.ctx.net.state;local id=state and state.PlotId
  local plots=workspace:FindFirstChild("CorePlots")
  local plot=type(id)=="number" and plots and plots:FindFirstChild(string.format("Plot_%02d",id))
  local box=plot and plot:FindFirstChild("CoreDeliveryBox")
  if validPosition(state and state.DeliveryPosition) then return state.DeliveryPosition,box end
  if box then return box.Position,box end
 else
  local interactions=workspace:FindFirstChild("GameplayInteractions");local part=interactions and interactions:FindFirstChild(goal.target)
  if validPosition(goal.position) then return goal.position,part end
  if part then return part.Position,part end
 end
end
function Tutorial:HideArrows()
 for _,arrow in self.arrows do for _,p in arrow do p.Transparency=1 end end
end
function Tutorial:HideWorld()
 self.pin.Enabled=false;self.highlight.Enabled=false;self:HideArrows()
end
function Tutorial:ClearRoute()
 if self.targetKey then self.generation+=1;self.job=nil end
 self.targetKey=nil;self.route=nil;self.nextPathAt=0;self:HideWorld()
end
function Tutorial:ComputeRoute(root,position,now)
 if self.goal and self.goal.air then
  self.route=nil;self.ctx.refs.Gui:SetAttribute("GuidancePathStatus","AirRoute");return
 end
 if self.job or now<self.nextPathAt then return end
 if self.route then
  local index=self.routeIndex or 2
  local a=self.route[index-1].Position
  local b=self.route[index].Position
  local segment=flat(b-a)
  local offset=flat(root.Position-a)
  local fraction=math.clamp(offset:Dot(segment)/math.max(segment:Dot(segment),.01),0,1)
  if (offset-segment*fraction).Magnitude<6 and math.abs(root.Position.Y-(a.Y+(b.Y-a.Y)*fraction))<8 then return end
  self.route=nil
 end
 self.nextPathAt=now+1.5
 local humanoid=root.Parent:FindFirstChildOfClass("Humanoid")
 local height=math.clamp(math.ceil((humanoid and humanoid.HipHeight or 2)+root.Size.Y+2),5,8)
 local job={generation=self.generation,start=root.Position};self.job=job
 local target=position+Vector3.new(0,1.5,0);self.ctx.refs.Gui:SetAttribute("GuidancePathStatus","Computing")
 task.spawn(function()
  local waypoints
  for _,allowJump in {false,true} do
   if self.dead or self.job~=job then return end
   local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=height,AgentCanJump=allowJump,WaypointSpacing=5})
   local ok=pcall(function()path:ComputeAsync(job.start,target)end)
   if ok and path.Status==Enum.PathStatus.Success then
    local result=path:GetWaypoints()
    if #result>=2 then waypoints=result end
   end
   path:Destroy();if waypoints then break end
  end
  if self.dead or self.job~=job or job.generation~=self.generation then return end
  self.job=nil;self.route=waypoints;self.routeIndex=2
  self.ctx.refs.Gui:SetAttribute("GuidancePathStatus",if waypoints then "Success" else "NoPath")
 end)
end
function Tutorial:DrawRoute(root,now)
 if self.lastDrawAt and now-self.lastDrawAt<.1 then return end
 self.lastDrawAt=now
 self:HideArrows()
 if self.goal and self.goal.air and validPosition(self.targetPosition) then
  local from=root.Position+Vector3.yAxis
  local delta=self.targetPosition-from
  if delta.Magnitude<3 then return end
  local direction=delta.Unit
  local up=if math.abs(direction:Dot(Vector3.yAxis))>.95 then Vector3.zAxis else Vector3.yAxis
  for i=1,5 do
   local distance=3+(i-1)*5.5;if distance>delta.Magnitude-1 then break end
   local arrow=self.arrows[i]
   if not arrow then arrow={piece(self.folder,"RouteStem"),piece(self.folder,"RouteHead"),piece(self.folder,"RouteHead")};self.arrows[i]=arrow end
   local position=from+direction*distance
   local frame=CFrame.lookAt(position,position+direction,up)
   arrow[1].Size=Vector3.new(.65,.22,2.5);arrow[1].CFrame=frame*CFrame.new(0,0,.5)
   arrow[2].Size=Vector3.new(.65,.22,1.9);arrow[2].CFrame=frame*CFrame.new(-.62,0,-.7)*CFrame.Angles(0,-math.pi/4,0)
   arrow[3].Size=arrow[2].Size;arrow[3].CFrame=frame*CFrame.new(.62,0,-.7)*CFrame.Angles(0,math.pi/4,0)
   for _,p in arrow do p.Transparency=.08 end
  end
  return
 end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.RespectCanCollide=true
 local objects={workspace.Terrain}
 for _,name in {"GeneratedWorld","GameplayInteractions"}do local object=workspace:FindFirstChild(name);if object then table.insert(objects,object) end end
 params.FilterDescendantsInstances=objects
 local route=self.route
 if not route or #route<2 then
  local target=self.targetPosition
  if not validPosition(target) then return end
  local aim=Vector3.new(target.X,root.Position.Y,target.Z)
  if (aim-root.Position).Magnitude>18 or workspace:Raycast(root.Position,aim-root.Position,params) then return end
  route={{Position=root.Position},{Position=target}}
 end
 local index=self.routeIndex or 2
 while index<#route do
  local p=route[index].Position
  if flat(p-root.Position).Magnitude>3.5 or math.abs(p.Y-root.Position.Y)>6 then break end
  index+=1
 end
 self.routeIndex=index
 local points={root.Position};for i=index,#route do table.insert(points,route[i].Position) end
 local segment,distance=1,4
 for i=1,6 do
  while segment<#points and flat(points[segment+1]-points[segment]).Magnitude<distance do
   distance-=flat(points[segment+1]-points[segment]).Magnitude;segment+=1
  end
  if segment>=#points then break end
  local delta=flat(points[segment+1]-points[segment]);local length=delta.Magnitude;if length<.01 then break end
  local point=points[segment]:Lerp(points[segment+1],distance/length)
  local hit=workspace:Raycast(point+Vector3.new(0,4,0),Vector3.new(0,-16,0),params)
  if hit and hit.Normal.Y>.65 and hit.Position.Y<=point.Y+1.5 then
   local arrow=self.arrows[i]
   if not arrow then arrow={piece(self.folder,"RouteStem"),piece(self.folder,"RouteHead"),piece(self.folder,"RouteHead")};self.arrows[i]=arrow end
   local cf=CFrame.lookAt(hit.Position+Vector3.new(0,.22,0),hit.Position+Vector3.new(0,.22,0)+delta.Unit)
   arrow[1].Size=Vector3.new(.95,.18,3.1)
   arrow[1].CFrame=cf*CFrame.new(0,0,.65)
   arrow[2].Size=Vector3.new(.82,.18,2.6)
   arrow[2].CFrame=cf*CFrame.new(-.84,0,-.95)*CFrame.Angles(0,-math.pi/4,0)
   arrow[3].Size=arrow[2].Size
   arrow[3].CFrame=cf*CFrame.new(.84,0,-.95)*CFrame.Angles(0,math.pi/4,0)
   for _,p in arrow do p.Transparency=0 end
  end
  distance+=6.5
 end
 local waypoint=route[self.routeIndex]
 if waypoint and waypoint.Action==Enum.PathWaypointAction.Jump and flat(waypoint.Position-root.Position).Magnitude<6 then
  self:HintText(if Input.PreferredInput==Enum.PreferredInput.Touch then "Прыжок ↑"
   elseif Input.PreferredInput==Enum.PreferredInput.Gamepad then "A · Прыжок" else "ПРОБЕЛ · Прыжок")
 end
end
function Tutorial:Render()
 local ctx=self.ctx;local player=Players.LocalPlayer
 local now=os.clock()
 if ctx.homeRouteRequested and not ctx.active and not ActivityCard.ActivityRunning() then
  local kiosk
  for _,candidate in CollectionService:GetTagged("VerityHomeStyling") do
   if candidate:GetAttribute("PlotId")==player:GetAttribute("HousePlotId") then kiosk=candidate;break end
  end
  local state=ctx.net.state
  local position=if kiosk then kiosk.Position elseif state then state.HomeStylePosition else nil
  if validPosition(position) then
   self.goal={id="home-styling",kind="World",target="HomeStyle",object=kiosk,position=position,
    title="Обустрой свой дом",detail="",near="%s · Применить стиль",touch="Применить стиль",prompt=true,radius=6}
   self:Update(now);return
  end
 end
 local adventureGoal=ctx.adventures and ctx.adventures:Goal()
 if adventureGoal then self.goal=adventureGoal;self:Update(now);return end
 local forgeGoal=ctx.forge and ctx.forge:Goal()
 if forgeGoal then self.goal=forgeGoal;self:Update(now);return end
 local communityGoal=ctx.community and ctx.community:Goal()
 if communityGoal then self.goal=communityGoal;self:Update(now);return end
 local secretGoal=ctx.secrets and ctx.secrets:Goal()
 if secretGoal then self.goal=secretGoal;self:Update(now);return end
 local diversion=ctx.diversions and ctx.diversions.run
 if diversion and diversion.kind=="Hunt" and diversion.phase=="Playing" then
  local target=ctx.diversions.target
  self.goal={id="spark:"..diversion.round..":"..diversion.count,kind="World",target="Spark",
   object=target,position=target.Position,title="Собери искру",detail="",near="Коснись искры",radius=2.5}
  self:Update(now);return
 end
 if player:GetAttribute("HouseSelectionReady") and not player:GetAttribute("HousePlotId") and not ctx.active then
  local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
  self.goal=if root then self:ClosestHouse(root,now) else nil
  self.goal=self.goal or {id="house-loading",kind="Wait",title="Ищем свободный дом",detail=""}
 else
  local state=ctx.net.state
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  local nearestTask,best=nil,math.huge
  if state and root then
   for _,entry in state.Tasks or {} do
    if entry.status=="Ready" and validPosition(entry.targetPosition) then
     local distance=flat(entry.targetPosition-root.Position).Magnitude
     if distance<best then nearestTask,best=entry.taskId,distance end
    end
   end
  end
  self.goal=Goals.Resolve(state,ctx.active,ctx.tasks and ctx.tasks.selectedTaskId,workspace:GetServerTimeNow(),nearestTask)
  local delivery=workspace:FindFirstChild("VerityStreetDelivery")
  local community=ctx.community and ctx.community.message
  if state and state.TutorialCompleted and self.goal and self.goal.id:match("^start:") and not ctx.active
   and community and community.joinable and not player:GetAttribute("VerityCommunityTried") and (state.TaskCompletedCount or 0)>=2 then
   local model=ctx.community:Model();local join=model and model:FindFirstChild("Join")
   if join then
    self.goal={id="community-join:"..(community.variant or "light"),kind="World",target="CommunityJoin",object=join,position=join.Position,
     title=CommunityConfig.Variants[community.variant or "light"].Name,detail="",near="%s · Помочь району",touch="Помочь району",prompt=true,radius=6}
   end
  end
  if state and state.TutorialCompleted and self.goal and self.goal.id:match("^start:")
   and (state.TaskCompletedCount or 0)>0 and state.TaskCompletedCount%3==0
   and not ctx.active and not (state.Progression and state.Progression.stage=="FirstActivity") then
   local kinds=if player:GetAttribute("VerityLastDiversionKind")=="Hunt" then {"Rhythm","Hunt"} else {"Hunt","Rhythm"}
   local world=workspace:FindFirstChild("GeneratedWorld")
   local stations=world and world:FindFirstChild("VerityDiversions")
   for _,kind in kinds do
    local station=stations and stations:FindFirstChild(kind.."Station")
    if station and workspace:GetServerTimeNow()>=(player:GetAttribute("Verity"..kind.."ReadyAt") or 0) then
     self.goal={id="diversion:"..kind,kind="World",target="Diversion",object=station,position=station.Position,
      title=if kind=="Hunt" then "Охота за искрами" else "Реакторный ритм",detail="",near="%s · Начать",touch="Начать",prompt=true,radius=7}
     break
    end
   end
  end
  if not ctx.active and self.goal and self.goal.id:match("^start:") and state and state.TutorialCompleted
   and not (state.Progression and state.Progression.stage=="FirstActivity")
   and delivery and delivery:GetAttribute("Phase")=="Collect" then
   self.goal={id="street-parcel",kind="World",target="StreetParcel",title="Забери посылку",detail="",
    near="%s · Подобрать",touch="Подобрать",prompt=true,radius=7}
  end
 end
 self:Update(now)
end

function Tutorial:HintText(text)
 self.ctx.refs.TutorialText.Text=Locale.Text(text)
end

function Tutorial:Update(now)
 if self.dead then return end
 local ctx,goal=self.ctx,self.goal
 local player=Players.LocalPlayer
 local char=player.Character
 local root=char and char:FindFirstChild("HumanoidRootPart")
 local hum=char and char:FindFirstChildOfClass("Humanoid")
 local alive=root and hum and hum.Health>0
 local activity=ActivityCard.ActivityRunning()
 local hunt=player:GetAttribute("VerityDiversionKind")=="Adventure" or player:GetAttribute("VerityDiversionKind")=="Hunt" or player:GetAttribute("VerityDiversionKind")=="Community"
 local blocked=ctx.presenting or ctx.forgeReveal or ctx.rewardOverlay or (activity and not hunt) or not alive
 self:RefreshAttention(now,blocked or activity)
 if blocked then
  ctx.refs.Tutorial.Visible=false;self.pointer.Visible=false;self.compass.Visible=false
  self:SetButton(nil);self:HideWorld();return
 end
 local touch=MobileHUD.IsTouch()
 local adventure=ctx.adventures
 local covered=touch and (activity or adventure and (adventure.card.Visible or adventure.dock.Visible and adventure.weatherExpanded))
 ctx.refs.Tutorial.Visible=goal~=nil and alive~=nil and alive~=false and not covered
  and ctx.active~="TASKS" and not (ctx.active and (touch or ctx.refs.Safe.AbsoluteSize.X<640))
 self.pointer.Visible=false;self.compass.Visible=false
 if not goal or not alive then self.lastRootPosition=nil;self:SetButton(nil);self:ClearRoute();return end
 if self.lastRootPosition and (root.Position-self.lastRootPosition).Magnitude>16 then self:ClearRoute() end
 self.lastRootPosition=root.Position
 ctx.refs.Gui:SetAttribute("GuidanceGoal",goal.id);ctx.refs.Gui:SetAttribute("GuidanceKind",goal.kind)
 ctx.refs.GuideTitle.Text=Locale.Text(goal.title);self:HintText(goal.detail)
 ctx.refs.TutorialText.Size=UDim2.new(1,if goal.kind=="World" then -54 else -16,1,if ctx.refs.Safe.AbsoluteSize.Y<360 and not touch then -22 else -25)
 if goal.kind=="UI" then
  self:ClearRoute();local button=self:UIButton(goal.target)
  if not button or not visible(button,true) then
   if ctx.active then button=ctx.refs.Panels[ctx.active].Close;self:HintText("Закрой окно") end
  end
  if ctx.net:IsBusy() and not goal.target:match("^Nav%.") and goal.target~="Close" then
   self:HintText("Подожди…");self:SetButton(nil);return
  end
  self:SetButton(button)
  if not button then return end
  if not visible(button) then self:HintText("Прокрути ↓");return end
  self:ShowButtonGuide(button,now);return
 end
 self:SetButton(nil);if ctx.active or goal.kind~="World" then self:ClearRoute();return end
 local position,part=self:Target(goal)
 if not validPosition(position) then self:ClearRoute();self:HintText("Подожди…");return end
 if self.targetKey~=goal.id or not self.targetPosition or (self.targetPosition-position).Magnitude>1 then
  self:ClearRoute();self.targetKey=goal.id;self.targetPosition=position;self.generation+=1
 end
 local delta=position-root.Position;local near=flat(delta).Magnitude<=goal.radius and math.abs(delta.Y)<6
 if near and (goal.target=="Delivery" or goal.prompt) then
  local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.RespectCanCollide=true
  local world=workspace:FindFirstChild("GeneratedWorld")
  ray.FilterDescendantsInstances=if world then {world} else {}
  local from=root.Position+Vector3.new(0,1,0)
  near=workspace:Raycast(from,position+Vector3.new(0,1.5,0)-from,ray)==nil
 end
 if near then
  local key=if Input.PreferredInput==Enum.PreferredInput.Gamepad then "X" else "E"
  local hint=Locale.Text(goal.near or goal.detail)
  self:HintText(if hint:find("%s",1,true) then string.format(hint,key) else hint)
  if Input.PreferredInput==Enum.PreferredInput.Touch then
   if goal.target=="Delivery" and ctx.net.state.DeliveryState=="Delivered" then self:HintText("Распаковать")
   elseif goal.touch then self:HintText(goal.touch) end
  end
 else self:HintText("→ "..math.max(1,math.round(delta.Magnitude*.28))..Locale.Text(" м")) end
 local camera=workspace.CurrentCamera
 if camera and flat(delta).Magnitude>.1 then
  local forward=flat(camera.CFrame.LookVector)
  if forward.Magnitude>.01 then
   forward=forward.Unit;local right=Vector3.new(-forward.Z,0,forward.X)
   self.compass.Rotation=math.deg(math.atan2(delta:Dot(right),delta:Dot(forward)));self.compass.Visible=true
  end
 end
 self.anchor.Position=position;self.pin.Enabled=not near and goal.target~="StreetParcel";self.pinTitle.Text=if goal.target=="Delivery" then Locale.Text("Забери Verity") else Locale.Text(goal.title)
 self.pin.StudsOffsetWorldSpace=Vector3.new(0,4+(if ctx.settings.values.ReducedMotion then 0 else math.sin(now*2)*.15),0)
 self.highlight.Adornee=part;self.highlight.Enabled=part~=nil
 if near then self:HideArrows() else self:ComputeRoute(root,position,now);self:DrawRoute(root,now) end
end
function Tutorial:Destroy()
 self.dead=true;self.generation+=1;self.job=nil;self:SetButton(nil);self.pointer.Visible=false;self.cleanup:Destroy()
end
return Tutorial
