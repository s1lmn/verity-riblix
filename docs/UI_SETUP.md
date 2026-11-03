# Запуск и интеграция интерфейса

Роль UI — Егор, ветка `agent/ui`. Карта World и её генераторы сохранены. UI готов к подключению серверных сервисов по [предложению API](UI_API_PROPOSAL.md). Без Core можно осматривать окна; деньги и покупки не симулируются обычной сборкой.

## Сборка

Нужны официальные [Rojo](https://github.com/rojo-rbx/rojo/releases) и [Luau CLI](https://github.com/luau-lang/luau/releases). Ничего из Creator Store для UI не требуется.

```powershell
rojo build default.project.json -o builds/VerityUI.rbxlx
```

Откройте `builds/VerityUI.rbxlx` через File → Open from File. Play создаёт существующую карту через MapBootstrap и запускает `StarterPlayerScripts/VerityClient/ClientBootstrap`. В UI будет `Waiting for Core`, пока сервер не создаст согласованные remotes и не пришлёт снимок.

Альтернатива: `rojo serve default.project.json`, затем подключение обычным Rojo plugin. Ветка не требует установки неофициального MCP или сторонних UI-фреймворков.

Пути в DataModel:

| Источник | DataModel |
| --- | --- |
| `src/client` | `StarterPlayer.StarterPlayerScripts.VerityClient` |
| `src/shared/LevelConfig.luau` | `ReplicatedStorage.Shared.LevelConfig` |
| `src/world`, MapBootstrap, интерьер | Исходные пути World, без изменений |

`StarterGui.ScreenOrientation = Sensor`: поддерживаются обе ориентации. ScreenGui использует CoreUISafeInsets и ClipToDeviceSafeArea. HUD и навигация расположены сверху, вне нижних зон управления. В коротком горизонтальном окне открытая панель временно занимает верхнюю область, навигация возвращается по Close/Back. На узком высоком экране лента перестраивается в одну колонку. Списки заданий и настроек прокручиваются.

## Проверки без Studio

```powershell
python tools/check_ui.py --luau-dir C:/path/to/official-luau --rojo C:/path/to/rojo.exe
```

Проверка компилирует исходники и тестовые Luau-модули, запускает 10 групп тестов, проверяет строгие типы трёх модулей без зависимостей от движка, собирает `.rbxlx`. На Windows исходники временно копируются в ASCII-путь под Public: это обход ошибки `require` Luau CLI в каталогах с кириллицей. Сборка и отчёт появляются в игнорируемом `builds/`.

## Изолированное превью и тестовые ответы

`tests/UIStudioHarness.luau` исключён из `default.project.json`. Для осмотра подтверждений без Core:

1. Вставьте его как `ModuleScript` с именем `UIStudioHarness` в ReplicatedStorage **копии тестового place**.
2. Запустите Play и переключитесь на Client.
3. Выполните в клиентской Command Bar:

```lua
local fixture = require(game.ReplicatedStorage.UIStudioHarness)
fixture.Main:Open("PHONE")
```

В заголовках будет `UI TEST FIXTURE`, суммы симулированы. Fixture не создаёт remotes, не сохраняет профиль и не является серверной экономикой. Его `Mode` поддерживает `Success`, `Reject`, `Timeout`; `fixture:SetLevel(99)` полезен для осмотра последней стадии. `fixture.Main.ctx.net`, `fixture.Requests` и `fixture.State` доступны только тестовому коду. Не включать fixture в опубликованную игру.

После завершения тестов остановите Play. Основная сборка никогда не вызывает fixture. В переданном открытом проекте тестовый модуль удалён после проверки.

## Что нужно от Core

Реализовать серверные каналы и полный снимок из `UI_API_PROPOSAL.md`; закрепить итог в `API_CONTRACT.md`. На старте UI синхронизируется закрытием телефонной сессии через существующий `RequestPhoneSession`. Публиковать revision результата и соответствующий снимок, точно коррелировать operationId. Обучение, cooldown и награды заданий остаются на сервере. В Complete перехода интерьера необходима позиция назначения.

Числа в примерах payload — образцы формы, не готовый баланс. 100 уровней, DataStore, баланс 20–30 часов, доставка и полноценная работа заданий не реализованы UI-веткой.

## Что нужно от World

UI-композиции карточек уже работают без изображений. При замене на разрешённые ImageAssets сохраните процедурную композицию на время загрузки/ошибки; нельзя оставлять пустую карточку. 12 тем описаны в `FeedController.Posts`.

Добавьте общий `World.AudioConfig.UI` с проверенными SoundId по таблице API. Пока AudioConfig отсутствует, звуков нет, ошибок из-за этого нет. World VFX наблюдает локальные атрибуты ReducedMotion/ReducedEffects в `PlayerGui.VerityUI`. Общая формула в LevelConfig уже точная; UI не масштабирует модели мира.

## Ограничения приёмки

Фактические выполненные проверки и снимки находятся в [отчёте UI](UI_TEST_REPORT.md). Эмулятор не доказывает FPS физического телефона или качество реального touch/gamepad-ввода. 2/8/16/24 игрока, 16 моделей 15×, перезаход с сохранением, внешние аудиоассеты и баланс требуют общей сборки Core + World + UI.
