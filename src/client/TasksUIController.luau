--!nonstrict
local Players=game:GetService("Players")
local Config=require(game:GetService("ReplicatedStorage").Shared.TaskConfig)
local Locale=require(script.Parent.Locale)
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local Card=require(script.Parent.ActivityCard)
local Tasks={};Tasks.__index=Tasks
function Tasks.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),target=nil,original={},prompts={},nodes={}},Tasks)
 for taskId,row in ctx.refs.Panels.TASKS.Rows do
  self.cleanup:Add(row.Button.Activated:Connect(function()
   local state=ctx.net.state
   if not state then return end
   for _,entry in state.Tasks do
    if entry.taskId~=taskId then continue end
    if entry.status=="Ready" or (entry.status=="Cooldown" and entry.cooldownEndsAt<=workspace:GetServerTimeNow()) then
     self.selectedTaskId=taskId;ctx.request("TaskStart",{taskId=taskId})
    elseif entry.status=="Active" then self.selectedTaskId=taskId;ctx.close() end
    return
   end
  end))
 end
 self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
  if result.action=="TaskStart" and result.success and ctx.active=="TASKS" then ctx.close() end
 end))
 self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function() self:ClearCarry() end))
 return self
end
function Tasks:ClearCarry()
 if self.carry then self.carry:Destroy();self.carry=nil;self.carryKind=nil end
end
function Tasks:Carry(kind)
 if kind==self.carryKind then return end
 self:ClearCarry()
 if not kind then return end
 local model=Instance.new("Model");model.Name="QuestCarry";model.Parent=workspace
 local function piece(name,size,color,offset)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.Color=Color3.fromHex(color)
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  p.CFrame=CFrame.new(offset);p.Material=Enum.Material.SmoothPlastic;p.Parent=model;return p
 end
 local colors={Cell="FFD34E",Parcel="E6B77F",Mail="FFB866",Water="6ADAF5",Tools="9E94EC",Trash="76AA84",Drone="80BBFF"}
 local body=piece("Item",Vector3.new(.9,.75,.7),colors[kind] or "FFD34E",Vector3.zero)
 model.PrimaryPart=body
 if kind=="Water" then
  piece("Spout",Vector3.new(.65,.18,.18),"6ADAF5",Vector3.new(.55,.15,0))
 elseif kind=="Drone" then
  piece("Rotor",Vector3.new(1.6,.1,.18),"37476B",Vector3.new(0,.5,0))
 else piece("Band",Vector3.new(.18,.79,.74),"FFF7D8",Vector3.zero) end
 self.carry,self.carryKind=model,kind
end
function Tasks:RefreshScenes()
 local folder=workspace:FindFirstChild("GameplayInteractions")
 local state=self.ctx.net.state
 if not folder or not state then return end
 local blocked=Card.Blocked(self.ctx) or Card.ActivityRunning()
 local entries,active={},nil
 for _,entry in state.Tasks do entries[entry.taskId]=entry;if entry.status=="Active" then active=entry.taskId end end
 self.nodes={}
 for _,target in folder:GetChildren() do
  if not target:IsA("BasePart") then continue end
  local id,index=target:GetAttribute("TaskId"),target:GetAttribute("TaskStep")
  local entry=entries[id]
  if not entry then continue end
  table.insert(self.nodes,target)
  local finished=(entry.status=="Cooldown" and entry.cooldownEndsAt>workspace:GetServerTimeNow()) or index<(entry.step or 1)
  local current=entry.status=="Active" and index==(entry.step or 1)
  local label=target:FindFirstChild("TaskLabel")
  if label then label.Enabled=current and not blocked and not target:FindFirstChild("TaskPrompt") end
  local prompt=target:FindFirstChild("TaskPrompt")
  if prompt then
   if self.prompts[prompt]==nil then self.prompts[prompt]=prompt.Enabled end
   prompt.Enabled=not blocked and (current or (not active and index==(entry.step or 1) and entry.cooldownEndsAt<=workspace:GetServerTimeNow()))
  end
  local props=target:FindFirstChild("Props")
  if props then for _,part in props:GetChildren() do
   if not part:IsA("BasePart") then continue end
   if not self.original[part] then self.original[part]={color=part.Color,material=part.Material,alpha=part.Transparency} end
   local original=self.original[part]
   if part:GetAttribute("TaskPickup") then part.LocalTransparencyModifier=if finished then 1 else 0 end
   if part:GetAttribute("TaskResult") then part.Transparency=if finished then 0 else 1 end
   if part:GetAttribute("TaskRestore") then
    part.Color=if finished then Color3.fromHex(Config[id].Color) else original.color
    part.Material=if finished then Enum.Material.Neon else original.material
   end
  end end
 end
 -- Streaming may discard nodes; do not retain dead instances across the session.
 for part in self.original do if not part:IsDescendantOf(workspace) then self.original[part]=nil end end
 for prompt in self.prompts do if not prompt:IsDescendantOf(workspace) then self.prompts[prompt]=nil end end
