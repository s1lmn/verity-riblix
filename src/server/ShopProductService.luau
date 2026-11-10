--!nonstrict
local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.GameConfig)
local Products = require(Shared.ShopProducts)
local Service = {}
Service.__index = Service

local function hasReceiptSpace(data)
 local count = 0
 for _ in data.Receipts do count += 1 end
 return count < Config.ReceiptLimit
end

function Service.new(data, state, income, clock, notify)
 local self = setmetatable({data=data, state=state, income=income, clock=clock, notify=notify, products={}}, Service)
 for key, offer in Products.Items do
  local id = Products.Id(key)
  if id then
   assert(not self.products[id], "Duplicate shop product ID")
   self.products[id] = offer
  end
 end
 return self
end

function Service:PreparePurchase(userId, key)
 local profile, session = self.data:Get(userId), self.state.sessions[userId]
 if not profile or not session then return "NOT_READY" end
 local id = Products.Id(key)
 local offer = id and self.products[id]
 if not offer then return "PRODUCT_UNAVAILABLE" end
 if not profile.Data.VerityUnlocked then return "BOX_NOT_OPENED" end
 local now = self.clock()
 if (session.PurchaseUntil or 0)>now then return "BUSY" end
 if not hasReceiptSpace(profile.Data) then return "PRODUCT_UNAVAILABLE" end
 if offer.Cash and profile.Data.Cash>Config.MaxMoney-offer.Cash then return "SHOP_WALLET_FULL" end
 session.PurchaseUntil, session.PurchaseProduct = now+60, id
 return "OK", id
end

function Service:ProcessReceiptAsync(userId, purchaseId, productId)
 local profile, session = self.data:Get(userId), self.state.sessions[userId]
 local offer = self.products[productId]
 if not profile or not session or not offer or session.ReceiptBusy or profile.Saving then return false end
 local data = profile.Data
 local newReceipt = not data.Receipts[purchaseId]
 if newReceipt then
  if not hasReceiptSpace(data) then return false end
  if offer.Cash and data.Cash>Config.MaxMoney-offer.Cash then return false end
 end
 session.ReceiptBusy = true
 if newReceipt then
  if offer.Cash then
   data.Cash += offer.Cash
   data.TotalEarned = math.min(Config.MaxMoney, data.TotalEarned+offer.Cash)
  else
   self.income:Settle(userId)
   data.ShopBoostExpiresAt = math.max(self.clock(), data.ShopBoostExpiresAt or 0)+offer.Seconds
  end
  data.Receipts[purchaseId] = true
  self.data:Touch(profile)
 end
 -- The grant and receipt share one write. Keep the receipt on ambiguous failure for retry.
 local saved = self.data:SaveAsync(userId, false)
 session.ReceiptBusy = false
 self.state:Publish(userId, true)
 if saved and newReceipt then self.notify(userId, if offer.Cash then "SHOP_CASH_GRANTED" else "SHOP_BOOST_GRANTED") end
 return saved
end

return Service
