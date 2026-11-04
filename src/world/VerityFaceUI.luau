-- One face contract for Core and the standalone preview; no runtime image APIs.
local Layout = require(game:GetService("ReplicatedStorage").Shared.VerityFaceLayout)
local Life = require(game:GetService("ReplicatedStorage").Shared.VerityPersonality)
local Face = {}
function Face.Image(gui)
    return gui:FindFirstChild("Expression",true)
end
local function ink(parent,name,x,y,w,h,rotation)
    local p=Instance.new("Frame")
    p.Name=name;p.AnchorPoint=Vector2.new(.5,.5)
    p.Position=UDim2.fromScale(x,y);p.Size=UDim2.fromScale(w,h)
    p.Rotation=rotation or 0;p.BorderSizePixel=0
    p.BackgroundColor3=Color3.fromRGB(33,20,33);p.Parent=parent
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(1,0);corner.Parent=p
end
function Face.Configure(gui,body)
    gui.Adornee=body;gui.Face=Enum.NormalId.Front
    gui.SizingMode=Enum.SurfaceGuiSizingMode.FixedSize;gui.CanvasSize=Vector2.new(512,512)
    gui.AlwaysOnTop=false;gui.LightInfluence=0;gui.ZOffset=.04;gui.MaxDistance=240
    local image=Face.Image(gui)
    assert(image and image:IsA("ImageLabel"),"Verity face template has no Expression image")
    local window=gui:FindFirstChild("FaceWindow")
    if not window then window=Instance.new("Frame");window.Name="FaceWindow";window.Parent=gui end
    window.BackgroundTransparency=1;window.ClipsDescendants=true
    window.Position=UDim2.fromScale(.19,.14);window.Size=UDim2.fromScale(.62,.64)
    local mouth=window:FindFirstChild("MouthClip")
    if not mouth then mouth=Instance.new("Frame");mouth.Name="MouthClip";mouth.Parent=window end
    mouth.BackgroundTransparency=1;mouth.ClipsDescendants=true
    mouth.Position=UDim2.fromScale(0,.43);mouth.Size=UDim2.fromScale(1,.57)
    image.Parent=mouth;image.ImageRectOffset=Vector2.zero;image.ImageRectSize=Vector2.zero
    image.Position=UDim2.fromScale(-Layout.X/Layout.Width,(-Layout.Y/Layout.Height-.43)/.57)
    image.Size=UDim2.fromScale(1/Layout.Width,1/(Layout.Height*.57))
    image.BackgroundTransparency=1;image.Visible=true;image.ZIndex=2
    local eyes=window:FindFirstChild("EyesClip")
    if not eyes then eyes=Instance.new("Frame");eyes.Name="EyesClip";eyes.Parent=window end
    eyes.BackgroundTransparency=1;eyes.ClipsDescendants=true
    eyes.Position=UDim2.fromScale(0,0);eyes.Size=UDim2.fromScale(1,.43)
    local eyeImage=eyes:FindFirstChild("EyeExpression")
    if not eyeImage then eyeImage=image:Clone();eyeImage.Name="EyeExpression";eyeImage.Parent=eyes end
    eyeImage.Image=image.Image
    eyeImage.Position=UDim2.fromScale(-Layout.X/Layout.Width,-Layout.Y/(Layout.Height*.43))
    eyeImage.Size=UDim2.fromScale(1/Layout.Width,1/(Layout.Height*.43))
    local fallback=gui:FindFirstChild("LoadingFace")
    if not fallback then
        fallback=Instance.new("Frame");fallback.Name="LoadingFace"
        fallback.BackgroundTransparency=1;fallback.Size=UDim2.fromScale(1,1);fallback.Parent=gui
        ink(fallback,"LeftEye",.374,.31,.065,.12)
        ink(fallback,"RightEye",.626,.31,.065,.12)
        for i=0,11 do
            local a,b=math.pi*i/12,math.pi*(i+1)/12
            local x,y=.5+.2*math.cos(a),.45+.15*math.sin(a)
            local xx,yy=.5+.2*math.cos(b),.45+.15*math.sin(b)
            ink(fallback,"Smile"..i,(x+xx)/2,(y+yy)/2,math.sqrt((xx-x)^2+(yy-y)^2)+.008,.018,math.deg(math.atan2(yy-y,xx-x)))
        end
    end
    local hearts=gui:FindFirstChild("ReactionHearts")
    if not hearts then
        hearts=Instance.new("Frame");hearts.Name="ReactionHearts";hearts.Size=UDim2.fromScale(1,1)
        hearts.BackgroundTransparency=1;hearts.Parent=gui
        for i=1,3 do
            local heart=Instance.new("TextLabel");heart.Name="Heart"..i;heart.BackgroundTransparency=1
            heart.Size=UDim2.fromScale(.11,.13);heart.AnchorPoint=Vector2.new(.5,.5)
            heart.Font=Enum.Font.GothamBold;heart.Text="♥";heart.TextScaled=true
            heart.TextColor3=Color3.fromRGB(255,57,128);heart.ZIndex=3;heart.Visible=false;heart.Parent=hearts
        end
    end
    Face.Refresh(gui,0)
    return gui
