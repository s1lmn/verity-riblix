--!nonstrict
-- A single callback routes existing consumables. Passes never enter the receipt ledger.
local Numeric=require(game:GetService("ReplicatedStorage").Shared.Numeric)
local Service={};Service.__index=Service
function Service.new(data,state,handlers,enabled)
 local self=setmetatable({data=data,state=state,byProduct={},busy={},enabled=enabled==true},Service)
 for _,handler in handlers do
  for id in handler.products do
   assert(Numeric.isInteger(id,1,9007199254740991),"Invalid developer product ID")
   assert(not self.byProduct[id],"Developer product belongs to multiple receipt handlers")
   self.byProduct[id]=handler
  end
 end
 return self
end
function Service:Process(receipt)
 local pending=Enum.ProductPurchaseDecision.NotProcessedYet
 if not self.enabled or type(receipt)~="table" or not Numeric.isInteger(receipt.PlayerId,1,9007199254740991)
  or not Numeric.isInteger(receipt.ProductId,1,9007199254740991) or type(receipt.PurchaseId)~="string" or #receipt.PurchaseId<1 or #receipt.PurchaseId>128 then return pending end
 local handler=self.byProduct[receipt.ProductId];local profile=self.data:Get(receipt.PlayerId);local session=self.state.sessions[receipt.PlayerId]
 if not handler or not profile or not session or session.ReceiptBusy or profile.Saving or self.busy[receipt.PlayerId] then return pending end
 local token={};self.busy[receipt.PlayerId]=token
 local ok,granted=pcall(function()return handler:ProcessReceiptAsync(receipt.PlayerId,receipt.PurchaseId,receipt.ProductId)end)
 if self.busy[receipt.PlayerId]==token then self.busy[receipt.PlayerId]=nil end
 if not ok then
  if self.state.sessions[receipt.PlayerId]==session then session.ReceiptBusy=false end
  warn("Purchase receipt handler failed; receipt remains pending",receipt.ProductId);return pending
 end
 return if granted==true then Enum.ProductPurchaseDecision.PurchaseGranted else pending
end
return Service
