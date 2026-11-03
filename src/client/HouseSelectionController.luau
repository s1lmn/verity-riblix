--!nonstrict
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage").Shared.GameConfig)
local Cleanup = require(script.Parent.Cleanup)

local HouseClaimPrompts = {}
local tag = "VerityHouseClaim"

function HouseClaimPrompts.new()
	local cleanup = Cleanup.new()
	local player = Players.LocalPlayer

	local function update(prompt)
		local canClaim = player:GetAttribute("HouseSelectionReady") and not player:GetAttribute("HousePlotId")
		prompt.MaxActivationDistance = if canClaim then Config.MaxInteractionDistance else 0
	end

	local function updateAll()
		for _, prompt in CollectionService:GetTagged(tag) do update(prompt) end
	end

	cleanup:Add(CollectionService:GetInstanceAddedSignal(tag):Connect(update))
	cleanup:Add(player:GetAttributeChangedSignal("HousePlotId"):Connect(updateAll))
	cleanup:Add(player:GetAttributeChangedSignal("HouseSelectionReady"):Connect(updateAll))
	updateAll()
	return cleanup
end

return HouseClaimPrompts
