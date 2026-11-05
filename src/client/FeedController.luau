--!nonstrict
local Drops = require(game:GetService("ReplicatedStorage").Shared.FeedDrops)
local Locale = require(script.Parent.Locale)
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local SceneArt = require(script.Parent.FeedSceneArt)
local Feed = {}
Feed.__index = Feed
Feed.Posts = {
	{ "Cute Verity", "Small friend. Big future.", "verity", T.Pink, T.Peach },
	{ "Firefly Night", "A thousand lights found the garden.", "fireflies", T.Purple, T.Mint },
	{ "Cloud Express", "Next stop is above the clouds.", "balloon", T.Blue, T.Peach },
	{ "Star Workshop", "Verity is making something that shines.", "workshop", T.Gold, T.Purple },
	{ "Coral Expedition", "Follow the bubbles to a secret reef.", "reef", T.Blue, T.Mint },
	{ "Rainbow Verity", "Every shade of happy.", "rainbow", T.Blue, T.Purple },
	{ "Verity Crown", "A royal little upgrade.", "crown", T.Gold, T.Peach },
	{ "Luxury House", "One day, this will be home.", "house", T.Mint, T.Blue },
	{ "Cartoon Planet", "Dream a little bigger.", "planet", T.Purple, T.Blue },
	{ "Cute Pet", "Your daily dose of tiny paws.", "pet", T.Peach, T.Pink },
	{ "Funny Food", "A very good day for a snack.", "food", T.Gold, T.Peach },
	{ "Color Explosion", "Good vibes, all directions.", "burst", T.Pink, T.Purple },
	{ "Dream Car", "Next stop: everywhere.", "car", T.Blue, T.Mint },
	{ "Fantasy Landscape", "A softer kind of adventure.", "landscape", T.Mint, T.Purple },
	{ "Party Verity", "You brought the good energy.", "party", T.Purple, T.Pink },
	{ "Midnight District", "The neighborhood looks different at night.", "district", T.Purple, T.Blue },
	{ "Desert Discovery", "A tiny explorer finds a giant crystal.", "desert", T.Peach, T.Gold },
	{ "Comet Ride", "Verity caught the last comet home.", "comet", T.Pink, T.Purple },
	{ "Rainy Day Café", "A warm cup while the rain taps the window.", "cafe", T.Peach, T.Blue },
	{ "Golden Verity", "Keep growing. Keep glowing.", "golden", T.Gold, T.Peach },
}

-- Keep the illustration IDs aligned with the shared drop catalog.
local previousPosts = Feed.Posts
Feed.Posts = {}
for index, previous in previousPosts do
	local art = SceneArt[index]
	table.insert(Feed.Posts, previous)
	table.insert(Feed.Posts, {art.title, art.caption, art, Color3.fromHex(art.top), Color3.fromHex(art.bottom)})
end

local function shape(parent, name, x, y, width, height, color, radius, rotation)
	local frame = W.Frame(parent, name, UDim2.fromScale(width, height), color)
	frame.Position, frame.AnchorPoint, frame.Rotation = UDim2.fromScale(x, y), Vector2.new(0.5, 0.5), rotation or 0
	if radius then W.Round(frame, radius) end
	return frame
end

local function face(parent, x, y, width, height, color, ears)
	if ears then
		shape(parent, "LeftEar", x-width*0.31, y-height*0.49, width*0.23, height*0.5, color, 100, -16)
		shape(parent, "RightEar", x+width*0.31, y-height*0.49, width*0.23, height*0.5, color, 100, 16)
	end
	shape(parent, "Shadow", x, y+height*.08, width*1.06, height*1.04, T.Ink, 100).BackgroundTransparency=.68
	local body=shape(parent, "Body", x, y, width, height, color, 100)
	W.New("UIGradient",{Color=ColorSequence.new(color:Lerp(T.White,.25),color),Rotation=70},body)
	shape(parent,"Highlight",x-width*.23,y-height*.28,width*.22,height*.07,T.White,100,-32).BackgroundTransparency=.25
	shape(parent, "LeftEye", x-width*0.19, y-height*0.05, width*0.055, height*0.12, T.Ink, 100)
	shape(parent, "RightEye", x+width*0.19, y-height*0.05, width*0.055, height*0.12, T.Ink, 100)
	shape(parent, "BlushLeft", x-width*0.30, y+height*0.10, width*0.13, height*0.06, T.Pink, 100)
	shape(parent, "BlushRight", x+width*0.30, y+height*0.10, width*0.13, height*0.06, T.Pink, 100)
	-- Native shapes avoid missing smile glyphs on Roblox's bundled fonts.
	shape(parent, "Smile", x, y+height*0.17, width*0.13, height*0.075, T.Ink, 100)
