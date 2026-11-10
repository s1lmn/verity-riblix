--!nonstrict
local W = require(script.Parent.UIWidgets)
local Art = {}
local INK = Color3.fromHex("171629")

local function shape(parent, name, x, y, w, h, hex, round, angle, edge)
 local node = W.Frame(parent, name, UDim2.fromScale(w,h), Color3.fromHex(hex))
 node.AnchorPoint = Vector2.new(.5,.5)
 node.Position = UDim2.fromScale(x,y)
 node.Rotation = angle or 0
 if round then W.New("UICorner",{CornerRadius=UDim.new(round,0)},node) end
 if edge then W.Stroke(node,INK,edge).Transparency=0 end
 return node
end

local function fade(node, light, dark)
 node.BackgroundColor3 = Color3.new(1,1,1)
 W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex(light),Color3.fromHex(dark)),Rotation=72},node)
end

local function word(parent, name, text, x, y, w, h, hex)
 local label = W.Text(parent,name,text,24,true,Color3.fromHex(hex))
 label.Position = UDim2.fromScale(x,y)
 label.Size = UDim2.fromScale(w,h)
 label.AnchorPoint = Vector2.new(.5,.5)
 label.TextScaled = true
 label.TextXAlignment = Enum.TextXAlignment.Center
 W.New("UIStroke",{Color=INK,Thickness=2},label)
 return label
end

local function sparkle(parent,x,y,size)
 local a=shape(parent,"Sparkle",x,y,size,size*.22,"FFF6C2",.5,45)
 shape(parent,"SparkleCross",x,y,size*.22,size,"FFFFFF",.5,45).ZIndex=a.ZIndex+1
end

local function bill(parent,x,y,width,angle)
 local holder=shape(parent,"Bundle",x,y,width,width*.59,"113C33",.15,angle,2)
 shape(holder,"PaperEdges",.5,.68,.92,.45,"27B15D",.12)
 for _,yEdge in {.63,.78} do
  shape(holder,"PaperEdge",.5,yEdge,.89,.035,"8BEB7E",.5)
 end
 local face=shape(holder,"BillFace",.5,.33,1,.63,"73ED74",.17,0,1)
 fade(face,"BDF980","29D478")
 shape(face,"Print",.23,.5,.21,.44,"116448",.5)
 local strap=shape(holder,"GoldStrap",.57,.5,.26,.99,"FFC134",.12,0,1)
 fade(strap,"FFF189","FFAA29")
 shape(strap,"Shine",.33,.17,.35,.16,"FFFBC3",.5)
end

local function cash(parent,offer)
 for i=1,offer.Stacks-1 do
  bill(parent,.5+(i-2)*.23,.5+((i+1)%2)*.09,.40,(i-2)*21)
 end
 bill(parent,.5,.62,if offer.Stacks==1 then .60 else .57,-14)
 sparkle(parent,.21,.40,.12)
 sparkle(parent,.78,.28,.14)
end

local function orb(parent,x,y,size,light,dark)
 local ball=shape(parent,"Verity",x,y,size,size,light,.5,0,3)
 fade(ball,light,dark)
 shape(ball,"Glint",.29,.24,.29,.12,"FFF9DA",.5,-28)
 for _,eyeX in {.35,.64} do
  local eye=shape(ball,"Eye",eyeX,.48,.116,.18,"1E1831",.5,-8)
  shape(eye,"Catchlight",.35,.26,.32,.32,"FFFFFF",.5)
 end
 local smile=shape(ball,"Smile",.50,.69,.34,.23,"311932",.42,4)
 shape(smile,"Tongue",.56,.75,.56,.32,"FF6888",.5)
 return ball
end

