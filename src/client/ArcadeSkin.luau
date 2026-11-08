--!nonstrict
-- Presentation owned and ticked by ArcadeController. All scores remain server-authored.
local W=require(script.Parent.UIWidgets)
local T=require(script.Parent.UITheme)
local Art=require(script.Parent.CollectionArt)
local Locale=require(script.Parent.Locale)
local C=require(game:GetService("ReplicatedStorage").Shared.ArcadeConfig)
local S={}
local function text(parent,name,value,size,color,x,y,w,h)
 local t=W.Text(parent,name,value,size,true,color);t.Position=UDim2.new(x,0,y,0);t.Size=UDim2.fromScale(w,h)
 t.TextXAlignment=Enum.TextXAlignment.Center;return t
end
function S.Build(self,ctx)
 local root=W.Round(W.Frame(ctx.refs.Safe,"HomeArcade",UDim2.fromOffset(360,510),Color3.fromHex("35215F")),24)
 self.root=self.cleanup:Add(root);root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromScale(.5,.5)
 root.Visible=false;root.Active=true;root.ZIndex=35;root.SelectionGroup=true
 W.Stroke(root,Color3.fromHex("CBB3FF"),2).Transparency=.18
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("584084"),Color3.fromHex("211638")),Rotation=90},root)
 self.openScale=W.New("UIScale",{Scale=1},root)
 local header=W.Round(W.Frame(root,"Marquee",UDim2.new(1,-16,0,46),T.Paper),16);header.Position=UDim2.fromOffset(8,8)
 W.New("UIGradient",{Color=ColorSequence.new(T.Paper,Color3.fromHex("F4DFFF")),Rotation=15},header)
 self.title=W.Text(header,"Title","ЗВЁЗДНЫЙ ПОТОК",16,true,T.Purple);self.title.Position=UDim2.fromOffset(12,1);self.title.Size=UDim2.new(1,-64,0,25)
 local brand=W.Text(header,"Brand","VERITY ARCADE",9,true,T.Muted);brand.Position=UDim2.fromOffset(12,27);brand.Size=UDim2.new(1,-64,0,13)
 self.close=W.Button(root,"Close","×",T.Pink:Lerp(T.White,.65));self.close.Position=UDim2.new(1,-54,0,9);self.close.Size=UDim2.fromOffset(44,44)
 self.hud=W.Frame(root,"Scoreboard",UDim2.new());self.hud.BackgroundTransparency=1
 self.scoreTitle=text(self.hud,"Label","ОЧКИ",10,T.White,.02,0,.36,.24)
 self.score=text(self.hud,"Score","0",33,T.Gold,0,.22,.4,.75)
 self.record=text(self.hud,"Best","",11,T.White,.44,.02,.55,.36)
 self.lives={}
 for i=1,3 do self.lives[i]=text(self.hud,"Life"..i,"♥",21,T.Pink,.44+(i-1)*.12,.46,.11,.5) end
 self.time=text(self.hud,"Time","30",13,T.Gold,.82,.46,.17,.5)
 self.board=W.Round(W.Frame(root,"Lanes",UDim2.new(),Color3.fromHex("19172F")),15);self.board.ClipsDescendants=true
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("392858"),Color3.fromHex("151B36")),Rotation=90},self.board)
 W.Stroke(self.board,T.Purple,1).Transparency=.5
 self.tracks={}
 for lane=1,3 do
  local track=W.Round(W.Frame(self.board,"Lane"..lane,UDim2.new(1/3,-6,1,-8),T.Purple),10)
  track.Position=UDim2.new((lane-1)/3,3,0,4);track.BackgroundTransparency=.92;self.tracks[lane]=track
  local target=Art.Shape(track,"LandingPad",.5,.89,.70,.10,T.Mint,100);target.BackgroundTransparency=.84
 end
 self.sky={}
 for i=1,12 do
  local p=Art.Shape(self.board,"SkySpark",.04+(i*29%91)/100,.04+(i*17%70)/100,.009,.009,T.White,100)
  W.New("UIAspectRatioConstraint",{AspectRatio=1},p);p.BackgroundTransparency=.5;self.sky[i]=p
 end
 self.timeTrack=W.Round(W.Frame(self.board,"TimeTrack",UDim2.new(1,-18,0,3),T.Ink),3);self.timeTrack.Position=UDim2.fromOffset(9,9)
 self.timeFill=W.Round(W.Frame(self.timeTrack,"Fill",UDim2.fromScale(1,1),T.Mint),3)
 self.combo=text(self.board,"Combo","",12,T.Gold,.06,.06,.88,.09)
 self.cursor=W.Frame(self.board,"Player",UDim2.fromOffset(44,44));self.cursor.BackgroundTransparency=1;self.cursor.AnchorPoint=Vector2.new(.5,.5)
 Art.Face(self.cursor,T.Mint);self.cursorScale=W.New("UIScale",{Scale=1},self.cursor)
 self.drops={}
 for i=1,8 do
  local drop=W.Frame(self.board,"Drop"..i,UDim2.fromOffset(40,40));drop.BackgroundTransparency=1;drop.AnchorPoint=Vector2.new(.5,.5);drop.Visible=false
  local star=Art.Star(drop,T.Gold)
  local meteor=W.Frame(drop,"Meteor");meteor.BackgroundTransparency=1
  for j=1,3 do local tail=Art.Shape(meteor,"Flame",.5,.25-(j-1)*.10,.55-j*.10,.25,T.Pink,100);tail.BackgroundTransparency=.2+j*.15 end
  local core=Art.Shape(meteor,"Core",.5,.61,.62,.62,Color3.fromHex("FF7DAB"),100)
  W.New("UIGradient",{Color=ColorSequence.new(T.Peach,T.Pink),Rotation=100},core)
  Art.Shape(meteor,"Crater",.42,.56,.16,.12,Color3.fromHex("AB4279"),100)
  Art.Shape(meteor,"Crater",.63,.71,.10,.09,Color3.fromHex("AB4279"),100)
  self.drops[i]={root=drop,star=star,meteor=meteor}
 end
 self.flash=W.Round(W.Frame(self.board,"Impact",UDim2.fromScale(1,1),T.Gold),15);self.flash.BackgroundTransparency=1
 self.feedback=text(self.board,"Feedback","",18,T.Gold,.05,.60,.9,.15);self.feedback.Visible=false
 self.resultPanel=W.Round(W.Frame(self.board,"Results",UDim2.fromScale(1,1),Color3.fromHex("211B3C")),15);self.resultPanel.Visible=false
 local medal=W.Frame(self.resultPanel,"Medal",UDim2.fromScale(.22,.25));medal.Position=UDim2.fromScale(.39,.02);medal.BackgroundTransparency=1
 W.New("UIAspectRatioConstraint",{AspectRatio=1},medal);self.medal=Art.Star(medal,T.Gold)
 self.resultTitle=text(self.resultPanel,"Heading","",14,T.Gold,.04,.29,.92,.15)
 self.resultScore=text(self.resultPanel,"Score","0",36,T.White,.04,.44,.92,.25)
 self.resultDetail=text(self.resultPanel,"Prize","",11,T.Mint,.06,.73,.88,.20)
 self.resultDetail.TextWrapped=true
 self.prizeTray=W.Frame(root,"PrizeProgress");self.prizeTray.BackgroundTransparency=1;self.prizeBadges={}
 for index,prize in C.Prizes do
  local badge=W.Round(W.Frame(self.prizeTray,prize.Id,UDim2.new(1/3,-4,1,0),T.Purple),9)
  badge.Position=UDim2.new((index-1)/3,2,0,0);badge.BackgroundTransparency=.7
  self.prizeBadges[index]=text(badge,"Score","★ "..prize.Score,11,Color3.fromHex(prize.Color),0,0,1,1)
 end
 self.left=W.Button(root,"Left","←",Color3.fromHex("B8FFE0"));self.right=W.Button(root,"Right","→",Color3.fromHex("FFE8A6"))
 self.left:SetAttribute("FixedFeedbackSize",true);self.right:SetAttribute("FixedFeedbackSize",true)
 self.controls=W.Text(root,"Controls","",10,false,Color3.fromHex("DFD0F6"));self.controls.TextXAlignment=Enum.TextXAlignment.Center
 for _,object in root:GetDescendants() do if object:IsA("GuiObject") then object.ZIndex=36 end end
 -- Results/feedback are explicitly above the falling pieces in either ZIndex mode.
 for _,object in self.resultPanel:GetDescendants() do if object:IsA("GuiObject") then object.ZIndex=39 end end
 self.resultPanel.ZIndex=38;self.flash.ZIndex=37;self.feedback.ZIndex=38;self.close.ZIndex=40
 root.ClipsDescendants=true
