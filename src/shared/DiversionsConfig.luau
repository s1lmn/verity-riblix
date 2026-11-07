--!nonstrict
local Layout = require(script.Parent.WorldLayout)
local Config = {
    Version = 1,
    HuntStation = Vector3.new(132, .85, 322),
    RhythmStation = Vector3.new(132, .85, 346),
    HuntSeconds = 60,
    HuntCount = 12,
    HuntCooldown = 90,
    HuntReach = 5.5,
    ComboSeconds = 5,
    RhythmCooldown = 55,
    RhythmLeadIn = 2.8,
    RhythmWindow = .32,
    PerfectWindow = .14,
    JoinReach = 10,
}
Config.HuntStation += Vector3.new(0, 0, Layout.EndShift)
Config.RhythmStation += Vector3.new(0, 0, Layout.EndShift)
local hunt = {
    Vector3.new(21, 2.5, 218), Vector3.new(21, 2.5, 184),
    Vector3.new(-21, 2.5, 150), Vector3.new(-21, 2.5, 112),
    Vector3.new(21, 2.5, 76), Vector3.new(21, 2.5, 40),
    Vector3.new(-21, 2.5, 4), Vector3.new(-21, 2.5, -32),
    Vector3.new(21, 2.5, -68), Vector3.new(21, 2.5, -104),
    Vector3.new(-21, 2.5, -140), Vector3.new(21, 2.5, -176),
}
Config.HuntPoints = table.freeze(hunt)
local beats = {}
local time = Config.RhythmLeadIn
for index = 1, 20 do
    table.insert(beats, time)
    time += 1.42 - .015 * (index - 1)
end
Config.Beats = table.freeze(beats)
Config.RhythmSeconds = beats[#beats] + .65
function Config.HuntPosition(index, variant)
    local point = Config.HuntPoints[index]
    return Vector3.new(if variant == 1 then point.X else -point.X, point.Y, point.Z)
end
function Config.Station(kind)
    return if kind == "Hunt" then Config.HuntStation else Config.RhythmStation
end
return table.freeze(Config)
