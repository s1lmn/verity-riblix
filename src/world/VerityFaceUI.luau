-- One face contract for Core and the standalone preview; no runtime image APIs.
local Layout = require(game:GetService("ReplicatedStorage").Shared.VerityFaceLayout)
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
    image.Parent=window;image.ImageRectOffset=Vector2.zero;image.ImageRectSize=Vector2.zero
    image.Position=UDim2.fromScale(-Layout.X/Layout.Width,-Layout.Y/Layout.Height)
    image.Size=UDim2.fromScale(1/Layout.Width,1/Layout.Height)
    image.BackgroundTransparency=1;image.Visible=true;image.ZIndex=2
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
    Face.Refresh(gui,0)
    return gui
end
function Face.Refresh(gui,alpha)
    local image=Face.Image(gui)
    local loaded=image and image.IsLoaded or false
    gui.Enabled=alpha<.7
    if image then image.ImageTransparency=alpha end
    local fallback=gui:FindFirstChild("LoadingFace")
    if fallback then
        fallback.Visible=not loaded
        for _,p in fallback:GetChildren() do if p:IsA("Frame") then p.BackgroundTransparency=alpha end end
    end
    return loaded
end
return Face
