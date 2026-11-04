--!nonstrict
return function(load,check)
 local VFX=load("src/world/VerityVFXService")
 local Levels=load("src/shared/LevelConfig")
 local Profile=load("src/shared/VerityAnimationProfile")
 check(not Profile.Aura(9).fire and Profile.Aura(10).fire,"Flames should unlock at level ten")
 check(Profile.Aura(49).trails==0 and Profile.Aura(50).trails==1,"Neon trails should unlock at level fifty")
 check(Profile.Aura(75).trails==2 and Profile.Aura(100).trails==3)
 local previous=Profile.Aura(1)
 for level=1,100 do
  local current=Profile.Aura(level)
  check(current.brightness>=previous.brightness and current.brightness<=1.5,"Aura light must increase within the lighting budget")
  check(current.fireStrength>=previous.fireStrength and current.width>=previous.width)
  check(current.lifetime>0 and current.lifetime<=1 and current.trails<=3,"Persistent trails must stay bounded")
  previous=current
 end
 local model,root={},{}
 local flame={Enabled=true}
 local trail={Enabled=true,clears=0}
 function trail:Clear() self.clears+=1 end
 local segment={Transparency=0}
 local group={root=root,light={Enabled=true},highlight={Enabled=true},fire=flame,trails={trail},
  rings={{segment},{}},stars={},lastTime=100,lastPosition={}}
 local effects=setmetatable({groups={[model]=group}},VFX)
 effects:Hide(model)
 check(not flame.Enabled and flame.Parent==root,"Hiding must detach the flame and clear its live particles")
 check(not trail.Enabled and trail.clears==1,"Hidden companions must not retain neon trails")
 check(not group.light.Enabled and not group.highlight.Enabled and segment.Transparency==1)
 check(group.lastTime==nil and group.lastPosition==nil,"Reappearing must not bridge the old trail position")
 effects:Hide({})

 for _,level in {1,25,50,75,100} do
  local scale=Levels.getVerityScale(level)*1.035
  for index=1,3 do
   local radius=VFX.Radius(scale,index)
   check(radius>.85*scale,"Effects must surround the new sphere instead of being buried inside it")
   check(radius<=1.15*scale+1.5,"Effects fit the companion clearance envelope")
  end
 end
end
