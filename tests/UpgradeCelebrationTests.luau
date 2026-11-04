return function(load,check)
 local Event=load("src/shared/VerityUpgradeCelebration")
 local Profile=load("src/shared/VerityAnimationProfile")
 local Levels=load("src/shared/LevelConfig")
 for _,level in {2,9,10,24,25,50,75,99,100} do
  local look=Event.Get(level)
  check(look.burstCount>0,"Early upgrades must celebrate too")
  check(look.chargeCount+look.burstCount<=Event.MaxParticles,"One upgrade exceeds the shared particle budget")
  check(look.special==Levels.isMilestone(level))
  check(look.duration==Profile.Duration(level),"World and camera timing diverged")
  local x,y,r=Event.Shake(.12,level,true)
  check(x==0 and y==0 and r==0,"Accessibility must disable shake")
  x,y,r=Event.Shake(.12,level,false)
  check(math.abs(x)<=.055 and math.abs(y)<=.04 and math.abs(r)<=math.rad(.55),"Shake exceeds bounded envelope")
  if not look.special then check(x==0 and y==0 and r==0,"Ordinary upgrades shake the screen") end
 end
 check(Event.Pulse(-.01)==0 and Event.Pulse(1)==0,"Glow persists outside its lifetime")
 for _,p in {.22,.4,.53,.69} do check(math.abs(Profile.Conceal(p)-1)<1e-9,"Old model is visible in the dense light storm") end
 check(Profile.Conceal(0)==0 and Profile.Conceal(1)==0 and Profile.Conceal(.9)==0,"Storm leaves Verity hidden after reveal")
 for i=0,100 do
  local conceal=Profile.Conceal(i/100)
  check(conceal>=0 and conceal<=1,"Invalid local visibility multiplier")
 end
 local VFX=load("src/world/VerityVFXService")
 local a,b={},{}
 local function part()return {Transparency=0}end
 local pa,pb=part(),part()
 local fx=setmetatable({groups={},pulses={[a]={},[b]={}},active={{owner=a,part=pa},{owner=b,part=pb}},free={}},VFX)
 fx:CancelUpgrade(a)
 check(#fx.active==1 and fx.active[1].owner==b and #fx.free==1,"Cancelling one owner removed another's event")
 check(pa.Transparency==1 and fx.pulses[a]==nil)
 fx:SuppressBursts()
 check(#fx.active==0 and #fx.free==2 and pb.Transparency==1,"Reduced effects retained active particles")
 fx:SuppressBursts()
 check(#fx.free==2,"Particle was returned to the pool twice")
end
