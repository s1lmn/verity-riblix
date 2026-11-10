--!nonstrict
local Players=game:GetService("Players")
local Config=require(game:GetService("ReplicatedStorage").Shared.TaskConfig)
local Locale=require(script.Parent.Locale)
local Cleanup=require(script.Parent.Cleanup)
local W=require(script.Parent.UIWidgets)
local Card=require(script.Parent.ActivityCard)
local Story=require(game:GetService("ReplicatedStorage").Shared.StoryConfig)
local Cosmetics=require(game:GetService("ReplicatedStorage").Shared.CosmeticCatalog)
local Tasks={};Tasks.__index=Tasks
function Tasks.new(ctx)
 local self=setmetatable({ctx=ctx,cleanup=Cleanup.new(),target=nil,original={},prompts={},nodes={}},Tasks)
 local p=ctx.refs.Panels.TASKS
 self.cleanup:Add(p.Guide.Activated:Connect(function()ctx.request("StoryGuide",{enabled=true})end))
 self.cleanup:Add(p.Pause.Activated:Connect(function()ctx.request("StoryGuide",{enabled=false})end))
 self.cleanup:Add(ctx.net.Result.Event:Connect(function(result)
  if result.action=="StoryGuide" and result.success and ctx.active=="TASKS" then ctx.close() end
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
  local finished=entry.status=="Done" or index<(entry.step or 1)
  local current=entry.status=="Active" and index==(entry.step or 1)
  local label=target:FindFirstChild("TaskLabel")
  if label then label.Enabled=current and not blocked and not target:FindFirstChild("TaskPrompt") end
  local prompt=target:FindFirstChild("TaskPrompt")
  if prompt then
   if self.prompts[prompt]==nil then self.prompts[prompt]=prompt.Enabled end
   prompt.Enabled=not blocked and current
  end
  local props=target:FindFirstChild("Props")
  if props then for _,part in props:GetChildren() do
   if not part:IsA("BasePart") then continue end
   if not self.original[part] then self.original[part]={color=part.Color,material=part.Material,alpha=part.Transparency} end
   local original=self.original[part]
   if part:GetAttribute("TaskPickup") then part.LocalTransparencyModifier=if finished or entry.status=="Locked" then 1 else 0 end
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
 local net=self.ctx.net;local state=net.state;local story=state and state.Story
 local p=self.ctx.refs.Panels.TASKS
 self.target=nil;self.activeEntry=nil
 p.Title.Text=string.format(Locale.Text("ИСТОРИЯ • %d/%d"),story and math.min(story.total,story.chapter-1) or 0,#Story.Chapters)
 p.Hint.Text=Locale.Text("История не обязательна: дом, рост Verity и все активности доступны без неё. Прогресс сохранится, даже если отложить её или выйти.")
 p.Guide.Visible=true;p.Pause.Visible=false
 if not story then
  p.Heading.Text=Locale.Text("Загружаем историю…")
  W.SetButton(p.Guide,Locale.Text("ПОДОЖДИ…"),false,false);return
 end
 if story.completed then
  p.Speaker.Text=Locale.Text("Все соседи");p.Heading.Text=Locale.Text("Район снова живёт")
  p.Narrative.Text=Locale.Text(Story.Chapters[#Story.Chapters].Outro)
  p.Step.Text=Locale.Text("Все десять глав пройдены")
  p.Progress.Text="";p.Reward.Text="";p.Milestone.Text=Locale.Text("Три памятных украшения — в твоей коллекции")
  p.Guide.Visible=false
 else
  local chapter=Story.Chapters[story.chapter];local definition=Config[chapter.TaskId]
  local entry
  for _,value in state.Tasks do if value.taskId==chapter.TaskId then entry=value;break end end
  local index=entry and entry.step or 1;local stage=definition.Steps[index]
  p.Speaker.Text=Locale.Text(chapter.Speaker);p.Heading.Text=Locale.Text(chapter.Title);p.Narrative.Text=Locale.Text(chapter.Brief)
  p.Step.Text=Locale.Text(stage.Title).."\n"..Locale.Text(stage.Action)
  p.Progress.Text=string.format(Locale.Text("Глава %d/%d · шаг %d/%d"),story.chapter,story.total,index,#definition.Steps)
  p.Reward.Text=string.format(Locale.Text("Награда за главу: $%s"),entry and Locale.Number(entry.reward) or "—")
  local item=chapter.Item and Cosmetics.Items[chapter.Item]
  p.Milestone.Text=if item then Locale.Text("И памятное украшение: ")..Locale.Text(item.name) else Locale.Text("Награда выдаётся один раз. Следующая глава появится сама.")
  if not story.available then p.Step.Text=Locale.Text("Сначала распакуй Verity и сделай первое улучшение.") end
  p.Pause.Visible=story.available and not story.paused
  W.SetButton(p.Guide,Locale.Text(if story.paused then "ВЕРНУТЬСЯ К ИСТОРИИ" else "ПОКАЗАТЬ ПУТЬ"),story.available and net.connected and not net:IsBusy(),net:IsBusy("StoryGuide"))
  W.SetButton(p.Pause,Locale.Text("ОТЛОЖИТЬ ИСТОРИЮ"),net.connected and not net:IsBusy(),false)
  if entry and entry.status=="Active" then
   self.activeEntry=entry;self.target,self.targetName=entry.targetPosition,stage.Title
  end
 end
 local signature={}
 for _,entry in state.Tasks or {} do table.insert(signature,entry.taskId..entry.status..tostring(entry.step)) end
 table.sort(signature);signature=table.concat(signature,"|")
 if signature~=self.sceneSignature then self.sceneSignature=signature;self:RefreshScenes() end
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
