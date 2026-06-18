local ServerScriptService = game:GetService("ServerScriptService")

local PlayerService = require(ServerScriptService.Modules.PlayerService)

local EconomyService = {}

function EconomyService.Init()
end

function EconomyService.Start()
end

function EconomyService.AddCoins(player, amount)
	local data = PlayerService.GetData(player)
	if not data then
		return
	end

	local newCoins = data.Coins + amount
	PlayerService.SetData(player, {"Coins"}, newCoins)
end

function EconomyService.SpendCoins(player, amount)
	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	if data.Coins < amount then
		return false
	end

	PlayerService.SetData(player, {"Coins"}, data.Coins - amount)
	return true
end

function EconomyService.CalcBalloonReward(balloonConfig, inflateTime)
	local t = math.clamp(inflateTime, 0, 60) / 60
	local reward = math.floor(balloonConfig.baseReward + (balloonConfig.maxReward - balloonConfig.baseReward) * t)
	return reward
end

return EconomyService