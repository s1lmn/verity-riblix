--!strict
-- Spatial values in studs; World must use these reservations, not smaller plots.
return table.freeze({
	ProtocolVersion = 1,
	PlotCount = 16,
	ServerCapacity = 16, -- Also set MaxPlayers in Creator Dashboard.
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
	DataVersion = 1,
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
