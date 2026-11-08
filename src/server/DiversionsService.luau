--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Config = require(Shared.DiversionsConfig)
local Rewards = require(Shared.ActivityRewards)
local Numeric = require(Shared.Numeric)
local Service = {}
Service.__index = Service

local function finite(position)
    return Numeric.isFinite(position.X) and Numeric.isFinite(position.Y) and Numeric.isFinite(position.Z)
end

function Service.new(model, data, state, economy, players, clock, stopMovement, notify)
    local self = setmetatable({
        model=model, data=data, state=state, economy=economy, players=players, clock=clock,
        stopMovement=stopMovement, notify=notify, runs={}, ready={}, limits={}, serial=0, links={},
    }, Service)
    self.remote = Instance.new("RemoteEvent")
    self.remote.Name, self.remote.Parent = "VerityDiversions", ReplicatedStorage
    for _, kind in {"Hunt", "Rhythm"} do
        table.insert(self.links, model[kind.."Station"]["Start"..kind].Triggered:Connect(function(player)
            self:Start(player, kind)
        end))
    end
    table.insert(self.links, self.remote.OnServerEvent:Connect(function(player, action, round, ...)
        if select("#", ...) > 0 or type(action) ~= "string" or not Numeric.isInteger(round, 0, 1e12) then return end
        local run = self.runs[player]
        if action == "Leave" then
            if run and run.round == round then self:End(player, false) end
            return
        end
        local now = clock()
        if now < (self.limits[player] or 0) then return end
        self.limits[player] = now + .12
        if action == "Sync" then
            if self.runs[player] then self:Publish(player, self.runs[player]) end
            return
        end
        if not run or run.round ~= round then return end
        if action == "Tap" and run.kind == "Rhythm" then self:Tap(player, run, now) end
    end))
    return self
end

function Service:Character(player)
    local profile = self.data:Get(player.UserId)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if player.Parent ~= self.players or not profile or not self.state.sessions[player.UserId] or not profile.Data.VerityUnlocked
        or not root or not humanoid or humanoid.Health <= 0 or root.Anchored or humanoid.SeatPart or not finite(root.Position) then return nil end
    return root, profile, character
end

function Service:Publish(player, run, phase, cash)
    local judged = {}
    for index in Config.Beats do judged[index] = run.judged[index] == true end
    self.remote:FireClient(player, {
        version=Config.Version, kind=run.kind, round=run.round, phase=phase or "Playing",
        startedAt=run.started, deadline=run.deadline, count=run.count, combo=run.combo,
        bestCombo=run.bestCombo, score=run.score, hits=run.hits, perfect=run.perfect,
        judged=judged, judgement=run.judgement, feedback=run.feedback,
        variant=run.variant, cash=cash or 0,
    })
end

function Service:Start(player, kind)
    if self.runs[player] then return end
    local root, profile, character = self:Character(player)
    if not root or (root.Position - Config.Station(kind)).Magnitude > Config.JoinReach + 1 then return end
    for _, attribute in {"VerityDiversionKind", "VerityRaceSlot", "VerityParkourStep", "VerityFusionSlot", "VerityBattleActive", "VerityRiding"} do
        if player:GetAttribute(attribute) then return end
    end
    local now = self.clock()
    local ready = self.ready[player] or {}
    if now < (ready[kind] or 0) then
        self.notify(player.UserId, "DIVERSION_COOLDOWN", 0)
        return
    end
    self.stopMovement(player)
    self.serial += 1
    local run = {
        round=self.serial, kind=kind, character=character, started=now, count=0, score=0,
        combo=0, bestCombo=0, hits=0, perfect=0, judged={}, feedback=0,
        variant=if self.serial % 2 == 0 then 1 else 2, lastPosition=root.Position, sampledAt=now,
        lastCollect=now, lastTap=-math.huge, level=profile.Data.VerityLevel,
    }
    run.deadline = now + (if kind == "Hunt" then Config.HuntSeconds else Config.RhythmSeconds)
    self.runs[player] = run
    ready[kind] = now + (if kind == "Hunt" then Config.HuntCooldown else Config.RhythmCooldown)
    self.ready[player] = ready
    player:SetAttribute("VerityDiversionKind", kind)
    player:SetAttribute("Verity"..kind.."ReadyAt", ready[kind])
    self.state:Publish(player.UserId, true)
    self:Publish(player, run)
end

