Актуальное объединение9ноября: [PREMIUM_INTEGRATION_MERGE.md](PREMIUM_INTEGRATION_MERGE.md). Два ID команды подключены; Core и визуальный контракт согласованы через bridge.

# Premium Core: контракт для разработчика UI / World / VFX

Реализована только наша часть Core,9ноября2026. База после pull: dd71cc0 (Scarlet Sentinel/арена/верховой полёт). Командные изменения сохранены.

## Реестр товаров и реальные цены

`Shared.PremiumCatalog`, версия1, — стабильные ID и определения товаров. Все товары в этом этапе постоянные Game Pass; один набор может открывать несколько вариантов. Новых расходуемых покупок и платных случайных выпадений нет.

| id | Категория | Что открывает | Цена-предложение |
|---|---|---|---:|
| money_x3 | Acceleration | ×3 ко всем деньгам | 99, ранее согласована |
| hero_kit | Verity | Алый страж: полёт/красные лазеры | 99, ранее согласована |
| home_style_pack | Home | 3 стиля дома | 149 |
| aura_pack | Verity | 3 ауры | 79 |
| fusion_pack | Verity | 2 оформления слияния | 99 |
| party_pack | Home | оформление вечеринки | 79 |
| collector_pack | Verity | витрина/рамки/обложка | 59 |
| atmosphere_pack | Home | 3 атмосферы участка | 99 |

Новые цены — SuggestedPrice для планирования, не цена продажи. Реальную цену UI получает через MarketplaceService:GetProductInfoAsync(gamePassId, Enum.InfoType.GamePass), учитывает IsForSale, кэширует по ID и обрабатывает отказ. Не печатать SuggestedPrice как действующую цену. Подтверждение списания показывает штатный диалог Roblox.

Реальные ID пользователь отложил: Config.MoneyPassId/HeroPassId=nil, Config.PremiumPassIds={} для остальных6. Не подставлять тестовые ID. После завершения конкретного оформления владелец интеграции ставит Config.PremiumPresentationReady[товар]=true. До этого новый товар не продаётся и не применяется, даже если кто-то уже вписал ID. Существующие2эффекта готовы, но их ID по-прежнему nil. Не включать продажу в Dashboard до полной поставки товара.

## Данные UI

Клиент читает `ctx.net.state.Premium`:

```luau
{
 version = 1,
 salesEnabled = boolean, -- false в StudioDataMode=Memory
 items = {
  {id="aura_pack", gamePassId=number?, configured=boolean,
   presentationReady=boolean, owned=boolean,
   ownershipState="NotConfigured"|"Unchecked"|"Checking"|"Saved"|"Owned"|"Unowned"|"Unknown",
   canPurchase=boolean},
 },
 loadout = {HouseStyle="default",Aura="default",FusionStyle="default",
            PartyStyle="default",AlbumStyle="default",Atmosphere="default"},
 savedLoadout = {...}, -- сохранённый выбор; для фактического отображения используй loadout
}
```

Имена, описания, категории и порядок — из PremiumCatalog.Items/Order, варианты — PremiumCatalog.Options. Locale.Text(definition.Name/Description) поддерживает русский/английский. Не считать legacy state.HeroPassOwned доказательством покупки: у администратора он может отражать временный сценарный доступ команды. Магазин читает owned из Premium.items.

Статусы «Скоро» для unconfigured/not-ready; «Проверяем владение» для Checking; Unknown не означает «Не куплено». При отсутствии данных цены не открывать пустой/поддельный Robux-диалог. Окончательное разрешение всегда на сервере, canPurchase — подсказка для UI. На время запроса использовать прежний ctx.net:IsBusy().

## Запросы через существующий NetworkAdapter

```luau
ctx.request("PremiumPurchase", {itemId="aura_pack"})
ctx.request("PremiumRefresh", {itemId="aura_pack"})
ctx.request("SetPremiumStyle", {slot="Aura", itemId="solar_corona"})
ctx.request("SetPremiumStyle", {slot="Aura", itemId="default"})
```

CoreProtocol сам добавляет wire names RequestPremiumPurchase/RequestPremiumRefresh/RequestSetPremiumStyle; operationId создаёт прежний adapter. Не создавай второй Remote/ProcessReceipt/слушатель выдачи владения. Покупка: Core открывает штатный PromptGamePassPurchase на сервере, а по серверному завершению повторно проверяет UserOwnsGamePassAsync. Результат OK означает «запрос принят/диалог подготовлен», не «покупка уже выдана».

PremiumRefresh ограничен10с на игрока, проверки API имеют максимум3попытки при временной ошибке. Внешняя покупка может появиться в Roblox ownership cache не сразу; есть ручное обновление/повторный вход, без обещания мгновенной внешней синхронизации. Привязка к конкретному profile/token защищает от завершений после выхода и от старого ответа до новой покупки.

Сервер проверяет существующий профиль/сессию, открытый Verity, зарегистрированный ID, готовность оформления, владение, конфликтующие активности и незакрытый диалог. Покупки/смена оформления не перебивают активную гонку/паркур/слияние/испытание. Основные ответы прежние: OK, PRODUCT_UNAVAILABLE, NOT_OWNED, ALREADY_OWNED, BUSY, COOLDOWN, BOX_NOT_OPENED, NOT_READY. Никаких цен, произвольного passId или owned из клиента.

## Варианты оформления

