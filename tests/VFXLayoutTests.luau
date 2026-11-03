--!nonstrict
return function(load,check)
 local VFX=load("src/world/VerityVFXService")
 local Levels=load("src/shared/LevelConfig")
 for _,level in {1,25,50,75,100} do
  local scale=Levels.getVerityScale(level)*1.035
  for index=1,3 do
   local radius=VFX.Radius(scale,index)
   check(radius>.85*scale,"Effects must surround the new sphere instead of being buried inside it")
   check(radius<=1.15*scale+1.5,"Effects fit the companion clearance envelope")
  end
 end
end
