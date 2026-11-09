# Объединение Premium Core и магазина команды — 9 ноября2026

По прямому запросу push перед отправкой получены dd913c4 (магазин/предпросмотры/косметика) и f655ac0 (ID двух пропусков). Core зафиксирован отдельным8515079, затем выполнено обычное слияние с origin/main. Текстовый конфликт CoreProtocol разрешён с сохранением обоих наборов запросов; смысловые различия контрактов сведены через PremiumVisualBridge. Сторонний main.py не включается в merge.

## Итоговый контракт

- Core canonical IDs/сохранения8товаров/6слотов не менялись. Shared.PremiumVisualBridge сопоставляет14карточек команды с8GamePassнаборами и их выборами. Например home_theme_cosmic → home_style_pack/HouseStyle/cosmic_villa, aura_solar_crown → aura_pack/Aura/solar_corona, fusion_starlight → fusion_pack/FusionStyle/stellar_duo.
- Сервер понимает и старые канонические RequestPremiumPurchase/RequestPremiumRefresh/RequestSetPremiumStyle, и RequestBuyPremiumOffer/RequestEquipPremiumOffer команды. Все идут через тот же RemoteService/валидацию/operationId и единственный PremiumService.
- State.Premium/ PremiumStyles сохранены; добавлены derived PremiumShop.offers и PremiumStyle{aura,party,collection,atmosphere} для магазина и эффектов команды. Они рассчитываются только из серверного подтверждения и выбора, не из клиентского утверждения. Владение и пробный admin доступ героя остаются раздельны.
- HomeStyle.Project отображает эффективный premium theme sakura/cosmic/neon из PremiumLoadout, не переписывая бесплатный HouseTheme и не подделывая CosmeticsOwned. Киоск не покупает платные темы за Cash; выбор бесплатной темы снимает платное оформление.
- World PremiumAura передаётся в визуальном ID команды ровно один раз. Сохранены native ауры, галерея/рамки, атмосферы, праздничный декор/конфетти и quality budgets. FusionState.premiumLook отображает подтверждённый stellar_duo как fusion_starlight; оба участника видят его, постоянная покупка партнёру не выдаётся. aurora_duo остаётся зарезервированным Core ID: применение запрещено до появления собственного визуала, подмена другим видом не делается.
- Новые6наборов presentation-ready для существующих вариантов команды, но PremiumPassIds пока пусты — их продажа не включена. В GameConfig сохранены реальные ID команды: MoneyPassId2075332782 и HeroPassId2074444798 для Grow your Verity/Cute Moggers Studios, universe10775557886. По записи команды при создании были Offsale; текущая доступность/цена читается из Roblox на клиенте, статус продажи не менялся этим чатом.
- Магазин кэширует GetProductInfoAsync по passId, не показывает SuggestedPrice вместо настоящей цены, при ошибке повторяет запрос не чаще30с. 3стиля дома/3ауры/3атмосферы открываются набором: на карточках это явно указано, стоимость помечена «Набор». Вариант выбирается после покупки; выбранное косметическое оформление можно снять до default.
- В StudioDataMode=Memory отключены все пути покупки, включая две legacy кнопки. Preview и admin пробный доступ остаются косметикой/сессионным доступом, а не оплатой. Процессинг квитанций расходников сохраняет один durable router, callback закрытия не выдаёт покупки.

## Статус

Сохранены изменения команды и Core. Без force push/Roblox Publish, без тестов/валидаторов/Luau-компиляции/Play/рендеров/профилирования. Только упаковка --no-verify; реальные платежи, сетевые сбои и вид в игре не наблюдались. Локальный Latest переупаковывается после объединения. Точные ранее опубликованные Core-документы читаются с этим дополнением: два ID теперь подключены, UI/VFX команды уже присутствуют, на месте два совместимых контракта.
