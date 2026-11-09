Актуальное объединение9ноября: [PREMIUM_INTEGRATION_MERGE.md](PREMIUM_INTEGRATION_MERGE.md). Два ID команды подключены; Core и визуальный контракт согласованы через bridge.

# Premium Core — реализация9ноября2026

Получен dd71cc0 fast-forward; сохранены Scarlet Sentinel/новая арена/верховой полёт и прошлый кооператив. Реализованы PremiumCatalog, PremiumService и PurchaseReceiptService; добавлены3строгих запроса/сохранение PremiumGrants+PremiumLoadout, owner/public projections,8товаров/6слотов, совместное право оформления слияния и оформление вечеринки хозяина без передачи владения. Legacy×3/hero используют единый pass owner, admin session entitlement не становится покупкой. Расходники сохраняют прежние durable ledger handlers за одним проверяющим router. Ни одного placeholderID/новой живой продажи/случайной платной награды.

Подробный контракт и ограничения: [PREMIUM_CORE_UI_HANDOFF.md](PREMIUM_CORE_UI_HANDOFF.md).

Без Play/тестов/валидаторов/компиляции/рендеров; только --no-verify упаковка. Реальные платежи/сохранение при сбое/визуальная часть пока не проверены. Изменения локальные, новый push/Publish не поручен. main.py сохранён отдельно.


## Локальная упаковка

Rojo --no-verify завершён успешно. Открывать `C:\Users\IvanI\PycharmProjects\verity-riblix\build\VERITY-Latest.rbxlx` или `build/VERITY-Premium-Core.rbxlx`. Обновлены текущие алиасы Polished/Coop-V2/Weather-Forge/Weather-Adventures/Fire-Sky/UI-Weather-Fixes.

Fingerprint: `bd40f438bd3cf7a96c5384b444109de1dd74878c249593ba5dd0576ab313f951`, sourceCommit:`dd71cc073a1bc9a8989b15524ef5c593466d75a0`, dirty:true. Это текущая локальная Core-интеграция поверх dd71cc0, без нового push/Publish и без проверок игрового исполнения. IDs nil/пустые, PresentationReady новых6наборов false.
