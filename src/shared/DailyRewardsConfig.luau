--!nonstrict
-- Deterministic calendar gifts. No paid attempts, random chances or UI dependencies.
local Numeric=require(script.Parent.Numeric)
local Config=require(script.Parent.GameConfig)
local Forge=require(script.Parent.WeatherForgeConfig)
local D={Version=1,DaySeconds=86400,MaxUtcDay=10000000,MaxCashSeconds=600}
D.Days={
 {Name="Тёплая встреча",Seconds=60,Minimum=200,Fraction=.35,Materials={Stardust=1}},
 {Name="Искра приключений",Seconds=90,Minimum=350,Fraction=.45,Materials={Ember=2,Stardust=1}},
 {Name="Звёздный подарок",Seconds=120,Minimum=500,Fraction=.60,Materials={Stardust=3},Look="star",Duplicate={Stardust=5}},
 {Name="Дождевые сокровища",Seconds=150,Minimum=750,Fraction=.70,Materials={RainPearl=3,Ember=2}},
 {Name="Запас для кузницы",Seconds=180,Minimum=1200,Fraction=.85,Materials={Ember=4,Stardust=4,RainPearl=2}},
 {Name="Большой сюрприз",Seconds=240,Minimum=2000,Fraction=1,Materials={Ember=5,Stardust=5,RainPearl=3}},
 {Name="Радужный финал",Seconds=300,Minimum=3500,Fraction=1.25,Materials={Ember=5,Stardust=5,RainPearl=5},Look="aurora",Duplicate={Ember=5,Stardust=5,RainPearl=5}},
}
for i,day in D.Days do day.Slot=i;table.freeze(day.Materials);if day.Duplicate then table.freeze(day.Duplicate) end;table.freeze(day) end
table.freeze(D.Days)
function D.NewRecord() return {Version=D.Version,LastDay=-1,Claims=0} end
function D.Copy(record)
 local copy=table.clone(record)
 if record.Last then copy.Last=table.clone(record.Last);copy.Last.Materials=table.clone(record.Last.Materials) end
 return copy
end
function D.Validate(raw)
 if type(raw)~="table" or raw.Version~=D.Version or not Numeric.isInteger(raw.LastDay,-1,D.MaxUtcDay)
  or not Numeric.isInteger(raw.Claims,0,D.MaxUtcDay+1) then return nil end
 for key in raw do if key~="Version" and key~="LastDay" and key~="Claims" and key~="Last" then return nil end end
 if raw.Claims==0 then return if raw.LastDay==-1 and raw.Last==nil then D.NewRecord() else nil end
 if raw.LastDay<0 or raw.Claims>raw.LastDay+1 then return nil end
 local last=raw.Last;local slot=(raw.Claims-1)%#D.Days+1;local day=D.Days[slot]
 if type(last)~="table" or last.Id~=tostring(raw.LastDay)..":"..tostring(raw.Claims) or last.Day~=raw.LastDay or last.Slot~=slot
  or not Numeric.isFinite(last.At) or last.At<0 or math.floor(last.At/D.DaySeconds)~=raw.LastDay
  or not Numeric.isFinite(last.Cash) or last.Cash<0 or last.Cash>Config.MaxMoney
  or type(last.Duplicate)~="boolean" or (last.Duplicate and not day.Look) or last.Look~=day.Look or type(last.Materials)~="table" then return nil end
 local allowed={Id=true,Day=true,Slot=true,At=true,Cash=true,Duplicate=true,Look=true,Materials=true}
 for key in last do if not allowed[key] then return nil end end
 for id,amount in last.Materials do if not Forge.Materials[id] or not Numeric.isInteger(amount,0,Forge.MaxMaterial) then return nil end end
 return D.Copy(raw)
end
return table.freeze(D)
