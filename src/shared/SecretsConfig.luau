--!nonstrict
local Layout=require(script.Parent.WorldLayout)
local C={Version=1,Reach=7,AirSeconds=90,RingRadius=5.5}
C.Order={"solar","canopy","cloud"}
C.Items={
 solar={Name="Солнечный архив",Hint="Запитай приёмник. День сменяется ночью, затем загорается звезда.",Reward="secret_solar",Item="prism_specs",Color="FFD875"},
 canopy={Name="Тайник в кроне",Hint="Поднимись по ветвям. Мелодия: лист, капля, солнце.",Reward="secret_canopy",Item="leaf_crown",Color="9AF5A9"},
 cloud={Name="Облачная обсерватория",Hint="Включи полёт и пройди три кольца по порядку.",Reward="secret_cloud",Item="cloud_charms",Color="8FEAFF"},
}
C.Solar=Vector3.new(-100,.5,-Layout.RoadHalfLength-22)
C.Tree=Vector3.new(94,.5,-Layout.RoadHalfLength-18)
C.Launch=Vector3.new(-25,.55,-Layout.GroundHalfLength+28)
C.Cloud=Vector3.new(25,40.5,-Layout.GroundHalfLength+26)
C.Rings={C.Launch+Vector3.new(0,15,2),C.Launch+Vector3.new(25,27,-6),C.Launch+Vector3.new(34,47,12)}
function C.Sanctuary(p)
 local a=p-C.Solar;local b=p-C.Tree
 return (math.abs(a.X)<24 and math.abs(a.Z)<27 and a.Y> -4 and a.Y<20)
  or (math.abs(b.X)<22 and math.abs(b.Z)<24 and b.Y> -4 and b.Y<48)
  or (p.X> -45 and p.X<45 and p.Z< -Layout.RoadHalfLength-12 and p.Z> -Layout.GroundHalfLength+4 and p.Y> -3 and p.Y<65)
end
return C
