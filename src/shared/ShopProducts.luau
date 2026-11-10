--!nonstrict
local Config = require(script.Parent.GameConfig)
local Products = {BoostMultiplier = 2}
Products.Order = {"cash_small", "cash_medium", "cash_large", "cash_vault", "boost_15", "boost_60"}
Products.Items = {
 cash_small = {Title="$25K", Cash=25000, Color="70F676", Art="Cash", Stacks=1},
 cash_medium = {Title="$250K", Cash=250000, Color="51F2A1", Art="Cash", Stacks=2},
 cash_large = {Title="$2.5M", Cash=2500000, Color="48E5BD", Art="Cash", Stacks=3},
 cash_vault = {Title="$25M", Cash=25000000, Color="B7FB64", Art="Cash", Stacks=4},
 boost_15 = {Title="×2 · 15 мин", Seconds=900, Color="FFCE50", Art="Boost"},
 boost_60 = {Title="×2 · 60 мин", Seconds=3600, Color="FF9A56", Art="Boost"},
}
function Products.Id(key)
 local id = Config.ShopProductIds[key]
 return if type(id)=="number" and id>0 then id else nil
end
function Products.Multiplier(data, now)
 return if (data.ShopBoostExpiresAt or 0)>now then Products.BoostMultiplier else 1
end
return Products
