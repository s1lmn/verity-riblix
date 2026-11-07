--!nonstrict
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Cleanup=require(script.Parent.Cleanup)
local Model=require(script.Parent.UIModel)
local Tracker=require(script.Parent.RequestTracker)
local Protocol=require(script.Parent.CoreProtocol)
local Locale=require(script.Parent.Locale)
local Cosmetics=require(ReplicatedStorage.Shared.CosmeticCatalog)
local Adapter={};Adapter.__index=Adapter
function Adapter.new()
	local self=setmetatable({cleanup=Cleanup.new(),remoteCleanup=Cleanup.new(),tracker=Tracker.new(),state=nil,
		remotes={},connected=false,fences={},started=false,sequence=Players.LocalPlayer:GetAttribute("VerityClientSequence") or 0,
		retryAt=0,sent={},needSync=true},Adapter)
	for _,name in {"StateChanged","Result","World","Notification","ConnectionChanged","PendingChanged","TimedOut"} do
		self[name]=self.cleanup:Add(Instance.new("BindableEvent"))
	end
	return self
end
function Adapter:IsBusy(_action)
	return next(self.tracker.pending)~=nil or next(self.fences)~=nil
end
function Adapter:Start()
	if self.started then return end
	self.started=true
	local function refresh() self:Attach(ReplicatedStorage:FindFirstChild("Remotes")) end
	self.cleanup:Add(ReplicatedStorage.ChildAdded:Connect(refresh));self.cleanup:Add(ReplicatedStorage.ChildRemoved:Connect(refresh))
	local elapsed=0
	self.cleanup:Add(RunService.Heartbeat:Connect(function(dt)
		elapsed+=dt;if elapsed<0.25 then return end;elapsed=0
		local now=os.clock()
		for _,item in self.tracker:Expire(now) do self.TimedOut:Fire(item);self.PendingChanged:Fire() end
		for id,sent in self.sent do
			local retryAfter=math.min(30,8*2^math.min(sent.retries,2))
			local remote=self.remotes[sent.action]
			if now-sent.at>=retryAfter and self.tracker.byId[id] and self.connected and remote then
				sent.at=now;sent.retries=math.min(sent.retries+1,2)
				-- Same operation ID: recover its outcome without charging again.
				remote:FireServer(sent.payload)
			end
		end
		if self.connected and (not self.state or self.needSync or next(self.fences)~=nil) and next(self.tracker.pending)==nil and now>=self.retryAt then
			self.retryAt=now+0.75;self:Request("Sync",nil,true)
		end
	end))
	refresh()
