# Игрушечный пульт настроек

SettingsSkin заменяет универсальную SETTINGS-панель корпусом в общей палитре:
кремовый пластик, фиолетовый бортик, белые карточки и крупные цветные переключатели.
Сохраняет прежний refs-контракт SettingsController: Language/Sound/Volume/Minus/
Plus/Motion/Effects. ToggleKnobs и VolumeFill только отображают существующие values.
Не добавляет новых настроек, серверных запросов или сохранений.

UISounds, Volume0–1, ReducedMotion и ReducedEffects по-прежнему применяются через
прежние GUI-атрибуты и Changed. Язык использует существующий Locale.SetLanguage.
Кнопки≥44px, низкие/узкие экраны прокручивают содержимое без уменьшения controls.
Новые тексты включены в LocaleText; Source английский, русский перевод через Locale.
Сохранены общий animator, SelectionGroup и единый владелец focus в Main.

Проверки check_settings_skin.py исполняют настоящие Skin/Widgets/Controller
с подставными engine values: единственный export, constructor/refs, пять экранов,
44px targets, все три переключателя и GUI-атрибуты, volume clamp и meter, язык
без лишнего Changed для аудио. Также прошли проверки телефона, каталога, задач,
feedback startup, аудио, компиляция110 Luau и полная сборка.
Это проверки кода, не Studio render/Play или визуальная приёмка устройств.
Play по указанию пользователя не запускался. Изменения пока локальные.
