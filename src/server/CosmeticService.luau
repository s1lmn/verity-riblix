--!nonstrict
local Shared=game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog=require(Shared.CosmeticCatalog)
local Config=require(Shared.GameConfig)
local Service={};Service.__index=Service
function Service.new(data,state,products,clock)
 local self=setmetatable({data=data,state=state,products=products,clock=clock,byItem={}},Service)
 for product,id in products do
  assert(type(product)=="number" and product>0 and product%1==0 and Catalog.Items[id],"Invalid cosmetic product")
  assert(not self.byItem[id],"Duplicate cosmetic product mapping")
  self.byItem[id]=product
 end
 return self
end
function Service:Catalog(purchasesEnabled)
 local result={}
 for _,id in Catalog.Order do
  local item=table.clone(Catalog.Items[id])
  item.productId=if purchasesEnabled==false then nil else self.byItem[id]
  item.available=item.productId~=nil
  table.insert(result,item)
 end
 return result
end
function Service:Equip(userId,itemId,equipped)
 local profile=self.data:Get(userId)
 if not profile then return "NOT_READY" end
 local item=Catalog.Items[itemId]
 if not item then return "INVALID_ITEM" end
 if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
 if not profile.Data.CosmeticsOwned[itemId] then return "NOT_OWNED" end
 if equipped then profile.Data.CosmeticsEquipped[item.slot]=itemId
 elseif profile.Data.CosmeticsEquipped[item.slot]==itemId then profile.Data.CosmeticsEquipped[item.slot]=nil end
 self.data:Touch(profile)
 return "OK"
end
function Service:PreparePurchase(userId,itemId)
 local profile,session=self.data:Get(userId),self.state.sessions[userId]
 if not profile or not session then return "NOT_READY" end
 if not Catalog.Items[itemId] then return "INVALID_ITEM" end
 if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
 if profile.Data.CosmeticsOwned[itemId] then return "ALREADY_OWNED" end
 local product=self.byItem[itemId]
 if not product then return "PRODUCT_UNAVAILABLE" end
 if session.PurchaseUntil and session.PurchaseUntil>self.clock() then return "BUSY" end
 session.PurchaseUntil=self.clock()+60;session.PurchaseProduct=product
 return "OK",product
end
function Service:ClosePrompt(userId,productId)
 local session=self.state.sessions[userId]
 if session and session.PurchaseProduct==productId then session.PurchaseUntil=nil;session.PurchaseProduct=nil end
end
function Service:ProcessReceiptAsync(userId,purchaseId,productId)
 local itemId=self.products[productId]
 if not itemId or type(purchaseId)~="string" or #purchaseId<1 or #purchaseId>128 then return false end
 local profile,session=self.data:Get(userId),self.state.sessions[userId]
 if not profile or not session or session.ReceiptBusy or profile.Saving then return false end
 if not profile.Data.Receipts[purchaseId] then
  local count=0;for _ in profile.Data.Receipts do count+=1 end
  if count>=Config.ReceiptLimit then return false end
  profile.Data.CosmeticsOwned[itemId]=true
  profile.Data.Receipts[purchaseId]=true
  self.data:Touch(profile)
 end
 session.ReceiptBusy=true
 -- Entitlement and receipt commit together; acknowledge only after durable success.
 local saved=self.data:SaveAsync(userId,false)
 session.ReceiptBusy=false
 self:ClosePrompt(userId,productId)
 self.state:Publish(userId,true)
 return saved
end
return Service
