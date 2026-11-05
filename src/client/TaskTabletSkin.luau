--!nonstrict
-- Toy order board: native widgets, shared task protocol, no external assets.
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Skin={}
local violet=Color3.fromHex("9960DC")
local cream=Color3.fromHex("FFF6ED")
local orders={
 {"PRESS_BUTTON","НАЖМИ КНОПКУ","Найди отмеченную кнопку и нажми её.",T.Pink},
 {"REACH_POINT","ПРОГУЛКА ПО РАЙОНУ","Доберись до точки, которую покажет стрелка.",T.Blue},
 {"STAND_ON_PLATFORM","ПОСТОЙ НА ПЛАТФОРМЕ","Встань на отмеченную платформу на одну секунду.",T.Mint},
 {"POSTBOX","РАЙОННАЯ ПОЧТА","Дойди до оранжевого ящика и отправь письмо.",T.Gold},
 {"CHECKPOINT","СИРЕНЕВЫЙ МАРШРУТ","Доберись до сиреневой метки на другой стороне улицы.",T.Purple},
 {"CHARGE_PAD","ЗАРЯДКА VERITY","Останься на зелёной площадке три секунды.",T.Mint},
}
local cardHeight, gap = 176, 10
local contentHeight = #orders * (cardHeight + gap) - gap
local function shape(parent,name,x,y,w,h,color,radius)
 local f=W.Round(W.Frame(parent,name,UDim2.fromOffset(w,h),color),radius or 4)
 f.Position=UDim2.fromOffset(x,y);return f
end
local function actionIcon(parent,kind,color)
 local tile=shape(parent,"ActionIcon",12,12,36,36,color,10)
 if kind=="POSTBOX" then
  shape(tile,"Envelope",6,10,24,17,T.White,4)
  local flap=shape(tile,"Fold",12,9,12,12,T.Ink,3);flap.Rotation=45
 elseif kind=="PRESS_BUTTON" then
  shape(tile,"Base",7,22,22,7,T.Ink,3)
  shape(tile,"Button",10,10,16,15,T.White,7)
 elseif kind=="REACH_POINT" or kind=="CHECKPOINT" then
  shape(tile,"Pin",10,5,16,20,T.Ink,9)
  shape(tile,"Center",15,10,6,6,T.White,6)
  shape(tile,"Shadow",7,28,22,3,T.White,3)
 else
  shape(tile,"Platform",5,25,26,7,T.Ink,3)
  shape(tile,"FootA",9,7,7,15,T.White,4)
  shape(tile,"FootB",21,10,7,15,T.White,4)
 end
end
function Skin.Build(parent)
 local root=W.Round(W.Frame(parent,"Tasks",UDim2.fromOffset(420,640),violet),28)
 root.Visible=false;root.Active=true;root.SelectionGroup=true
 for _,dir in {"Up","Down","Left","Right"} do root["SelectionBehavior"..dir]=Enum.SelectionBehavior.Stop end
 W.Stroke(root,Color3.fromHex("633D92"),3).Transparency=.08
 local shell=shape(root,"CreamBoard",6,6,408,628,cream,23)
 shell.Size=UDim2.new(1,-12,1,-12)
 local clip=shape(root,"OrderClip",0,4,78,16,T.Gold,7)
 clip.AnchorPoint=Vector2.new(.5,0);clip.Position=UDim2.new(.5,0,0,4)
 shape(clip,"ClipInset",18,5,42,4,Color3.fromHex("D7A72F"),2)
 local title=W.Text(root,"Title","ЗАКАЗЫ РАЙОНА",20,true)
 title.Position=UDim2.fromOffset(20,28);title.Size=UDim2.new(1,-86,0,32)
 local subtitle=W.Text(root,"Subtitle","Маленькое приключение — приятная награда!",12,false,T.Muted)
 subtitle.Position=UDim2.fromOffset(20,64);subtitle.Size=UDim2.new(1,-40,0,34)
 local close=W.Button(root,"Close","×",T.Gold)
 close.Size=UDim2.fromOffset(44,44);close.Position=UDim2.new(1,-62,0,24);close.TextSize=26
 local body=W.New("ScrollingFrame",{Name="Orders",BackgroundTransparency=1,BorderSizePixel=0,
  Position=UDim2.fromOffset(16,108),Size=UDim2.new(1,-32,1,-144),CanvasSize=UDim2.fromOffset(0,contentHeight),
  AutomaticCanvasSize=Enum.AutomaticSize.None,ScrollingDirection=Enum.ScrollingDirection.Y,
  ScrollBarThickness=3,ScrollBarImageColor3=violet},root)
 W.List(body,gap)
 local rows={}
 for index,info in orders do
  local card=W.Round(W.Frame(body,info[1],UDim2.new(1,-6,0,cardHeight),T.White),16)
  card.LayoutOrder=index;W.Stroke(card,info[4],2).Transparency=.45
  actionIcon(card,info[1],info[4])
  local heading=W.Text(card,"Title",info[2],14,true)
  heading.Position=UDim2.fromOffset(58,10);heading.Size=UDim2.new(1,-70,0,40)
  local description=W.Text(card,"Description",info[3],12,false,T.Muted)
  description.Position=UDim2.fromOffset(12,53);description.Size=UDim2.new(1,-24,0,34)
  local rewardBadge=shape(card,"RewardBadge",12,92,94,24,T.Gold,8)
  local reward=W.Text(rewardBadge,"Reward","$—",15,true)
  reward.TextXAlignment=Enum.TextXAlignment.Center;reward.Size=UDim2.fromScale(1,1)
  local status=W.Text(card,"Status","Загрузка…",11,true,T.Muted)
  status.Position=UDim2.fromOffset(116,92);status.Size=UDim2.new(1,-128,0,24)
  status.TextXAlignment=Enum.TextXAlignment.Right
  local button=W.Button(card,"Start","ЗАГРУЗКА…",info[4])
  button.Position=UDim2.fromOffset(12,120);button.Size=UDim2.new(1,-24,0,44)
  rows[info[1]]={Root=card,Title=heading,Description=description,Reward=reward,Status=status,Button=button}
 end
 local footer=W.Text(root,"Footer","Выбери заказ — стрелка покажет путь",11,false,T.Muted)
 footer.Position=UDim2.new(0,16,1,-31);footer.Size=UDim2.new(1,-32,0,20)
 footer.TextXAlignment=Enum.TextXAlignment.Center
 return {Root=root,Title=title,Subtitle=subtitle,Close=close,Body=body,Rows=rows,Footer=footer}
end
function Skin.Layout(p,size,panelX)
 local width=math.min(420,size.X-(panelX or 12)-12)
 local height=math.min(640,size.Y-24)
 p.Root.Position=UDim2.fromOffset(panelX or 12,12)
 p.Root.Size=UDim2.fromOffset(width,height)
 p.Title.TextSize=if width<360 then 16 else 20
 return {width=width,height=height,contentHeight=contentHeight,bodyHeight=height-144}
end
return Skin
