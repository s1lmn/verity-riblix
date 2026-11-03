--!nonstrict
-- A single boundary between the authoritative Core wire format and UI presentation types.
local Protocol = {}
Protocol.RequestNames = {Sync="RequestSync",OpenBox="RequestOpenBox",UpgradeVerity="RequestUpgradeVerity",
	UpgradeSwipe="RequestUpgradeSwipe",PhoneSession="RequestPhoneSession",Swipe="RequestSwipe",
	TaskStart="RequestTaskStart",TaskComplete="RequestTaskComplete"}
function Protocol.State(raw)
	if type(raw)~="table" then return nil end
	if raw.protocolVersion~=1 then return if raw.version==1 then raw else nil end
	local state=table.clone(raw)
	state.version=1;state.PhoneSessionOpen=raw.PhoneOpen
	state.Boost={multiplier=raw.BoostMultiplier,endsAt=raw.BoostExpiresAt}
	return state
end
function Protocol.Result(raw)
	if type(raw)~="table" then return nil end
	if raw.protocolVersion~=1 then return if raw.version==1 then raw else nil end
	local result=table.clone(raw)
	result.version=1;result.success=raw.status=="OK"
	for action,name in Protocol.RequestNames do if raw.action==name then result.action=action end end
	local aliases={NOT_READY="PROFILE_NOT_READY",BOX_NOT_OPENED="VERITY_LOCKED",PHONE_CLOSED="PHONE_SESSION_CLOSED"}
	result.errorCode=aliases[raw.status] or raw.status
	return result
end
function Protocol.World(raw)
	if type(raw)~="table" then return nil end
	if raw.protocolVersion~=1 then return if raw.version==1 then raw else nil end
	local event=table.clone(raw);event.version=1;event.kind=raw.type
	return event
end
return Protocol