| slot | Допустимые itemId |
|---|---|
| HouseStyle | default, sakura, cosmic_villa, neon_villa |
| Aura | default, solar_corona, galaxy_dust, liquid_gold |
| FusionStyle | default, stellar_duo, aurora_duo |
| PartyStyle | default, disco |
| AlbumStyle | default, collector |
| Atmosphere | default, star_ceiling, fireflies, aurora |

default возвращает прежнее бесплатное оформление. PremiumLoadout отделён от бесплатных HouseTheme/WeatherLook/CosmeticsOwned: не заменять таблицы и не продавать уже заработанные награды. Выбор бесплатной темы через старую станцию снимает Premium HouseStyle, право покупки сохраняется. Aura — косметический слой; размер15×, способности, PvP, деньги, шансы карточек и погодные награды не менять. В альбоме сохраняется прежнее число showcase slots/право владения картами; витрина больше визуально, не выдаёт новые карты.

## Public World / VFX контракт

В owner snapshot и PublicPlotSnapshot есть `PremiumStyles` — только действующий, проверенный выбор6слотов. История покупок/receipt IDs другим игрокам не отправляется.

- WorkshopHouse и Core-модель участка: атрибуты PremiumHouseStyle, PremiumPartyStyle, PremiumAlbumStyle, PremiumAtmosphere. Строки из таблицы выше, иначе default. При ClearPlot все возвращаются в default; не оставлять оформление ушедшего владельца.
- Модель игрового Verity: PremiumAura. Применяй в существующем VerityVisualController/VFXService; не добавляй второй контроллер модели или физику. Сохраняй приоритет основной прокачки/распаковки/слияния, глаза/лицо, Low/Reduced и очистку.
- VerityAdventures snapshot.parties[].premiumStyle — действующий PartyStyle хозяина. Показывать общий декор только на Lobby/Playing реальной вечеринки, не создавать новый исход/награду. Гости не получают постоянный пропуск.
- FusionState.premiumStyle={id,ownerUserId,shared}. Если выбранный стиль есть у пилота, используется он; иначе стиль второго участника. Достаточно одного владельца. Ничего не добавляется в профиль напарника. Во время результата оформление ещё может красиво завершаться; перед следующим ожиданием сбрасывается. Player attribute VerityFusionPremiumStyle очищается при Restore. Общие атрибуты модели: FusionPremiumStyle/FusionPremiumOwner. Смотри поле snapshot, не выдумывай оплату по наличию эффекта.

Новые оформления пока не отрисованы в Core: это задача UI/World/VFX. Имеются server selectors, сохранения и public сигналы. При отсутствии поддержки/default прежняя графика остаётся целиком. Музыку не включать. Участковая атмосфера не меняет глобальный серверный weatherCycle/доступные занятия/вероятности.

## Сохранение и покупки

Добавочно в DataVersion2: PremiumGrants[itemId]=подтверждённый passId и PremiumLoadout[slot]=choice. Значения проверяет ProfileSchema, таблицы копируются, старые профили получают пустые права/default без сброса денег/вещей. Право действует только при совпадении сохранённого подтверждения с текущим зарегистрированным ID. ID нельзя менять/переиспользовать для другого товара без отдельной миграции. Успешный ответ false снимает право/связанный выбор; временный отказ API оставляет ранее подтверждённое право и status Unknown. Game Pass можно восстановить по Roblox после потери несохранённого выбора, но DataStore-сбой не гарантирует сохранение последнего выбранного оформления.

PremiumService — единственный production-владелец UserOwnsGamePassAsync/серверного pass-finished. Старые MoneyPassService/AbilityShopService delegate к нему; admin session hero доступа команды не выдаёт PremiumGrants. ×3 применяется как один множитель, не накапливается при повторном callback; старый доход рассчитывается до смены флага. Покупка героя выбирает прежний стабильный internal id homelander (название Scarlet Sentinel), без отката нового набора команды.

Для Developer Products сохранён один MarketplaceService.ProcessReceipt через PurchaseReceiptService. Он маршрутизирует только реальные product IDs в прежние Boost/Cosmetic handlers, отклоняет дубли ID между реестрами, сериализует квитанции игрока, принимает только успешный durable SaveAsync. grant и receipt уже сохраняются в одном session-locked профиле. При неизвестном ID, отсутствующем профиле, ошибке/неудачном save — NotProcessedYet; повторная доставка не прибавляет награду ещё раз. PromptProductPurchaseFinished только закрывает UI и ничего не выдаёт. Пока реестры расходников пустые, новые платные попытки/фейерверки не продаются.

Официальные источники: [Passes](https://create.roblox.com/docs/production/monetization/passes), [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService), [Developer Products](https://create.roblox.com/docs/production/monetization/developer-products).

## Фактическая приёмка

Выполнены source-интеграция и получение коммита команды. По сохраняющемуся запрету пользователя не выполнялись тесты/валидаторы/компиляция/Play/рендер/профилирование. Допустима только конечная упаковка Rojo --no-verify. Реальные покупки, дубли квитанций при сбое, повторный вход с DataStore и отображение магазина/новых эффектов не наблюдались. Настоящие IDs не подключены, платные6оформлений дополнительно отключены presentation-ready gate. Не считать backend готовым живым магазином до UI/ассетов/настоящихIDs и согласованной приёмки. Новый push/Roblox Publish в этом запросе не поручались; main.py оставлен staged отдельно.
