local RarityUtil = {}

local RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

local function getRarityIndex(rarity)
	for i, name in ipairs(RARITIES) do
		if name == rarity then
			return i
		end
	end
	return 0
end

function RarityUtil.FilterByMaxRarity(collection, maxRarity)
	local maxIndex = getRarityIndex(maxRarity)
	local result = {}
	for _, pet in ipairs(collection) do
		if getRarityIndex(pet.rarity) <= maxIndex then
			table.insert(result, pet)
		end
	end
	return result
end

function RarityUtil.WeightedPick(candidates, luck)
	if #candidates == 0 then
		return nil
	end

	local totalWeight = 0
	local weights = {}

	for i, pet in ipairs(candidates) do
		local rarityIndex = #RARITIES - getRarityIndex(pet.rarity)
		local adjustedWeight = pet.rarityWeight * (1 + luck * rarityIndex * 0.1)
		table.insert(weights, adjustedWeight)
		totalWeight = totalWeight + adjustedWeight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	for i, pet in ipairs(candidates) do
		cumulative = cumulative + weights[i]
		if roll <= cumulative then
			return pet
		end
	end

	return candidates[#candidates]
end

return RarityUtil