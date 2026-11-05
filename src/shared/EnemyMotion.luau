--!nonstrict
-- One deterministic trajectory, sampled by server hitboxes and client visuals.
-- Packet times use Workspace:GetServerTimeNow(); never client os.clock().
local Motion={Version=1,Step=.15,TurnFraction=.65}
function Motion.Sample(segment,now)
 local alpha=math.clamp((now-segment.startedAt)/segment.duration,0,1)
 return segment.from:Lerp(segment.to,alpha)
end
function Motion.Plan(id,sequence,from,to,now)
 return {version=1,enemyId=id,sequence=sequence,from=from,to=to,startedAt=now,duration=Motion.Step}
end
return table.freeze(Motion)
