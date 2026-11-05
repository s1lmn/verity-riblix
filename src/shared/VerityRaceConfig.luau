--!strict
local Race={Version="verity-race-1",MinPlayers=2,MaxPlayers=4,Countdown=10,BaseSeconds=16,FinishGap=.8,Intermission=12,
 QueueTimeout=90,QueueRadius=20,JoinReach=9,RewardSeconds=12,StartZ=128,EndZ=276,BaseY=.45,PadZ=92,
 LaneX={-306,-274,-242,-210},Colors={"FFB72D","67DCD2","FF8ABE","A78AF8"}}
function Race.Weight(level:number):number
 return 1+4*(math.clamp(level,1,100)-1)/99
end
function Race.Rank(entries,random)
 local ranked={}
 for _,entry in entries do
  table.insert(ranked,{slot=entry.slot,key=-math.log(math.max(1e-12,random()))/Race.Weight(entry.level)})
 end
 table.sort(ranked,function(a,b)return if a.key==b.key then a.slot<b.slot else a.key<b.key end)
 local finishes={}
 for rank,item in ranked do finishes[item.slot]=Race.BaseSeconds+(rank-1)*Race.FinishGap end
 return finishes
end
function Race.Progress(elapsed:number,finish:number,seed:number):number
 local u=math.clamp(elapsed/finish,0,1)
 -- Derivative stays positive: .065*(2pi+pi)<1. Endpoints retain the server's finish order.
 return math.clamp(u+.065*math.sin(2*math.pi*u+seed)*math.sin(math.pi*u),0,1)
end
function Race.Position(slot:number,elapsed:number?,finish:number?,seed:number?,radius:number?)
 local progress=if elapsed and finish then Race.Progress(elapsed,finish,seed or 0) else 0
 return Vector3.new(Race.LaneX[slot],Race.BaseY,Race.StartZ+(Race.EndZ-(radius or 0)-Race.StartZ)*progress)
end
return table.freeze(Race)
