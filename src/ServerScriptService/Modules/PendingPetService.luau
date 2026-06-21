local Players = game:GetService("Players")

local PendingPetService = {}

local pending = {}

function PendingPetService.Init()
end

function PendingPetService.Start()
	Players.PlayerRemoving:Connect(function(player)
		pending[player] = nil
	end)
end

function PendingPetService.SetPending(player, petResult)
	pending[player] = petResult
end

function PendingPetService.GetPending(player)
	local result = pending[player]
	pending[player] = nil
	return result
end

function PendingPetService.HasPending(player)
	return pending[player] ~= nil
end

return PendingPetService