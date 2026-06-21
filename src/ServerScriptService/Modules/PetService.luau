local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerService = require(ServerScriptService.Modules.PlayerService)
local EconomyService = require(ServerScriptService.Modules.EconomyService)
local IndexService = require(ServerScriptService.Modules.IndexService)
local BaseService = require(ServerScriptService.Modules.BaseService)

local PetService = {}

local pendingIncome = {}

local location = Workspace:WaitForChild("Location")
local balloonStation = location:WaitForChild("BalloonStation")
local basesFolder = location:WaitForChild("Bases")
local petsAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Pets")

local activeStandModels = {}

function PetService.Init()
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

local function destroyStandModel(player, slotIndex)
	local models = activeStandModels[player]
	if not models then
		return
	end

	local model = models[tostring(slotIndex)]
	if model then
		if model.Parent then
			model:Destroy()
		end
		models[tostring(slotIndex)] = nil
	end
end

local function findPrimaryPart(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

local function createStandModel(player, petEntry, slotIndex)
	local baseId = BaseService.GetBaseId(player)
	if not baseId then
		return nil
	end

	local baseModel = basesFolder:FindFirstChild("Base" .. tostring(baseId))
	if not baseModel then
		return nil
	end

	local baseArea = baseModel:FindFirstChild("BaseArea")
	if not baseArea then
		return nil
	end

	local standSlot = baseArea:FindFirstChild("StandSlot_" .. tostring(slotIndex))
	if not standSlot then
		return nil
	end

	local standMesh = standSlot:FindFirstChild("StandMesh")
	if not standMesh then
		return nil
	end

	local template = petsAssets:FindFirstChild(petEntry.name)
	if not template then
		return nil
	end

	local petModel = template:Clone()
	petModel.Parent = Workspace

	local primaryPart = findPrimaryPart(petModel)
	if primaryPart then
		primaryPart.Position = standMesh.Position + Vector3.new(0, 3, 0)
		primaryPart.Anchored = true
		primaryPart.Rotation = standMesh.Rotation
	end

	activeStandModels[player] = activeStandModels[player] or {}
	activeStandModels[player][tostring(slotIndex)] = petModel

	local prompt = Instance.new("ProximityPrompt")
	prompt.Parent = primaryPart or petModel
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Triggered:Connect(function(triggeredPlayer)
		PetService.SellFromStand(triggeredPlayer, slotIndex)
	end)

	return petModel
end

function PetService.Start()
	Remotes.Pet_PlaceStand.OnServerEvent:Connect(function(player, slotIndex, petUid)
		PetService.PlaceOnStand(player, petUid, slotIndex)
	end)

	Remotes.Pet_RemoveStand.OnServerEvent:Connect(function(player, slotIndex)
		PetService.SellFromStand(player, slotIndex)
	end)

	Remotes.Pet_SpawnWorld.OnServerEvent:Connect(function(player, payload)
		if type(payload) ~= "table" or type(payload.uid) ~= "string" then
			return
		end

		local data = PlayerService.GetData(player)
		if not data then
			return
		end

		local entry = nil
		for _, e in pairs(data.StandPets) do
			if e.uid == payload.uid then
				entry = e
				break
			end
		end
		if not entry then
			return
		end

		PetService.SpawnWorldPet(player, entry)
	end)

	Remotes.Base_Collect.OnServerInvoke = function(player, slotIndex)
		local data = PlayerService.GetData(player)
		if not data then return 0 end

		local key = tostring(slotIndex)
		if not data.StandPets[key] then return 0 end

		local slotPending = pendingIncome[player] and pendingIncome[player][key] or 0
		if slotPending < 1 then return 0 end

		local floorAmount = math.floor(slotPending)
		pendingIncome[player] = pendingIncome[player] or {}
		pendingIncome[player][key] = slotPending - floorAmount

		EconomyService.AddCoins(player, floorAmount)
		return floorAmount
	end

	Players.PlayerRemoving:Connect(function(player)
		pendingIncome[player] = nil
		local models = activeStandModels[player]
		if models then
			for _, model in pairs(models) do
				if model and model.Parent then
					model:Destroy()
				end
			end
			activeStandModels[player] = nil
		end
	end)

	local function syncExistingStandModels(player)
		local data = PlayerService.GetData(player)
		if not data then
			return
		end

		activeStandModels[player] = activeStandModels[player] or {}

		for slotIndex, petEntry in pairs(data.StandPets) do
			local slotNum = tonumber(slotIndex)
			if slotNum and not activeStandModels[player][tostring(slotIndex)] then
				createStandModel(player, petEntry, slotNum)
			end
		end
	end

	PlayerService.PlayerDataReady:Connect(syncExistingStandModels)

	for _, player in ipairs(Players:GetPlayers()) do
		if PlayerService.GetData(player) then
			task.spawn(syncExistingStandModels, player)
		end
	end

	local lastTick = tick()
	RunService.Heartbeat:Connect(function()
		local now = tick()
		local dt = now - lastTick
		lastTick = now

		for _, player in ipairs(Players:GetPlayers()) do
			local data = PlayerService.GetData(player)
			if not data then continue end
			for slotIndex, petEntry in pairs(data.StandPets) do
				local petConfig = findPetConfig(petEntry.name, petEntry.collectionName)
				if not petConfig then continue end
				pendingIncome[player] = pendingIncome[player] or {}
				pendingIncome[player][slotIndex] = (pendingIncome[player][slotIndex] or 0) + petConfig.standIncome * dt
			end
		end
	end)
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

	for i = 1, data.BaseSlots do
		if data.StandPets[tostring(i)] == nil then
			data.StandPets[tostring(i)] = entry
			break
		end
	end

	IndexService.AddToIndex(player, petResult.name)

	PlayerService.GetReplica(player):Set({"StandPets"}, data.StandPets)
	return entry
end

function PetService.CommitPetToStand(player, petResult, slotIndex)
	local data = PlayerService.GetData(player)
	if not data then
		return nil
	end

	if slotIndex > data.BaseSlots then
		return nil
	end

	if data.StandPets[tostring(slotIndex)] ~= nil then
		return nil
	end

	local entry = {
		uid = generateUid(),
		name = petResult.name,
		rarity = petResult.rarity,
		collectionName = petResult.collectionName,
	}

	data.StandPets[tostring(slotIndex)] = entry

	IndexService.AddToIndex(player, petResult.name)

	PlayerService.GetReplica(player):Set({"StandPets"}, data.StandPets)

	local model = createStandModel(player, entry, slotIndex)

	return entry, model
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

	local entry = nil
	local currentSlot = nil
	for slotKey, petEntry in pairs(data.StandPets) do
		if petEntry.uid == petUid then
			entry = petEntry
			currentSlot = slotKey
			break
		end
	end

	if not entry then
		return false
	end

	if currentSlot then
		destroyStandModel(player, tonumber(currentSlot))
		data.StandPets[currentSlot] = nil
	end

	data.StandPets[tostring(slotIndex)] = entry
	createStandModel(player, entry, slotIndex)

	local replica = PlayerService.GetReplica(player)
	replica:Set({"StandPets"}, data.StandPets)
	return true
end

function PetService.SellFromStand(player, slotIndex)
	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	local entry = data.StandPets[tostring(slotIndex)]
	if not entry then
		return false
	end

	local petConfig = findPetConfig(entry.name, entry.collectionName)
	local price = petConfig and petConfig.cost or 0

	destroyStandModel(player, slotIndex)
	data.StandPets[tostring(slotIndex)] = nil

	EconomyService.AddCoins(player, price)

	local replica = PlayerService.GetReplica(player)
	replica:Set({"StandPets"}, data.StandPets)
	return true
end

function PetService.SpawnWorldPet(player, petEntry)
	local spawnArea = balloonStation:FindFirstChild("SpawnPets")
	if not spawnArea then
		return nil
	end

	local half = spawnArea.Size / 2
	local randPos = spawnArea.Position + Vector3.new(
		math.random() * spawnArea.Size.X - half.X,
		0,
		math.random() * spawnArea.Size.Z - half.Z
	)

	local template = petsAssets:FindFirstChild(petEntry.name)
	if not template then
		return nil
	end

	local petModel = template:Clone()
	petModel.Parent = Workspace

	local primaryPart = findPrimaryPart(petModel)
	if primaryPart then
		primaryPart.Position = randPos
		primaryPart.Anchored = true
	end

	task.delay(5, function()
		if petModel and petModel.Parent then
			petModel:Destroy()
		end
	end)

	return petModel
end

function PetService.SellPet(player, petUid)
	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	for slotKey, entry in pairs(data.StandPets) do
		if entry.uid == petUid then
			local petConfig = findPetConfig(entry.name, entry.collectionName)
			local price = petConfig and petConfig.cost or 0
			destroyStandModel(player, tonumber(slotKey))
			data.StandPets[slotKey] = nil
			EconomyService.AddCoins(player, price)
			PlayerService.GetReplica(player):Set({"StandPets"}, data.StandPets)
			return true
		end
	end

	return false
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