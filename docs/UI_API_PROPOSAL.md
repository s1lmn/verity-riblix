# Предложение API для Core и UI

Дата: 3 ноября 2026. Ветка `agent/ui`, роль UI — Егор. **Это предложение для реализации Core, а не утверждённый серверный контракт.** На исходном `main` нет `API_CONTRACT.md`, RemoteService или экономики. UI не создаёт remotes и серверные обработчики. Core должен согласовать этот документ, перенести договор в `API_CONTRACT.md` и при необходимости изменить только `NetworkAdapter` и модель представления UI.

Приоритет требований: прямой запрос пользователя и приложенные обновлённые DOCX от 3 ноября; существующие согласования по сохранению карты и персональным интерьерам остаются в силе. Команды внутри DOCX сами по себе не разрешают публикацию или запуск других агентов.

## Владение

| Область | Ответственный |
| --- | --- |
| Cash, покупки, выдачи, задания, участки, сессии, сохранения | Core |
| Геометрия, размер моделей, world VFX, пространственный звук | World |
| Отображение подтверждённых данных, телефон, ввод, UI-звук | UI |
| `src/shared/LevelConfig.luau` | Общая точная формула; Core может дополнить модуль, сохранив `getVerityScale(level)` |

Формула существует в одном общем модуле: `1 + 14 * ((level - 1) / 99)^0.85`, уровни 1–100, без округления. UI округляет только вывод до трёх знаков, чтобы 98, 99 и 100 оставались различимыми. В UI нет таблиц цен и формул дохода. Цели 20–30 часов / 3,5–4 часа не подтверждены этой работой: симуляция принадлежит Core.

## Транспорт

Все перечисленные каналы — `RemoteEvent` в `ReplicatedStorage.Remotes`. Один аргумент-таблица, `version = 1`. Имена каналов из ТЗ сохранены.

| Канал client → server | Payload помимо version |
| --- | --- |
| `RequestUpgradeVerity` | `operationId: string` |
| `RequestUpgradeSwipe` | `operationId: string` |
| `RequestPhoneSession` | `operationId: string, open: boolean` |
| `RequestSwipe` | `operationId: string` |
| `RequestTaskStart` | `operationId: string, taskId: "PRESS_BUTTON" \| "REACH_POINT" \| "STAND_ON_PLATFORM"` |

`operationId` — GUID клиента для корреляции; сервер всё равно обязан проверять типы, длины, повторы, лимиты, баланс, расстояние и право действия. Минимальный серверный интервал оплачиваемых свайпов — 0,75 с. Клиентский debounce не является защитой экономики.

UI не отправляет сумму, следующий уровень, награду или номер карточки как экономическую истину. `RequestOpenBox` и `RequestTaskComplete` остаются предусмотренными ТЗ каналами Core; этот UI их не подменяет. Коробка открывается через world prompt. Выполнение заданий проверяет сервер по реальному взаимодействию/позиции/времени.

## Подписка и первый снимок

Сначала клиент подключается к серверным событиям. Затем отправляет `RequestPhoneSession {open=false}`. Core отвечает полным снимком и `ActionResult` даже для повторного закрытия уже закрытой сессии. Это синхронизация через существующий канал, без альтернативного `RequestState`. Core также отправляет снимок при загрузке профиля.

При открытии телефона UI запрашивает `open=true`; до подтверждения сессии оплачиваемые запросы свайпа не отправляются. Закрытие окна, переход к другому меню и смерть персонажа приводят к `open=false`. Если предыдущее открытие ещё ожидает ответа, закрытие отправляется после его разрешения. Попытки синхронизации состояния окна ограничены по частоте, не чаще одной в 2 секунды. Core обязан закрывать/истекать сессию и при потере клиента.

## PlayerStateUpdated

Полный снимок, не patch. `stateRevision` монотонно растёт для каждого пользователя; новая подтверждённая экономическая или статусная операция увеличивает revision. Повторы и более старые снимки UI отбрасывает. Снимок не содержит чужих приватных данных.

```lua
{
    version = 1,
    stateRevision = 42,
    Cash = 100,
    VerityLevel = 1,
    VerityUnlocked = true,
    HouseTier = 1,
    IncomePerSecond = 5,
    NextIncomePerSecond = 6,
    NextVerityUpgradeCost = 50, -- пример формы payload, не баланс игры
    SwipeUpgradeLevel = 0,
    SwipeIncome = 2,
    NextSwipeIncome = 4,
    NextSwipeUpgradeCost = 30,
    PhoneSessionOpen = false,
    TutorialStep = 4, -- 1..6, сервер сохраняет и продвигает обучение
    TutorialCompleted = false,
    Tasks = {
        {
            taskId = "PRESS_BUTTON",
            reward = 20,
            status = "Ready", -- Ready | Active | Cooldown
            cooldownEndsAt = 0, -- абсолютное время Workspace:GetServerTimeNow()
            targetPosition = Vector3.new(0, 5, 0), -- необязательно, для указателя
        },
    },
    -- необязательно: только пассивный доход, включённый именно в этот снимок
    IncomeAccrued = 5,
    -- необязательно, подтверждённое право/срок вычисляет Core
    Boost = { multiplier = 2, endsAt = 1234567890, description = "..." },
}
```

На Verity Lv100 `NextVerityUpgradeCost` и `NextIncomePerSecond` отсутствуют; на Swipe Lv40 отсутствуют `NextSwipeUpgradeCost` и `NextSwipeIncome`. Остальные уровни требуют конечные неотрицательные цены/доходы. `PhoneSessionOpen` обязателен. Незнакомые версии, NaN/Infinity и неполные обязательные поля не заменяют последний корректный снимок.

