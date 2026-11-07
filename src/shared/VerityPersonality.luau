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
-- Additive pose, evaluated only by the existing companion renderer.
function Life.Gesture(kind,age,duration,scale,disabled)
 if disabled or age<0 or age>duration or duration<=0 then return 0,0,0 end
 local envelope=math.sin(math.pi*math.clamp(age/duration,0,1))^2
 local pitch,roll,lift=0,0,0
 if kind=="Pet" or kind=="Home" then
  pitch=math.sin(age*5)*.09*envelope;roll=.11*envelope;lift=.08*envelope
 elseif kind=="Play" then
  pitch=math.sin(age*7)*.1*envelope;roll=math.sin(age*6)*.22*envelope
  lift=math.abs(math.sin(age*5))*.22*envelope
 elseif kind=="Curious" then roll=math.sin(age*2.5)*.16*envelope
 else pitch=-.08*envelope;lift=.12*envelope end
 return pitch,roll,math.min(lift,1.4/math.max(1,scale))
end
return table.freeze(Life)
