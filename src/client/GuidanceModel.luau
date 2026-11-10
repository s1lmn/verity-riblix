--!nonstrict
-- Presentation choices only; every milestone is read from confirmed Core state.
local Houses=require(game:GetService("ReplicatedStorage").Shared.HouseConfig)
local Locale=require(script.Parent.Locale)
local Model={}
local Config=require(game:GetService("ReplicatedStorage").Shared.TaskConfig)
local order={}
for id in Config do table.insert(order,id) end
table.sort(order,function(a,b)return Config[a].Order<Config[b].Order end)
local function ui(id,target,title,detail)
 return {id=id,kind="UI",target=target,title=title,detail=detail or ""}
end

local function phone(panel,title)
 if panel=="PHONE" then return ui("earn","Phone.Next",title or "Листай → зарабатывай","ЛИСТАТЬ ↑") end
 return ui("phone","Nav.PHONE",title or "Открой телефон")
end

function Model.ReadyAbility(state)
 if not state or not state.VerityUnlocked then return nil end
 for _,item in state.AbilityCollection or {} do
  local slot=(state.AbilitySlots or {})[item.slot]
  if (not item.premium and item.canBuy and item.affordable) or
   (item.owned and item.canEquip and slot and slot.empty) then return item.id,item.owned end
 end
 return nil
end

function Model.ReadyHomeUpgrade(state)
 if not state or not state.VerityUnlocked then return nil end
 local nextBuild=Houses.IncomeUpgrades[(state.HouseIncomeLevel or 0)+1]
 if nextBuild and state.VerityLevel>=nextBuild.Level and state.Cash>=nextBuild.Cost then return "Income" end
 if not state.HouseDoorOwned and state.Cash>=Houses.Features.Door.Cost then return "Door" end
 if not state.HouseSecondFloorOwned and state.Cash>=Houses.Features.SecondFloor.Cost then return "Floor" end
 return nil
end

local function taskGoal(id,entry,panel,now)
 if panel then return ui("close-task","Close","Задание выбрано","Закрой окно") end
 local definition=Config[id]
 local index=entry.step or 1
 local stage=definition.Steps[index]
 local goal={title=stage.Title,detail="",near=stage.Action,touch=stage.Action,
  prompt=stage.Mode=="Prompt",radius=if stage.Mode=="Hold" then 2.2 else 5}
 goal.detail=string.format(Locale.Text("Этап %d/%d"),index,#definition.Steps)
 if goal.prompt then goal.near="%s · "..Locale.Text(stage.Action) end
 if stage.Mode=="Hold" and entry.holdStartedAt then
  goal.near=string.format(Locale.Text("Удерживай позицию: %d%%"),math.clamp(math.floor((now-entry.holdStartedAt)/stage.HoldSeconds*100),0,100))
  goal.touch=goal.near
 end
 goal.id="task:"..id..":"..index;goal.kind="World";goal.target=id..":"..index
 goal.taskId=id;goal.position=entry.targetPosition
 return goal
end

function Model.Resolve(state,panel,selectedTaskId,now,nearestTaskId)
 if type(state)~="table" then return nil end
 if not state.VerityUnlocked then
  if panel then return ui("close-delivery","Close","Забери Verity","Закрой окно") end
  return {id="delivery",kind="World",target="Delivery",title="Забери Verity",
   detail="",near=if state.DeliveryState=="Delivered" then "%s · Распаковать" else "Жди коробку",radius=10}
 end

 local entries={}
 for _,entry in state.Tasks or {} do entries[entry.taskId]=entry end
 local active
 if selectedTaskId and entries[selectedTaskId] and entries[selectedTaskId].status=="Active" then active=selectedTaskId end
 for _,id in order do if not active and entries[id] and entries[id].status=="Active" then active=id end end
 -- An optional chapter only guides the world, never forces a menu to close.

 local cost=state.NextVerityUpgradeCost
 if state.VerityLevel<100 and type(cost)=="number" and state.Cash>=cost
  and (panel==nil or panel=="PHONE" or panel=="VERITY") then
  local target=if panel=="PHONE" then "Phone.Grow" elseif panel=="VERITY" then "Verity.Buy" else "Nav.VERITY"
  return ui("upgrade-ready",target,"Улучши Verity!","↑")
 end

 if not state.TutorialCompleted then
  if panel=="PHONE" and not state.PhoneSessionOpen then return {id="phone-wait",kind="Wait",title="Открываем телефон",detail="Подожди…"} end
  return phone(panel,"Заработай на улучшение")
 end

 if panel=="TASKS" then return nil end
 if active and not panel and state.Story and not state.Story.paused then return taskGoal(active,entries[active],nil,now) end
 local first=false
 if not first then
  local abilityId,owned=Model.ReadyAbility(state)
  if abilityId and (panel==nil or panel=="MORE" or panel=="ABILITIES") then
   return ui("ability:"..abilityId,if panel=="ABILITIES" then "Ability."..abilityId else "Nav.ABILITIES",
    if owned then "Выбери способность!" else "Купи способность!","!")
  end
  local home=Model.ReadyHomeUpgrade(state)
  if home and (panel==nil or panel=="WORKSHOP") then
   if panel then return ui("close-workshop","Close","Улучши дом","Закрой окно") end
   return {id="home:"..home,kind="World",target="HousePurchase",purchaseKind=home,title="Улучши дом",
    detail="",near="%s · Улучшить",touch="Улучшить",prompt=true,radius=6}
  end
 end

 if panel=="PHONE" then return phone(panel) end
 if panel=="VERITY" then
  if state.VerityLevel>=100 then return nil end
  return phone(panel,"Заработай на улучшение")
 end
 if panel and panel~="TASKS" then return nil end

 -- No mission picker or repeatable cooldown offers; free play remains available.

 return phone(panel)
end
return Model
