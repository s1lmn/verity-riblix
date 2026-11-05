--!strict
local Numeric=require(script.Parent.Numeric)
local HouseConfig={}
HouseConfig.IncomeUpgrades=table.freeze({
	table.freeze({Level=1,Cost=25,Name="Тёплый старт",Build="Стены, входная комната и кухня",Bonus=.25,Color="8AF4CB"}),
	table.freeze({Level=10,Cost=500,Name="Гостиная Verity",Build="Новый жилой корпус, диван и телевизор",Bonus=.30,Color="88D7FF"}),
	table.freeze({Level=25,Cost=8000,Name="Панорамные окна",Build="Остекление, растения и освещение",Bonus=.35,Color="C49BFF"}),
	table.freeze({Level=50,Cost=350000,Name="Надёжная крыша",Build="Крыша, отделка и галерея Verity",Bonus=.40,Color="FFBBDF"}),
	table.freeze({Level=75,Cost=14000000,Name="Сад светлячков",Build="Первая светящаяся производственная станция",Bonus=.50,Color="9EFFBA"}),
	table.freeze({Level=80,Cost=26000000,Name="Мастерская звёзд",Build="Звёздный генератор рядом с домом",Bonus=.60,Color="FFD887"}),
	table.freeze({Level=85,Cost=52000000,Name="Лунная оранжерея",Build="Новый лунный модуль производства",Bonus=.70,Color="A5C4FF"}),
	table.freeze({Level=90,Cost=100000000,Name="Солнечная электростанция",Build="Солнечные панели на крыше и энергомодуль",Bonus=.80,Color="FFE177"}),
	table.freeze({Level=95,Cost=180000000,Name="Кристальная турбина",Build="Мощная неоновая турбина у дома",Bonus=.95,Color="E7A4FF"}),
	table.freeze({Level=100,Cost=300000000,Name="Реактор радуги",Build="Финальный реактор и золотая корона дома",Bonus=1.15,Color="FF9AD3"}),
})
HouseConfig.IncomeStep=.25 -- Legacy display compatibility; actual bonuses are per stage.
HouseConfig.Features=table.freeze({
	Door=table.freeze({Name="Дверь с замком",Cost=150,Field="HouseDoorOwned",Bonus=.15}),
	SecondFloor=table.freeze({Name="Второй этаж",Cost=1500,Field="HouseSecondFloorOwned",Bonus=.50}),
})
function HouseConfig.getIncomeMultiplier(upgrades:number,doorOwned:boolean?,upperOwned:boolean?):number
	local multiplier=1
	for index,upgrade in HouseConfig.IncomeUpgrades do if index<=upgrades then multiplier+=upgrade.Bonus end end
	if doorOwned then multiplier+=HouseConfig.Features.Door.Bonus end
	if upperOwned then multiplier+=HouseConfig.Features.SecondFloor.Bonus end
	return multiplier
end
function HouseConfig.getHouseTier(level:number):number
	assert(Numeric.isInteger(level,1,100),"Invalid Verity level")
	if level>=100 then return 6 elseif level>=75 then return 5 elseif level>=50 then return 4 elseif level>=25 then return 3 elseif level>=10 then return 2 end
	return 1
end
return table.freeze(HouseConfig)
