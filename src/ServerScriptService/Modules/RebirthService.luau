local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RebirthConfig = require(ReplicatedStorage.Shared.Config.RebirthConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerService = require(ServerScriptService.Modules.PlayerService)

local RebirthService = {}

function RebirthService.Init()
end

function RebirthService.Start()
	Remotes.Rebirth_Perform.OnServerInvoke = function(player)
		return RebirthService.PerformRebirth(player)
	end
end

function RebirthService.GetTierForPlayer(player)
	local data = PlayerService.GetData(player)
	if not data then
		return nil
	end

	local tierIndex = math.min(data.RebirthCount + 1, #RebirthConfig.Tiers)
	return RebirthConfig.Tiers[tierIndex]
end

function RebirthService.CanRebirth(player)
	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	local tier = RebirthService.GetTierForPlayer(player)
	if not tier then
		return false
	end

	if data.Coins < tier.cost then
		return false
	end

	for _, petName in ipairs(tier.requiredPets) do
		local owned = false
		for _, petEntry in ipairs(data.StandPets) do
			if petEntry.name == petName then
				owned = true
				break
			end
		end
		if not owned then
			return false
		end
	end

	return true
end

function RebirthService.PerformRebirth(player)
	if not RebirthService.CanRebirth(player) then
		return false
	end

	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	local tier = RebirthService.GetTierForPlayer(player)
	if not tier then
		return false
	end

	data.RebirthCount = data.RebirthCount + 1
	data.BaseLuck = data.BaseLuck * tier.luckMultiplier
	data.StandPets = {}
	data.StandPets = {}
	data.Coins = 0
	data.Balloons = { Default = 1 }
	data.ActiveBalloon = "Default"

	if PlayerService.HasPass(player, "StarterPack") then
		data.Coins = tier.starterPackCash
	end

	local replica = PlayerService.GetReplica(player)
	replica:Set({"RebirthCount"}, data.RebirthCount)
	replica:Set({"BaseLuck"}, data.BaseLuck)
	replica:Set({"StandPets"}, data.StandPets)
	replica:Set({"Coins"}, data.Coins)
	replica:Set({"Balloons"}, data.Balloons)
	replica:Set({"ActiveBalloon"}, data.ActiveBalloon)

	return true
end

return RebirthService