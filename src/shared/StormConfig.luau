--!nonstrict
-- Renderer contract only; no GUI, Lighting writes, camera movement or new audio assets.
local Layout=require(script.Parent.WorldLayout)
local S={Version=2,WarningSeconds=1.6,ThunderSpeed=1200,ThunderMaxDelay=6,CloudHeight=105,StrikeHeight=125}
S.Phases={
 {Id="Approach",Name="Надвигается гроза",From=0,Until=.18,IntensityFrom=.12,IntensityTo=.52,Rain=.25,Wind=14,Darkness=.35,Clouds=.8},
 {Id="Downpour",Name="Стена дождя",From=.18,Until=.46,IntensityFrom=.52,IntensityTo=.82,Rain=.85,Wind=26,Darkness=.62,Clouds=.96},
 {Id="Tempest",Name="Сердце бури",From=.46,Until=.86,IntensityFrom=.82,IntensityTo=1,Rain=1,Wind=38,Darkness=.76,Clouds=1},
 {Id="Retreat",Name="Гроза отступает",From=.86,Until=1,IntensityFrom=1,IntensityTo=.08,Rain=.02,Wind=.5,Darkness=.04,Clouds=.18},
}
S.StrikeFractions={.27,.38,.49,.59,.69,.78,.84}
S.Anchors={}
for i=1,8 do
 S.Anchors[i]=Vector3.new(if i%2==0 then 55 else -55,1,-Layout.RoadHalfLength+35+(i-1)*(Layout.RoadHalfLength*2-70)/7)
end
for _,phase in S.Phases do table.freeze(phase) end
table.freeze(S.Phases);table.freeze(S.Anchors);table.freeze(S.StrikeFractions)
return table.freeze(S)
