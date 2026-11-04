--!strict
-- A form replaces the previous movement bonus. Intermediate levels keep the
-- latest form until the next milestone unlocks a new one.
local forms = {
	{level=1, name="Лёгкий шаг", speed=18, jump=50},
	{level=2, name="Солнечный прыжок", speed=16, jump=59},
	{level=3, name="Вишнёвый бег", speed=21, jump=50},
	{level=4, name="Розовый рывок", speed=18, jump=52, action="dash"},
	{level=5, name="Пружинка", speed=17, jump=66},
	{level=6, name="Синий спринт", speed=20, jump=53, action="sprint"},
	{level=7, name="Небесный шаг", speed=20, jump=60},
	{level=8, name="Мятный полёт", speed=18, jump=55, action="flight"},
	{level=9, name="Лаймовый бег", speed=23, jump=57},
	{level=10, name="Золотой взлёт", speed=20, jump=66, action="flight"},
	{level=25, name="Левитация", speed=21, jump=62, action="flight"},
	{level=50, name="Импульс", speed=23, jump=60, action="dash"},
	{level=75, name="Легендарный спринт", speed=24, jump=66, action="sprint"},
	{level=100, name="Звёздный полёт", speed=24, jump=70, action="flight"},
}

local Abilities = {}
function Abilities.Get(level: number)
	for index = #forms, 1, -1 do
		if level >= forms[index].level then return forms[index] end
	end
	return forms[1]
end

return Abilities