local function boost(parent,id)
 local dial=shape(parent,"Clock",.50,.54,.59,.59,"FFCC51",.5,-12,3)
 fade(dial,"FFF9B0","F89829")
 local rim=shape(dial,"Dial",.5,.5,.78,.78,"583290",.5,0,2)
 fade(rim,"7C57C4","292057")
 for _,t in {.13,.87} do
  shape(rim,"HourMark",.5,t,.055,.09,"FFE79D",.5)
  shape(rim,"HourMark",t,.5,.09,.055,"FFE79D",.5)
 end
 word(dial,"Multiplier",if id=="money_x3" then "×3" else "×2",.50,.50,.75,.48,"FFEB83").ZIndex=3
 if id=="boost_60" or id=="money_x3" then
  shape(parent,"GoldSpeedLine",.17,.61,.23,.047,"FFB53A",.5,-12)
  shape(parent,"LightSpeedLine",.18,.71,.30,.037,"FFF2AD",.5,-12)
 end
 sparkle(parent,.78,.31,.14)
 sparkle(parent,.24,.27,.08)
end

local heroes={
 scarlet_sentinel={"FFC9A2","ED4560","FF344C","Visor"},
 reef_captain={"C0FFE4","22AEBA","1C6899","Visor"},
 phase_courier={"E4C6FF","7445DC","31FBEC","Visor"},
 magma_smith={"FFE080","F65A2C","9D2851","Forge"},
 amber_medic={"FFF4A8","EF9B30","FF5374","Medic"},
 polar_ranger={"D8FAFF","55B3FA","226DBF","Polar"},
}
local function hero(parent,look)
 local ball=orb(parent,.50,.54,.66,look[1],look[2])
 local color=look[3]
 if look[4]=="Visor" then
  local visor=shape(ball,"Visor",.50,.48,.80,.23,color,.28,-6,2)
  fade(visor,color,"492453")
  shape(visor,"VisorGlint",.27,.26,.29,.18,"FFF5DA",.5)
  shape(visor,"VisorGlint",.71,.26,.23,.18,"FFF5DA",.5)
 elseif look[4]=="Medic" then
  local hat=shape(ball,"MedicCap",.45,.14,.58,.35,"FFF3EB",.22,-13,2)
  shape(hat,"CrossArm",.52,.50,.33,.21,color,.16)
  shape(hat,"CrossStem",.52,.50,.12,.55,color,.16)
 elseif look[4]=="Forge" then
  shape(ball,"Helmet",.49,.22,.92,.23,color,.19,-4,2)
  shape(ball,"ForgeStripe",.52,.20,.68,.08,"FFA64B",.5,-4)
 else
  shape(ball,"EarGuard",.11,.46,.24,.37,color,.4,8,2)
  shape(ball,"EarGuard",.91,.46,.24,.37,color,.4,-8,2)
  shape(ball,"SnowTrim",.48,.20,.75,.18,"ECFDFF",.5,-5,2)
 end
 sparkle(parent,.80,.25,.11)
end

local function house(parent)
 local base=shape(parent,"House",.50,.62,.58,.42,"FFAEC6",.12,0,3)
 fade(base,"FFE4D9","EF71AF")
 shape(parent,"Gable",.50,.35,.38,.38,"D65491",.14,45,3)
 local facade=shape(parent,"Facade",.50,.61,.56,.40,"FFD5C2",.12)
 fade(facade,"FFE8D0","F99AB8")
 shape(facade,"Door",.51,.70,.23,.55,"5D4C99",.15,0,2)
 for _,x in {.19,.82} do shape(facade,"Window",x,.45,.19,.29,"FFF3A0",.12,0,2) end
 shape(parent,"Path",.52,.82,.36,.065,"C8FFE0",.3,0,2)
 for _,x in {.17,.82} do
  shape(parent,"Trunk",x,.68,.065,.22,"925777",.25,0,2)
  shape(parent,"Blossoms",x,.51,.24,.23,"FF9CC8",.5,0,2)
  shape(parent,"BlossomLight",x-.035,.47,.10,.078,"FFD8EA",.5)
 end
 sparkle(parent,.76,.29,.10)
end