end
function Face.Refresh(gui,alpha)
    local image=Face.Image(gui)
    local loaded=image and image.IsLoaded or false
    local eyes=gui:FindFirstChild("EyeExpression",true)
    if eyes and image then
        if eyes.Image~=image.Image then eyes.Image=image.Image end
        loaded=loaded and eyes.IsLoaded
        eyes.ImageTransparency=alpha
    end
    local body=gui.Adornee
    local distance=math.max(240,math.min(600,if body and body:IsA("BasePart") then body.Size.Magnitude*12 else 240))
    if gui.MaxDistance~=distance then gui.MaxDistance=distance end
    local camera=workspace.CurrentCamera
    local inRange=not camera or not body or (camera.CFrame.Position-body.Position).Magnitude<distance-2
    -- The native Eye/Smile parts remain a fallback when the GUI is culled.
    gui.Enabled=alpha<.7 and inRange
    if image then image.ImageTransparency=alpha end
    local fallback=gui:FindFirstChild("LoadingFace")
    if fallback then
        fallback.Visible=not loaded
        for _,p in fallback:GetChildren() do if p:IsA("Frame") then p.BackgroundTransparency=alpha end end
    end
    return loaded
end
function Face.Animate(gui,now,seed,emotion,token,state,reducedMotion,reducedEffects)
    local eyes=gui:FindFirstChild("EyeExpression",true)
    if eyes then
        local blink=Life.Blink(now,seed,emotion,reducedMotion)
        local center=.61
        eyes.Position=UDim2.fromScale(-Layout.X/Layout.Width,center+(-Layout.Y/(Layout.Height*.43)-center)*blink)
        eyes.Size=UDim2.fromScale(1/Layout.Width,blink/(Layout.Height*.43))
    end
    if token~=state.token then
        state.token=token
        if emotion=="Love" and now-(state.pulse or -math.huge)>.55 then state.pulse=now end
    end
    local hearts=gui:FindFirstChild("ReactionHearts")
    if hearts then for i=1,3 do
        local heart=hearts:FindFirstChild("Heart"..i)
        local age=now-(state.pulse or -10)-.07*(i-1)
        local visible=not reducedMotion and not reducedEffects and emotion=="Love" and age>=0 and age<.85
        heart.Visible=visible
        if visible then
            local t=age/.85
            heart.Position=UDim2.fromScale(if i==1 then .1 elseif i==2 then .9 else .5,.64-.4*t-(if i==3 then .32 else 0))
            heart.TextTransparency=t*t
            heart.Rotation=(if i==2 then 1 else -1)*(8+8*t)
        end
    end end
end
return Face
