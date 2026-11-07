--!nonstrict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Actions = game:GetService("ContextActionService")
local Input = game:GetService("UserInputService")
local Gui = game:GetService("GuiService")
local Config = require(ReplicatedStorage.Shared.DiversionsConfig)
local Cleanup = require(script.Parent.Cleanup)
local Card = require(script.Parent.ActivityCard)
local Locale = require(script.Parent.Locale)
local W = require(script.Parent.UIWidgets)
local T = require(script.Parent.UITheme)
local Controller = {}
Controller.__index = Controller

function Controller.new(ctx)
    local self = setmetatable({ctx=ctx, cleanup=Cleanup.new(), lastFeedback=0, lastCount=0}, Controller)
    self.remote = ReplicatedStorage:WaitForChild("VerityDiversions", 10)
    self.card, self.title, self.detail, self.leave = Card.Build(ctx.refs.Safe, "DiversionStatus", "LeaveDiversion")
    self.cleanup:Add(self.card)
    self.cleanup:Add(self.leave.Activated:Connect(function() self:Leave() end))
    self.folder = self.cleanup:Add(Instance.new("Folder"))
    self.folder.Name, self.folder.Parent = "VeritySparkHunt", workspace
    for _, name in {"Spark", "Glow"} do
        local part = Instance.new("Part")
        part.Name, part.Shape, part.Material = name, Enum.PartType.Ball, Enum.Material.Neon
        part.Size = Vector3.one * (if name=="Spark" then 1.45 else 2.3)
        part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.CastShadow = true, false, false, false, false
        part.Transparency, part.Parent = 1, self.folder
        self[name] = part
    end
    self.target = self.Spark
    self.light = Instance.new("PointLight")
    self.light.Range, self.light.Brightness, self.light.Shadows = 9, .5, false
    self.light.Enabled, self.light.Parent = false, self.Spark

    self.rhythm = self.cleanup:Add(W.Round(W.Frame(ctx.refs.Safe, "RhythmGame", UDim2.fromOffset(330,320), T.Paper), 24))
    self.rhythm.AnchorPoint, self.rhythm.Position = Vector2.new(.5,.5), UDim2.fromScale(.5,.5)
    self.rhythm.Visible, self.rhythm.ZIndex = false, 24
    W.Stroke(self.rhythm, T.Purple, 3).Transparency = .15
    local heading = W.Text(self.rhythm,"Title","Попади в ритм",19,true,T.Purple)
    heading.Position, heading.Size = UDim2.fromOffset(14,12), UDim2.new(1,-70,0,28)
    local close = W.Button(self.rhythm,"Close","×",T.Gold)
    close.Size, close.Position = UDim2.fromOffset(44,44), UDim2.new(1,-54,0,8)
    self.cleanup:Add(close.Activated:Connect(function() self:Leave() end))
    self.score = W.Text(self.rhythm,"Score","",13,true,T.Ink)
    self.score.Position, self.score.Size = UDim2.fromOffset(14,44), UDim2.new(1,-28,0,23)
    self.tap = W.Button(self.rhythm,"Tap","",T.Purple)
    self.tap:FindFirstChildOfClass("UICorner").CornerRadius = UDim.new(0,40)
    self.tap.AnchorPoint, self.tap.Position, self.tap.Size = Vector2.new(.5,.5), UDim2.fromScale(.5,.52), UDim2.fromOffset(78,78)
    self.tap.Selectable = true
    self.tapText = W.Text(self.tap,"Prompt","",15,true,T.White)
    self.tapText.Size, self.tapText.TextXAlignment = UDim2.fromScale(1,1), Enum.TextXAlignment.Center
    self.ring = W.Round(W.Frame(self.tap,"TimingRing",UDim2.fromOffset(160,160)),100)
    self.ring.BackgroundTransparency = 1
    self.ring.AnchorPoint, self.ring.Position = Vector2.new(.5,.5), UDim2.fromScale(.5,.5)
    self.ringStroke = W.Stroke(self.ring,T.Gold,5)
    self.ringStroke.Transparency = .08
    self.feedback = W.Text(self.rhythm,"Feedback","",16,true,T.Purple)
    self.feedback.AnchorPoint, self.feedback.Position = Vector2.new(.5,1), UDim2.new(.5,0,1,-36)
    self.feedback.Size, self.feedback.TextXAlignment = UDim2.new(1,-24,0,28), Enum.TextXAlignment.Center
    self.key = W.Text(self.rhythm,"Key","",11,false,T.Muted)
    self.key.Position, self.key.Size = UDim2.new(0,10,1,-27), UDim2.new(1,-20,0,20)
    self.key.TextXAlignment = Enum.TextXAlignment.Center
    self.cleanup:Add(self.tap.Activated:Connect(function()
        if self.run and self.run.phase=="Playing" then self:Tap() else self:Leave() end
    end))
    Actions:BindAction("VerityRhythmTap", function(_, state)
        if state==Enum.UserInputState.Begin and self:Tap() then return Enum.ContextActionResult.Sink end
        return Enum.ContextActionResult.Pass
    end, false, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
    Actions:BindAction("VerityDiversionLeave", function(_, state)
        if state==Enum.UserInputState.Begin and not Gui.MenuIsOpen and not Input:GetFocusedTextBox() and self:Leave() then return Enum.ContextActionResult.Sink end
        return Enum.ContextActionResult.Pass
    end, false, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
    self.cleanup:Add(function()
        Actions:UnbindAction("VerityRhythmTap")
        Actions:UnbindAction("VerityDiversionLeave")
    end)
    if self.remote then
        self.cleanup:Add(self.remote.OnClientEvent:Connect(function(message) self:Receive(message) end))
        self.remote:FireServer("Sync",0)
    end
    self.cleanup:Add(RunService.RenderStepped:Connect(function() self:Render() end))
    self.cleanup:Add(Players.LocalPlayer.CharacterRemoving:Connect(function() self.run=nil;self:Render() end))
    return self
end

function Controller:Tap()
    if not self.remote or not self.run or self.run.phase~="Playing" or self.run.kind~="Rhythm"
        or self.ctx.active or self.ctx.presenting or self.ctx.rewardOverlay or Gui.MenuIsOpen or Input:GetFocusedTextBox() then return false end
    self.remote:FireServer("Tap",self.run.round)
    return true
end

function Controller:Leave()
    if not self.run then return false end
    if self.run.phase=="Playing" and self.remote then self.remote:FireServer("Leave",self.run.round)
    else self.run=nil end
    return true
end

function Controller:Receive(message)
    if type(message)~="table" or message.version~=Config.Version or (message.kind~="Hunt" and message.kind~="Rhythm") then return end
    if self.run and message.round<self.run.round then return end
    if not self.run or message.round~=self.run.round then
        self.lastFeedback, self.lastCount, self.playedBeat = 0, 0, 0
        self.ctx.close()
        if message.kind=="Rhythm" and Input.PreferredInput==Enum.PreferredInput.Gamepad then Gui.SelectedObject=self.tap end
    end
    if message.kind=="Hunt" and message.count>self.lastCount then self.ctx.sound:Play("TaskCheckpoint") end
    self.lastCount=message.count
    if message.feedback>self.lastFeedback then
        self.feedbackAt=os.clock()
        if message.judgement~="МИМО" then self.ctx.sound:Play("Click") end
    end
    self.lastFeedback=message.feedback
    self.run=message
    if message.phase~="Playing" then
        self.resultUntil=os.clock()+4
        if Gui.SelectedObject==self.tap then Gui.SelectedObject=nil end
    end
    self:Render()
end

function Controller:Render()
    local run=self.run
    local blocked=Card.Blocked(self.ctx) or Gui.MenuIsOpen
    local playing=run and run.phase=="Playing"
    local hunt=playing and run.kind=="Hunt"
    local visible=run~=nil and not blocked
    self.card.Visible=visible and run.kind=="Hunt" or false
    self.rhythm.Visible=visible and run.kind=="Rhythm" or false
    self.Spark.Transparency, self.Glow.Transparency, self.light.Enabled = 1,1,false
    if not run then return end
    if not playing and os.clock()>=(self.resultUntil or 0) then self.run=nil;return end
    local size=self.ctx.refs.Safe.AbsoluteSize
    local now=workspace:GetServerTimeNow()
    local remaining=math.max(0,math.ceil(run.deadline-now))
    if hunt then
        local position=Config.HuntPosition(run.count+1,run.variant)
        local motion=if self.ctx.settings.values.ReducedMotion then 0 else math.sin(now*2.8)*.13
        self.Spark.Position=position+Vector3.yAxis*motion
        self.Glow.Position=self.Spark.Position
        local color=if (run.count+1)%4==0 then T.Pink else T.Gold
        self.Spark.Color,self.Glow.Color,self.light.Color=color,color,color
        self.Spark.Transparency=if blocked then 1 else .02
        self.Glow.Transparency=if blocked or self.ctx.settings.values.LowGraphics or self.ctx.settings.values.ReducedEffects then 1 else .83
        self.light.Enabled=not blocked and not self.ctx.settings.values.LowGraphics
    end
    if run.kind=="Hunt" then
        Card.Layout(self.card,self.title,self.detail,size)
        self.title.Text=string.format(Locale.Text("ИСКРЫ %d / %d"),run.count,Config.HuntCount)
        self.detail.Text=if playing then string.format(Locale.Text("%d с • серия ×%d"),remaining,run.combo)
            else string.format(Locale.Text("Счёт %d • награда $%s"),run.score,Locale.Number(run.cash))
    else
        self.rhythm.Size=UDim2.fromOffset(math.min(330,size.X-24),math.min(320,size.Y-24))
        self.score.Text=string.format(Locale.Text("Счёт %d • серия ×%d"),run.score,run.combo)
        self.key.Text=Locale.Text(if Input.PreferredInput==Enum.PreferredInput.Touch then "Коснись круга"
            elseif Input.PreferredInput==Enum.PreferredInput.Gamepad then "A — нажать • B — выйти" else "ПРОБЕЛ — нажать • Q — выйти")
        if playing and not blocked then
            for index,offset in Config.Beats do
                if index>(self.playedBeat or 0) and now>=run.startedAt+offset then
                    self.playedBeat=index
                    if now-run.startedAt-offset<.12 then self.ctx.sound:Play("Click") end
                end
            end
        end
        local nextBeat
        for index,offset in Config.Beats do
            if not run.judged[index] and now<=run.startedAt+offset+Config.RhythmWindow then nextBeat=run.startedAt+offset;break end
        end
        local delta=if nextBeat then nextBeat-now else 2
        local active=playing and math.abs(delta)<=Config.RhythmWindow
        local diameter=if self.ctx.settings.values.ReducedMotion then 78 else 78+math.clamp(delta/1.4,0,1)*90
        self.ring.Size=UDim2.fromOffset(diameter,diameter)
        self.ring.Visible=playing
        self.ringStroke.Color=if active then T.Mint else T.Gold
        self.tap.BackgroundColor3=if active then T.Mint else T.Purple
        self.tapText.Text=if not playing then Locale.Text("ГОТОВО") elseif active then Locale.Text("ЖМИ!") else "♪"
        if not playing then self.feedback.Text=string.format(Locale.Text("Награда $%s"),Locale.Number(run.cash))
        elseif self.feedbackAt and os.clock()-self.feedbackAt<.6 then self.feedback.Text=Locale.Text(run.judgement or "")
        else self.feedback.Text=Locale.Text("Нажми, когда круги совпадут") end
    end
end

function Controller:Destroy()
    if Gui.SelectedObject==self.tap then Gui.SelectedObject=nil end
    self.cleanup:Destroy()
end
return Controller
