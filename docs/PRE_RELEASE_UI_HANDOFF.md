# Передача разработчику 2: World / UI / VFX

Core: PRE_RELEASE_CORE.md. Сервер уже пишет следующие поля; использовать их, не вычислять владение/шансы/цены/выдачу на клиенте.

## NPC: одна траектория и одна визуальная система

`ReplicatedStorage.VerityEnemyMotion.OnClientEvent(packet)`:
```
{version=1, enemyId:number, sequence:number,
 from:CFrame, to:CFrame, startedAt:number, duration=.15}
```
Пакет атомарный (одна таблица), только server→client, примерно 6.7 Hz, до трёх врагов, участникам и наблюдателям в пределах 260 studs. Серверный модельный EnemyId связывает его с Enemies/EnemyVerity. sequence монотонна для данного врага. Возле арены новый пакет придёт на следующем decision tick. Не завязываться на порядок появления модели и прихода remote.

- Использовать Shared.EnemyMotion.Sample(packet, workspace:GetServerTimeNow()). Серверный UpdateMotion тем же Sample двигает боевую модель каждый Heartbeat и перед raycast. Не добавлять ещё один local PivotTo/Tween к серверной модели: будет конкурировать с репликацией.
- Сделать **одну** локальную неколлизионную и неqueryable визуальную копию. Серверные части скрывать локально, сохранив их query и серверную физику. Копия не получает gameplay tags/автоконтроллер спутника. Не запускать второй FollowOwner/aim mover.
- Только свежие sequence, bounded cache для stream-in; пока пакета/модели нет — аккуратный fallback на реплицированный pose. Не продолжать экстраполяцию за конец сегмента. Не добавлять большой временной буфер: он оторвёт картинку от hitbox. Не увеличивать урон/попадание по запросу клиента.
- EnemyDead отменяет движение/предупреждение и запускает fade .6 с; удаление/stream-out/смена арены уничтожают копию, marker, ссылки и cache. Штатный ActivitiesController уже обрабатывает EnemyDead и StrikeAt/StrikeTarget; встроить новое представление туда, не создавать параллельную систему.
- Сохранить предупреждения и видимый радиус EnemyRadius. Не гасить предупреждения активного боя из-за низкой графики. Это ещё не проверено в Play.

## Доставка

Config.Rewards задаёт веса 70/22/6/2, Config.Cosmetics содержит только delivery_*; компенсация при полной коллекции Config.CosmeticCompensationMultiplier=5. На `workspace.VerityStreetDelivery` есть RewardDescription_ru/en, RewardOdds, CosmeticCompensationMultiplier — показать текст в краткой справке активности при приближении/взаимодействии, без постоянного длинного баннера.

У победителя NotificationEvent сохраняет прежние code=STREET_DELIVERY_REWARD, reward=фактические деньги, eventId, source, плюс:
```
deliveryReward={version=1,cycle,kind,itemId?,cash,multiplier,compensation,rare}
```
kind=Cash / DoubleCash / JackpotCash / Cosmetic. При косметике cash=0; при полной коллекции kind=Cosmetic, compensation=true, cash>0. Повторы eventId/цикла не повторяют reveal. rare=true для ×5 и косметики; короткая выразительная анимация с учётом ReducedEffects/quality; не показывать косметику при compensation=true. Пакет не выдаёт прогресс на клиенте.

Для наблюдателей после подбора есть атрибуты RewardKind/RewardItemId/RewardCash/RewardMultiplier/RewardCompensation/WinnerUserId; они независимы по репликации — итоговую личную карточку строить по атомарному уведомлению, не по смеси старых атрибутов. Сервер выбирает награду заранее, но не раскрывает её до подбора.

В CosmeticCatalog добавлены три source=StreetDelivery, exclusive=true предмета, уже есть начальная носимая native-геометрия в CosmeticFactory. Подпись вместо «скоро/купить за Robux»: «Награда доставки • шанс украшения 2%»; конкретный неполученный предмет выбирается равномерно из оставшихся. Не выдавать delivery_* за паркур/гонки/арену. Улучшить art по желанию без смены ID/slot.

Машину увеличить примерно ×1.5 вместе с tireCF/hubCF и колёсами; поправить from точки броска в StreetDeliveryController. Это World-задача, Core не масштабировал truck. Серверная точка подбора на тротуаре неизменна (Config.SidewalkX/ParcelY).

## Снимок игрока

