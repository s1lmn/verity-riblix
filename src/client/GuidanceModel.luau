--!nonstrict
-- Presentation choices only; every milestone is read from confirmed Core state.
local Model={}
local order={"PRESS_BUTTON","REACH_POINT","STAND_ON_PLATFORM"}
local tasks={
 PRESS_BUTTON={title="Нажми кнопку",detail="Иди по стрелкам к жёлтой кнопке",near="Нажми %s у кнопки",radius=7},
 REACH_POINT={title="Дойди до метки",detail="Иди по стрелкам к розовой площадке",near="Шагни в центр метки",radius=3},
 STAND_ON_PLATFORM={title="Встань на платформу",detail="Иди по стрелкам к голубой площадке",near="Не сходи с платформы 1 секунду",radius=2.2},
}
local function ui(id,target,title,detail)
 return {id=id,kind="UI",target=target,title=title,detail=detail}
end
local function phone(panel,title)
 if panel=="PHONE" then return ui("earn","Phone.Next",title or "3/4 · Заработай деньги","Листай вверх или нажми «ЛИСТАТЬ»") end
 return ui("phone","Nav.PHONE",title or "2/4 · Открой телефон","Нажми кнопку с телефоном слева")
end
function Model.Resolve(state,panel,selectedTaskId,now)
 if type(state)~="table" then return nil end
 if not state.VerityUnlocked then
  if panel then return ui("close-delivery","Close","1/4 · Забери коробку","Закрой окно и иди по стрелкам") end
  return {id="delivery",kind="World",target="Delivery",title="1/4 · Забери коробку",
   detail=if state.DeliveryState=="Delivered" then "Иди по стрелкам к своей коробке" else "Доставка уже в пути — иди к метке",
   near=if state.DeliveryState=="Delivered" then "Нажми %s и распакуй Verity" else "Коробка появится через пару секунд",radius=10}
 end
 if selectedTaskId and (not panel or panel=="TASKS") then
  for _,entry in state.Tasks or {} do
   if entry.taskId==selectedTaskId and entry.status=="Active" and tasks[selectedTaskId] then
    if panel then return ui("close-task","Close","Задание выбрано","Закрой окно и иди по стрелкам") end
    local goal=table.clone(tasks[selectedTaskId]);goal.id="task:"..selectedTaskId;goal.kind="World"
    goal.target=selectedTaskId;goal.taskId=selectedTaskId;goal.position=entry.targetPosition;return goal
   end
  end
 end
 if not state.TutorialCompleted then
  local step=state.TutorialStep or 4
  if step<6 then
   if panel=="PHONE" and not state.PhoneSessionOpen then
    return {id="phone-wait",kind="Wait",title="2/4 · Открываем телефон",detail="Подожди подключения…"}
   end
   return phone(panel)
  end
  local cost=state.NextVerityUpgradeCost
  if type(cost)=="number" and state.Cash>=cost then
   return ui("first-upgrade",if panel=="VERITY" then "Verity.Buy" else "Nav.VERITY",
    "4/4 · Улучши Verity",if panel=="VERITY" then "Нажми зелёную кнопку улучшения" else "Нажми кнопку с Verity слева")
  end
  return phone(panel,"3/4 · Накопи на улучшение")
 end
 if panel=="PHONE" then return phone(panel,"Свайпай и зарабатывай") end
 if panel=="VERITY" then
  if state.VerityLevel>=100 then return {id="max",kind="Wait",title="Verity выросла до максимума!",detail="Все 100 уровней открыты"} end
  if state.NextVerityUpgradeCost and state.Cash>=state.NextVerityUpgradeCost then
   return ui("upgrade","Verity.Buy","Улучши Verity","Нажми зелёную кнопку улучшения")
  end
  return {id="save",kind="Wait",title="Нужно немного больше денег",detail="Телефон и задания помогут накопить"}
 end
 if panel=="WORKSHOP" or panel=="COSMETICS" or panel=="SETTINGS" then return nil end
 local entries={};for _,entry in state.Tasks or {} do entries[entry.taskId]=entry end
 local active
 if selectedTaskId and entries[selectedTaskId] and entries[selectedTaskId].status=="Active" then active=selectedTaskId end
 for _,id in order do if not active and entries[id] and entries[id].status=="Active" then active=id end end
 if active then
  if panel then return ui("close-task","Close","Задание выбрано","Закрой окно и иди по стрелкам") end
  local goal=table.clone(tasks[active]);goal.id="task:"..active;goal.kind="World";goal.target=active;goal.taskId=active
  goal.position=entries[active].targetPosition
  return goal
 end
 if panel=="TASKS" then
  for _,id in order do local entry=entries[id]
   if entry and (entry.status=="Ready" or (entry.status=="Cooldown" and entry.cooldownEndsAt<=now)) then
    return ui("start:"..id,"Task."..id,"Выбери задание","Нажми «Начать» — появятся стрелки")
   end
  end
  return {id="cooldowns",kind="Wait",title="Задания скоро обновятся",detail="Пока можно заработать в телефоне"}
 end
 return ui("tasks","Nav.TASKS","Хочешь больше денег?","Нажми кнопку с заданиями слева")
end
return Model
