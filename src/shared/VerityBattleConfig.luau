--!nonstrict
local Layout=require(script.Parent.WorldLayout)
local C={Center=Vector3.new(0,1,333+Layout.EndShift),HalfWidth=45,HalfLength=27,Ceiling=45,MaxPlayers=4,Countdown=6,BreakSeconds=5,Timeout=300,Cooldown=150,RewardSeconds=55}
C.Exit=Vector3.new(0,4,298+Layout.EndShift)
C.Types=table.freeze({
 Spark=table.freeze({Name="Искра",Health=28,Speed=7,Damage=12,Radius=5,Range=8,Windup=.95,Delay=3.3,Color="FF8B64",Size=2.1}),
 Watcher=table.freeze({Name="Страж",Health=42,Speed=4,Damage=15,Radius=4,Range=23,Windup=1.2,Delay=4.1,Color="AB8AFF",Size=2.5}),
 Boss=table.freeze({Name="Неоновый титан",Health=180,Speed=3,Damage=22,Radius=10,Range=16,Windup=1.6,Delay=4.8,Color="FF568A",Size=3.5}),
})
C.Waves=table.freeze({{"Spark","Spark"},{"Spark","Watcher"},{"Spark","Spark","Watcher"},{"Watcher","Watcher","Spark"},{"Boss","Spark","Spark"}})
function C.Contains(p)
 local d=p-C.Center
 return math.abs(d.X)<=C.HalfWidth and math.abs(d.Z)<=C.HalfLength and d.Y>=-2 and d.Y<=C.Ceiling
end
return table.freeze(C)