- `AbilityCollection`: массив записей id/icon/name/description/slot/availableSlots/requiredLevel/cost/premium/owned/levelMet/state/equippedSlots/canEquip/canBuy/affordable/color/cooldown/duration/blockedReason. Основные state: LockedLevel, Purchasable, Owned, Equipped; premium: PassRequired, Unavailable. levelMet не означает owned. blockedReason=BOX_NOT_OPENED/ABILITY_LEVEL_REQUIRED при ограничении. canBuy не включает affordable: отдельно не давать покупку при недостатке Cash. HeroPassId=nil — никакого настоящего платежа.
- `AbilitySlots.Mobility / Attack`: itemId/name/icon/key/gamepadKey/empty/emptyAction/temporary/blockedReason/readyAt/activeUntil/duration/active/canUse. Два слота сохранять видимыми даже при empty/временном ограничении; пустой ведёт в существующее ABILITIES. F/G, L1/R1 и touch сохранить; на ПК ключи уже действуют.
- Таймеры считать от абсолютных serverTime/Workspace:GetServerTimeNow(), не уменьшать значения снимка по кадрам. Мгновенные изменения: прежние player attributes VerityAbilityReadyAt / VerityAttackReadyAt / VerityMobilityUntil плюс VerityAttackUntil. Смена этапов арены/гонки/вход-выход паркура force-publish. Повторная активация всегда проверяется сервером. RACE_POWER / PARKOUR_POWER / RIDING_POWER / SAFE_ZONE объясняют блокировку; cooldown/activeUntil — отдельные состояния.
- `RequestEquipAbility({operationId,itemId,slot?})`: slot Mobility/Attack. Обычная сила допускает свой slot, premium bundle также Mobility; старое отсутствие slot выбирает bundle сразу в оба. Не нужно новое equip remote.
- `Progression.stage`: Delivery / FirstUpgrade / FirstActivity / FreePlay. goal: OpenBox / EarnCash / UpgradeVerity / Task. FirstActivity предлагает PRESS_BUTTON; не создавать новый параллельный TutorialController.
- `NextUnlock`: kind AbilityPurchase / AbilityAccess / Appearance / Riding, itemId?, name?, requiredLevel, progress/total/remaining, cost?, requiresPurchase. Показывать значение после роста/покупки. AbilityAccess открывает **доступность покупки**, не владение. Riding остаётся постоянным открытием 50 уровня, без ранней сохранённой выдачи.
- `ActivityRewardQuotes`: Parkour/Battle/Race — текущие награды с множителями; Parkour quote до бонуса медали, Race только победителю. `Tasks[*].reward` уже масштабирован и совпадает с серверной формулой. Самому не умножать повторно на pass/boost/house.

## Паркур и оставшиеся World/UI-задачи

ParkourConfig.Version=4. Те же 48 платформ, но новые ловушки на секциях 5/6, безопасные окна + предупреждения у каждого Sweep/Pulse. Config.HazardGeometry(index,serverNow) возвращает CFrame,size,phase; Config.HazardHits использует эту же геометрию. Не менять видимые размеры/угол без общего конфига. Активный phase=2, предупреждение=1, безопасно=0. Support/декор не должен выглядеть физической опорой. Без надписей над каждой платформой. Если перерабатывать физические движущиеся платформы — сначала общий координатный/коллизионный контракт с Core; локально двигать коллизионные опоры нельзя.

Остаются: композиция испытаний/окружение, truck, proximity-only баннеры, спокойный единый визуальный стиль, реальные два HUD-слота/коллекция, NextUnlock-карточка, редкий reveal и доступность для маленького экрана. Не включать фоновую музыку и не добавлять отдельный графический режим. Реальный доступ к аудио, мобильная проходимость, сохранения/rejoin/PvP/несколько игроков — ручная приёмка команды, не подтверждённые результаты этого этапа.

## Объединение с командой при push

Сохранён 629cfb8: отдельные parkour_star_band/champion_goggles/titan_charms, бесплатные starter-образы/цвета, домашняя полка и карточки наград. Shared.ActivityRewards объединяет обе группы функций: не заменять его целиком только балансом или только достижениями. Адаптер переносит одновременно deliveryReward и achievementId/itemId. В COSMETICS уже добавлены базовые подписи источника доставки, кнопка «Как получить» и вероятности; полноценная новая композиция/reveal по-прежнему остаётся здесь.
