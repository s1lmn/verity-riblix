local Levels=require("../src/shared/LevelConfig")
local Profile=require("../src/shared/VerityAnimationProfile")
local tests=0
local function check(name,fn)
	local ok,reason=pcall(fn)
	assert(ok,name..": "..tostring(reason))
	tests+=1;print("PASS",name)
end
check("all 99 animations: finite bounded poses, exact endpoints",function()
	for level=1,99 do
		local old,target=Levels.getVerityScale(level),Levels.getVerityScale(level+1)
		for step=0,100 do
			local pose=Profile.Sample(level,level+1,step/100,false)
			assert(pose.scale==pose.scale and pose.scale>0 and pose.scale<=target*Profile.MaxExpansion+0.000001)
			assert(math.abs(pose.lift)<3 and math.abs(pose.yaw)<=math.pi*2+0.000001)
		end
		assert(Profile.Sample(level,level+1,0,false).scale==old)
		assert(Profile.Sample(level,level+1,1,false).scale==target)
	end
end)
check("Reduced Motion: monotonic scale, no lift, no spin, no overshoot",function()
	for level=1,99 do
		local previous=Levels.getVerityScale(level)
		for step=0,100 do
			local pose=Profile.Sample(level,level+1,step/100,true)
			assert(pose.scale>=previous and pose.scale<=Levels.getVerityScale(level+1))
			assert(pose.lift==0 and pose.yaw==0)
			previous=pose.scale
		end
	end
end)
check("five stages, unique durations and no 101",function()
	for i,level in {10,25,50,75,100} do
		assert(Profile.IsMilestone(level) and Profile.Stage(level)==i)
		assert(Profile.Duration(level)>Profile.Duration(level-1))
	end
	assert(not pcall(Profile.Sample,100,101,0.5,false))
	assert(not pcall(Profile.Sample,1,3,0.5,false))
end)
check("full 15x uses flying clearance instead of the decorative platform",function()
 local Follow=require("../src/shared/CompanionConfig")
 assert(Profile.Footprint()>17 and Levels.MaxScale==15)
 for level=1,100 do
  local scale=Levels.getVerityScale(level)
  local x,_,z=Follow.Offset(scale,1)
  assert(math.sqrt(x*x+z*z)>scale*.85+2)
 end
 assert(Follow.Blend(0)==0 and Follow.Blend(1/30)>0 and Follow.Blend(1/30)<1)
end)
print(string.format("%d animation profile groups passed",tests))
