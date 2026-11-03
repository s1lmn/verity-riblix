--!strict
local Theme = {
	Pink = Color3.fromHex("FF5CB8"),
	Purple = Color3.fromHex("9865FF"),
	Blue = Color3.fromHex("59C9FF"),
	Mint = Color3.fromHex("64F5B4"),
	Gold = Color3.fromHex("FFD85A"),
	Peach = Color3.fromHex("FFAC70"),
	Ink = Color3.fromHex("22264B"),
	Paper = Color3.fromHex("FFF9FF"),
	Muted = Color3.fromHex("686B85"),
	Soft = Color3.fromHex("F0EAFB"),
	White = Color3.new(1, 1, 1),
	Disabled = Color3.fromHex("DDD9E6"),
	Font = Enum.Font.Gotham,
	Bold = Enum.Font.GothamBold,
	Radius = 16,
	TouchTarget = 44,
	Gap = 10,
}
return table.freeze(Theme)
