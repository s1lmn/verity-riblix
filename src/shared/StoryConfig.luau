--!nonstrict
-- One optional, one-time neighborhood story. No progression or paid ability gates.
local Story={Version=1,MaxRewardSeconds=240}
Story.Chapters={
 {TaskId="PRESS_BUTTON",Title="Первая искра",Speaker="Механик Мира",Brief="После сбоя район погас. Найди запасную ячейку и верни свет первой улице.",Outro="Свет вернулся! Но почтовый дрон передал странный сигнал.",Seconds=60,Fraction=.65,Minimum=200,Item="story_spark_band"},
 {TaskId="REACH_POINT",Title="Посылка без адреса",Speaker="Курьер Рик",Brief="Из фургона выпала посылка с картой старой сети. Доставь её в почтовый ящик — узнаем, откуда пришёл сигнал.",Outro="На карте отмечен заброшенный сквер. Начнём поиски там.",Seconds=65,Fraction=.70,Minimum=300},
 {TaskId="CLEAN_PARK",Title="След в старом сквере",Speaker="Механик Мира",Brief="Мусор закрыл старые энергоканалы. Очисти сквер и верни материалы на переработку.",Outro="Каналы целы! Теперь сад сможет снова питать район.",Seconds=70,Fraction=.75,Minimum=400},
 {TaskId="STAND_ON_PLATFORM",Title="Сад, который проснулся",Speaker="Садовница Лина",Brief="Энергия возвращается через живые растения. Напои три клумбы и пробуди светящийся сад.",Outro="Цветы подсказали путь к старым фонарям. Они хранят часть сигнала.",Seconds=75,Fraction=.80,Minimum=500},
 {TaskId="CHECKPOINT",Title="Созвездие на улице",Speaker="Механик Мира",Brief="Восстанови три фонаря. Их огни сложатся в маршрут к пропавшему дрону.",Outro="Маршрут найден. Но жители ещё не знают, что район оживает.",Seconds=80,Fraction=.85,Minimum=650,Item="story_signal_charms"},
 {TaskId="POSTBOX",Title="Письма соседям",Speaker="Курьер Рик",Brief="Разнеси приглашения трём соседям. Вместе мы сможем запустить центральную станцию.",Outro="Соседи готовы помочь. Осталось сделать дорогу к станции безопасной.",Seconds=85,Fraction=.90,Minimum=800},
 {TaskId="SIGNAL_REPAIR",Title="Зелёная волна",Speaker="Курьер Рик",Brief="Синхронизируй пульт и оба сигнала перехода, чтобы соседи добрались до станции.",Outro="Путь открыт. Мира ждёт два предохранителя для главного ядра.",Seconds=90,Fraction=.95,Minimum=1000},
 {TaskId="CHARGE_PAD",Title="Сердце района",Speaker="Механик Мира",Brief="Собери предохранители и запусти ядро. Полная мощность вернёт пропавшего дрона домой.",Outro="Станция работает! Поисковый маяк наконец видит дрона.",Seconds=95,Fraction=1,Minimum=1300},
 {TaskId="DRONE_RESCUE",Title="Домой, маленький друг",Speaker="Курьер Рик",Brief="Пройди по следу маяка, найди дрона и подзаряди его на базе. Он привезёт последний заряд для звезды.",Outro="Дрон спасён! Весь район готов зажечь праздничную звезду.",Seconds=100,Fraction=1,Minimum=1600},
 {TaskId="FESTIVAL",Title="Звезда для всех",Speaker="Все соседи",Brief="Соедини три цветных заряда и зажги звезду. Ты вернул району свет и друзей.",Outro="Район снова живёт. Спасибо тебе и твоему Verity! Дальше — твои собственные приключения.",Seconds=120,Fraction=1.1,Minimum=2500,Item="story_neighborhood_crown"},
}
Story.ByTask={}
for index,chapter in Story.Chapters do chapter.Index=index;Story.ByTask[chapter.TaskId]=chapter;table.freeze(chapter) end
table.freeze(Story.Chapters);table.freeze(Story.ByTask)
return table.freeze(Story)
