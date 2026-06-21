local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local RarityUtil = require(ReplicatedStorage.Shared.Util.RarityUtil)
local LuckService = require(ServerScriptService.Modules.LuckService)

local RouletteService = {}

function RouletteService.Init()
end

function RouletteService.Start()
end

function RouletteService.Roll(player, maxRarity, inflatePercent)
	if math.random() < GameConfig.BOMB_CHANCE then
		return { type = "bomb" }
	end

	local keyChance = GameConfig.KEY_CHANCE
		+ (GameConfig.KEY_CHANCE_MAX_INFLATE - GameConfig.KEY_CHANCE) * inflatePercent
	if math.random() < keyChance then
		return { type = "key" }
	end

	local allCollections = {}
	for collectionName, collection in pairs(PetConfig) do
		if type(collection) == "table" and collectionName ~= "RARITIES" then
			local filtered = RarityUtil.FilterByMaxRarity(collection, maxRarity)
			for _, pet in ipairs(filtered) do
				table.insert(allCollections, { pet = pet, collectionName = collectionName })
			end
		end
	end

	local luck = LuckService.GetLuck(player, 0)
	local chosen = RarityUtil.WeightedPickFromAll(allCollections, luck)
	return {
		type = "pet",
		name = chosen.pet.name,
		rarity = chosen.pet.rarity,
		collectionName = chosen.collectionName,
	}
end

return RouletteService