end
function Adapter:Attach(folder)
	if self.folder==folder then return end
	self.remoteCleanup:Destroy();self.remoteCleanup=Cleanup.new()
	self.folder,self.connected,self.remotes=folder,false,{}
	if not folder then self.ConnectionChanged:Fire(false);return end
	local bound={}
	self.remoteCleanup:Add(function()
		for remote,link in bound do link:Disconnect();bound[remote]=nil end
	end)
	local function discover()
		for _,name in {"PlayerStateUpdated","ActionResult","WorldEvent","NotificationEvent"} do
			local remote=folder:FindFirstChild(name)
			if remote and remote:IsA("RemoteEvent") and not bound[remote] then
				bound[remote]=remote.OnClientEvent:Connect(function(payload)
					if remote.Parent~=folder then return end
					if name=="PlayerStateUpdated" then self:AcceptState(payload)
					elseif name=="ActionResult" then self:AcceptResult(payload)
					elseif name=="WorldEvent" then self:AcceptWorld(payload)
					elseif type(payload)=="table" then
						if payload.protocolVersion==1 then
							local messages={
        TASK_OTHER_ACTIVITY="Заверши текущую активность, затем возьми поручение.",DIVERSION_COOLDOWN="Награда скоро обновится. Попробуй соседнюю активность.",DIVERSION_REWARD="Испытание завершено! Награда получена.",
        FUSION_PRIZE="Заезд завершён! Парные подвески в меню стиля Verity.",FUSION_WIN="Заезд слияния завершён!",
        FUSION_ENDED="Заезд завершён. Ваши Verity вернулись.",FUSION_FAILED="Попытки закончились. Можно повторить заезд у установки.",
        FUSION_TIME="Время вышло. Ваши Verity вернулись.",ACTIVITY_REWARD_UNLOCKED="Новая награда за приключение!",OK="Verity is ready!",ALREADY_OPENED="Your Verity is already unpacked.",
								PARKOUR_FINISH="Паркур пройден! Награда получена.",
        PARKOUR_STARTED="Фабрика запущена! Пройди семь цехов и включи ядро. Способности отключены.",
        PARKOUR_CORE_READY="Маршрут пройден! Нажми «Запустить ядро» у пульта.",
        PARKOUR_MISSED_STEP="Пропущен участок. Следующая площадка подсвечена — продолжи от неё.",
        PARKOUR_GATE_MISSED="Пропущены контрольные ворота. Возвращаем к сохранённой точке.",
        PARKOUR_START_REQUIRED="Начни у входа: награда выдаётся за все платформы по порядку.",
        PARKOUR_TOO_FAST="Слишком быстро для зачётного прохождения. Подожди на финише.",
        PARKOUR_REWARD_RETRY="Награда пока не выдана. Повтори запуск ядра у пульта.",PARKOUR_CHECKPOINT="Чекпоинт сохранён!",PARKOUR_PRACTICE="Отличная тренировка! Награда скоро обновится.",
        STREET_DELIVERY_STARTED="Фургон Verity Express в районе! Следи за посылкой на главной дороге.",STREET_DELIVERY_DROPPED="Посылка выпала! Успей первым подобрать её на тротуаре.",STREET_DELIVERY_REWARD="Посылка твоя! Награда получена.",
        RACE_JOINED="Ты в заезде! Дождись второго участника у своего места.",RACE_STARTED="Старт! Болей за своего Verity!",RACE_WIN="Твой Verity победил! Награда получена.",RACE_FINISH="Заезд завершён! Можно попробовать ещё раз.",RACE_CANCELLED="Недостаточно участников. Verity вернулся к тебе.",
        BATTLE_JOINED="Ты на арене! Готовься к пяти волнам.",BATTLE_BUSY="Арена занята. Дождись конца битвы.",BATTLE_COOLDOWN="Награда арены скоро обновится.",BATTLE_OTHER_ACTIVITY="Сначала заверши текущую активность.",BATTLE_WAVE="Новая волна! Выходи из красных кругов.",BATTLE_BOSS="Появился Неоновый титан!",BATTLE_WIN="Пять волн пройдены! Награда получена.",BATTLE_FAILED="Битва завершена. Попробуй ещё раз!",PARKOUR_RETRY="Ловушка! Ты вернулся на контрольную точку.",
        COMBAT_REWARD="Цель разрушена! Награда получена.",PURCHASE_ERROR="Purchase could not open. Please try again.",TOO_FAR="Move closer to the interaction.",TASK_REWARD="Task completed!"}
							if payload.source=="HouseFeature" then
								messages={OK="Дом улучшен!",INSUFFICIENT_CASH="Не хватает денег",
									ALREADY_OWNED="Куплено",BOX_NOT_OPENED="Сначала распакуй Verity"}
							elseif payload.source=="Workshop" then
								messages={
									HOUSE_UPGRADED="Мастерская улучшена! Пассивный доход вырос.",
									INSUFFICIENT_CASH="На улучшение мастерской пока не хватает денег.",
									HOUSE_LEVEL_REQUIRED="Сначала подними уровень Verity.",
									BOX_NOT_OPENED="Сначала распакуй Verity",
									MAX_LEVEL="Все улучшения куплены",
								}
							end
							local message=messages[payload.code]
       if payload.code=="TASK_REWARD" then
        local outcomes={PRESS_BUTTON="Свет на улице восстановлен!",REACH_POINT="Посылка доставлена получателю!",STAND_ON_PLATFORM="Все три клумбы расцвели!",POSTBOX="Все письма доставлены!",CHECKPOINT="Фонари снова работают!",CHARGE_PAD="Зарядная станция запущена!",CLEAN_PARK="Сквер стал чистым!",SIGNAL_REPAIR="Сигналы перехода работают!",DRONE_RESCUE="Дрон спасён и заряжен!",FESTIVAL="Звезда Verity зажжена!"}
        message=outcomes[payload.taskId] or message
       end
       local drop=payload.deliveryReward
       if payload.code=="STREET_DELIVERY_REWARD" and type(drop)=="table" and drop.version==1 and type(drop.cycle)=="number" then
        if self.lastDeliveryCycle and drop.cycle<=self.lastDeliveryCycle then return end
        self.lastDeliveryCycle=drop.cycle
        if drop.compensation then message=Locale.Text("Коллекция доставки собрана! Компенсация ×5.").." +$"..Locale.Number(drop.cash)
        elseif drop.itemId and Cosmetics.Items[drop.itemId] and Cosmetics.Items[drop.itemId].source=="StreetDelivery" then
         message=string.format(Locale.Text("Из посылки: %s!"),Locale.Text(Cosmetics.Items[drop.itemId].name))
        else message=string.format(Locale.Text("Награда доставки ×%d: $%s"),drop.multiplier or 1,Locale.Number(payload.reward)) end
       end
							if message then self.Notification:Fire({version=1,message=message,kind="Info",eventId=payload.eventId,reward=payload.reward,code=payload.code,source=payload.source,deliveryReward=payload.deliveryReward,achievementId=payload.achievementId,itemId=payload.itemId}) end
						elseif payload.version==1 and type(payload.message)=="string" then self.Notification:Fire(payload) end
					end
				end)
			end
		end
		for action,name in Protocol.RequestNames do
			local remote=folder:FindFirstChild(name);self.remotes[action]=if remote and remote:IsA("RemoteEvent") then remote else nil
		end
		local ready=self.remotes.Sync~=nil and bound[folder:FindFirstChild("PlayerStateUpdated")]~=nil
			and bound[folder:FindFirstChild("ActionResult")]~=nil
		if ready~=self.connected then self.connected=ready;self.needSync=true;self.ConnectionChanged:Fire(ready) end
	end
	self.remoteCleanup:Add(folder.ChildAdded:Connect(discover))
	self.remoteCleanup:Add(folder.ChildRemoved:Connect(function(remote)
		local link=bound[remote]
		if link then link:Disconnect();bound[remote]=nil end
		discover()
	end))
	discover()
