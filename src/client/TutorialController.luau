--!nonstrict
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Input=game:GetService("UserInputService")
local Pathfinding=game:GetService("PathfindingService")
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
 p.Material=Enum.Material.Neon;p.Color=T.Mint;p.Transparency=1;p.Size=Vector3.new(.2,.07,1.3);p.Parent=parent;return p
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
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),arrows={},subtitles={},nextPathAt=0,generation=0,dead=false},Tutorial)
 for name,panel in ctx.refs.Panels do self.subtitles[name]=panel.Subtitle.Text end
 self.folder=self.cleanup:Add(Instance.new("Folder"));self.folder.Name="VerityGuidance";self.folder.Parent=workspace
 self.anchor=piece(self.folder,"GoalMarker");self.anchor.Size=Vector3.one*.1
 self.pin=Instance.new("BillboardGui");self.pin.Name="GoalPin";self.pin.Size=UDim2.fromOffset(170,64)
 self.pin.StudsOffsetWorldSpace=Vector3.new(0,4,0);self.pin.AlwaysOnTop=true;self.pin.MaxDistance=1500;self.pin.Enabled=false;self.pin.Parent=self.anchor
 self.pinTitle=W.Text(self.pin,"Target","",13,true,T.Ink);self.pinTitle.Size=UDim2.new(1,0,0,27)
 self.pinTitle.TextXAlignment=Enum.TextXAlignment.Center;self.pinTitle.TextStrokeColor3=T.White;self.pinTitle.TextStrokeTransparency=.1
 local down=W.Text(self.pin,"Arrow","▼",28,true,T.Mint);down.Position=UDim2.fromOffset(0,28);down.Size=UDim2.new(1,0,0,32)
 down.TextXAlignment=Enum.TextXAlignment.Center;down.TextStrokeColor3=T.Ink;down.TextStrokeTransparency=.25
 self.highlight=Instance.new("Highlight");self.highlight.Name="CurrentGoal";self.highlight.FillColor=T.Mint;self.highlight.OutlineColor=T.Mint
 self.highlight.FillTransparency=.82;self.highlight.OutlineTransparency=.15;self.highlight.Enabled=false;self.highlight.Parent=self.folder
 self.compass=W.Text(ctx.refs.Tutorial,"Compass","↑",28,true,T.Purple)
 self.compass.AnchorPoint=Vector2.new(.5,.5);self.compass.Position=UDim2.new(1,-22,.5,0);self.compass.Size=UDim2.fromOffset(32,32);self.compass.Visible=false
 self.pointer=ctx.refs.Direction;self.pointer.Size=UDim2.fromOffset(32,32);self.pointer.AnchorPoint=Vector2.new(.5,.5)
 self.pointer.TextSize=28;self.pointer.TextColor3=T.Purple;self.pointer.TextStrokeColor3=T.White;self.pointer.TextStrokeTransparency=.15;self.pointer.ZIndex=40
 local elapsed=0
 self.cleanup:Add(RunService.RenderStepped:Connect(function(dt)
  elapsed+=dt;if elapsed<1/30 then return end;elapsed=0;self:Update(os.clock())
 end))
 return self
end
function Tutorial:SetButton(button)
 if self.button==button then return end
 if self.stroke then self.stroke:Destroy();self.stroke=nil end
 self.button=button
 if button then
  self.stroke=Instance.new("UIStroke");self.stroke.Name="GuidanceGlow";self.stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
  self.stroke.Color=T.Gold;self.stroke.Thickness=3;self.stroke.Transparency=0;self.stroke.Parent=button
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
function Tutorial:UIButton(key)
 local refs=self.ctx.refs;local group,name=key:match("^([^%.]+)%.(.+)$")
 if group=="Nav" then return refs.Nav[name] end
 if group=="Phone" then return refs.Panels.PHONE.Next end
 if group=="Verity" then return refs.Panels.VERITY.Buy end
 if group=="Task" then return refs.Panels.TASKS.Rows[name].Button end
 if key=="Close" and self.ctx.active then return refs.Panels[self.ctx.active].Close end
end
function Tutorial:Target(goal)
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
 self.targetKey=nil;self.route=nil;self.routeStart=nil;self.nextPathAt=0;self:HideWorld()
end
function Tutorial:ComputeRoute(root,position,now)
 if self.job or now<self.nextPathAt then return end
 if self.route and self.routeStart and (root.Position-self.routeStart).Magnitude<8 then return end
 self.nextPathAt=now+1.5
 local humanoid=root.Parent:FindFirstChildOfClass("Humanoid")
 local height=math.clamp(math.ceil((humanoid and humanoid.HipHeight or 2)+root.Size.Y+2),5,8)
 local job={generation=self.generation,start=root.Position};self.job=job
 local target=position
 if self.goal.target=="Delivery" or self.goal.target=="PRESS_BUTTON" then
  local approach=flat(root.Position-position);if approach.Magnitude>.1 then target+=approach.Unit*3 end
 end
 target+=Vector3.new(0,3,0);self.ctx.refs.Gui:SetAttribute("GuidancePathStatus","Computing")
 task.spawn(function()
  local waypoints
  for _,allowJump in {false,true} do
   if self.dead or self.job~=job then return end
   local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=height,AgentCanJump=allowJump,WaypointSpacing=5})
   local ok=pcall(function()path:ComputeAsync(job.start,target)end)
   if ok and path.Status==Enum.PathStatus.Success then waypoints=path:GetWaypoints() end
   path:Destroy();if waypoints then break end
  end
  if self.dead or self.job~=job or job.generation~=self.generation then return end
  self.job=nil;self.route=waypoints;self.routeIndex=2;self.routeStart=job.start
  self.ctx.refs.Gui:SetAttribute("GuidancePathStatus",if waypoints then "Success" else "NoPath")
 end)
