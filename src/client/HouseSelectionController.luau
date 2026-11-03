--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Cleanup = require(script.Parent.Cleanup)

local HouseClaimPrompts = {}
local claimTag = "VerityHouseClaim"
local workshopTag = "VerityHouseWorkshop"

function HouseClaimPrompts.new()
	local cleanup = Cleanup.new()
	local player = Players.LocalPlayer

	local function update(prompt)
		local plotId = player:GetAttribute("HousePlotId")
		local workshopPlot = prompt:GetAttribute("WorkshopPlotId")
		local enabled = if workshopPlot then workshopPlot == plotId else player:GetAttribute("HouseSelectionReady") and not plotId
		prompt.MaxActivationDistance = if enabled then Config.MaxInteractionDistance else 0
	end

	local function updateAll()
		for _, prompt in CollectionService:GetTagged(claimTag) do update(prompt) end
		for _, prompt in CollectionService:GetTagged(workshopTag) do update(prompt) end
	end

	cleanup:Add(CollectionService:GetInstanceAddedSignal(claimTag):Connect(update))
	cleanup:Add(CollectionService:GetInstanceAddedSignal(workshopTag):Connect(update))
	cleanup:Add(player:GetAttributeChangedSignal("HousePlotId"):Connect(updateAll))
	cleanup:Add(player:GetAttributeChangedSignal("HouseSelectionReady"):Connect(updateAll))
	updateAll()
	return cleanup
end

return HouseClaimPrompts
