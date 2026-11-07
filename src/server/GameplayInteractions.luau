--!nonstrict
-- Small story props on the sidewalks. Geometry is non-blocking; server owns progress.
local Shared=game:GetService("ReplicatedStorage").Shared
local LocaleText=require(Shared.LocaleText)
local Config=require(Shared.TaskConfig)
local Interactions={}
function Interactions.Start(workspace,world,tasks,state)
 local folder=Instance.new("Folder");folder.Name="GameplayInteractions";folder.Parent=workspace
 local map=workspace.GeneratedWorld
 -- Positions are normalized to the actual sidewalk length for any plot count.
 local ink=Color3.fromHex("37476B")
 local function piece(parent,name,size,position,color,shape)
  local p=Instance.new("Part");p.Name=name;p.Size=size;p.Position=position;p.Color=color
  p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
  p.Material=Enum.Material.SmoothPlastic
  if shape then p.Shape=shape end
  p.Parent=parent;return p
 end
 local function result(p)
  p:SetAttribute("TaskResult",true);p.Transparency=1;return p
 end
 for id,definition in Config do
  for index,stage in definition.Steps do
   local sidewalk=map.Environment:FindFirstChild("Sidewalk"..stage.Side)
   local pos=Vector3.new(sidewalk.Position.X+stage.Side*2,sidewalk.Position.Y+sidewalk.Size.Y/2+.12,sidewalk.Position.Z-sidewalk.Size.Z/2+10+(stage.Distance/504)*(sidewalk.Size.Z-20))
   local color=Color3.fromHex(definition.Color)
   if id=="FESTIVAL" then
    if index==2 then color=Color3.fromHex("FFD34E") elseif index==3 then color=Color3.fromHex("6FDFFF") end
   end
   local key=id..":"..index
   local target=piece(folder,key,Vector3.new(4.6,.18,4.6),pos,color)
   target.Transparency=.82
   target:SetAttribute("TaskId",id);target:SetAttribute("TaskStep",index)
   world:RegisterTaskTarget(id,target,index)
   local props=Instance.new("Model");props.Name="Props";props.Parent=target
   local base=pos+Vector3.new(0,.15,0)
   local function p(name,size,offset,tint,shape) return piece(props,name,size,base+offset,tint or color,shape) end
   local prop=stage.Prop
   if prop=="Lamp" or prop=="Signal" then
    p("Post",Vector3.new(.28,3.7,.28),Vector3.new(0,1.85,0),ink)
    local head=p("Head",Vector3.new(1.65,.7,1.1),Vector3.new(0,3.9,0),ink)
    head:SetAttribute("TaskRestore",true)
    local light=result(p("RestoredLight",Vector3.new(1.5,.4,1),Vector3.new(0,3.9,-.1),Color3.fromHex("C9FF83")))
    light.Material=Enum.Material.Neon
   elseif prop=="Flower" then
    p("Planter",Vector3.new(2.6,.55,1.8),Vector3.new(0,.25,0),Color3.fromHex("CFA27C"))
    for n=-1,1 do
     p("Stem",Vector3.new(.12,.8,.12),Vector3.new(n*.72,.9,0),Color3.fromHex("48AE73"))
     result(p("Bloom",Vector3.new(.75,.7,.75),Vector3.new(n*.72,1.45,0),color,Enum.PartType.Ball))
    end
   elseif prop=="Drone" then
    local body=p("Drone",Vector3.new(1.2,.65,1.2),Vector3.new(0,1.1,0),color)
    body:SetAttribute("TaskPickup",true)
    for n=-1,1,2 do
     local rotor=p("Rotor",Vector3.new(2.4,.12,.3),Vector3.new(0,1.5,n*.7),ink)
     rotor:SetAttribute("TaskPickup",true)
    end
   elseif prop=="Flag" then
    p("Pole",Vector3.new(.12,2.7,.12),Vector3.new(0,1.35,0),ink)
    p("Flag",Vector3.new(1.3,.8,.12),Vector3.new(.6,2.3,0),color)
    result(p("Check",Vector3.one*.55,Vector3.new(0,3,0),Color3.fromHex("78F3A9"),Enum.PartType.Ball))
   elseif prop=="Star" then
    p("Stand",Vector3.new(.4,2.5,.4),Vector3.new(0,1.25,0),ink)
    local star=p("Star",Vector3.new(2,.5,.5),Vector3.new(0,3,0),ink)
    local cross=p("Cross",Vector3.new(.5,2,.5),Vector3.new(0,3,0),ink)
    star:SetAttribute("TaskRestore",true);cross:SetAttribute("TaskRestore",true)
    for n=1,8 do
     local angle=n*math.pi/4
     local spark=result(p("Celebration",Vector3.one*.26,Vector3.new(math.cos(angle)*1.6,3+math.sin(angle)*1.6,0),color,Enum.PartType.Ball))
     spark.Material=Enum.Material.Neon
    end
   elseif prop=="Water" then
    p("Basin",Vector3.new(2.3,.8,1.6),Vector3.new(0,.4,0),ink)
    p("Water",Vector3.new(2,.12,1.3),Vector3.new(0,.84,0),Color3.fromHex("70D9FF"))
    result(p("Ready",Vector3.one*.6,Vector3.new(0,1.45,0),color,Enum.PartType.Ball))
   else
    local pickup=prop=="Cell" or prop=="Parcel" or prop=="Mail" or prop=="Tools" or prop=="Trash"
    local body=p("Body",Vector3.new(1.7,if prop=="Trash" then .7 else 1.5,1.5),Vector3.new(0,.9,0),color)
    if pickup then body:SetAttribute("TaskPickup",true) else body:SetAttribute("TaskRestore",true) end
    local detail=p("Detail",Vector3.new(1,.22,1.6),Vector3.new(0,1.25,-.03),ink)
    if pickup then detail:SetAttribute("TaskPickup",true) end
    if prop=="Cell" then
     body.Shape=Enum.PartType.Cylinder;body.Size=Vector3.new(1.4,.8,.8)
     body.CFrame=CFrame.new(base+Vector3.new(0,.9,0))*CFrame.Angles(0,0,math.pi/2)
     body.Material=Enum.Material.Neon;detail.Size=Vector3.new(.4,.3,.4)
     detail.Position=base+Vector3.new(0,1.7,0)
    elseif prop=="Mail" then
     body.Size=Vector3.new(1.7,1.1,.2);body.Color=Color3.fromHex("FFF7D8")
     detail.Size=Vector3.new(1,.12,.23);detail.Position=base+Vector3.new(0,1.1,-.03);detail.Rotation=Vector3.new(0,0,28)
    elseif prop=="Tools" then
     detail.Size=Vector3.new(.8,.4,.22);detail.Position=base+Vector3.new(0,1.8,0)
    elseif prop=="Parcel" then
     detail.Size=Vector3.new(.23,1.55,1.55);detail.Position=body.Position;detail.Color=Color3.fromHex("FFF3CF")
    elseif prop=="Trash" then
     body.Shape=Enum.PartType.Ball;detail.Size=Vector3.new(.5,.4,.6);detail.Position=base+Vector3.new(.8,.4,.3)
    end
    if prop=="Mailbox" then
     p("Post",Vector3.new(.32,1,.32),Vector3.new(0,.3,0),ink)
     result(p("Delivered",Vector3.new(.8,.6,.12),Vector3.new(0,1.1,-.82),Color3.fromHex("FFF8D7")))
    elseif not pickup then
     if prop=="Generator" or prop=="Dock" then
      body.Shape=Enum.PartType.Cylinder;body.Size=Vector3.new(1.5,2,2)
      body.CFrame=CFrame.new(base+Vector3.new(0,.9,0))*CFrame.Angles(0,0,math.pi/2)
      local core=p("Core",Vector3.one*.75,Vector3.new(0,1.8,0),color,Enum.PartType.Ball)
      core.Material=Enum.Material.Neon
      if prop=="Dock" then
       result(p("RescuedDrone",Vector3.new(1.2,.6,1.2),Vector3.new(0,2.5,0),Color3.fromHex("80BBFF")))
       result(p("DroneRotor",Vector3.new(2,.12,.25),Vector3.new(0,2.9,0),ink))
      end
     elseif prop=="Console" then
      detail.Size=Vector3.new(1.45,.8,.15);detail.CFrame=CFrame.new(base+Vector3.new(0,1.5,-.5))*CFrame.Angles(math.rad(-20),0,0)
     elseif prop=="Bin" then
      detail.Size=Vector3.new(1.9,.15,1.7);detail.Position=base+Vector3.new(0,1.7,0)
     end
     local ready=result(p("Powered",Vector3.new(.8,.65,.12),Vector3.new(0,1,-.82),Color3.fromHex("7EFFB2")))
     ready.Material=Enum.Material.Neon
    end
   end
   local gui=Instance.new("BillboardGui");gui.Name="TaskLabel";gui.Size=UDim2.fromOffset(160,34)
   gui.StudsOffsetWorldSpace=Vector3.new(0,4.7,0);gui.MaxDistance=15;gui.Enabled=false;gui.Parent=target
   local label=Instance.new("TextLabel");label.Size=UDim2.fromScale(1,1);label.BackgroundTransparency=1
   LocaleText.SetWorld(label,"Text",stage.Title);label.Font=Enum.Font.GothamBold;label.TextSize=12;label.TextWrapped=true
   label.TextColor3=ink;label.TextStrokeColor3=Color3.new(1,1,1);label.TextStrokeTransparency=.15;label.Parent=gui
   if stage.Mode=="Prompt" then
    local prompt=Instance.new("ProximityPrompt");prompt.Name="TaskPrompt"
    LocaleText.SetWorld(prompt,"ActionText",stage.Action);LocaleText.SetWorld(prompt,"ObjectText",stage.Title)
    prompt.MaxActivationDistance=definition.Radius;prompt.HoldDuration=.5;prompt.RequiresLineOfSight=true
    prompt.Style=Enum.ProximityPromptStyle.Default;prompt.Parent=target
    prompt.Triggered:Connect(function(player)
     local near,alive=world:IsNearTask(player.UserId,id,index)
     if near and alive then tasks:Interact(player.UserId,id,index) end
    end)
   end
  end
 end
 state.TaskPosition=function(id,step) local target=world.targets[id..":"..tostring(step or 1)];return target and target.Position end
 return folder
end
return Interactions
