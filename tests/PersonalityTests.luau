return function(load,check)
 local Life=load("src/shared/VerityPersonality")
 for _,emotion in {"Love","Stars","Laugh","Wink","Playful","Surprise"} do
  check(Life.Blink(.075,0,emotion,false)==1,"Blink must not distort an authored reaction")
 end
 check(Life.Blink(.075,0,"Joy",true)==1,"Reduced Motion must suppress blinking")
 check(Life.Blink(.075,0,"Joy",false)<.1)
 check(Life.Blink(.075,1,"Joy",false)==1,"Owners must not blink in sync")
 local function drive(hz)
  local state={};local pitch,roll,lift
  for i=1,hz do pitch,roll,lift=Life.Step(state,16,8,1/hz,i/hz,false,false) end
  return state,pitch,roll,lift
 end
 local a,ap,ar=drive(30)
 local b,bp,br=drive(60)
 check(math.abs(ap-bp)<1e-9 and math.abs(ar-br)<1e-9,"Tilt filter depends on frame rate")
 check(math.abs(ap)<=.045 and math.abs(ar)<=.065,"Travel tilt exceeds intended envelope")
 local sawSettle=false
 for i=1,120 do
  local pitch,roll,lift=Life.Step(a,0,0,1/60,1+i/60,false,false)
  check(math.abs(pitch)<.081 and math.abs(roll)<=.065 and math.abs(lift)<.075,"Stop reaction escaped envelope")
  sawSettle=sawSettle or math.abs(lift)>.001
 end
 check(sawSettle,"Stopping must produce a short settling motion")
 local pitch,roll,lift=Life.Step(a,16,16,1/60,4,true,false)
 check(pitch==0 and roll==0 and lift==0,"Reduced Motion retains travel motion")
 pitch,roll,lift=Life.Step(b,16,16,1/60,4,false,true)
 check(pitch==0 and roll==0 and lift==0 and b.stopped==nil,"Teleport retains an old stop reaction")
end
