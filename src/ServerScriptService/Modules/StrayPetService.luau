local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")

local MonetizationConfig = require(ReplicatedStorage.Shared.Config.MonetizationConfig)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerService = require(ServerScriptService.Modules.PlayerService)
local PetService = require(ServerScriptService.Modules.PetService)
local PetMovementService = require(ServerScriptService.Modules.PetMovementService)

local StrayPetService = {}

local strayPets = {}
local nextUid = 0
local pendingPurchases = {}
local rng = Random.new()

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
			rng:NextNumber() * spawnArea.Size.X - half.X,
			0,
			rng:NextNumber() * spawnArea.Size.Z - half.Z
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

	attachTo:SetAttribute("OwnerUserId", player.UserId)
	attachTo:SetAttribute("StrayPrice", MonetizationConfig.STRAY_PRICES[petResult.rarity].priceRobux)
	attachTo:SetAttribute("SavePetsActive", savePets)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Parent = attachTo
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.ActionText = "Interact"
	prompt.ObjectText = petResult.name

	if savePets then
		prompt.Enabled = false
	end

	prompt.Triggered:Connect(function(triggeredPlayer)
		if prompt.Enabled == false then return end
		if triggeredPlayer == player then
			StrayPetService.ClaimStray(uid, triggeredPlayer)
		else
			StrayPetService.BuyStray(uid, triggeredPlayer)
		end
	end)
	stray.prompt = prompt

	stray.wanderConnection = PetMovementService.WanderStray(petModel)

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

	if pendingPurchases[player.UserId] then
		return false
	end

	local priceInfo = MonetizationConfig.STRAY_PRICES[stray.rarity]
	if not priceInfo or not priceInfo.productId then
		return false
	end

	pendingPurchases[player.UserId] = {
		uid = uid,
		productId = priceInfo.productId,
	}

	MarketplaceService:PromptProductPurchase(player, priceInfo.productId)
	return true
end

function StrayPetService.GrantStrayPurchase(player, productId)
	local pending = pendingPurchases[player.UserId]
	if not pending or pending.productId ~= productId then
		return false
	end

	pendingPurchases[player.UserId] = nil

	local stray = strayPets[pending.uid]
	if not stray then
		Remotes.Notification:FireClient(player, { text = "This pet is no longer available" })
		return false
	end

	local petConfig = PetConfig.GetPetByName(stray.petName)
	if petConfig then
		local entry = PetService.AddPet(player, {
			name = stray.petName,
			rarity = stray.rarity,
			collectionName = stray.collectionName or "Base",
		})
		if entry then
			local data = PlayerService.GetData(player)
			if data then
				for slotKey, pet in pairs(data.StandPets) do
					if pet.uid == entry.uid then
						PetService.CreateStandModel(player, entry, tonumber(slotKey))
						break
					end
				end
			end
			Remotes.Notification:FireClient(player, { text = "You bought " .. stray.petName .. "!" })
		else
			Remotes.Notification:FireClient(player, { text = "No free stand slots!" })
		end
	else
		Remotes.Notification:FireClient(player, { text = "Pet not found" })
	end

	removeStray(pending.uid)
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
		local entry = PetService.AddPet(player, {
			name = stray.petName,
			rarity = stray.rarity,
			collectionName = stray.collectionName or "Base",
		})
		if entry then
			for slotKey, pet in pairs(data.StandPets) do
				if pet.uid == entry.uid then
					PetService.CreateStandModel(player, entry, tonumber(slotKey))
					break
				end
			end
			Remotes.Notification:FireClient(player, { text = stray.petName .. " returned to your base!" })
		else
			Remotes.Notification:FireClient(player, { text = "No free stand slots!" })
		end
	else
		Remotes.Notification:FireClient(player, { text = "Pet not found" })
	end

	removeStray(uid)
	return true
end

function StrayPetService.ApplySavePetsTransparency(player)
	for _, stray in pairs(strayPets) do
		if stray.ownerPlayer == player then
			stray.savePets = true
			setTransparency(stray.model, 0.5)
			if stray.prompt then
				stray.prompt.Enabled = false
			end
			local attach = findPrimaryPart(stray.model) or stray.model
			attach:SetAttribute("SavePetsActive", true)
		end
	end
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
		pendingPurchases[player.UserId] = nil
		for uid, stray in pairs(strayPets) do
			if stray.ownerPlayer == player then
				removeStray(uid)
			end
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		local data = PlayerService.GetData(player)
		if data then
			local now = os.time()
			for _, boost in ipairs(data.MonetizationEntitlements.Timed) do
				if boost.id == "SavePets" and boost.expiresAt > now then
					StrayPetService.ApplySavePetsTransparency(player)
					break
				end
			end
		end
	end
end

return StrayPetService