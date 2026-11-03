--!nonstrict
return function(load,check)
 local make=load("tests/Fixture")
 local Cosmetic=load("src/server/CosmeticService")
 local Schema=load("src/server/ProfileSchema")
 local f=make(load);local p=f.join(1);local q=f.join(2)
 p.Data.DeliveryState="Opened";p.Data.VerityUnlocked=true
 q.Data.DeliveryState="Opened";q.Data.VerityUnlocked=true
 -- Synthetic IDs only in tests; no Roblox purchase is performed.
 local service=Cosmetic.new(f.Data,f.State,{[101]="round_glasses",[102]="party_hat"},f.clock)
 f.Remote:Register("RequestEquipCosmetic",function(id,a)return service:Equip(id,a.itemId,a.equipped)end)
 check(service:Equip(1,"round_glasses",true)=="NOT_OWNED")
 check(service:PreparePurchase(1,"star_earrings")=="PRODUCT_UNAVAILABLE")
 check(service:PreparePurchase(1,"round_glasses")=="OK")
 check(service:PreparePurchase(1,"party_hat")=="BUSY")
 service:ClosePrompt(1,101)
 check(not p.Data.CosmeticsOwned.round_glasses,"Closing a successful/cancelled prompt never grants")
 check(not service:ProcessReceiptAsync(1,"a",999))
 f.Store.Fail=true
 check(not service:ProcessReceiptAsync(1,"receipt-a",101),"Unpersisted receipt cannot be acknowledged")
 check(p.Data.CosmeticsOwned.round_glasses and p.Data.Receipts['receipt-a'])
 f.Store.Fail=false
 check(service:ProcessReceiptAsync(1,"receipt-a",101),"Ambiguous failure retries same grant")
 local before=p.Revision
 check(service:ProcessReceiptAsync(1,"receipt-a",101) and p.Revision==before,"Replayed receipt cannot grant twice")
 check(service:PreparePurchase(1,"round_glasses")=="ALREADY_OWNED")
 local result=f.Remote:Handle(1,"RequestEquipCosmetic",{operationId="1",itemId="round_glasses",equipped=true})
 check(result.status=="OK" and p.Data.CosmeticsEquipped.Face=="round_glasses")
 check(f.Remote:Handle(1,"RequestEquipCosmetic",{operationId="1",itemId="round_glasses",equipped=false}).status=="OPERATION_CONFLICT")
 check(service:Equip(2,"round_glasses",true)=="NOT_OWNED" and not q.Data.CosmeticsEquipped.Face,"Foreign inventory cannot equip")
 check(service:ProcessReceiptAsync(1,"receipt-b",102))
 check(service:Equip(1,"party_hat",true)=="OK")
 check(p.Data.CosmeticsEquipped.Head=="party_hat" and p.Data.CosmeticsEquipped.Face=="round_glasses","Compatible slots coexist")
 check(f.State:Snapshot(1).IncomePerSecond==5 and p.Data.Cash==0 and p.Data.BoostExpiresAt==0,"Cosmetics have zero economic benefit")
 check(f.Tasks:Start(1,"PRESS_BUTTON")=="OK")
 check(f.Tasks:Complete(1,"PRESS_BUTTON")=="OK")
 local cooldown=p.Data.TaskCooldowns.PRESS_BUTTON
 check(cooldown>f.clock())
 f.State:Remove(1);check(f.Data:ReleaseAsync(1));local restored=f.join(1)
 check(restored.Data.VerityUnlocked and restored.Data.CosmeticsOwned.round_glasses and restored.Data.CosmeticsEquipped.Head=="party_hat")
 check(f.Tasks:Start(1,"PRESS_BUTTON")=="COOLDOWN","Rejoin cannot reset personal task cooldown")
 check(service:Equip(1,"round_glasses",false)=="OK" and restored.Data.CosmeticsEquipped.Face==nil)
 local old={DataVersion=1,Cash=12,TotalEarned=12,VerityLevel=1,VerityUnlocked=false,DeliveryState="NotDelivered"}
 local migrated=assert(Schema.validate(old));check(migrated.DataVersion==2 and migrated.Cash==12 and next(migrated.CosmeticsOwned)==nil,"v1 migration preserves existing progress")
 local copy=Schema.copy(restored.Data);copy.CosmeticsOwned.round_glasses=nil;copy.TaskCooldowns.PRESS_BUTTON=0
 check(restored.Data.CosmeticsOwned.round_glasses and restored.Data.TaskCooldowns.PRESS_BUTTON==cooldown,"Save snapshot owns independent tables")
 local bad=Schema.new();bad.CosmeticsEquipped.Face="round_glasses";check(Schema.validate(bad)==nil)
 bad=Schema.new();bad.TaskCooldowns.PRESS_BUTTON=0/0;check(Schema.validate(bad)==nil)
 bad=Schema.new();bad.CosmeticsOwned.round_glasses=true;bad.CosmeticsEquipped.Head="round_glasses";check(Schema.validate(bad)==nil)
end
