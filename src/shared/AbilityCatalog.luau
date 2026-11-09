--!nonstrict
-- Shared presentation definitions; purchases and hits are owned by the server.
local Catalog = {}
Catalog.Order = {"dash","leap","sprint","shield","flight","repulsor","eye_laser","lightning","gravity","nova","homelander"}
Catalog.Icons=table.freeze({dash="➜",leap="↑",sprint="»",shield="◇",flight="✧",repulsor="✦",eye_laser="◎",lightning="ϟ",gravity="◉",nova="☀",homelander="★"})
Catalog.Items = {
	dash={Name="Квантовый рывок",Description="Мощный рывок вперёд со световым следом.",Slot="Mobility",Level=1,Cost=75,Action="dash",Cooldown=5,Duration=.3,Power=65,Color="79E8FF"},
	leap={Name="Прыжок титана",Description="Взлети над районом одним прыжком.",Slot="Mobility",Level=3,Cost=300,Action="leap",Cooldown=8,Duration=.8,Power=115,Color="A5FF80"},
	sprint={Name="Сверхскорость",Description="Пять секунд сверхбыстрого бега.",Slot="Mobility",Level=6,Cost=900,Action="sprint",Cooldown=12,Duration=5,Power=44,Color="FFE26A"},
	shield={Name="Энергетический щит",Description="Четыре секунды защиты: входящий урон снижен на 75%.",Slot="Mobility",Level=10,Cost=2500,Action="shield",Cooldown=14,Duration=4,Color="83BFFF"},
	flight={Name="Небесный полёт",Description="12 секунд управляемого полёта. Движение и прыжок — подъём.",Slot="Mobility",Level=15,Cost=9000,Action="flight",Cooldown=18,Duration=12,Power=34,Color="8FFFE6"},
	repulsor={Name="Плазменный импульс",Description="Направленный энергетический выстрел и ударная волна.",Slot="Attack",Level=10,Cost=1800,Action="pulse",Cooldown=5,Damage=26,Range=65,Color="72E7FF"},
	eye_laser={Name="Лазерный взгляд",Description="Два луча из глаз Verity прожигают цель.",Slot="Attack",Level=25,Cost=22000,Action="laser",Cooldown=7,Damage=30,Range=110,Duration=.8,Color="A6F8FF"},
	lightning={Name="Цепная молния",Description="Разряд перескакивает между тремя ближайшими целями.",Slot="Attack",Level=40,Cost=150000,Action="lightning",Cooldown=9,Damage=28,Range=100,Chains=3,ChainRange=20,Color="BD9AFF"},
	gravity={Name="Гравитационный удар",Description="Сожми энергию в точке и порази цели в радиусе 14 метров.",Slot="Attack",Level=50,Cost=750000,Action="gravity",Cooldown=11,Damage=38,Range=75,Radius=14,Color="E796FF"},
	nova={Name="Сверхновая",Description="Взрыв звёздной энергии в радиусе 21 метра.",Slot="Attack",Level=75,Cost=18000000,Action="nova",Cooldown=15,Damage=52,Range=90,Radius=21,Color="FFD773"},
	homelander={Name="Хоумлендер",Description="Полёт героя и красные лазеры из глаз. Две способности в одном наборе.",Slot="Attack",Level=1,Premium=true,Action="laser",Cooldown=8,Damage=40,Range=140,Duration=1.1,Color="FF3B57",MobilityAction="flight",FlightDuration=18,FlightSpeed=42,FlightCooldown=24},
}
for _,item in Catalog.Items do table.freeze(item) end
table.freeze(Catalog.Order);table.freeze(Catalog.Items)

function Catalog.Collection(data,heroOwned,passConfigured)
 local result={}
 for _,id in Catalog.Order do
  local item=Catalog.Items[id];local owned=Catalog.Owns(data,id,heroOwned)
  local unlocked=data.VerityUnlocked==true
  local levelMet=data.VerityLevel>=item.Level;local slots={item.Slot};local equipped={}
  if item.MobilityAction then table.insert(slots,"Mobility") end
  for _,slot in slots do
   local _,equippedId=Catalog.Equipped(data,slot,heroOwned)
   if equippedId==id then table.insert(equipped,slot) end
  end
  local status=if #equipped>0 then "Equipped" elseif owned then "Owned" elseif not levelMet then "LockedLevel"
   elseif item.Premium then (if passConfigured then "PassRequired" else "Unavailable") else "Purchasable"
  table.insert(result,{id=id,icon=Catalog.Icons[id],name=item.Name,description=item.Description,slot=item.Slot,availableSlots=slots,
   requiredLevel=item.Level,cost=item.Cost,premium=item.Premium==true,owned=owned,levelMet=levelMet,
   state=status,equippedSlots=equipped,canEquip=unlocked and owned and levelMet,canBuy=unlocked and not item.Premium and not owned and levelMet,
   blockedReason=if not unlocked then "BOX_NOT_OPENED" elseif not levelMet then "ABILITY_LEVEL_REQUIRED" else nil,
   affordable=not item.Premium and data.Cash>=(item.Cost or 0),color=item.Color,
   cooldown=item.Cooldown,duration=item.Duration or 0})
 end
 return result
end
function Catalog.Owns(data,id,heroOwned)
	local item=Catalog.Items[id]
	return item~=nil and (if item.Premium then heroOwned==true else data.AbilitiesOwned[id]==true)
end
function Catalog.Equipped(data,slot,heroOwned)
	local id=data.AbilitiesEquipped[slot]
	local item=id and Catalog.Items[id]
	if not item or not Catalog.Owns(data,id,heroOwned) or data.VerityLevel<item.Level then return nil end
	if item.Slot~=slot and not (slot=="Mobility" and item.MobilityAction) then return nil end
	return item,id
end
return table.freeze(Catalog)