end
function Tasks:Render()
 local net=self.ctx.net;local state=net.state
 self.target=nil;self.activeEntry=nil
 local entries={}
 self.ctx.refs.Panels.TASKS.Title.Text=string.format(Locale.Text("ЗАДАНИЯ • %d/10"),state and state.TaskCompletedCount or 0)
 if state then for _,entry in state.Tasks do entries[entry.taskId]=entry;if entry.status=="Active" then self.activeEntry=entry end end end
 for taskId,row in self.ctx.refs.Panels.TASKS.Rows do
  local entry=entries[taskId];local definition=Config[taskId]
  if not entry then
   row.Reward.Text="$—";row.Status.Text=Locale.Text("Загрузка…")
   W.SetButton(row.Button,Locale.Text("WAITING FOR SERVER"),false,false);continue
  end
  row.Reward.Text="$"..Locale.Number(entry.reward)
  local remaining=math.max(0,math.ceil(entry.cooldownEndsAt-workspace:GetServerTimeNow()))
  local busy=net:IsBusy("TaskStart")
  local cooldown=entry.status=="Cooldown" and remaining>0
  local index=entry.step or 1
  if entry.status=="Active" then
   row.Description.Text=Locale.Text(definition.Steps[index].Title)
   row.Progress.Text=string.format(Locale.Text("Этап %d/%d • %s"),index,#definition.Steps,Locale.Text(definition.Steps[index].Action))
  else
   row.Description.Text=Locale.Text(definition.Description)
   row.Progress.Text=if cooldown then string.format(Locale.Text("Выполнено %d/%d"),#definition.Steps,#definition.Steps)
    else string.format(Locale.Text("Выполнено %d/%d"),index-1,#definition.Steps)
  end
  row.Status.Text=if cooldown then string.format(Locale.Text("Снова через %dс"),remaining) elseif entry.status=="Active" then Locale.Text("Выполняется") else Locale.Text("Можно начать")
  W.SetButton(row.Button,if cooldown then Locale.Text("СКОРО СНОВА") elseif busy then Locale.Text("WAITING…")
   elseif entry.status=="Active" then Locale.Text("ПОКАЗАТЬ ПУТЬ →") elseif index>1 then Locale.Text("ПРОДОЛЖИТЬ →")
   else Locale.Text("НАЧАТЬ ЗАДАНИЕ →"),net.connected and not cooldown and not busy and not Card.ActivityRunning(),busy)
  if entry.status=="Active" and typeof(entry.targetPosition)=="Vector3" then
   self.target,self.targetName=entry.targetPosition,definition.Steps[index].Title
  end
 end
 local signature={}
 for _,entry in state and state.Tasks or {} do table.insert(signature,entry.taskId..entry.status..tostring(entry.step or 1)) end
 table.sort(signature);signature=table.concat(signature,"|")
 if self.sceneSignature~=signature then self.sceneSignature=signature;self:RefreshScenes() end
end
function Tasks:Tick()
 local now=os.clock()
 local blocked=not not (Card.Blocked(self.ctx) or Card.ActivityRunning())
 if blocked~=self.sceneBlocked or now>=(self.refreshAt or 0) then
  self.sceneBlocked=blocked;self.refreshAt=now+1;self:RefreshScenes()
 end
 local entry=self.activeEntry
 local player=Players.LocalPlayer
 local char=player.Character;local root=char and char:FindFirstChild("HumanoidRootPart")
 local humanoid=char and char:FindFirstChildOfClass("Humanoid")
 local hidden=not root or not humanoid or humanoid.Health<=0 or Card.ActivityRunning() or self.ctx.presenting or self.ctx.rewardOverlay
 local kind=entry and Config[entry.taskId].Steps[entry.step or 1].Carry
 self:Carry(if hidden then nil else kind)
 if self.carry then
  self.carry:PivotTo(root.CFrame*CFrame.new(1.2,-.1,-1.05))
  local camera=workspace.CurrentCamera
  local firstPerson=camera and (camera.CFrame.Position-camera.Focus.Position).Magnitude<1
  for _,part in self.carry:GetChildren() do part.LocalTransparencyModifier=if firstPerson then 1 else 0 end
 end
end
function Tasks:Destroy()
 self:ClearCarry()
 for part,original in self.original do if part.Parent then
  part.Color=original.color;part.Material=original.material;part.Transparency=original.alpha;part.LocalTransparencyModifier=0
 end end
 for prompt,enabled in self.prompts do if prompt.Parent then prompt.Enabled=enabled end end
 for _,target in self.nodes do if target.Parent then local label=target:FindFirstChild("TaskLabel");if label then label.Enabled=false end end end
 self.cleanup:Destroy()
end
return Tasks