end

local function crown(parent, x, y, width)
	shape(parent, "CrownBase", x, y+0.05, width, 0.10, T.Gold, 5)
	for index = 1, 3 do
		shape(parent, "CrownTip" .. index, x+(index-2)*width*0.3, y-0.01, width*0.24, 0.17, T.Gold, 3, if index==1 then -16 elseif index==3 then 16 else 0)
	end
	shape(parent, "CrownGem", x, y+0.05, width*0.13, 0.05, T.Purple, 100)
end


local function vivid(color)
	local hue, saturation, value = color:ToHSV()
	return Color3.fromHSV(hue, math.min(1, saturation * 1.42), math.min(1, value * 1.2))
end

local function scene(canvas, top, bottom)
	local plate = W.Round(W.Frame(canvas, "Scene", UDim2.fromScale(1, 1), T.White), 15)
	plate.ClipsDescendants = true
	W.New("UIGradient", {Color = ColorSequence.new(vivid(Color3.fromHex(top)), vivid(Color3.fromHex(bottom))), Rotation = 55}, plate)
	local layer = W.Frame(plate, "Artwork")
	layer.BackgroundTransparency = 1
	return layer
end

local function spark(canvas, x, y, size, color)
	shape(canvas, "SparkHalo", x, y, size*2.6, size*2.6, color, 100).BackgroundTransparency = .74
	shape(canvas, "Spark", x, y, size, size, color, 2, 45)
	shape(canvas,"StarRay",x,y,size*.20,size*2.1,color,2)
	shape(canvas,"StarRay",x,y,size*2.1,size*.20,color,2)
end

local function skyDots(canvas, count, color)
	for i=1,count do
		spark(canvas, .07 + ((i*31)%83)/100, .09 + ((i*23)%71)/100, .014 + (i%3)*.008, color)
	end
end

local function cloud(canvas, x, y, width, color)
	shape(canvas, "CloudBase", x, y, width, width*.24, color, 100)
	shape(canvas, "CloudTop", x-width*.11, y-width*.1, width*.47, width*.43, color, 100)
end