end
function S.Layout(self,size)
 local wide=size.Y<430 and size.X>=440 and size.X>size.Y
 local width=math.max(200,math.min(if wide then 610 else 370,size.X-20))
 local height=math.max(220,math.min(if wide then 340 else 540,size.Y-16))
 self.root.Size=UDim2.fromOffset(width,height)
 self.prizeTray.Visible=wide or height>=430
 if wide then
  self.hud.Position=UDim2.fromOffset(12,65);self.hud.Size=UDim2.new(.36,-12,0,70)
  self.board.Position=UDim2.new(.39,0,0,64);self.board.Size=UDim2.new(.61,-12,1,-138)
  self.prizeTray.Position=UDim2.new(0,12,0,146);self.prizeTray.Size=UDim2.new(.36,-12,0,30)
  self.left.Position=UDim2.new(.39,0,1,-64);self.left.Size=UDim2.new(.305,-6,0,44)
  self.right.Position=UDim2.new(.695,0,1,-64);self.right.Size=self.left.Size
  self.controls.Position=UDim2.new(0,12,0,180);self.controls.Size=UDim2.new(.36,-12,0,math.max(25,height-190))
 else
  self.hud.Position=UDim2.fromOffset(12,62);self.hud.Size=UDim2.new(1,-24,0,57)
  self.board.Position=UDim2.fromOffset(12,124);self.board.Size=UDim2.new(1,-24,0,math.max(1,height-250))
  self.prizeTray.Position=UDim2.new(0,12,1,-116);self.prizeTray.Size=UDim2.new(1,-24,0,28)
  self.left.Position=UDim2.new(0,12,1,-78);self.left.Size=UDim2.new(.5,-18,0,44)
  self.right.Position=UDim2.new(.5,6,1,-78);self.right.Size=self.left.Size
  self.controls.Position=UDim2.new(0,12,1,-30);self.controls.Size=UDim2.new(1,-24,0,24)
  if height<430 then
   self.hud.Size=UDim2.new(1,-24,0,45)
   self.board.Position=UDim2.fromOffset(12,110);self.board.Size=UDim2.new(1,-24,0,math.max(1,height-200))
  end
 end
 self.scoreTitle.Text=Locale.Text("ОЧКИ");self.title.Text=Locale.Text("ЗВЁЗДНЫЙ ПОТОК")
 local boardHeight=self.board.AbsoluteSize.Y
 self.resultTitle.TextSize=if boardHeight<180 then 11 else 14
 self.resultScore.TextSize=if boardHeight<180 then 24 else 36
 self.resultDetail.TextSize=if boardHeight<180 then 9 else 11
end
return S
