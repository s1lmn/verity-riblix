local Profile=require("../src/shared/VeritySpawnProfile")
assert(Profile.Duration==5.03 and Profile.Reveal==2.31)
for _,reduced in {false,true} do
 local cover,opening,join=1,0,0
 for i=0,1000 do
  local age=i*Profile.Duration/1000
  local p=Profile.Sample(age,reduced)
  for _,name in {"cover","open","charge","tail","join","burst"} do
   assert(p[name]==p[name] and p[name]>=0 and p[name]<=1,name)
  end
  assert(p.cover<=cover+1e-9 and p.open>=opening-1e-9 and p.join>=join-1e-9)
  assert(p.scale>=1 and p.scale<=1.12)
  if age<=Profile.Reveal then assert(p.cover==1,'early reveal') end
  if reduced then assert(p.shake==0 and p.scale==1,'motion reduction') end
  cover,opening,join=p.cover,p.open,p.join
 end
 local final=Profile.Sample(Profile.Duration,reduced)
 assert(final.cover==0 and final.join==1 and final.scale==1 and final.tail==0)
end
assert(Profile.Sample(Profile.Reveal+.4,false).cover==0)
print("Spawn profile: reveal timing, bounded phases, exact finish, monotonic mask/join and reduced motion passed")
