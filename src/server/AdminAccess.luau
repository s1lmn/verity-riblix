--!strict
-- Viewing tools only. Never grants currency, paid ownership or saved progression.
local Admin={UserIds=table.freeze({[1371278087]=true})} -- JSER42
function Admin.IsAllowed(userId: number,creatorId: number,userOwned: boolean): boolean
 return Admin.UserIds[userId]==true or (userOwned and creatorId>0 and userId==creatorId)
end
function Admin.Apply(player: Player)
 player:SetAttribute("VerityAdmin",Admin.IsAllowed(player.UserId,game.CreatorId,game.CreatorType==Enum.CreatorType.User))
end
return Admin