local function gallery(parent)
 local card=shape(parent,"Album",.51,.54,.58,.64,"7B53B0",.14,12,3)
 fade(card,"CC88FC","583490")
 shape(card,"Frame",.5,.5,.77,.80,"FFC14C",.11,0,2)
 shape(card,"Mount",.5,.5,.63,.66,"4E347E",.1)
 orb(card,.5,.5,.41,"FFF8A2","FF9646")
 sparkle(parent,.81,.32,.10)
end

local function disco(parent)
 shape(parent,"Cord",.50,.24,.04,.25,"EFE3FF",.5)
 local ball=shape(parent,"DiscoBall",.50,.48,.48,.48,"B895FF",.5,0,3)
 fade(ball,"E5FAFF","9443D4")
 for row=1,3 do
  local width=if row==2 then .25 else .20
  for col=1,3 do
   shape(ball,"Mirror",.5+(col-2)*(width+.025),.5+(row-2)*.23,width,.19,
    if (row+col)%2==0 then "FFF3FF" elseif col==1 then "70E7FF" else "F6A6FA",.17)
  end
 end
 for i=1,4 do
  shape(parent,"DanceTile",.5+(i-2.5)*.14,.82,.14,.11,
   if i%2==0 then "FF78EA" else "82E5FF",.17,-8,1)
 end
 sparkle(parent,.78,.31,.13)
end

local function orbit(parent, atmosphere)
 local ring=shape(parent,"Orbit",.5,.55,.87,.40,"D1C4FF",.5,-23)
 ring.BackgroundTransparency=1
 W.Stroke(ring,Color3.fromHex(if atmosphere then "7BFFF1" else "DDB2FF"),4).Transparency=.08
 if atmosphere then
  local planet=shape(parent,"NightSky",.48,.52,.56,.56,"512881",.5,0,2)
  fade(planet,"8878DF","24326B")
  for _,x in {.23,.46,.70} do
   shape(planet,"AuroraRibbon",x,.66-x*.39,.49,.085,if x==.46 then "FF9AF3" else "83FFCC",.5,-24)
  end
 else
  orb(parent,.50,.52,.55,"F1CAFF","7941DE")
 end
 sparkle(parent,.78,.33,.14)
 sparkle(parent,.24,.67,.12)
end

function Art.Build(parent,id,item,offer)
 local illustration=W.Frame(parent,"Illustration",UDim2.new(1,0,1,-38))
 illustration.Position=UDim2.fromOffset(0,35)
 illustration.BackgroundTransparency=1
 local canvas=W.Frame(illustration,"Sticker",UDim2.fromScale(.93,1))
 canvas.BackgroundTransparency=1
 canvas.AnchorPoint=Vector2.new(.5,.5)
 canvas.Position=UDim2.fromScale(.5,.5)
 W.New("UIAspectRatioConstraint",{AspectRatio=1,AspectType=Enum.AspectType.FitWithinMaxSize},canvas)
 local halo=shape(canvas,"Halo",.5,.52,.88,.88,"FFFFFF",.5)
 halo.BackgroundTransparency=.82
 local ground=shape(canvas,"GroundShadow",.50,.85,.69,.10,"181928",.5)
 ground.BackgroundTransparency=.72
 if offer and offer.Art=="Cash" then cash(canvas,offer)
 elseif offer or id=="money_x3" then boost(canvas,id)
 elseif heroes[id] then hero(canvas,heroes[id])
 elseif id=="premium_homes" then house(canvas)
 elseif id=="premium_auras" or id=="home_atmosphere" then orbit(canvas,id=="home_atmosphere")
 elseif id=="fusion_starlight" then
  orb(canvas,.36,.57,.49,"FFE48C","FF7848")
  orb(canvas,.66,.48,.47,"B5F7FF","6954DF")
  sparkle(canvas,.52,.29,.14)
 elseif id=="party_disco" then disco(canvas)
 elseif id=="collector_gallery" then gallery(canvas)
 else orb(canvas,.50,.54,.62,item.Color,"6548A8") end
 return illustration
end

return Art
