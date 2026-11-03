-- Pure bounded presentation; never affects progression, physics or saved size.
local Life = {}
function Life.Blink(now,seed,emotion,reduced)
    if reduced or (emotion~="Joy" and emotion~="Confident") then return 1 end
    local period=3.6+(math.abs(seed)%11)*.17
    local t=(now+math.abs(seed)%23*.31)%period
    if t>=.17 then return 1 end
    if t<.06 then return 1-.93*(t/.06) end
    if t<.09 then return .07 end
    return .07+.93*((t-.09)/.08)
end
function Life.Step(state,vx,vz,dt,now,disabled,reset)
    if disabled or reset then
        state.x,state.z,state.moving,state.stopped=0,0,false,nil
        return 0,0,0
    end
    local blend=1-math.exp(-8*math.clamp(dt,0,.1))
    state.x=(state.x or 0)+(math.clamp(vx/16,-1,1)-(state.x or 0))*blend
    state.z=(state.z or 0)+(math.clamp(vz/16,-1,1)-(state.z or 0))*blend
    local speed=math.sqrt(vx*vx+vz*vz)
    if speed>2 then state.moving=true
    elseif speed<.7 and state.moving then state.moving=false;state.stopped=now end
    local age=state.stopped and now-state.stopped or 10
    local settle=if age>=0 and age<.65 then math.sin(age*math.pi*4)*math.exp(-age*7) else 0
    return state.z*.045+settle*.035,-state.x*.065,settle*.075
end
return table.freeze(Life)