local function drawScene(canvas, kind)
	if type(kind) == "table" then
		local art = scene(canvas, kind.top, kind.bottom)
		for _, layer in kind.layers do
			local style, x, y, width = layer[1], layer[2], layer[3], layer[4]
			if style == "D" then
				spark(art, x, y, width, vivid(Color3.fromHex(layer[5])))
			elseif style == "C" then
				cloud(art, x, y, width, vivid(Color3.fromHex(layer[5])))
			elseif style == "V" then
				face(art, x, y, width, width, vivid(Color3.fromHex(layer[5])), false)
			else
				shape(art, "Detail", x, y, width, layer[5], vivid(Color3.fromHex(layer[6])),
					if style == "O" then 100 else 6, layer[7])
			end
		end
		return true
	end
	if kind=="fireflies" then
		local a=scene(canvas,"17143D","275565")
		shape(a,"Moon",.76,.22,.24,.24,T.Gold,100)
		shape(a,"Hill",.23,1.03,1.38,.63,Color3.fromHex("154A51"),100)
		shape(a,"Hill",.84,1.06,1.12,.54,Color3.fromHex("216B62"),100)
		skyDots(a,15,T.Gold)
		face(a,.48,.60,.36,.36,T.Mint,false)
		for i=1,5 do shape(a,"Grass",.06+i*.17,.94,.035,.22,T.Mint,6,i*9-24) end
	elseif kind=="balloon" then
		local a=scene(canvas,"56A8F4","F8CCFC")
		cloud(a,.16,.35,.36,T.White)
		cloud(a,.78,.72,.48,T.White)
		cloud(a,.15,.88,.42,T.Paper)
		shape(a,"Cable",.41,.58,.018,.3,T.Ink,3,-10)
		shape(a,"Cable",.59,.58,.018,.3,T.Ink,3,10)
		shape(a,"Basket",.5,.73,.23,.14,T.Peach,8)
		face(a,.5,.37,.41,.41,T.Pink,false)
		shape(a,"Shine",.39,.25,.1,.038,T.White,8,-38).BackgroundTransparency=.3
	elseif kind=="workshop" then
		local a=scene(canvas,"302052","9657B5")
		for i=1,5 do
			shape(a,"Shelf",.5,.14+i*.12,.87,.018,T.Purple,4).BackgroundTransparency=.62
		end
		shape(a,"Bench",.5,.8,.84,.11,T.Peach,7)
		shape(a,"BenchFront",.5,.92,.75,.15,Color3.fromHex("492C5E"),7)
		for i=1,4 do
			shape(a,"Crystal",.16+i*.14,.64-(i%2)*.09,.1,.21,({T.Blue,T.Pink,T.Gold,T.Mint})[i],5,36)
			spark(a,.16+i*.14,.44-(i%2)*.08,.029,T.White)
		end
		face(a,.79,.28,.25,.25,T.Gold,false)
	elseif kind=="reef" then
		local a=scene(canvas,"258FD4","0D3C71")
		for i=1,5 do
			shape(a,"Coral",.08+i*.16,.93,.07,.22+(i%3)*.09,({T.Pink,T.Peach,T.Mint})[i%3+1],8,i*10-30)
		end
		skyDots(a,12,T.Blue)
		shape(a,"DiveBubble",.47,.49,.57,.57,T.Blue,100).BackgroundTransparency=.48
		face(a,.47,.49,.37,.37,T.Gold,false)
		local glass=shape(a,"GlassRim",.47,.49,.58,.58,T.White,100)
		glass.BackgroundTransparency=1
		W.Stroke(glass,T.White,1.6).Transparency=.2
		shape(a,"GlassShine",.31,.32,.12,.034,T.White,7,-39)
	elseif kind=="district" then
		local a=scene(canvas,"151A47","683F9C")
		skyDots(a,9,T.Paper)
		shape(a,"Moon",.76,.21,.19,.19,T.Gold,100)
		for i=1,5 do
			local x=.1+(i-1)*.2
			local h=.26+(i%3)*.1
			shape(a,"Building",x,.8-h*.5,.17,h,Color3.fromHex("262653"),5)
			for row=1,2 do for col=1,2 do
				shape(a,"Window",x+(col-1.5)*.065,.8-h+row*.085,.042,.05,if i%2==0 then T.Blue else T.Gold,3)
			end end
		end
		shape(a,"Street",.5,.9,1,.2,Color3.fromHex("121932"),5)
		for i=1,5 do shape(a,"LaneDash",i*.17,.91,.09,.019,T.Paper,4) end
		face(a,.46,.28,.22,.22,T.Pink,false)
	elseif kind=="desert" then
		local a=scene(canvas,"F5B583","FB784F")
		shape(a,"Sun",.74,.29,.31,.31,T.Gold,100)
		shape(a,"Dune",.20,1.03,1.4,.68,Color3.fromHex("D56B65"),100)
		shape(a,"Dune",.84,1.1,1.36,.63,Color3.fromHex("F5A254"),100)
		shape(a,"Crystal",.71,.66,.19,.34,T.Mint,7,28)
		shape(a,"CrystalShine",.69,.60,.035,.15,T.White,5,28).BackgroundTransparency=.35
		spark(a,.8,.42,.05,T.White)
		face(a,.31,.71,.29,.29,T.Peach,false)
	elseif kind=="comet" then
		local a=scene(canvas,"141D4B","53317A")
		skyDots(a,15,T.White)
		for i=1,4 do
			shape(a,"CometTrail",.34,.62+i*.047,.53-i*.055,.067,({T.Blue,T.Mint,T.Purple,T.Pink})[i],100,-32).BackgroundTransparency=.16
		end
		shape(a,"CometGlow",.66,.44,.43,.43,T.Blue,100).BackgroundTransparency=.65
		face(a,.66,.44,.31,.31,T.Pink,false)
		spark(a,.79,.28,.045,T.Gold)
	elseif kind=="cafe" then
		local a=scene(canvas,"577D9F","A6BCCC")
		for i=1,10 do
			shape(a,"Rain",.06+i*.085,.16+(i*17%55)/100,.015,.13,T.White,6,19).BackgroundTransparency=.33
		end
		shape(a,"WindowFrame",.5,.42,.032,.82,T.Ink,5)
		shape(a,"Counter",.5,.86,1,.29,Color3.fromHex("814A5B"),9)
		local handle=shape(a,"CupHandle",.73,.64,.18,.18,T.Paper,100)
		handle.BackgroundTransparency=1
		W.Stroke(handle,T.Paper,4).Transparency=0
		shape(a,"Saucer",.51,.8,.54,.1,T.Peach,100)
		shape(a,"Cup",.51,.66,.39,.24,T.Paper,12)
		for i=1,3 do
			shape(a,"Steam",.37+i*.069,.47-i*.038,.025,.15,T.White,8,i*8-20).BackgroundTransparency=.36
		end
		face(a,.49,.66,.13,.13,T.Pink,false)
	else return false end
	return true
