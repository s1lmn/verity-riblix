--!nonstrict
return function(load,check)
 local Goals=load("src/client/GuidanceModel")
 local state={VerityUnlocked=false,DeliveryState="Delivered",TutorialStep=2,TutorialCompleted=false,Cash=0,
  VerityLevel=1,NextVerityUpgradeCost=50,PhoneSessionOpen=false,Tasks={}}
 check(Goals.Resolve(nil,nil,nil,0)==nil)
 check(Goals.Resolve(state,nil,nil,0).target=="Delivery","First goal is own delivery")
 check(Goals.Resolve(state,"COSMETICS",nil,0).target=="Close","Guide back from unrelated window")
 state.VerityUnlocked=true;state.DeliveryState="Opened";state.TutorialStep=4
 check(Goals.Resolve(state,nil,nil,0).target=="Nav.PHONE")
 check(Goals.Resolve(state,"PHONE",nil,0).kind=="Wait","Opening phone waits for server session")
 state.PhoneSessionOpen=true;state.TutorialStep=5
 check(Goals.Resolve(state,"PHONE",nil,0).target=="Phone.Next")
 state.TutorialStep=6
 check(Goals.Resolve(state,"PHONE",nil,0).target=="Phone.Next","First swipe does not pretend money is sufficient")
 state.Cash=49;check(Goals.Resolve(state,nil,nil,0).target=="Nav.PHONE")
 state.Cash=50;check(Goals.Resolve(state,nil,nil,0).target=="Nav.VERITY")
 check(Goals.Resolve(state,"VERITY",nil,0).target=="Verity.Buy")
 check(not state.TutorialCompleted and state.VerityLevel==1,"Presentation never advances game progress")
 state.Tasks={{taskId="PRESS_BUTTON",status="Active",cooldownEndsAt=0}}
 check(Goals.Resolve(state,nil,"PRESS_BUTTON",0).kind=="World","An explicitly chosen task remains guided during onboarding")
 state.Tasks={}
 state.TutorialCompleted=true;state.TutorialStep=nil;state.VerityLevel=2
 check(Goals.Resolve(state,nil,nil,0).target=="Nav.TASKS")
 state.Tasks={{taskId="REACH_POINT",status="Active",targetPosition="point",cooldownEndsAt=0},
  {taskId="PRESS_BUTTON",status="Active",targetPosition="button",cooldownEndsAt=0}}
 check(Goals.Resolve(state,nil,"REACH_POINT",0).target=="REACH_POINT","Selected active task wins")
 check(Goals.Resolve(state,nil,nil,0).target=="PRESS_BUTTON","Stable fallback order")
 check(Goals.Resolve(state,"TASKS",nil,0).target=="Close")
 check(Goals.Resolve(state,"PHONE",nil,0).target=="Phone.Next","Open phone keeps its own guidance")
 check(Goals.Resolve(state,"SETTINGS",nil,0)==nil)
 state.Tasks={{taskId="PRESS_BUTTON",status="Cooldown",cooldownEndsAt=10}}
 check(Goals.Resolve(state,nil,nil,0).target=="Nav.TASKS","Confirmed completion removes world target")
 check(Goals.Resolve(state,"TASKS",nil,0).kind=="Wait")
 check(Goals.Resolve(state,"TASKS",nil,11).target=="Task.PRESS_BUTTON")
 state.VerityLevel=100
 check(Goals.Resolve(state,"VERITY",nil,0).kind=="Wait","Never point to a level101 purchase")
end
