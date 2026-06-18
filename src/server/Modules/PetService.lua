local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerService = require(ServerScriptService.Modules.PlayerService)
local EconomyService = require(ServerScriptService.Modules.EconomyService)

local PetService = {}

function PetService.Init()
end

function PetService.Start()
	Remotes.Pet_PlaceStand.OnServerEvent:Connect(function(player, slotIndex, petUid)
		PetService.PlaceOnStand(player, petUid, slotIndex)
	end)

	Remotes.Pet_RemoveStand.OnServerEvent:Connect(function(player, slotIndex)
		PetService.RemoveFromStand(player, slotIndex)
	end)

	Remotes.Base_Collect.OnServerEvent:Connect(function(player)
		local earned = PetService.CollectIncome(player)
		if earned > 0 then
			Remotes.Notification:FireClient(player, {
				text = "+" .. earned .. " монет со стендов!",
				style = "income"
			})
		end
	end)
end

local function generateUid()
	return tostring(math.floor(tick() * 1000)) .. "_" .. tostring(math.random(1000, 9999))
end

local function findPetConfig(name, collectionName)
	local collection = PetConfig[collectionName]
	if not collection then
		return nil
	end
	for _, pet in ipairs(collection) do
		if pet.name == name then
			return pet
		end
	end
	return nil
end

function PetService.AddPet(player, petResult)
	local data = PlayerService.GetData(player)
	if not data then
		return nil
	end

	local entry = {
		uid = generateUid(),
		name = petResult.name,
		rarity = petResult.rarity,
		collectionName = petResult.collectionName,
	}
	table.insert(data.Pets, entry)
	PlayerService.GetReplica(player):Set({"Pets"}, data.Pets)
	return entry
end

function PetService.PlaceOnStand(player, petUid, slotIndex)
	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	if slotIndex > data.BaseSlots then
		return false
	end

	if data.StandPets[tostring(slotIndex)] ~= nil then
		return false
	end

	local petIndex = nil
	for i, entry in ipairs(data.Pets) do
		if entry.uid == petUid then
			petIndex = i
			break
		end
	end

	if not petIndex then
		return false
	end

	local entry = table.remove(data.Pets, petIndex)
	data.StandPets[tostring(slotIndex)] = entry

	local replica = PlayerService.GetReplica(player)
	replica:Set({"Pets"}, data.Pets)
	replica:Set({"StandPets"}, data.StandPets)
	return true
end

function PetService.RemoveFromStand(player, slotIndex)
	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	local entry = data.StandPets[tostring(slotIndex)]
	if not entry then
		return false
	end

	data.StandPets[tostring(slotIndex)] = nil
	table.insert(data.Pets, entry)

	local replica = PlayerService.GetReplica(player)
	replica:Set({"Pets"}, data.Pets)
	replica:Set({"StandPets"}, data.StandPets)
	return true
end

function PetService.SellPet(player, petUid)
	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	for i, entry in ipairs(data.Pets) do
		if entry.uid == petUid then
			local petConfig = findPetConfig(entry.name, entry.collectionName)
			local price = petConfig and petConfig.cost or 0
			table.remove(data.Pets, i)
			EconomyService.AddCoins(player, price)
			PlayerService.GetReplica(player):Set({"Pets"}, data.Pets)
			return true
		end
	end

	return false
end

function PetService.CollectIncome(player)
	local data = PlayerService.GetData(player)
	if not data then
		return 0
	end

	local total = 0
	for slotIndex, petEntry in pairs(data.StandPets) do
		local petConfig = findPetConfig(petEntry.name, petEntry.collectionName)
		if petConfig then
			total = total + petConfig.standIncome
		end
	end

	if total > 0 then
		EconomyService.AddCoins(player, total)
	end

	return total
end

function PetService.UpgradeBase(player)
	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	data.BaseSlots = data.BaseSlots + 1
	data.BaseLevel = math.ceil(data.BaseSlots / GameConfig.BASE_SLOTS_PER_FLOOR)

	local replica = PlayerService.GetReplica(player)
	replica:Set({"BaseSlots"}, data.BaseSlots)
	replica:Set({"BaseLevel"}, data.BaseLevel)
	return true
end

return PetService