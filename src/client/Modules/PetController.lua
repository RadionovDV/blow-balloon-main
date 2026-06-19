local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StatefulObjectController = require(script.Parent.StatefulObjectController)

local PetController = {}

local location = Workspace:WaitForChild("Location")
local balloonStation = location:WaitForChild("BalloonStation")
local basesFolder = location:WaitForChild("Bases")
local petsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Pets")
local billboardTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UI"):WaitForChild("PetBillboardGui")
local incomeBillboardTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UI"):WaitForChild("IncomeBillboardGui")

local spawnedStandModels = {}
local activePetSpawns = {}
local assignedBaseId = nil
local cachedBaseSlots = 10
local cachedStandPets = {}

local incomeBillboards = {}
local displayTotal = {}

local function findPrimaryPart(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

local function getPetConfigByName(name, collectionName)
	local collection = PetConfig[collectionName]
	if not collection then return nil end
	for _, pet in ipairs(collection) do
		if pet.name == name then
			return pet
		end
	end
	return nil
end

function PetController.SpawnAndRun(petResult)
	local spawnArea = balloonStation:WaitForChild("SpawnPets")
	local half = spawnArea.Size / 2
	local randPos = spawnArea.Position + Vector3.new(
		math.random() * spawnArea.Size.X - half.X,
		0,
		math.random() * spawnArea.Size.Z - half.Z
	)

	local template = petsFolder:FindFirstChild(petResult.name)
	if not template then
		warn("[PetController] Pet model not found:", petResult.name)
		return
	end

	local petModel = template:Clone()
	petModel.Parent = workspace
	local primaryPart = findPrimaryPart(petModel)
	if primaryPart then
		primaryPart.Position = randPos
		primaryPart.Anchored = true
	end

	local billboard = billboardTemplate:Clone()
	billboard.Parent = petModel
	local nameLabel = billboard:FindFirstChild("NameLabel")
	local rarityLabel = billboard:FindFirstChild("RarityLabel")
	local collectionLabel = billboard:FindFirstChild("CollectionLabel")
	local incomeLabel = billboard:FindFirstChild("IncomeLabel")
	local costLabel = billboard:FindFirstChild("CostLabel")

	if nameLabel then nameLabel.Text = petResult.name end
	if rarityLabel then
		rarityLabel.Text = petResult.rarity
		rarityLabel.TextColor3 = GameConfig.GetRarityColor(petResult.rarity)
	end
	if collectionLabel then collectionLabel.Text = petResult.collectionName end

	local petConfig = getPetConfigByName(petResult.name, petResult.collectionName)
	if petConfig then
		if incomeLabel then incomeLabel.Text = tostring(petConfig.standIncome) end
		if costLabel then costLabel.Text = tostring(petConfig.cost) end
	end

	local targetSlot = nil
	for i = 1, cachedBaseSlots do
		if not cachedStandPets[tostring(i)] then
			targetSlot = i
			break
		end
	end

	if targetSlot and petResult.uid then
		Remotes.Pet_PlaceStand:FireServer(targetSlot, petResult.uid)
	end

	local spawnId = tostring(tick())
	activePetSpawns[spawnId] = petModel

	task.delay(2.5, function()
		if not activePetSpawns[spawnId] then return end
		activePetSpawns[spawnId] = nil
		local part = findPrimaryPart(petModel)
		if part then
			StatefulObjectController.Tween(part, { Transparency = 1 }, 0.5)
		end
		task.wait(0.5)
		petModel:Destroy()
	end)
end

function PetController.RefreshStands(standPets)
	if not assignedBaseId then return end

	for slotKey, model in pairs(spawnedStandModels) do
		model:Destroy()
		spawnedStandModels[slotKey] = nil
	end
	for slotKey, billboard in pairs(incomeBillboards) do
		billboard:Destroy()
		incomeBillboards[slotKey] = nil
	end
	table.clear(displayTotal)

	local baseModel = basesFolder:FindFirstChild("Base" .. tostring(assignedBaseId))
	if not baseModel then
		warn("[PetController] Base model not found:", "Base" .. tostring(assignedBaseId))
		return
	end
	local baseArea = baseModel:FindFirstChild("BaseArea")
	if not baseArea then return end

	for slotIndex, petEntry in pairs(standPets) do
		local standSlot = baseArea:FindFirstChild("StandSlot_" .. tostring(slotIndex))
		if not standSlot then
			continue
		end

		local template = petsFolder:FindFirstChild(petEntry.name)
		if not template then
			warn("[PetController] Pet model not found for stand:", petEntry.name)
			continue
		end

		local petModel = template:Clone()
		petModel.Parent = workspace
		local primaryPart = findPrimaryPart(petModel)
		if primaryPart then
			primaryPart.Position = standSlot.Position + Vector3.new(0, 1, 0)
			primaryPart.Anchored = true
		end

		spawnedStandModels[slotIndex] = petModel

		local claimButton = standSlot:FindFirstChild("ClaimButton")
		if not claimButton then continue end

		local billboard = incomeBillboardTemplate:Clone()
		billboard.Adornee = claimButton
		billboard.Parent = claimButton
		billboard.Frame.AmmountLabel.Text = "0"
		incomeBillboards[tostring(slotIndex)] = billboard

		claimButton.Touched:Connect(function(hit)
			local character = Players.LocalPlayer.Character
			if not character then return end
			if hit ~= character:FindFirstChild("HumanoidRootPart") then return end

			task.spawn(function()
				local earned = Remotes.Base_Collect:InvokeServer(slotIndex)
				if earned > 0 then
					local key = tostring(slotIndex)
					displayTotal[key] = 0
					local b = incomeBillboards[key]
					if b then
						b.Frame.AmmountLabel.Text = "0"
					end
				end
			end)
		end)
	end
end

function PetController.Init()
	Remotes.Base_Assigned.OnClientEvent:Connect(function(baseId)
		assignedBaseId = baseId
		PetController.RefreshStands(cachedStandPets)
	end)

	ReplicaClient.OnNew("PlayerData", function(replica)
		cachedStandPets = replica.Data.StandPets or {}
		cachedBaseSlots = replica.Data.BaseSlots or 10
		PetController.RefreshStands(cachedStandPets)

		replica:OnSet({"StandPets"}, function(new)
			cachedStandPets = new
			for _, billboard in pairs(incomeBillboards) do
				billboard:Destroy()
			end
			table.clear(incomeBillboards)
			table.clear(displayTotal)
			PetController.RefreshStands(new)
		end)

		replica:OnSet({"BaseSlots"}, function(new)
			cachedBaseSlots = new
		end)
	end)
end

function PetController.Start()
	RunService.Heartbeat:Connect(function(dt)
		local interval = GameConfig.STAND_INCOME_INTERVAL
		for slotKey, billboard in pairs(incomeBillboards) do
			local petEntry = cachedStandPets[slotKey]
			if not petEntry then continue end
			local petConfig = getPetConfigByName(petEntry.name, petEntry.collectionName)
			if not petConfig then continue end
			displayTotal[slotKey] = (displayTotal[slotKey] or 0) + petConfig.standIncome * dt
			if displayTotal[slotKey] >= interval then
				local label = billboard.Frame.AmmountLabel
				label.Text = tostring(math.floor(displayTotal[slotKey]))
				displayTotal[slotKey] = 0
			end
		end
	end)
end

return PetController