end

function Feed.Draw(parent, index, reward, isNew)
	local post = Feed.Posts[index]
	local rarity, chance = Drops.Get(index)
	local accent = Color3.fromHex(rarity.color)
	local card = W.Round(W.Frame(parent, "Post_" .. index), 14)
	card.BackgroundColor3 = T.White
	card.ClipsDescendants = true
	local dark = Color3.fromHex("161435")
	W.New("UIGradient", {
		Color = ColorSequence.new(vivid(post[4]):Lerp(dark,.15), vivid(post[5]):Lerp(dark,.38)),
		Rotation = 55,
	}, card)
	local rim = W.Stroke(card,accent,if rarity.multiplier >= 8 then 3 else 2)
	rim.Transparency = .14

	local tag = W.Round(W.Text(card, "Rarity", "", 11, true, dark), 8)
	tag.BackgroundColor3, tag.BackgroundTransparency = accent, 0
	tag.Position, tag.Size = UDim2.fromScale(.045,.025), UDim2.fromScale(.58,.095)
	tag.TextXAlignment, tag.TextScaled = Enum.TextXAlignment.Center, true
	W.New("UITextSizeConstraint", {MinTextSize=7, MaxTextSize=12}, tag)

	local payout = W.Text(card,"Payout","",15,true,T.White)
	payout.Position,payout.Size=UDim2.fromScale(.65,.025),UDim2.fromScale(.305,.095)
	payout.TextXAlignment,payout.TextScaled=Enum.TextXAlignment.Right,true
	W.New("UITextSizeConstraint", {MinTextSize=7, MaxTextSize=17}, payout)
	local function renderNumbers()
		local odds = string.format("%.2f", chance):gsub("0+$", ""):gsub("%.$", "")
		if Locale.GetLanguage() == "ru" then odds = odds:gsub("%.", ",") end
		tag.Text = Locale.Text(rarity.label) .. " • " .. odds .. "%"
		payout.Text = if reward then "+$" .. Locale.Number(reward) else string.format("#%02d",index)
	end
	renderNumbers()
	local localeConnection = Locale.Changed.Event:Connect(renderNumbers)
	card.Destroying:Once(function() localeConnection:Disconnect() end)
	if isNew then
		local badge=W.Round(W.Text(card,"NewDiscovery","ВПЕРВЫЕ!",12,true,T.Ink),8)
		badge.Position,badge.Size=UDim2.fromScale(.59,.66),UDim2.fromScale(.36,.08)
		badge.BackgroundColor3,badge.BackgroundTransparency,badge.ZIndex=T.Gold,0,3
		badge.TextXAlignment,badge.TextScaled=Enum.TextXAlignment.Center,true
		W.New("UITextSizeConstraint",{MinTextSize=7,MaxTextSize=12},badge)
	end
	local art = W.Frame(card, "Illustration", UDim2.fromScale(0.9,0.61))
	art.Position, art.BackgroundTransparency = UDim2.fromScale(0.05,0.13), 1
	for i = 1, 10 do
		local side = if i <= 5 then .02 else .98
		local y = .1 + ((i * 19) % 78) / 100
		spark(art, side, y, .012 + (i % 3) * .007, if i % 2 == 0 then accent else post[5])
	end
	-- The square canvas keeps silhouettes consistent in portrait and landscape.
	local canvas = W.Frame(art, "Canvas")
	canvas.BackgroundTransparency, canvas.AnchorPoint, canvas.Position = 1, Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.5)
	W.New("UIAspectRatioConstraint", { AspectRatio = 1, AspectType = Enum.AspectType.FitWithinMaxSize }, canvas)
	shape(canvas,"Halo",0.5,0.52,0.86,0.86,T.White,100).BackgroundTransparency = 0.55
	local kind = post[3]
	if drawScene(canvas, kind) then
		-- Illustrated scene already rendered.
	elseif kind == "verity" or kind == "rainbow" or kind == "party" or kind == "golden" then
		if kind == "rainbow" then
			for i, color in {T.Purple,T.Blue,T.Mint,T.Gold,T.Pink} do
				local ring=shape(canvas,"Rainbow"..i,0.5,0.46,0.93-i*0.1,0.93-i*0.1,color,100)
				ring.BackgroundTransparency=0.15
			end
		end
		if kind=="verity" then
			cloud(canvas,.16,.68,.28,T.White)
			cloud(canvas,.83,.40,.27,T.White)
			shape(canvas,"Island",.5,.86,.69,.12,T.Mint,100)
			spark(canvas,.78,.21,.055,T.Gold)
			spark(canvas,.19,.31,.035,T.Purple)
		end
		face(canvas,0.5,0.56,0.55,0.55,if kind=="golden" then T.Gold else T.Pink,false)
		if kind=="verity" then shape(canvas,"Shine",.36,.40,.13,.04,T.White,8,-35).BackgroundTransparency=.35 end
		if kind == "golden" then crown(canvas,0.5,0.24,0.36) end
		if kind == "party" then
			shape(canvas,"PartyHat",0.5,0.27,0.22,0.24,T.Gold,4,12)
			for i=1,12 do
				local angle=i*math.pi/6
				shape(canvas,"Confetti"..i,0.5+math.cos(angle)*0.39,0.5+math.sin(angle)*0.4,0.035,0.07,({T.Mint,T.Gold,T.Blue})[(i%3)+1],2,i*29)
			end
		end
	elseif kind == "crown" then
		shape(canvas,"RoyalCushion",0.5,0.72,0.68,0.18,T.Purple,20)
		crown(canvas,0.5,0.45,0.63)
	elseif kind == "house" then
		shape(canvas,"Lawn",0.5,0.79,0.9,0.12,T.Mint,20)
		shape(canvas,"House",0.5,0.53,0.62,0.47,T.Paper,10)
		shape(canvas,"Roof",0.5,0.27,0.72,0.12,T.Purple,6)
		for _,x in {0.31,0.68} do shape(canvas,"Window",x,0.5,0.16,0.18,T.Blue,6) end
		shape(canvas,"Door",0.5,0.65,0.13,0.24,T.Pink,6)
		shape(canvas,"Chimney",0.72,0.2,0.09,0.16,T.Peach,4)
	elseif kind == "planet" then
		local orbit=shape(canvas,"Orbit",0.5,0.5,0.93,0.35,T.Gold,100,-24)
		orbit.BackgroundTransparency=1
		local stroke=W.Stroke(orbit,T.Gold,8);stroke.Transparency=0
		shape(canvas,"Planet",0.5,0.5,0.57,0.57,T.Purple,100)
		shape(canvas,"Crater",0.4,0.4,0.16,0.16,T.Blue,100)
		shape(canvas,"Moon",0.83,0.18,0.13,0.13,T.Gold,100)
	elseif kind == "pet" then
		face(canvas,0.5,0.55,0.6,0.55,T.Peach,true)
		shape(canvas,"Nose",0.5,0.59,0.08,0.06,T.Ink,100)
		for _,x in {0.32,0.68} do shape(canvas,"Paw",x,0.8,0.18,0.12,T.Paper,100) end
	elseif kind == "food" then
		shape(canvas,"Plate",0.5,0.77,0.88,0.14,T.White,100)
		shape(canvas,"LowerBun",0.5,0.66,0.62,0.16,T.Peach,30)
		shape(canvas,"Burger",0.5,0.53,0.68,0.12,T.Ink,15)
		shape(canvas,"Lettuce",0.5,0.46,0.73,0.07,T.Mint,15)
		face(canvas,0.5,0.35,0.65,0.29,T.Gold,false)
	elseif kind == "burst" then
		for i=1,12 do
			local a=i*math.pi/6
			shape(canvas,"Ray"..i,0.5+math.cos(a)*0.31,0.5+math.sin(a)*0.31,0.11,0.25,({T.Gold,T.Pink,T.Blue,T.Mint})[(i%4)+1],8,i*30-90)
		end
		face(canvas,0.5,0.5,0.4,0.4,T.Paper,false)
	elseif kind == "car" then
		shape(canvas,"Road",0.5,0.78,0.95,0.1,T.Purple,8)
		shape(canvas,"Cabin",0.52,0.45,0.45,0.25,T.Blue,24)
		shape(canvas,"Glass",0.52,0.42,0.27,0.14,T.Paper,10)
		shape(canvas,"Body",0.5,0.62,0.83,0.22,T.Pink,25)
		for _,x in {0.25,0.75} do
			shape(canvas,"Wheel",x,0.72,0.19,0.19,T.Ink,100)
			shape(canvas,"Hub",x,0.72,0.08,0.08,T.Gold,100)
		end
	elseif kind == "landscape" then
		shape(canvas,"Sun",0.72,0.24,0.21,0.21,T.Gold,100)
		shape(canvas,"MountainLeft",0.30,0.64,0.52,0.52,T.Purple,12,45)
		shape(canvas,"MountainRight",0.70,0.63,0.55,0.55,T.Blue,12,45)
		shape(canvas,"Meadow",0.5,0.83,1,0.23,T.Mint,12)
		shape(canvas,"River",0.54,0.85,0.1,0.25,T.Blue,20,20)
	end
	for i = 1, if rarity.multiplier >= 8 then 8 else 4 do
		local angle = i * 2.4
		local x, y = .5 + .43 * math.cos(angle), .5 + .43 * math.sin(angle)
		shape(canvas,"Glint",x,y,.028,.028,accent,3,45)
		shape(canvas,"GlintCore",x,y,.012,.012,T.White,2,45)
	end
	local title=W.Text(card,"PostTitle",post[1],18,true,T.White)
	title.Position,title.Size=UDim2.fromScale(0.06,0.77),UDim2.fromScale(0.88,0.11)
	title.TextScaled=true
	W.New("UITextSizeConstraint", {MinTextSize=9,MaxTextSize=18}, title)
	local caption=W.Text(card,"PostCaption",post[2],11,false,Color3.fromHex("EAE3FF"))
	caption.TextScaled=true
	W.New("UITextSizeConstraint", {MinTextSize=8,MaxTextSize=11}, caption)
	caption.Position,caption.Size=UDim2.fromScale(0.06,0.89),UDim2.fromScale(0.88,0.09)
	return card, rarity, payout