end
function Adapter:Request(action,args,handshake)
	local remote=self.remotes[action]
	if not self.connected or not remote or (not self.state and not handshake) then return nil,"Waiting for the game server." end
	if self:IsBusy(action) and not (action=="Sync" and next(self.tracker.pending)==nil) then return nil,"Waiting for the previous server result." end
	self.sequence+=1
	Players.LocalPlayer:SetAttribute("VerityClientSequence",self.sequence)
	local id=string.format("%.0f",self.sequence)
	if not self.tracker:Begin(action,id,os.clock(),if self.state then self.state.stateRevision else -1) then return nil end
	local payload=table.clone(args or {});payload.operationId=id
	self.sent[id]={action=action,payload=payload,at=os.clock(),retries=0}
	remote:FireServer(payload);self.PendingChanged:Fire()
	return id
end
function Adapter:AcceptState(raw)
	local normalized=Protocol.State(raw)
	local state,reason=Model.ValidateSnapshot(normalized)
	if not state then warn("[Verity UI] Rejected Core snapshot:",reason);return end
	if type(raw.NextOperationSequence)=="number" then self.sequence=math.max(self.sequence,raw.NextOperationSequence-1) end
	if self.state and state.stateRevision<self.state.stateRevision then return end
	self.state=state;self.needSync=false
	for action,revision in self.fences do if state.stateRevision>=revision then self.fences[action]=nil end end
	self.StateChanged:Fire(state);self.PendingChanged:Fire()
end
function Adapter:AcceptResult(raw)
	local result=Protocol.Result(raw)
	if not result or result.version~=1 or type(result.operationId)~="string" or type(result.success)~="boolean" then return end
	if type(raw.nextOperationSequence)=="number" then self.sequence=math.max(self.sequence,raw.nextOperationSequence-1) end
	local pending=self.tracker:Resolve(result)
	if not pending then return end
	self.sent[result.operationId]=nil
	if result.success and (not self.state or result.stateRevision>self.state.stateRevision) then self.fences[result.action]=result.stateRevision end
	if result.action=="Sync" then self.needSync=not result.success or not self.state or next(self.fences)~=nil
	elseif not result.replayed or result.action=="Swipe" then self.Result:Fire(result) end
	if result.replayed or pending.unresolved then self.needSync=true end
	self.PendingChanged:Fire()
end
function Adapter:AcceptWorld(raw)
	local event=Protocol.World(raw)
	if not event or event.version~=1 or type(event.kind)~="string" then return end
	if event.kind=="VerityLevelChanged" then
		local minimum=if RunService:IsStudio() then -2^53+1 else 1
		if not Model.IsInteger(event.oldLevel,1,99) or event.newLevel~=event.oldLevel+1
			or not Model.IsInteger(event.ownerUserId,minimum,2^53-1) or event.ownerUserId==0
			or type(event.eventId)~="string" or not Model.IsFinite(event.oldScale) or not Model.IsFinite(event.newScale)
			or math.abs(event.oldScale-Model.Scale(event.oldLevel))>1e-6
			or math.abs(event.newScale-Model.Scale(event.newLevel))>1e-6 then return end
	end
	self.World:Fire(event)
end
function Adapter:Destroy() self.remoteCleanup:Destroy();self.cleanup:Destroy() end
return Adapter
