local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BalloonConfig = require(ReplicatedStorage.Shared.Config.BalloonConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerService = require(ServerScriptService.Modules.PlayerService)
local EconomyService = require(ServerScriptService.Modules.EconomyService)
local RouletteService = require(ServerScriptService.Modules.RouletteService)
local PetService = require(ServerScriptService.Modules.PetService)

local BalloonService = {}

local inflating = {}

function BalloonService.Init()
end

function BalloonService.Start()
	Remotes.Balloon_Start.OnServerEvent:Connect(function(player)
		if inflating[player] then
			return
		end

		local data = PlayerService.GetData(player)
		if not data then
			return
		end

		local activeBalloon = data.ActiveBalloon
		if not data.Balloons[activeBalloon] or data.Balloons[activeBalloon] <= 0 then
			Remotes.Balloon_Result:FireClient(player, { type = "no_balloon" })
			return
		end

		inflating[player] = { startTime = tick(), balloonName = activeBalloon, popped = false }

		task.spawn(function()
			while inflating[player] and not inflating[player].popped do
				task.wait(0.5)
				if not inflating[player] then
					break
				end

				local elapsed = tick() - inflating[player].startTime
				local config = BalloonConfig[inflating[player].balloonName]
				if not config then
					break
				end

				local popChance = getPopChance(config.popCurve, elapsed)

				if math.random() < popChance * 0.5 then
					inflating[player].popped = true
					inflating[player] = nil
					Remotes.Balloon_Result:FireClient(player, { type = "pop" })
					break
				end
			end
		end)
	end)

	Remotes.Balloon_Stop.OnServerEvent:Connect(function(player)
		if not inflating[player] or inflating[player].popped then
			return
		end

		local inflateTime = tick() - inflating[player].startTime
		local balloonName = inflating[player].balloonName
		inflating[player] = nil

		local config = BalloonConfig[balloonName]
		if not config then
			return
		end

		local inflatePercent = math.clamp(inflateTime / 60, 0, 1)
		local reward = EconomyService.CalcBalloonReward(config, inflateTime)
		EconomyService.AddCoins(player, reward)

		if math.random(1, GameConfig.ROULETTE_CHANCE) == 1 then
			local result = RouletteService.Roll(player, config.maxRarity, inflatePercent)
			if result.type == "pet" then
				PetService.AddPet(player, result)
			end
			Remotes.Balloon_Result:FireClient(player, { type = "roulette", result = result, reward = reward })
		else
			Remotes.Balloon_Result:FireClient(player, { type = "coins_only", reward = reward })
		end
	end)

	Remotes.Balloon_Equip.OnServerEvent:Connect(function(player, balloonName)
		local data = PlayerService.GetData(player)
		if not data then
			return
		end

		if not data.Balloons[balloonName] or data.Balloons[balloonName] <= 0 then
			return
		end

		if inflating[player] then
			return
		end

		PlayerService.SetData(player, {"ActiveBalloon"}, balloonName)
	end)
end

function getPopChance(popCurve, elapsed)
	if elapsed <= popCurve[1].time then
		return popCurve[1].chance
	end

	for i = 1, #popCurve - 1 do
		local a = popCurve[i]
		local b = popCurve[i + 1]
		if elapsed >= a.time and elapsed < b.time then
			local t = (elapsed - a.time) / (b.time - a.time)
			return a.chance + (b.chance - a.chance) * t
		end
	end

	return popCurve[#popCurve].chance
end

return BalloonService