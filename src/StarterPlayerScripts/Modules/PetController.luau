local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local PetController = {}

local location = Workspace:WaitForChild("Location")
local basesFolder = location:WaitForChild("Bases")
local incomeBillboardTemplate = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("UI"):WaitForChild("IncomeBillboardGui")

local assignedBaseId = nil
local cachedBaseSlots = 10
local cachedStandPets = {}

local incomeBillboards = {}
local displayTotal = {}
local touchConnections = {}

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

local function destroySlotUi(slotKey)
	local billboard = incomeBillboards[slotKey]
	if billboard then
		billboard:Destroy()
		incomeBillboards[slotKey] = nil
	end

	local conn = touchConnections[slotKey]
	if conn then
		conn:Disconnect()
		touchConnections[slotKey] = nil
	end

	displayTotal[slotKey] = nil
end

function PetController.RefreshStands(standPets, previousStandPets)
	if not assignedBaseId then return end

	local baseModel = basesFolder:FindFirstChild("Base" .. tostring(assignedBaseId))
	if not baseModel then
		warn("[PetController] Base model not found:", "Base" .. tostring(assignedBaseId))
		return
	end
	local baseArea = baseModel:FindFirstChild("BaseArea")
	if not baseArea then return end

	local desiredSlots = {}

	for slotIndex, petEntry in pairs(standPets) do
		local slotKey = tostring(slotIndex)
		desiredSlots[slotKey] = true

		local standSlot = baseArea:FindFirstChild("StandSlot_" .. tostring(slotIndex))
		if not standSlot then
			continue
		end

		local claimButton = standSlot:FindFirstChild("ClaimButton")
		if not claimButton then continue end

		local billboard = incomeBillboards[slotKey]
		local currentEntry = previousStandPets and previousStandPets[slotKey] or nil
		if not billboard then
			billboard = incomeBillboardTemplate:Clone()
			billboard.Adornee = claimButton
			billboard.Parent = claimButton
			billboard.Frame.AmmountLabel.Text = "0"
			incomeBillboards[slotKey] = billboard
			displayTotal[slotKey] = 0
		elseif currentEntry and currentEntry.uid ~= petEntry.uid then
			displayTotal[slotKey] = 0
			billboard.Frame.AmmountLabel.Text = "0"
		end

		if not touchConnections[slotKey] then
			touchConnections[slotKey] = claimButton.Touched:Connect(function(hit)
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

	for slotKey in pairs(incomeBillboards) do
		if not desiredSlots[slotKey] then
			destroySlotUi(slotKey)
		end
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
			local previousStandPets = cachedStandPets
			cachedStandPets = new
			PetController.RefreshStands(new, previousStandPets)
		end)

		replica:OnSet({"BaseSlots"}, function(new)
			cachedBaseSlots = new
		end)
	end)
end

local accum = 0

function PetController.Start()
	RunService.Heartbeat:Connect(function(dt)
		accum += dt
		if accum >= GameConfig.STAND_INCOME_INTERVAL then
			accum -= GameConfig.STAND_INCOME_INTERVAL
			for slotKey, billboard in pairs(incomeBillboards) do
				local petEntry = cachedStandPets[slotKey]
				if not petEntry then continue end
				local petConfig = getPetConfigByName(petEntry.name, petEntry.collectionName)
				if not petConfig then continue end
				displayTotal[slotKey] = (displayTotal[slotKey] or 0) + petConfig.standIncome
				local label = billboard.Frame.AmmountLabel
				label.Text = tostring(math.floor(displayTotal[slotKey]))
			end
		end
	end)
end

return PetController
