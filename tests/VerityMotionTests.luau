local definitions=require("../src/world/VerityDefinitions")
local motion=require("../src/world/VerityMotion")
local levels=require("../src/shared/LevelConfig")
local count=0
local function check(condition,message)
    assert(condition,message);count+=1
end
local colors={}
local previous=0
for level=1,10 do
    local definition=definitions[level]
    check(definition~=nil,"missing variant")
    check(not colors[definition.Color],"duplicate body color");colors[definition.Color]=true
    local size=levels.getVerityScale(level)
    check(size>previous,"growth must be strictly increasing");previous=size
    check(3.21*size*1.14<17,"animated aura must fit the existing platform")
    check(definition.Special==(level==5 or level==10),"special-level contract")
    local maximum=0
    for tick=0,600 do
        local bob,yaw,roll=motion.Sample(definition,tick/30)
        check(bob==bob and yaw==yaw and roll==roll,"finite motion")
        check(bob>=0 and bob<=definition.Bob+.00001,"never bob under the platform")
        check(math.abs(roll)<=.121,"bounded roll")
        maximum=math.max(maximum,bob)
    end
    check(maximum>definition.Bob*.9,"motion should be visibly present")
end
local e0,p0=motion.Transition(0);local e1,p1=motion.Transition(1)
check(e0==0 and p0==1,"transition start")
check(e1==1 and math.abs(p1-1)<1e-10,"transition finish")
for i=0,100 do
    local ease,pop=motion.Transition(i/100)
    check(ease>=0 and ease<=1 and pop>=1 and pop<=1.14,"bounded transition")
end
check(#definitions==10,"only ten authored variants")
print("Verity motion/growth checks passed:",count)