end
function Tutorial:DrawRoute(root,now)
 if self.lastDrawAt and now-self.lastDrawAt<.1 then return end
 self.lastDrawAt=now
 self:HideArrows();if not self.route or #self.route<2 then return end
 while self.routeIndex<#self.route do
  local p=self.route[self.routeIndex].Position
  if flat(p-root.Position).Magnitude>3.5 or math.abs(p.Y-root.Position.Y)>6 then break end
  self.routeIndex+=1
 end
 local points={root.Position};for i=self.routeIndex,#self.route do table.insert(points,self.route[i].Position) end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.RespectCanCollide=true
 local objects={workspace.Terrain}
 for _,name in {"GeneratedWorld","GameplayInteractions"}do local object=workspace:FindFirstChild(name);if object then table.insert(objects,object) end end
 params.FilterDescendantsInstances=objects
 local segment,distance=1,3
 for i=1,8 do
  while segment<#points and flat(points[segment+1]-points[segment]).Magnitude<distance do
   distance-=flat(points[segment+1]-points[segment]).Magnitude;segment+=1
  end
  if segment>=#points then break end
  local delta=flat(points[segment+1]-points[segment]);local length=delta.Magnitude;if length<.01 then break end
  local point=points[segment]:Lerp(points[segment+1],distance/length)
  local hit=workspace:Raycast(point+Vector3.new(0,4,0),Vector3.new(0,-16,0),params)
  if hit and hit.Position.Y<=point.Y+1.5 then
   local arrow=self.arrows[i]
   if not arrow then arrow={piece(self.folder,"RouteStem"),piece(self.folder,"RouteHead"),piece(self.folder,"RouteHead")};self.arrows[i]=arrow end
   local cf=CFrame.lookAt(hit.Position+Vector3.new(0,.11,0),hit.Position+Vector3.new(0,.11,0)+delta.Unit)
   arrow[1].CFrame=cf*CFrame.new(0,0,.35)
   arrow[2].Size=Vector3.new(.2,.07,.9);arrow[2].CFrame=cf*CFrame.new(-.28,0,-.35)*CFrame.Angles(0,-math.pi/4,0)
   arrow[3].Size=Vector3.new(.2,.07,.9);arrow[3].CFrame=cf*CFrame.new(.28,0,-.35)*CFrame.Angles(0,math.pi/4,0)
   for _,p in arrow do p.Transparency=.12 end
  end
  distance+=5
 end
 local waypoint=self.route[self.routeIndex]
 if waypoint and waypoint.Action==Enum.PathWaypointAction.Jump and flat(waypoint.Position-root.Position).Magnitude<6 then
  self:HintText(if Input.PreferredInput==Enum.PreferredInput.Touch then "Нажми кнопку прыжка" else "Прыгни: нажми ПРОБЕЛ")
 end
end
function Tutorial:Render()
 local ctx=self.ctx
 self.goal=Goals.Resolve(ctx.net.state,ctx.active,ctx.tasks and ctx.tasks.selectedTaskId,workspace:GetServerTimeNow());self:Update(os.clock())
end
function Tutorial:HintText(text)
 self.ctx.refs.TutorialText.Text=text
 local panel=self.ctx.active and self.ctx.refs.Panels[self.ctx.active]
 if panel then panel.Subtitle.Text=text end
