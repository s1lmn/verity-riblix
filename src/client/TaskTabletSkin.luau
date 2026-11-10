--!nonstrict
-- One story page, no task picker.
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Skin={}
local function line(parent,name,size,bold,color)
 local label=W.Text(parent,name,"",size,bold,color)
 label.Size=UDim2.new(1,0,0,0);label.AutomaticSize=Enum.AutomaticSize.Y
 label.TextYAlignment=Enum.TextYAlignment.Top;return label
end
function Skin.Build(parent)
 local root=W.Round(W.Frame(parent,"Story",UDim2.fromOffset(420,580),T.Paper),20)
 root.Visible=false;root.Active=true;root.SelectionGroup=true;root.ClipsDescendants=true
 for _,d in {"Up","Down","Left","Right"} do root["SelectionBehavior"..d]=Enum.SelectionBehavior.Stop end
 W.Stroke(root,T.Purple,2).Transparency=.4
 local title=W.Text(root,"Title","ИСТОРИЯ РАЙОНА",20,true)
 title.Position=UDim2.fromOffset(16,12);title.Size=UDim2.new(1,-78,0,30)
 local subtitle=W.Text(root,"Subtitle","Необязательное приключение",12,false,T.Muted)
 subtitle.Position=UDim2.fromOffset(16,44);subtitle.Size=UDim2.new(1,-32,0,25)
 local close=W.Button(root,"Close","×",T.Gold);close.Size=UDim2.fromOffset(44,44);close.Position=UDim2.new(1,-58,0,10)
 close:SetAttribute("FixedFeedbackSize",true)
 local body=W.New("ScrollingFrame",{Name="StoryPage",BackgroundTransparency=1,BorderSizePixel=0,
  Position=UDim2.fromOffset(12,79),Size=UDim2.new(1,-24,1,-91),AutomaticCanvasSize=Enum.AutomaticSize.Y,
  CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,ScrollBarImageColor3=T.Purple},root)
 W.List(body,10);W.Padding(body,3)
 local card=W.Round(W.Frame(body,"CurrentChapter",UDim2.new(1,-6,0,0),T.White),16)
 card.AutomaticSize=Enum.AutomaticSize.Y;W.Padding(card,14);W.List(card,12)
 W.Stroke(card,T.Purple,1).Transparency=.5
 local refs={Root=root,Title=title,Subtitle=subtitle,Close=close,Body=body,Rows={}}
 refs.Speaker=line(card,"Speaker",12,true,T.Purple)
 refs.Heading=line(card,"ChapterTitle",21,true,T.Ink)
 refs.Narrative=line(card,"Narrative",14,false,T.Ink)
 refs.Step=line(card,"CurrentAction",15,true,T.Ink)
 refs.Progress=line(card,"Progress",12,false,T.Muted)
 refs.Reward=line(card,"CashReward",18,true,Color3.fromHex("2B8563"))
 refs.Milestone=line(card,"Keepsake",13,true,T.Purple)
 refs.Guide=W.Button(card,"Guide","ПОКАЗАТЬ ПУТЬ",T.Gold);refs.Guide.Size=UDim2.new(1,0,0,48)
 refs.Pause=W.Button(card,"Pause","ОТЛОЖИТЬ ИСТОРИЮ",T.Soft);refs.Pause.Size=UDim2.new(1,0,0,44)
 refs.Guide:SetAttribute("FixedFeedbackSize",true);refs.Pause:SetAttribute("FixedFeedbackSize",true)
 refs.Hint=line(card,"OptionalHint",12,false,T.Muted)
 return refs
end
function Skin.Layout(p,size,panelX)
 p.Root.Position=UDim2.fromOffset(panelX or 12,12)
 p.Root.Size=UDim2.fromOffset(math.min(460,size.X-(panelX or 12)-12),math.min(680,size.Y-24))
 p.Title.TextSize=if p.Root.Size.X.Offset<360 then 16 else 20
 return {width=p.Root.Size.X.Offset,height=p.Root.Size.Y.Offset}
end
return Skin