end

function Feed.new(viewport, animation, settings, onReady, onCharge)
	local self = setmetatable({ viewport=viewport, animation=animation, settings=settings, onReady=onReady, onCharge=onCharge, busy=false, dead=false },Feed)
	local cover = W.Round(W.Frame(viewport,"DeckCover",nil,Color3.fromHex("34227A")),14)
	W.New("UIGradient", {Color=ColorSequence.new(T.Purple,Color3.fromHex("251E66")),Rotation=45},cover)
	local symbol = shape(cover,"DeckGem",.5,.32,.23,.23,T.Gold,12,45)
	W.New("UIAspectRatioConstraint", {AspectRatio=1},symbol)
	local title = W.Text(cover,"Title","Draw your first card",19,true,T.White)
	title.Position,title.Size=UDim2.fromScale(.04,.53),UDim2.fromScale(.92,.15)
	title.TextXAlignment,title.TextScaled=Enum.TextXAlignment.Center,true
	W.New("UITextSizeConstraint",{MinTextSize=9,MaxTextSize=19},title)
	local hint = W.Text(cover,"Hint","Swipe up or tap the button",12,false,T.White)
	hint.Position,hint.Size=UDim2.fromScale(.04,.73),UDim2.fromScale(.92,.15)
	hint.TextXAlignment,hint.TextScaled=Enum.TextXAlignment.Center,true
	W.New("UITextSizeConstraint",{MinTextSize=8,MaxTextSize=12},hint)
	self.card=cover
	self.settingsConnection=settings.Changed.Event:Connect(function(values)
		if values.ReducedMotion or values.ReducedEffects then self:FinishReveal() end
	end)
	return self
