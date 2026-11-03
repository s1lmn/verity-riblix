--!nonstrict
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local Feed = {}
Feed.__index = Feed
Feed.Posts = {
	{ "Cute Verity", "Small friend. Big future.", "verity", T.Pink, T.Peach },
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
	{ "Golden Verity", "Keep growing. Keep glowing.", "golden", T.Gold, T.Peach },
}

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
	shape(parent, "Body", x, y, width, height, color, 100)
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

function Feed.Draw(parent, index)
	local post = Feed.Posts[index]
	local card = W.Frame(parent, "Post_" .. index)
	card.BackgroundColor3 = T.Paper
	W.New("UIGradient", { Color = ColorSequence.new(post[4]:Lerp(T.White,0.70),post[5]:Lerp(T.White,0.85)), Rotation = 35 }, card)
	local tag = W.Text(card, "Tag", string.format("VERITY DAILY   /   %02d", index), 10, true, T.Muted)
	tag.Position, tag.Size = UDim2.fromScale(0.06,0.03), UDim2.fromScale(0.9,0.09)
	local art = W.Frame(card, "Illustration", UDim2.fromScale(0.9,0.65))
	art.Position, art.BackgroundTransparency = UDim2.fromScale(0.05,0.10), 1
	-- The square canvas keeps silhouettes consistent in portrait and landscape.
	local canvas = W.Frame(art, "Canvas")
	canvas.BackgroundTransparency, canvas.AnchorPoint, canvas.Position = 1, Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.5)
	W.New("UIAspectRatioConstraint", { AspectRatio = 1, AspectType = Enum.AspectType.FitWithinMaxSize }, canvas)
	shape(canvas,"Halo",0.5,0.52,0.86,0.86,T.White,100).BackgroundTransparency = 0.55
	local kind = post[3]
	if kind == "verity" or kind == "rainbow" or kind == "party" or kind == "golden" then
		if kind == "rainbow" then
			for i, color in {T.Purple,T.Blue,T.Mint,T.Gold,T.Pink} do
				local ring=shape(canvas,"Rainbow"..i,0.5,0.46,0.93-i*0.1,0.93-i*0.1,color,100)
				ring.BackgroundTransparency=0.15
			end
		end
		face(canvas,0.5,0.59,0.52,0.45,if kind=="golden" then T.Gold else T.Pink,true)
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
	local title=W.Text(card,"PostTitle",post[1],18,true)
	title.Position,title.Size=UDim2.fromScale(0.06,0.77),UDim2.fromScale(0.88,0.11)
	local caption=W.Text(card,"PostCaption",post[2],11,false,T.Muted)
	caption.Position,caption.Size=UDim2.fromScale(0.06,0.89),UDim2.fromScale(0.88,0.09)
	return card
end

function Feed.new(viewport, animation, settings)
	local self = setmetatable({ viewport=viewport, animation=animation, settings=settings, index=1, busy=false, dead=false },Feed)
	self.card=Feed.Draw(viewport,1)
	return self
end

function Feed:Next()
	if self.busy or self.dead then return false end
	self.index=self.index%#Feed.Posts+1
	local old=self.card
	local card=Feed.Draw(self.viewport,self.index)
	self.card=card
	if self.settings.values.ReducedMotion then old:Destroy();return true end
	self.busy=true
	card.Position=UDim2.fromScale(0,1)
	self.animation:Tween(old,0.26,{Position=UDim2.fromScale(0,-1)})
	self.animation:Tween(card,0.26,{Position=UDim2.new()})
	task.delay(0.28,function()
		old:Destroy()
		if not self.dead then self.busy=false end
	end)
	return true
end

function Feed:Destroy() self.dead=true;self.card:Destroy() end
return Feed