end
function Tutorial:Update(now)
 if self.dead then return end
 local ctx,goal=self.ctx,self.goal
 if ctx.presenting then
  ctx.refs.Tutorial.Visible=false;self.pointer.Visible=false;self.compass.Visible=false
  self:SetButton(nil);self:HideWorld();return
 end
 local char=Players.LocalPlayer.Character;local root=char and char:FindFirstChild("HumanoidRootPart");local hum=char and char:FindFirstChildOfClass("Humanoid")
 local alive=root and hum and hum.Health>0
 ctx.refs.Tutorial.Visible=goal~=nil and alive~=nil and alive~=false and not (ctx.active and ctx.refs.Safe.AbsoluteSize.X<640)
 self.pointer.Visible=false;self.compass.Visible=false
 for name,panel in ctx.refs.Panels do if name~=ctx.active or not goal then panel.Subtitle.Text=self.subtitles[name] end end
 if not goal or not alive then self.lastRootPosition=nil;self:SetButton(nil);self:ClearRoute();return end
 if self.lastRootPosition and (root.Position-self.lastRootPosition).Magnitude>16 then self:ClearRoute() end
 self.lastRootPosition=root.Position
 ctx.refs.Gui:SetAttribute("GuidanceGoal",goal.id);ctx.refs.Gui:SetAttribute("GuidanceKind",goal.kind)
 ctx.refs.GuideTitle.Text=goal.title;self:HintText(goal.detail)
 ctx.refs.TutorialText.Size=UDim2.new(1,if goal.kind=="World" then -54 else -16,1,if ctx.refs.Safe.AbsoluteSize.Y<360 then -22 else -25)
 if goal.kind=="UI" then
  self:ClearRoute();local button=self:UIButton(goal.target)
  if not button or not visible(button,true) then
   if ctx.active then button=ctx.refs.Panels[ctx.active].Close;self:HintText("Закрой окно, затем нажми кнопку слева") end
  end
  if ctx.net:IsBusy() and not goal.target:match("^Nav%.") and goal.target~="Close" then
   self:HintText("Подожди ответа игры…");self:SetButton(nil);return
  end
  self:SetButton(button)
  if not button then return end
  if not visible(button) then self:HintText("Прокрути окно до подсвеченной кнопки");return end
  local origin=ctx.refs.Safe.AbsolutePosition;local pos=button.AbsolutePosition-origin
  if goal.target:match("^Nav%.") then
   self.pointer.Text="↙";self.pointer.TextSize=20;self.pointer.Size=UDim2.fromOffset(20,20)
   self.pointer.Position=UDim2.fromOffset(pos.X+button.AbsoluteSize.X-4,pos.Y+5)
   self.pointer.Visible=true;return
  end
  self.pointer.TextSize=28;self.pointer.Size=UDim2.fromOffset(32,32)
  local x=pos.X+button.AbsoluteSize.X+20;self.pointer.Text="←"
  if x>ctx.refs.Safe.AbsoluteSize.X-18 then x=pos.X-20;self.pointer.Text="→" end
  local pulse=if ctx.settings.values.ReducedMotion then 0 else math.sin(now*4)*3
  self.pointer.Position=UDim2.fromOffset(x+pulse,pos.Y+button.AbsoluteSize.Y/2);self.pointer.Visible=true;return
 end
 self:SetButton(nil);if goal.kind~="World" then self:ClearRoute();return end
 local position,part=self:Target(goal)
 if not validPosition(position) then self:ClearRoute();self:HintText("Метка загружается…");return end
 if self.targetKey~=goal.id or not self.targetPosition or (self.targetPosition-position).Magnitude>1 then
  self:ClearRoute();self.targetKey=goal.id;self.targetPosition=position;self.generation+=1
 end
 local delta=position-root.Position;local near=flat(delta).Magnitude<=goal.radius and math.abs(delta.Y)<6
 if near and (goal.target=="Delivery" or goal.target=="PRESS_BUTTON") then
  local ray=RaycastParams.new();ray.FilterType=Enum.RaycastFilterType.Include;ray.RespectCanCollide=true
  local world=workspace:FindFirstChild("GeneratedWorld")
  ray.FilterDescendantsInstances=if world then {world} else {}
  local from=root.Position+Vector3.new(0,1,0)
  near=workspace:Raycast(from,position-from,ray)==nil
 end
 if near then
  local key=if Input.PreferredInput==Enum.PreferredInput.Gamepad then "X" else "E"
  self:HintText(string.format(goal.near or goal.detail,key))
  if Input.PreferredInput==Enum.PreferredInput.Touch then
   if goal.target=="Delivery" and ctx.net.state.DeliveryState=="Delivered" then self:HintText("Коснись «Распаковать» у коробки")
   elseif goal.target=="PRESS_BUTTON" then self:HintText("Коснись «Нажать» у кнопки") end
  end
 else self:HintText("Следуй стрелкам · "..math.max(1,math.round(delta.Magnitude*.28)).." м") end
 local camera=workspace.CurrentCamera
 if camera and flat(delta).Magnitude>.1 then
  local forward=flat(camera.CFrame.LookVector)
  if forward.Magnitude>.01 then
   forward=forward.Unit;local right=Vector3.new(-forward.Z,0,forward.X)
   self.compass.Rotation=math.deg(math.atan2(delta:Dot(right),delta:Dot(forward)));self.compass.Visible=true
  end
 end
 self.anchor.Position=position;self.pin.Enabled=true;self.pinTitle.Text=if goal.target=="Delivery" then "ТВОЯ КОРОБКА" else goal.title
 self.pin.StudsOffsetWorldSpace=Vector3.new(0,4+(if ctx.settings.values.ReducedMotion then 0 else math.sin(now*2)*.15),0)
 self.highlight.Adornee=part;self.highlight.Enabled=part~=nil
 if near then self:HideArrows() else self:ComputeRoute(root,position,now);self:DrawRoute(root,now) end
end
function Tutorial:Destroy()
 self.dead=true;self.generation+=1;self.job=nil;self:SetButton(nil);self.pointer.Visible=false;self.cleanup:Destroy()
end
return Tutorial