end

-- Timings and particle counts increase with the value of the confirmed drop.
local reveals = {
	[4] = {windup=.32, hold=.55, sparks=14, radius=.36, rings=1},
	[8] = {windup=.42, hold=.70, sparks=22, radius=.43, rings=2},
	[16] = {windup=.53, hold=.86, sparks=32, radius=.49, rings=3},
}

function Feed:FinishReveal()
	local slide = self.slide
	if slide then
		self.slide, self.busy = nil, false
		self.animation:Cancel(slide.old)
		slide.old:Destroy()
		self.animation:Cancel(self.card)
		self.card.Position, self.card.Rotation = UDim2.new(), 0
		if not self.dead then self.onReady() end
		return
	end
	local reveal = self.reveal
	if not reveal then return end
	self.reveal = nil
	self.busy = false
	reveal.effects:Destroy()
	self.card.Visible = true
	self.animation:Cancel(self.card)
	self.card.Size=UDim2.fromScale(1,1)
	self.card.Position = UDim2.new()
	self.card.AnchorPoint = Vector2.zero
	if not self.dead then
		if reveal.onImpact then reveal.onImpact(nil) end
		self.onReady()
	end
end

function Feed:Celebrate(card, rarity, payout, profile, onImpact)
	local accent = Color3.fromHex(rarity.color)
	local animation = self.animation
	local effects = W.Frame(self.viewport,"RareCardEffects")
	effects.BackgroundTransparency, effects.ZIndex = 1, 5
	local reveal = {effects=effects,onImpact=onImpact}
	self.reveal = reveal
	self.busy, card.Visible = true, false
	self.onCharge()

	local back = W.Round(W.Frame(effects,"CardBack",UDim2.fromScale(1,1),T.White),14)
	W.New("UIGradient",{Color=ColorSequence.new(Color3.fromHex("1A103C"),accent),Rotation=55},back)
	local gem = shape(back,"Gem",.5,.5,.30,.30,accent,8,45)
	W.New("UIAspectRatioConstraint",{AspectRatio=1},gem)
	W.Stroke(gem,T.White,2).Transparency = .18
	local gemScale = W.New("UIScale",{Scale=.62},gem)
	animation:Tween(gemScale,profile.windup*.64,{Scale=1.2})
	for i=1,profile.sparks//2 do
		local angle=i*2.39996
		local mote=shape(back,"ChargingLight",.5+math.cos(angle)*.48,.5+math.sin(angle)*.44,.021,.021,T.White,100)
		W.New("UIAspectRatioConstraint",{AspectRatio=1},mote)
		animation:Tween(mote,profile.windup*(.47+i%5*.055),{
			Position=UDim2.fromScale(.5,.5), BackgroundTransparency=.85,
		})
	end
	local label = W.Text(back,"Rarity",rarity.label,17,true,T.White)
	label.Position,label.Size=UDim2.fromScale(.07,.73),UDim2.fromScale(.86,.16)
	label.TextXAlignment,label.TextScaled=Enum.TextXAlignment.Center,true
	W.New("UITextSizeConstraint",{MinTextSize=8,MaxTextSize=19},label)
	local backScale = W.New("UIScale",{Scale=.86},back)
	animation:Tween(backScale,profile.windup*.64,{Scale=1})
	task.delay(profile.windup*.64,function()
		if self.reveal ~= reveal then return end
		animation:Tween(back,profile.windup*.36,{
			Size=UDim2.fromScale(.02,1),Position=UDim2.fromScale(.49,0),
		})
	end)
	task.delay(profile.windup,function()
		if self.reveal ~= reveal then return end
		back:Destroy()
		card.AnchorPoint,card.Position = Vector2.new(.5,.5),UDim2.fromScale(.5,.5)
		card.Size,card.Visible = UDim2.fromScale(.04,1),true
		animation:Tween(card,.21,{Size=UDim2.fromScale(1,1)})
		local impact = reveal.onImpact
		reveal.onImpact = nil
		impact(rarity.multiplier)
		local payoutScale = W.New("UIScale",{Scale=1.28},payout)
		payout.TextColor3 = accent
		animation:Tween(payoutScale,.34,{Scale=1})
		local glow = W.Round(W.Frame(effects,"ImpactGlow",nil,accent),14)
		glow.BackgroundTransparency = if profile.rings == 3 then .62 else .76
		animation:Tween(glow,.24,{BackgroundTransparency=1})

		local shine = W.Frame(effects,"PrismShine",nil,T.White)
		local sheen = W.New("UIGradient",{
			Color=ColorSequence.new(accent,T.White),
			Transparency=NumberSequence.new({
				NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(.41,1),
				NumberSequenceKeypoint.new(.5,.57), NumberSequenceKeypoint.new(.59,1),
				NumberSequenceKeypoint.new(1,1),
			}),
			Rotation=24, Offset=Vector2.new(-1,0),
		},shine)
		animation:Tween(sheen,profile.hold*.9,{Offset=Vector2.new(1,0)})

		for i=1,profile.rings do
			local ring = shape(effects,"HaloRing",.5,.5,.12,.12,accent,100)
			ring.BackgroundTransparency=1
			W.New("UIAspectRatioConstraint",{AspectRatio=1},ring)
			local stroke=W.Stroke(ring,if i==2 then T.White else accent,4-i*.7)
			stroke.Transparency=.15+i*.12
			local radius=.98-(i-1)*.2
			animation:Tween(ring,profile.hold*(.75+i*.08),{Size=UDim2.fromScale(radius,radius)})
			animation:Tween(stroke,profile.hold*.77,{Transparency=1})
		end
		for i=1,profile.sparks do
			local angle=i*2.39996
			local radius=profile.radius*(.65+(i%5)*.08)
			local size=.019+(i%4)*.009
			local color=if i%3==0 then T.White elseif i%3==1 then accent else T.Gold
			local star=shape(effects,"Facet",.5+math.cos(angle)*.08,.5+math.sin(angle)*.08,size,size,color,2,45)
			W.New("UIAspectRatioConstraint",{AspectRatio=1},star)
			animation:Tween(star,profile.hold*(.73+(i%4)*.08),{
				Position=UDim2.fromScale(.5+math.cos(angle)*radius,.5+math.sin(angle)*radius),
				Rotation=135+i*21, BackgroundTransparency=1, Size=UDim2.fromScale(size*.35,size*.35),
			})
		end
		task.delay(profile.hold,function()
			if self.reveal == reveal then self:FinishReveal() end
		end)
	end)
