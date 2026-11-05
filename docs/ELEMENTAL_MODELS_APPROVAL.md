# Elemental Verity: первая серия образцов

По запросу пользователя от5ноября2026 созданы статические GLB-модели по
утверждённому элементальному концепту. Предварительные целевые рубежи:
10Aqua,25Frost,50Magma,75Cyber,100Rainbow; Cosmic — альтернативный образец75.
Окончательное распределение/вид и переходные уровни ожидают художественного утверждения.

Папка: assets/verity-elemental. Есть6отдельных GLB, общая галерея, bodies-only
пакет для Studio3DImporter,6диффузных PNG1024×512,8исходных общих лиц без изменений,
README/manifest и ручной ElementalImportAdapter. Генератор:
tools/build_verity_elemental.py; программный рендер экспортированных GLB:
tools/preview_verity_elemental.py. Рецепт необязательного Blender-рендера:
tools/render_verity_elemental.py (Blender на этой машине упал до выполнения скрипта).

Общее тело2208треугольников, базовый диаметр1.7,−Zfront, origin у основания.
Лицо не запечено: GLB имеет отдельную preview-plane2треугольника; adapter удаляет
её и подключает прежний World.VerityFaceUI с нормализованным layout и8реальными
известными image IDs. Цвет MeshPart белый, VerityTint=false, чтобы не перетонировать
skin. Adapter не является startup/контроллером: нет тиков, анимаций, событий
экономики или записи VerityLevel/прогресса. Это образцы, не live-подмена Factory.

Структурно проверены8GLB: headers/длины/границыbuffers, accessorindices, finitexyz,
точные габариты, количество triangles;6PNG и совпадение UVшва,8исходных expressions.
Luauадаптер компилируется. preview-render.png растеризует настоящие mesh/UV/PNG
изGLB; это не сгенерированный концепт и не Studio screenshot.
Studio подключённых экземпляров нет: upload IDs, импорт, asset permissions,
рендеринг Roblox/производительность/видимость лиц после импорта не проверены.
Не обещать готовую интеграцию с live-игрой до импорта и художественного утверждения.
Play не запускался. Промежуточные уровни, Core/Factory/мир/анимации не менялись.

## Интеграция в Roblox,5ноября

После прямого запроса импорта Studio запущена, открыта Verity_Toy_UI_Complete_v1,
подключена в Edit. Загружены6текстур и подключён существующий собственный mesh
98969698787830. Его UV проверены на6624углах: ошибка реконструкции5.3e-7; исходные
процедурные skin-рецепты пересчитаны для этой развёртки (roblox-skins). Это отдельные
загрузки от исходных GLBтекстур; использовать только ID из roblox-assets.json.
CreateAssetAsync для нового меша недоступен в этой Studio; используется уже
существующий mesh без новой генерации/упрощения.

Shared.VerityElementalSkins задаёт ТОЧНЫЕ10/25/50/75/100, Cosmic доступен как
preview override. Промежуточные уровни используют прежние цвета, не наследуют skin.
Factory.SetStage меняет SpecialMesh и отключает VerityTint на текстурном теле;
VisualController сохраняет его в tints и уважает текущий флаг, поэтому восстановление
обычных цветов работает и после initial spawn на целевом уровне. ScaleTo масштабирует
FileMesh: baseScale=1.7/2.8, при смене stage учитывается текущий Model:GetScale().
При возврате к native sphere MeshId очищается ПЕРЕД установкой MeshType.Sphere:
обратный порядок незаметно возвращает FileMesh и ломает отображение.

Создана native-библиотека Verity_Elemental_Models.rbxmx из6моделей с общим mesh,
пять назначений+альтернатива. default.project.json включает её в ReplicatedStorage.
Live Factory оставляет прежний Root/face/восемь эмоций/cosmetics/аниматор; нового
контроллера нет. В открытой Studio дополнительно есть временная Workspace-галерея
Verity_Elemental_Approval без игровых тегов; в чистую game-сборку она не включена.

Edit readback:6моделей,6texture IDs+mesh+Joy face получили AssetFetchStatus.Success;
IsLoaded=true у всех6лиц. Проверены реальные переходы stage10→11→25→26→50→51→75→76→100→1
и масштаб FileMesh. Это Edit проверки, не Play и не измерение производительности.
Требование не запускать Play сохранено. Подключённые модули нельзя require из
Assistant sandbox из-за Capabilities.Network; проверка stage выполнена собственным
точным текстом функции в Edit на временной копии модели. Полная игра проверена
сборкой/compile, не runtime запуском.
Выход: outputs/Verity_Elemental_Integrated_v1.rbxlx, fingerprint bacd993fb091;
фактический StudioEdit screenshot Verity_Elemental_Studio_Edit_v1.png.
