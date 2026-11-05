--!strict
local Config=require(script.Parent.GameConfig)
local shift=(Config.PlotCount-16)*Config.PlotSpacing/4
return table.freeze({EndShift=shift,RoadHalfLength=310+shift,GroundHalfLength=370+shift})
