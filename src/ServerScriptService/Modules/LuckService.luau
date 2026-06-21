local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerService = require(ServerScriptService.Modules.PlayerService)

local LuckService = {}

local serverBoostAmount = 0
local serverBoostExpires = 0

function LuckService.Init()
end

function LuckService.Start()
end

function LuckService.GetLuck(player, inflateLuck)
	inflateLuck = inflateLuck or 0
	local data = PlayerService.GetData(player)
	if not data then
		return 0
	end

	local now = os.time()

	local tempBonus = 0
	for _, boost in ipairs(data.LuckBonuses.temporary) do
		if boost.expiresAt > now then
			tempBonus = tempBonus + boost.amount
		end
	end

	return data.BaseLuck
		+ tempBonus
		+ data.LuckBonuses.permanent
		+ LuckService.GetServerBoost()
		+ inflateLuck
end

function LuckService.AddServerBoost(amount, duration)
	serverBoostAmount = amount
	serverBoostExpires = os.time() + duration
end

function LuckService.GetServerBoost()
	if os.time() < serverBoostExpires then
		return serverBoostAmount
	end
	return 0
end

return LuckService