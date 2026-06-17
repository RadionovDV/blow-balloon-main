local PetConfig = require(script.Parent.Parent.Config.PetConfig)

local RarityUtil = {}

function RarityUtil.FilterByMaxRarity(collection, maxRarity)
	local maxIndex = 0
	for i, rarity in ipairs(PetConfig.RARITIES) do
		if rarity == maxRarity then
			maxIndex = i
			break
		end
	end

	local result = {}
	for _, pet in ipairs(collection) do
		local petIndex = 0
		for i, rarity in ipairs(PetConfig.RARITIES) do
			if rarity == pet.rarity then
				petIndex = i
				break
			end
		end
		if petIndex <= maxIndex then
			table.insert(result, pet)
		end
	end
	return result
end

function RarityUtil.WeightedPick(candidates, luck)
	local totalWeight = 0
	local adjusted = {}

	for i = #candidates, 1, -1 do
		local pet = candidates[i]
		local rarityIndex = 0
		for j, rarity in ipairs(PetConfig.RARITIES) do
			if rarity == pet.rarity then
				rarityIndex = j
				break
			end
		end
		local weight = pet.rarityWeight * (1 + luck * rarityIndex * 0.1)
		table.insert(adjusted, { pet = pet, weight = weight })
		totalWeight = totalWeight + weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0
	for _, entry in ipairs(adjusted) do
		cumulative = cumulative + entry.weight
		if roll <= cumulative then
			return entry.pet
		end
	end

	return candidates[#candidates]
end

return RarityUtil