-- Pure motion math, shared by renderer/tests. All translations are upward from the pad.
local Motion = {}
function Motion.Sample(definition, time)
    local phase = time * definition.Speed * 2
    local wave = (math.sin(phase)+1)/2
    local bob = definition.Bob * wave
    local yaw = math.sin(phase*.55)*.06
    local roll = math.sin(phase*.75)*.035
    if definition.Motion == "Hop" then bob = definition.Bob * math.max(0,math.sin(phase))^2 end
    if definition.Motion == "DoubleHop" then bob = definition.Bob * math.abs(math.sin(phase*1.5))^3 end
    if definition.Motion == "Tilt" then roll = math.sin(phase)*.12 end
    if definition.Motion == "Rock" then roll = math.sin(phase)*.07 end
    if definition.Motion == "Float" then yaw = math.sin(phase*.35)*.11 end
    if definition.Motion == "Sway" then roll = math.sin(phase)*.075 end
    if definition.Motion == "Orbit" then yaw = math.sin(phase*.4)*.1 end
    return bob, yaw, roll
end
function Motion.Transition(progress)
    local t=math.clamp(progress,0,1)
    local ease=1-(1-t)^3
    local pop=1+.14*math.sin(math.pi*t)*math.exp(-2*t)
    return ease,pop
end
return Motion
