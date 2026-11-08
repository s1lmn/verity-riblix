--!nonstrict
local C={Version=2,Duration=150,Cooldown=180,MinimumContribution=2,Reach=7,JoinSeconds=75}
C.Order={"light","van","drones","festival"}
C.Variants={
 light={Name="Вернём свет району",Collect="Взять энергию",Deliver="Передать энергию",Unit="Энергия",Reward="home_beacon",Color="FFE580",
  Stations={"Левый генератор","Правый генератор","Главное ядро"},Sequential=false},
 van={Name="Помоги почтовому фургону",Collect="Взять запчасть",Deliver="Установить запчасть",Unit="Ремонт",Reward="home_repair_trophy",Color="FFB66D",
  Stations={"Почини колёса","Замени батарею","Запусти двигатель"},Sequential=true},
 drones={Name="Сбежавшие дроны",Collect="Поймать дрона",Deliver="Вернуть дрона",Unit="Дроны",Reward="home_drone_nest",Color="89E8F6",
  Stations={"Дрон найден","Дрон пойман","Дрон дома"},Sequential=false},
 festival={Name="Праздник района",Collect="Взять украшение",Deliver="Украсить площадку",Unit="Декор",Reward="home_festival_lantern",Color="FF99D6",
  Stations={"Развесь флажки","Зажги фонарики","Подготовь сцену"},Sequential=true},
}
C.StationNames=C.Variants.light.Stations
return C
