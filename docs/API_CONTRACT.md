# VERITY единый контракт локальной финальной версии

Сервер авторитетен для денег, уровней, владения, заданий, cooldown и сохранения.
Shared.LevelConfig — единственный источник масштаба:1/1.4/2/3/4/5 на уровнях
1/10/25/50/75/100, линейная интерполяция между точками. Все99 переходов строго растут.
Milestones содержит объекты level/name/reward для UI; isMilestone/getNextMilestone — Core API.

## Запросы

ReplicatedStorage.Remotes содержит RemoteEvents. Каждый запрос — одна таблица с
operationId: канонической положительной десятичной строкой1..1e15. Один возрастающий
счётчик на подключение игрока, общий для всех действий; повторы сохраняют исходный ID.
UI сериализует запросы и повторяет неизвестный результат тем же ID, не создавая новую покупку.
Дополнительное поле version в запрос не отправляется.

| Remote | Дополнительные поля |
|---|---|
| RequestSync | нет |
| RequestOpenBox | нет; загруженный профиль, владелец и дистанция проверяются сервером |
| RequestUpgradeVerity | нет; распаковка, деньги, предел100 |
| RequestUpgradeSwipe | нет; деньги, предел40 |
| RequestPhoneSession | open:boolean |
| RequestSwipe | нет; открытая сессия, интервал0.75s |
| RequestTaskStart / RequestTaskComplete | taskId: PRESS_BUTTON / REACH_POINT / STAND_ON_PLATFORM |

Чужие суммы, координаты, уровни, PlotId, owner и неизвестные поля не принимаются.
Дубликаты возвращают cached result без исполнения; watermark запрещает повтор после eviction.
Лимит:20 burst,8 requests/sec/player; flood отбрасывается без усиления ответами.

## Ответы и состояние

ActionResult wire: {protocolVersion=1,action=полное имя remote,operationId?,status,
reward,stateRevision,replayed,nextOperationSequence}. OK означает успех.
Корректный ID сохраняется при ошибке схемы. Частые отказы: NOT_READY, TOO_FAR,
INSUFFICIENT_CASH, BOX_NOT_OPENED, MAX_LEVEL, PHONE_CLOSED, COOLDOWN, STALE_OPERATION.

PlayerStateUpdated — полный подтверждённый snapshot с protocolVersion/stateRevision/serverTime,
Cash/TotalEarned, уровнями, доходами, ценами, VerityUnlocked/DeliveryState, HouseTier,
VerityScale/NextVerityScale/NextMilestoneLevel, PhoneOpen, TutorialStep/TutorialCompleted,
BoostMultiplier/BoostExpiresAt и NextOperationSequence. Tasks — записи по taskId с
taskId/reward/status/cooldownEndsAt/targetPosition и Core-полями Active/CooldownUntil.
Отсутствующая следующая цена на максимуме — nil, не0. Награды вычисляются сервером.

CoreProtocol преобразует wire-формат во внутренний UI-формат version/success/errorCode,
короткие имена действий, PhoneSessionOpen и kind. UI не меняет цены и не начисляет деньги.
После покупки он ждёт соответствующую revision snapshot. RequestSync восстанавливает поздний UI.

## Мировая презентация

WorldEvent wire: {protocolVersion=1,type,eventId,ownerUserId,plotId,stateRevision,...}.
VerityLevelChanged содержит oldLevel/newLevel/oldScale/newScale/milestoneLevel?.
Одна покупка = один переход; события HouseTierChanged/MilestoneReached с purchaseEventId
не создают вторую презентацию. WorldSnapshot/PlotAssigned применяют baseline без истории.
UI адаптирует type→kind. Канонический VerityVisualController получает подтверждённые события,
очередь проигрывает все переходы, а не перескакивает на последний уровень.

Core создаёт tagged VerityVisual после распаковки. Модель содержит OwnerUserId/PlotId,
VerityLevel/StateRevision/PresentationVersion/VerityOrigin. Клиент меняет только позу/цвет/VFX.
Стриминг восстанавливает актуальную форму без повторения старых празднований.
VerityPrototypeVisual принадлежит отдельной арт-галерее и не создаётся игровым bootstrap.

## Карта, дома и задания

WorldBuilder создаёт открытый район v5 один раз. Core привязывает владение/SpawnLocation
к готовым World-маркерам и зеркалирует состояние на участке. Все дома и мебель общие;
гости входят пешком. Никаких частных комнат, серверных дверных телепортов или fade-событий.
При выходе освобождаются владение, персонаж и Verity; физический дом остаётся на карте.
Улучшать можно только собственный профиль: клиент не выбирает owner/PlotId.

GameplayInteractions добавляет три отдельных игровых объекта на существующей площади.
Кнопка использует checked ProximityPrompt. Reach проверяется серверным polling, платформа
требует непрерывного нахождения над прямоугольником не менее1s. Cooldown индивидуален.
Все выплаты проходят EconomyService. NotificationEvent сообщает подтверждённую награду.

## Данные

DataService: UpdateAsync, session lease180s, autosave60s, fail closed до истечения lease,
release/BindToClose, повторы и валидация. Ошибка загрузки не создаёт профиль поверх старого.
Производные масштабы/доходы/HouseTier и физический PlotId не сохраняются как отдельная истина.
Studio Memory временный; опубликованная игра использует DataStore. Реальные сохранения
и16/24-player/mobile acceptance остаются отдельными невыполненными проверками.