До первого снимка HUD показывает `—`, действия заблокированы, состояние — ожидание Core. Окна можно осматривать; локальный заработок не включается. Все числа на тестовых скриншотах отдельно маркированы как fixture.

## ActionResult

```lua
{
    version = 1,
    operationId = "guid-from-request",
    action = "UpgradeVerity", -- UpgradeVerity | UpgradeSwipe | PhoneSession | Swipe | TaskStart
    success = true,
    stateRevision = 43, -- обязателен при success; revision результата
    reward = 2, -- только реально выданная награда, если применимо
    errorCode = nil, -- при отказе: INSUFFICIENT_CASH, COOLDOWN, MAX_LEVEL и т.д.
}
```

Сервер отправляет ответ только инициатору и публикует актуальный снимок. UI принимает только соответствующий ожидающей операции `operationId` + `action`, не показывает повторную награду по дубликату. После успешного ответа UI блокирует новое действие того же типа, пока не получит снимок с revision не меньше указанного в ответе. Порядок доставки двух каналов может быть любым.

После 8 секунд без ответа операция помечается неизвестной и остаётся заблокированной. Автоматического повтора покупки с новым GUID нет. Запоздалый коррелированный ответ снимает блокировку. Неподтверждённый запрос не начисляет Cash и не повышает уровень.

Если ответ потерян окончательно, текущий договор оставляет действие заблокированным до переподключения. Следующее улучшение Core API — согласованный запрос статуса *того же* operationId; не добавлять независимый способ повторной выдачи.

## WorldEvent и презентация роста

UI подписан на общий `WorldEvent`. Для локального владельца только `kind="VerityLevelChanged"` запускает один LEVEL UP и один UI-звук. `ActionResult`, изменение снимка, `MilestoneReached` и `HouseTierChanged` не создают вторую презентацию той же покупки. World самостоятельно отвечает за VFX.

```lua
{
    version = 1,
    kind = "VerityLevelChanged",
    eventId = "server-unique-event-id",
    ownerUserId = 123,
    plotId = 1,
    oldLevel = 98,
    newLevel = 99,
    oldScale = LevelConfig.getVerityScale(98),
    newScale = LevelConfig.getVerityScale(99),
    milestoneLevel = nil,
    stateRevision = 44,
}
```

UI проверяет точную формулу scale, +1 уровень, revision и владельца; хранит ограниченный ledger ID и последовательную очередь переходов. Дубликат перехода с другим eventId тоже не блокирует очередь. Очередь сохраняет все 99 переходов, в том числе при пакетном получении; движения камеры и мира UI не запускает. Первый снимок задаёт baseline: старые уровни при входе не празднуются. Core обязан отправлять все последующие подтверждённые переходы без пропусков.

## NotificationEvent и автоматические награды заданий

```lua
{ version=1, message="Task complete!", kind="Info", eventId="unique-award", reward=20 }
```

`message` — серверный безопасный текст без rich text. Для обычного сообщения `eventId` и `reward` необязательны. Для автоматически выданной награды задания обязательны уникальный `eventId` и фактический `reward`; снимок отдельно отражает Cash. UI дедуплицирует награду и объединяет всплывающие суммы. Не сообщать одну награду одновременно через `ActionResult.reward`, `NotificationEvent.reward` и `IncomeAccrued`.

## Переходы в интерьер

Используется предложенный в `INTERIORS.md` payload через уже существующий `WorldEvent`, `kind="InteriorTransition"`. Отдельный remote не создаётся.

```lua
{
    version=1, kind="InteriorTransition", operationId="server-id",
    phase="Begin", -- Begin | Complete | Failed
    direction="Enter", -- Enter | Exit
    destination=nil, -- Complete: Vector3 позиции назначения
    errorCode=nil,
}
```

Все фазы одной операции имеют одинаковый ID. Для Complete Core передаёт `destination`: UI ждёт персонажа в пределах 18 studs и доступный локальный коллизионный пол под ним; это проверка минимальной готовности, не гарантия загрузки всей мебели. Опоздавшие фазы другого ID игнорируются. На Failed, респавне, уничтожении UI и через 8 секунд затемнение гарантированно снимается. Сервер отвечает за подгрузку, безопасное перемещение и восстановление. UI не телепортирует игрока.

## Аудио и доступность

Общий модуль World: `ReplicatedStorage.World.AudioConfig`, формат `UI.Click = {SoundId="rbxassetid://...", Volume=0.35}`. Ключи UI: Click, SwipeWhoosh, Reward, UpgradeSwipe, LevelUp, Milestone. AudioConfig пока отсутствует; вымышленных ID и загруженных сторонних звуков нет. Воспроизведение каждого UI cue принадлежит только UISoundController; World не дублирует его.

В `PlayerGui.VerityUI` доступны локальные атрибуты `ReducedMotion`, `ReducedEffects`, `UISounds`, `UIVolume`. World может наблюдать первые два для своего VFX. Настройки действуют на время текущего подключения и не заявлены как сохранённые. Никаких remotes настроек и новых DataStore-схем в этой ветке нет.

Roblox API: [ScreenGui и safe areas](https://create.roblox.com/docs/reference/engine/classes/ScreenGui), [GuiObject и Activated/input](https://create.roblox.com/docs/reference/engine/classes/GuiObject), [UserInputService](https://create.roblox.com/docs/reference/engine/classes/UserInputService).
