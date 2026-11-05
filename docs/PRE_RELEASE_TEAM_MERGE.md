# Core + изменения команды перед push

Пользователь прямо поручил push. Core e5830e8 объединён с origin/main 629cfb8b01127d11ebce94317bf75805e0edbf95. Без выбора целиком ours/theirs:

- Shared.ActivityRewards сохраняет денежные Definitions/Base/Task и командные достижения Order/Items/Unlocked.
- CosmeticCatalog/Factory содержат все командные награды, starter-образы/цвета и наши три delivery_* украшения. Серверная проверка покупок запрещает продажу обеих групп эксклюзивов и бесплатных вариантов.
- PlayerState сохраняет Core AbilityCollection/AbilitySlots/Progression/NextUnlock и командные ActivityTrophies в личной/публичной проекции.
- Notification adapter сохраняет deliveryReward и achievementId/itemId, обе системы вручения продолжают получать свои данные. Звуки доставки не дублируются звуком платной покупки.
- Сохранены finish hooks паркура, победы гонки/арены, ActivityRewardService, native-полка, карточка вручения, бесплатные стили, реакции и одно и то же исправление строки запуска.
- В UI косметики доставка отмечена бесплатным источником с шансом 2%, кнопка «Как получить» сообщает всю таблицу и компенсацию. Владение и выдача остаются серверными.

main.py временно сохранён в адресном stash bb314efe9cb7dea708bfa77a1d121bd9e8de2e60, после merge восстанавливается с исходным staged-состоянием и не включается в игровые коммиты. Backup stash не удаляется.

Проверка разрешена только чтением исходников/diff и статуса Git. Никаких тестов, валидаторов, Luau compilation, Play, profiler, реального DataStore или визуальной приёмки. Упаковка только --no-verify, без Roblox Publish. Подтверждение push и fingerprint сборки фиксируются отдельно после операции.
