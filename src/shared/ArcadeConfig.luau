--!nonstrict
local C={Version=1,Duration=30,FallSeconds=2.3,MoveCooldown=.18,Reach=8}
C.Prizes={
 {Score=100,Id="home_arcade_bronze",Name="Бронзовая звезда",Color="E3A071"},
 {Score=300,Id="home_arcade_silver",Name="Серебряная звезда",Color="B9E6F0"},
 {Score=600,Id="home_arcade_gold",Name="Золотая звезда",Color="FFE184"},
}
function C.Plan(seed)
 local rng=Random.new(seed);local drops={};local at=2.4
 while at<C.Duration-.2 do
  table.insert(drops,{at=at,lane=rng:NextInteger(1,3),star=rng:NextInteger(1,100)<=72})
  at+=.72
 end
 return drops
end
return C
