--!strict
-- Temporary tools for the project owner's verified Roblox account (JSER42).
local Admin = {}
local ownerUserId = 1371278087

function Admin.IsAllowed(userId: number): boolean
 return userId == ownerUserId
end

function Admin.Apply(player: Player)
 player:SetAttribute("VerityAdmin", Admin.IsAllowed(player.UserId))
end

return Admin
