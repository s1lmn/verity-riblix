--!strict
local Numeric = {}
function Numeric.isFinite(value: any): boolean
	return type(value) == "number" and value == value and math.abs(value) < math.huge
end
function Numeric.isInteger(value: any, minimum: number, maximum: number): boolean
	return Numeric.isFinite(value) and value % 1 == 0 and value >= minimum and value <= maximum
end
function Numeric.round(value: number): number
	return math.floor(value + 0.5)
end
return table.freeze(Numeric)
