local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

local MonetizationConfig = require(ReplicatedStorage.Shared.Config.MonetizationConfig)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerService = require(ServerScriptService.Modules.PlayerService)
local PetService = require(ServerScriptService.Modules.PetService)
local EconomyService = require(ServerScriptService.Modules.EconomyService)
local PetMovementService = require(ServerScriptService.Modules.PetMovementService)

local StrayPetService = {}

local strayPets = {}
local nextUid = 0

local location = Workspace:WaitForChild("Location")
local balloonStation = location:WaitForChild("BalloonStation")
local petsAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Pets")

local function generateStrayUid()
	nextUid += 1
	return "stray_" .. tostring(nextUid) .. "_" .. tostring(math.floor(tick() * 1000))
end

local function findPrimaryPart(model)
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			return descendant
		end
	end
	return nil
end

local function setTransparency(model, transparency)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Transparency = transparency
		end
	end
end

local function removeStray(uid)
	local stray = strayPets[uid]
	if not stray then
		return
	end

	if stray.model and stray.model.Parent then
		stray.model:Destroy()
	end

	if stray.wanderConnection then
		stray.wanderConnection:Disconnect()
	end

	strayPets[uid] = nil
end

local function ownerCanClaim(uid, player)
	local stray = strayPets[uid]
	if not stray then
		return false
	end
	return stray.ownerPlayer == player
end

function StrayPetService.CreateStray(player, petResult)
	local uid = generateStrayUid()

	local template = petsAssets:FindFirstChild(petResult.name)
	if not template then
		return nil
	end

	local data = PlayerService.GetData(player)
	local savePets = false
	if data then
		local now = os.time()
		for _, boost in ipairs(data.MonetizationEntitlements.Timed) do
			if boost.id == "SavePets" and boost.expiresAt > now then
				savePets = true
				break
			end
		end
	end

	local petModel = template:Clone()
	petModel.Parent = Workspace

	for _, desc in ipairs(petModel:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = false
		end
	end

	local spawnArea = balloonStation:FindFirstChild("SpawnPets")
	if spawnArea then
		local half = spawnArea.Size / 2
		local randPos = spawnArea.Position + Vector3.new(
			math.random() * spawnArea.Size.X - half.X,
			0,
			math.random() * spawnArea.Size.Z - half.Z
		)
		local primaryPart = findPrimaryPart(petModel)
		if primaryPart then
			primaryPart.Position = randPos
		end
	end

	if savePets then
		setTransparency(petModel, 0.5)
	end

	local stray = {
		uid = uid,
		petName = petResult.name,
		rarity = petResult.rarity,
		collectionName = petResult.collectionName,
		ownerPlayer = player,
		savePets = savePets,
		model = petModel,
	}

	local primaryPart = findPrimaryPart(petModel)
	local attachTo = primaryPart or petModel

	local buyPrompt = Instance.new("ProximityPrompt")
	buyPrompt.Name = "Buy"
	buyPrompt.Parent = attachTo
	buyPrompt.MaxActivationDistance = 8
	buyPrompt.RequiresLineOfSight = false
	buyPrompt.ActionText = "Buy"
	buyPrompt.ObjectText = petResult.name .. " ($" .. tostring(MonetizationConfig.STRAY_PRICES[petResult.rarity] or 100) .. ")"

	if savePets then
		buyPrompt.Enabled = false
	end

	buyPrompt.Triggered:Connect(function(triggeredPlayer)
		if buyPrompt.Enabled == false then
			return
		end
		if triggeredPlayer ~= player then
			StrayPetService.BuyStray(uid, triggeredPlayer)
		end
	end)
	stray.buyPrompt = buyPrompt

	local claimPrompt = Instance.new("ProximityPrompt")
	claimPrompt.Name = "Claim"
	claimPrompt.Parent = attachTo
	claimPrompt.MaxActivationDistance = 8
	claimPrompt.RequiresLineOfSight = false
	claimPrompt.ActionText = "Claim"
	claimPrompt.ObjectText = "Claim " .. petResult.name

	claimPrompt.Triggered:Connect(function(triggeredPlayer)
		if triggeredPlayer == player then
			StrayPetService.ClaimStray(uid, triggeredPlayer)
		end
	end)
	stray.claimPrompt = claimPrompt

	local cleanupDelay = 120
	task.delay(cleanupDelay, function()
		if strayPets[uid] then
			removeStray(uid)
		end
	end)

	strayPets[uid] = stray

	return uid, stray
end

function StrayPetService.BuyStray(uid, player)
	local stray = strayPets[uid]
	if not stray then
		Remotes.Notification:FireClient(player, { text = "This pet is no longer available" })
		return false
	end

	if stray.savePets then
		Remotes.Notification:FireClient(player, { text = "This pet is protected by Save Pets" })
		return false
	end

	if stray.ownerPlayer == player then
		return false
	end

	local price = MonetizationConfig.STRAY_PRICES[stray.rarity]
	if not price then
		return false
	end

	if not EconomyService.SpendCoins(player, price) then
		Remotes.Notification:FireClient(player, { text = "Not enough coins!" })
		return false
	end

	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	local petConfig = PetConfig.GetPetByName(stray.petName)
	if petConfig then
		PetService.AddPet(player, {
			name = stray.petName,
			rarity = stray.rarity,
			collectionName = stray.collectionName or "Base",
		})
		Remotes.Notification:FireClient(player, { text = "You bought " .. stray.petName .. "!" })
	else
		EconomyService.AddCoins(player, price)
		Remotes.Notification:FireClient(player, { text = "Pet not found, coins refunded" })
	end

	removeStray(uid)
	return true
end

function StrayPetService.ClaimStray(uid, player)
	local stray = strayPets[uid]
	if not stray then
		Remotes.Notification:FireClient(player, { text = "This pet is no longer available" })
		return false
	end

	if stray.ownerPlayer ~= player then
		return false
	end

	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	local petConfig = PetConfig.GetPetByName(stray.petName)
	if petConfig then
		PetService.AddPet(player, {
			name = stray.petName,
			rarity = stray.rarity,
			collectionName = stray.collectionName or "Base",
		})
		Remotes.Notification:FireClient(player, { text = stray.petName .. " returned to your base!" })
	else
		Remotes.Notification:FireClient(player, { text = "Pet not found" })
	end

	removeStray(uid)
	return true
end

function StrayPetService.Init()
	Remotes.StrayPet_Buy.OnServerEvent:Connect(function(player, payload)
		if type(payload) ~= "table" or type(payload.strayUid) ~= "string" then
			return
		end
		StrayPetService.BuyStray(payload.strayUid, player)
	end)

	Remotes.StrayPet_Claim.OnServerEvent:Connect(function(player, payload)
		if type(payload) ~= "table" or type(payload.strayUid) ~= "string" then
			return
		end
		StrayPetService.ClaimStray(payload.strayUid, player)
	end)
end

function StrayPetService.Start()
	Players.PlayerRemoving:Connect(function(player)
		for uid, stray in pairs(strayPets) do
			if stray.ownerPlayer == player then
				removeStray(uid)
			end
		end
	end)
end

return StrayPetService