end

function Feed:Drag(offset, release)
	if self.dead or self.busy or self.waiting then return end
	if release then
		self.animation:Tween(self.card,.22,{Position=UDim2.new()})
	elseif not self.settings.values.ReducedMotion then
		self.animation:Tween(self.card,.045,{
			Position=UDim2.fromScale(0,if offset>0 then offset*.19 else math.max(-.72,offset*.82)),
		})
	end
end

function Feed:CommitSwipe()
	if self.dead then return end
	self.waiting=true
	self.animation:Tween(self.card,.22,{Position=UDim2.fromScale(0,-1)})
end

function Feed:RejectSwipe()
	self.waiting=false
	if not self.dead then self.animation:Tween(self.card,.22,{Position=UDim2.new()}) end
end

function Feed:Reveal(index, reward, animate, onImpact, isNew)
	if self.dead then return end
	self.waiting=false
	if not Feed.Posts[index] or type(reward) ~= "number" then onImpact(nil);return end
	local old=self.card
	local card,rarity,payout=Feed.Draw(self.viewport,index,reward,isNew)
	self.card=card
	if not animate or self.settings.values.ReducedMotion then old:Destroy();onImpact(nil);return end
	local profile=reveals[rarity.multiplier]
	if profile and not self.settings.values.ReducedEffects then
		old:Destroy()
		self:Celebrate(card,rarity,payout,profile,onImpact)
		return
	end
	onImpact(nil)
	self.busy=true
	card.Position, card.Rotation = UDim2.fromScale(0, 1), 3
	self.animation:Tween(old, 0.25, {Position = UDim2.fromScale(0, -1), Rotation = -2})
	self.animation:Tween(card, 0.28, {Position = UDim2.new(), Rotation = 0})
	local slide = {old = old}
	self.slide = slide
	task.delay(0.3, function()
		if self.slide == slide then self:FinishReveal() end
	end)
end

function Feed:Destroy()
	self.dead=true
	self.settingsConnection:Disconnect()
	self:FinishReveal()
	self.card:Destroy()
end
return Feed
