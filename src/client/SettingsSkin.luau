--!nonstrict
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Skin={}
local violet=Color3.fromHex("9960DC")
local function label(parent,name,value,x,y,w,h,size,bold)
 local t=W.Text(parent,name,value,size or 13,bold,T.Ink)
 t.Position=UDim2.fromOffset(x,y);t.Size=UDim2.new(1,w,0,h);return t
end
local function card(parent,name,height,order)
 local c=W.Round(W.Frame(parent,name,UDim2.new(1,-6,0,height),T.White),16)
 c.LayoutOrder=order;W.Stroke(c,T.Purple,1).Transparency=.8;return c
end
function Skin.Build(parent)
 local root=W.Round(W.Frame(parent,"SettingsPanel",UDim2.fromOffset(420,640),violet),28)
 root.Visible=false;root.Active=true;root.SelectionGroup=true
 for _,dir in {"Up","Down","Left","Right"} do root["SelectionBehavior"..dir]=Enum.SelectionBehavior.Stop end
 W.Stroke(root,Color3.fromHex("633D92"),3).Transparency=.08
 local shell=W.Round(W.Frame(root,"CreamShell",UDim2.new(1,-12,1,-12),Color3.fromHex("FFF6ED")),23)
 shell.Position=UDim2.fromOffset(6,6)
 local title=label(root,"Title","YOUR CONTROL PANEL",20,24,-86,32,20,true)
 local subtitle=label(root,"Subtitle","Make yourself comfortable",20,61,-40,28,12,false)
 local close=W.Button(root,"Close","×",T.Gold)
 close.Position=UDim2.new(1,-62,0,20);close.Size=UDim2.fromOffset(44,44);close.TextSize=26
 local body=W.New("ScrollingFrame",{Name="Controls",Position=UDim2.fromOffset(16,100),Size=UDim2.new(1,-32,1,-136),
  BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
  ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,ScrollBarImageColor3=violet},root)
 W.List(body,10)
 local refs={Root=root,Title=title,Subtitle=subtitle,Close=close,Body=body,ToggleKnobs={}}
 local language=card(body,"LanguageCard",104,1)
 label(language,"Title","LANGUAGE",12,8,-24,28,14,true)
 refs.Language=W.Button(language,"Language","",T.Blue)
 refs.Language.Position=UDim2.fromOffset(12,48);refs.Language.Size=UDim2.new(1,-24,0,44);refs.Language.TextSize=12
 local function toggle(name,key,heading,description,color,order)
  local row=card(body,name.."Card",128,order)
  label(row,"Title",heading,12,8,-24,25,14,true)
  label(row,"Description",description,12,35,-24,34,12,false).TextColor3=T.Muted
  local button=W.Button(row,name,"",color)
  button.Position=UDim2.fromOffset(12,76);button.Size=UDim2.new(1,-24,0,44)
  button.TextXAlignment=Enum.TextXAlignment.Left;W.Padding(button,12)
  local track=W.Round(W.Frame(button,"ToggleTrack",UDim2.fromOffset(48,24),T.Ink),12)
  track.Position=UDim2.new(1,-48,.5,-12);track.BackgroundTransparency=.75
  local knob=W.Round(W.Frame(track,"Knob",UDim2.fromOffset(18,18),T.White),9)
  knob.Position=UDim2.fromOffset(3,3)
  refs[key]=button;refs.ToggleKnobs[key]=knob
 end
 toggle("UISounds","Sound","GAME SOUNDS","Hear your companion, rewards and the world.",T.Mint,2)
 local volume=card(body,"VolumeCard",112,3)
 refs.Volume=label(volume,"Volume","VOLUME 60%",12,8,-24,24,14,true)
 local track=W.Round(W.Frame(volume,"VolumeTrack",UDim2.new(1,-24,0,6),T.Soft),3);track.Position=UDim2.fromOffset(12,39)
 refs.VolumeFill=W.Round(W.Frame(track,"Fill",UDim2.fromScale(.6,1),T.Purple),3)
 refs.Minus=W.Button(volume,"VolumeDown","−",T.Soft);refs.Plus=W.Button(volume,"VolumeUp","+",T.Soft)
 refs.Minus.Position=UDim2.fromOffset(12,56);refs.Plus.Position=UDim2.new(.5,4,0,56)
 refs.Minus.Size=UDim2.new(.5,-16,0,44);refs.Plus.Size=UDim2.new(.5,-16,0,44)
 toggle("ReducedMotion","Motion","CALMER MOTION","Reduce camera shake and menu movement.",T.Blue,4)
 toggle("ReducedEffects","Effects","LIGHTER EFFECTS","Use fewer sparkles and softer visual effects.",T.Pink,5)
 local footer=label(root,"Footer","Sound and effects apply during this play session",16,0,-32,20,11,false)
 footer.Position=UDim2.new(0,16,1,-31);footer.TextXAlignment=Enum.TextXAlignment.Center;footer.TextColor3=T.Muted
 return refs
end
function Skin.Layout(p,size,panelX)
 local x=panelX or 12;local w=math.min(420,size.X-x-12);local h=math.min(640,size.Y-24)
 p.Root.Position=UDim2.fromOffset(x,12);p.Root.Size=UDim2.fromOffset(w,h)
 p.Title.TextSize=if w<360 then 17 else 20
 return {width=w,height=h}
end
return Skin
