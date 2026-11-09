--!strict
-- Spatial values in studs; World must use these reservations, not smaller plots.
return table.freeze({
	ProtocolVersion = 1,
	MoneyPassMultiplier = 3,
	MoneyPassPrice = 99,
	-- Set MoneyPassId to the real pass ID from this experience before enabling sales.
	MoneyPassId = nil,
	HeroPassId = nil, -- Real Scarlet Sentinel Game Pass ID; no placeholder entitlement.
	HeroPassPrice = 99,
 -- Real IDs only: home_style_pack, aura_pack, fusion_pack, party_pack, collector_pack, atmosphere_pack.
 PremiumPassIds = table.freeze({}),
 -- UI/VFX developer enables a key only after that product's actual presentation is integrated.
 PremiumPresentationReady = table.freeze({}),
	PlotCount = 12,
	ServerCapacity = 12, -- Also set MaxPlayers in Creator Dashboard.
	BaseWidth = 2,
	BaseDepth = 2,
	BaseHeight = 3,
	AnimationExpansion = 1.15,
	EffectMargin = 2,
	PlotWidth = 120,
	PlotDepth = 72,
	PlotSpacing = 72,
	RoadWidth = 26,
	SidewalkWidth = 12,
	MaxInteractionDistance = 12,
	DeliveryDelay = 2,
	InteractionFallback = true, -- Core arrival pads/boxes; World can disable after integration.
	SnapshotInterval = 0.5,
	IncomeInterval = 1,
	TaskPollInterval = 0.1,
	DataVersion = 2,
	DataStoreName = "Verity_PlayerData_v1",
	StudioDataMode = "Memory", -- Memory or StudioStore; never fall back after a failed load.
	SaveInterval = 60,
	LeaseSeconds = 180,
	LeaseSafetySeconds = 15,
	DataRetries = 3,
	MaxMoney = 1e15,
	ReceiptLimit = 5000, -- Fail closed at the limit; never evict paid receipt IDs.
	OperationTTL = 120,
	OperationLimit = 256,
	RemoteBurst = 20,
	RemoteRefillPerSecond = 8,
})
