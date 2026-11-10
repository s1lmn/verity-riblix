--!nonstrict
-- Called by Core, projected to the UI. This never grants an unlock or ownership.
local Economy=require(script.Parent.EconomyConfig)
local Abilities=require(script.Parent.AbilityCatalog)
local Ride=require(script.Parent.VerityRideConfig)
local Goals={}
function Goals.NextUnlock(data,heroOwned)
 if not data.VerityUnlocked then return nil end
 for _,id in Abilities.Order do
  local item=Abilities.Items[id]
  if not item.Premium and item.Level<=data.VerityLevel and not Abilities.Owns(data,id,heroOwned) then
   return {kind="AbilityPurchase",itemId=id,name=item.Name,requiredLevel=item.Level,cost=item.Cost,
    progress=math.min(data.Cash,item.Cost),total=item.Cost,remaining=math.max(0,item.Cost-data.Cash),requiresPurchase=true}
  end
 end
 local nextLevel=100;local kind="Appearance";local itemId
 for _,level in {10,25,50,75,90,100} do if level>data.VerityLevel then nextLevel=level;break end end
 for _,id in Abilities.Order do
  local item=Abilities.Items[id]
  if not item.Premium and item.Level>data.VerityLevel and item.Level<nextLevel then nextLevel=item.Level;kind="AbilityAccess";itemId=id end
 end
 if data.VerityLevel<Ride.MinLevel and Ride.MinLevel<=nextLevel then nextLevel=Ride.MinLevel;kind="Riding";itemId=nil end
 if data.VerityLevel>=100 then return nil end
 return {kind=kind,itemId=itemId,requiredLevel=nextLevel,progress=data.VerityLevel,total=nextLevel,
  remaining=nextLevel-data.VerityLevel,requiresPurchase=kind=="AbilityAccess"}
end
function Goals.Build(data)
 if not data.VerityUnlocked then return {stage="Delivery",goal={kind="OpenBox"}} end
 if not data.TutorialCompleted then
  local cost=Economy.LevelCost[data.VerityLevel] or 0
  return {stage="FirstUpgrade",goal={kind=if data.Cash>=cost then "UpgradeVerity" else "EarnCash",
   progress=math.min(data.Cash,cost),total=cost,remaining=math.max(0,cost-data.Cash)}}
 end
 -- The story is optional and never gates FreePlay, abilities or growth.
 return {stage="FreePlay"}
end
return table.freeze(Goals)
