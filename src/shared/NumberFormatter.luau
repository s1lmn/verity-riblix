--!strict
local Numeric = require(script.Parent.Numeric)
local Formatter = {}
local Units = {{divisor = 1e12, suffix = "T"}, {divisor = 1e9, suffix = "B"},
	{divisor = 1e6, suffix = "M"}, {divisor = 1e3, suffix = "K"}}
function Formatter.format(value: number): string
	if not Numeric.isFinite(value) then return "0" end
	local magnitude = math.abs(value)
	for _, unit in Units do
		if magnitude >= unit.divisor then return string.format("%.2f%s", value / unit.divisor, unit.suffix) end
	end
	return tostring(Numeric.round(value))
end
return table.freeze(Formatter)