function Service:End(player, award)
    local run = self.runs[player]
    if not run then return end
    -- Remove membership before the synchronous cash grant or any publish.
    self.runs[player] = nil
    player:SetAttribute("VerityDiversionKind", nil)
    player:SetAttribute("VerityLastDiversionKind", run.kind)
    local root, profile = self:Character(player)
    local cash = 0
    if award and root and profile and player.Character == run.character then
        local fraction = if run.kind == "Hunt" then run.count / Config.HuntCount * (1 + .03 * run.bestCombo)
            else math.clamp(run.score / 2200, 0, 1.3)
        if (run.kind == "Hunt" and run.count > 0) or (run.kind == "Rhythm" and run.hits > 0) then
            local amount = Rewards.Base(run.level, run.kind) * fraction * self.economy:GetMultiplier(profile)
            local ok, actual = self.economy:AddCash(player.UserId, amount)
            if ok then
                cash = actual
                self.state:CompleteActivity(profile, run.kind)
                self.notify(player.UserId, "DIVERSION_REWARD", cash)
            end
        end
    end
    self.state:Publish(player.UserId, true)
    if player.Parent == self.players then self:Publish(player, run, if award then "Finished" else "Left", cash) end
end

function Service:Tap(player, run, now)
    local root = self:Character(player)
    if not root or player.Character ~= run.character or now >= run.deadline or now - run.lastTap < .18
        or (root.Position - Config.RhythmStation).Magnitude > 18 then return end
    run.lastTap = now
    local best, error
    for index, offset in Config.Beats do
        local delta = math.abs(now - run.started - offset)
        if not error or delta < error then best, error = index, delta end
    end
    if not best or run.judged[best] or error > .65 then return end
    run.judged[best] = true
    if error <= Config.RhythmWindow then
        run.hits += 1
        run.combo += 1
        local perfect = error <= Config.PerfectWindow
        if perfect then run.perfect += 1 end
        run.score += (if perfect then 100 else 65) + math.min(10, run.combo) * 3
        run.judgement = if perfect then "ТОЧНО!" else "ХОРОШО!"
        run.bestCombo = math.max(run.bestCombo, run.combo)
    else
        run.combo = 0
        run.judgement = "МИМО"
    end
    run.feedback += 1
    self:Publish(player, run)
end

function Service:Tick()
    local now = self.clock()
    for player, run in self.runs do
        local root = self:Character(player)
        if not root or player.Character ~= run.character then self:End(player, false);continue end
        if run.kind == "Rhythm" then
            if (root.Position - Config.RhythmStation).Magnitude > 18 then self:End(player, false);continue end
            if now >= run.deadline then self:End(player, true);continue end
            local changed = false
            for index, offset in Config.Beats do
                if not run.judged[index] and now > run.started + offset + Config.RhythmWindow then
                    run.judged[index] = true
                    run.combo, run.judgement = 0, "МИМО"
                    run.feedback += 1
                    changed = true
                end
            end
            if changed then self:Publish(player, run) end
        else
            local elapsed = now - run.sampledAt
            if (root.Position - run.lastPosition).Magnitude > math.max(28, elapsed * 85) then self:End(player, false);continue end
            run.lastPosition, run.sampledAt = root.Position, now
            if now >= run.deadline then self:End(player, true);continue end
            local target = Config.HuntPosition(run.count + 1, run.variant)
            if now - run.lastCollect >= .45 and (root.Position - target).Magnitude <= Config.HuntReach then
                local ray = RaycastParams.new()
                ray.FilterDescendantsInstances, ray.RespectCanCollide = {run.character}, true
                if not workspace:Raycast(root.Position, target - root.Position, ray) then
                    run.combo = if now - run.lastCollect <= Config.ComboSeconds then math.min(10, run.combo + 1) else 1
                    run.bestCombo = math.max(run.bestCombo, run.combo)
                    run.count += 1
                    run.score += 10 + 2 * run.combo
                    run.lastCollect = now
                    if run.count == Config.HuntCount then self:End(player, now - run.started >= 15)
                    else self:Publish(player, run) end
                end
            end
        end
    end
end

function Service:Remove(player)
    self:End(player, false)
    self.ready[player], self.limits[player] = nil, nil
end

function Service:Destroy()
    for player in self.runs do self:End(player, false) end
    for _, link in self.links do link:Disconnect() end
    self.remote:Destroy()
end
return Service
