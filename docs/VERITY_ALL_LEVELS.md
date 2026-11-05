# Полная серия Verity1–100

Новое прямое указание пользователя: дополнить промежуточные модели по образцу
утверждённых элементальных. Оно заменяет прежнее ограничение «только ключевые уровни».

1–9: прежняя яркая базовая палитра.10–24:вода;25–49:лёд;50–74:магма;
75–89:киберпанк;90–99:космос;100:радужный финал. На семействе три стадии текстуры,
между ними небольшая цветовая эволюция.16 общих texture IDs, единая сфера2208tri
для текстурных стадий; на ранних уровнях прежний native sphere. Это100 уровневых
моделей, не100 отдельных новых mesh/PNG. Первые9цветов и картинки anchor10/25/50/
75/100 сохранены. Восемь прежних эмоций не запечены в тело.

Shared.VerityElementalSkins кэширует descriptors для10–100 и поддерживает preview
override. Factory.SetStage учитывает LevelKey и Mesh.VertexColor; при возврате к
ранним уровням сбрасывает vertex tint. FileMesh Scale учитывает текущий ScaleTo.
Существующие VisualController/FaceUI/рост/полёт/распаковка/апгрейд/косметика
сохранены, новых tick-loop или серверных команд нет. Formula берётся из LevelConfig.

assets/verity-elemental/all-levels:общая native-библиотека100моделей, отдельные100
rbxmx, levels.json и README. default.project.json включает её вместо прежних6
образцов. Базовый диаметр1.7, origin у основания, −Zfront, AlreadyScaled=false.
Модели содержат metadata уровня/семейства/предложенного scale и8ссылок выражений.
Новые10texture IDs:progression-skins/roblox-assets.json. Родительский roblox-assets
сохраняет6исходных IDs. Рецепты/пересборка:tools/build_verity_progression_skins.py,
tools/build_verity_all_levels.py.

Проверено tools/check_verity_all_levels.py:100моделей/уникальныеrefs/Body/FaceGui,
16textureIDs,8эмоций,200прямых/обратных вызовов настоящей функции SetStage с
подставными engine values, границы уровней/override/сохранность anchors. Пройдены
admin/feedbackstartup/audio регрессии и полная Rojo-сборка, fingerprint b09126e0d6fa.
Play не запускался. Полная серия сохранена на диске, установка100моделей в открытый
Studioplace в продолжении не подтверждена (Place is not open). Новые10images
получили реальные IDs при upload, их доступность в gameplay не выдавать за проверенную.

Промежуточная остановка произошла из-за лимита использования: automatic approval
review не завершилась, последующий запрос пользователя разрешил продолжить работу.
Отдельно auto-review отклонила принятие миграции Compatibility→Voxel; миграция не
принималась и исходники Lighting для обхода не менялись. Обновление моделей не
требует её принятия. Push в этой задаче не выполнялся.
