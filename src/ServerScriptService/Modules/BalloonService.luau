local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BalloonConfig = require(ReplicatedStorage.Shared.Config.BalloonConfig)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerService = require(ServerScriptService.Modules.PlayerService)
local EconomyService = require(ServerScriptService.Modules.EconomyService)
local RouletteService = require(ServerScriptService.Modules.RouletteService)
local PetService = require(ServerScriptService.Modules.PetService)
local PendingPetService = require(ServerScriptService.Modules.PendingPetService)
local PetMovementService = require(ServerScriptService.Modules.PetMovementService)
local StrayPetService = require(ServerScriptService.Modules.StrayPetService)

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

		if activeBalloon ~= "Default" then
			data.Balloons[activeBalloon] -= 1
		end
		PlayerService.SetData(player, {"Balloons"}, data.Balloons)

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
			result.icon = ""
			if result.type == "pet" then
				PendingPetService.SetPending(player, result)
				result.icon = PetConfig.GetPetByName(result.name).icon or ""
			end
			local skipAnimation = PlayerService.HasPass(player, "SkipRollAnimation")
			Remotes.Balloon_Result:FireClient(player, { type = "roulette", result = result, reward = reward, skipAnimation = skipAnimation })
		else
			-- Check if EnsureRoll is active — if so, force roulette
			local data = PlayerService.GetData(player)
			if data then
				local now = os.time()
				for _, boost in ipairs(data.MonetizationEntitlements.Timed) do
					if boost.id == "EnsureRoll" and boost.expiresAt > now then
						local result = RouletteService.Roll(player, config.maxRarity, 1)
						result.icon = ""
						if result.type == "pet" then
							PendingPetService.SetPending(player, result)
							result.icon = PetConfig.GetPetByName(result.name).icon or ""
						end
						Remotes.Balloon_Result:FireClient(player, { type = "roulette", result = result, reward = reward })
						return
					end
				end
			end
			Remotes.Balloon_Result:FireClient(player, { type = "coins_only", reward = reward })
		end
	end)

	Remotes.Roulette_ResolvePetChoice.OnServerInvoke = function(player, payload)
		if type(payload) ~= "table" or payload.choice ~= "take" and payload.choice ~= "leave" then
			return { success = false }
		end

		local pendingResult = PendingPetService.GetPending(player)
		if not pendingResult or pendingResult.type ~= "pet" then
			return { success = false }
		end

		if payload.choice == "take" then
			local data = PlayerService.GetData(player)
			if not data then
				return { success = false }
			end

			local freeSlot = nil
			for i = 1, data.BaseSlots do
				if data.StandPets[tostring(i)] == nil then
					freeSlot = i
					break
				end
			end

			if freeSlot then
				local petModel = PetMovementService.SpawnAtSpawnPets(pendingResult.name)
				PetMovementService.MoveToBase(player, petModel, function()
					PetService.CommitPetToStand(player, pendingResult, freeSlot)
					if petModel and petModel.Parent then
						petModel:Destroy()
					end
				end)
				return { success = true }
			else
				Remotes.Notification:FireClient(player, {
					text = "Игрок физически не может забрать питомца, из-за нехватки мест на стендах",
				})
				local petModel = PetMovementService.SpawnAtSpawnPets(pendingResult.name)
				PetMovementService.WanderAndDespawn(petModel)
				return { success = false, reason = "no_slots" }
			end
		end

		if payload.choice == "leave" then
			StrayPetService.CreateStray(player, pendingResult)
			return { success = true }
		end

		return { success = false }
	end

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

	Remotes.Shop_BuyBalloon.OnServerInvoke = function(player, payload)
		if type(payload) ~= "table" or type(payload.balloonName) ~= "string" then
			return false
		end

		local balloonName = payload.balloonName

		if balloonName == "Default" then
			return false
		end

		local config = BalloonConfig[balloonName]
		if not config then
			return false
		end

		local data = PlayerService.GetData(player)
		if not data then
			return false
		end

		if not EconomyService.SpendCoins(player, config.price) then
			return false
		end

		data.Balloons[balloonName] = (data.Balloons[balloonName] or 0) + 1
		PlayerService.SetData(player, {"Balloons"}, data.Balloons)

		return true
	end
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