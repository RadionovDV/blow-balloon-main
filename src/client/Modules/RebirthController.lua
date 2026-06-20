local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
local RebirthConfig = require(ReplicatedStorage.Shared.Config.RebirthConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)


local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hudGui = playerGui:WaitForChild("HudGui")
local rebirthFrame = hudGui:WaitForChild("RebirthFrame")
local coinAmountFrame = rebirthFrame:WaitForChild("CoinAmount")
local coinFiller = coinAmountFrame:WaitForChild("Filler")
local amountLabel = coinAmountFrame:WaitForChild("AmountLabel")
local bottomLine = rebirthFrame:WaitForChild("BottomLine")
local petSlotsFrame = bottomLine:WaitForChild("PetSlots")
local rebirthButton = bottomLine:WaitForChild("RebirthButton")
local lockFrame = rebirthButton:WaitForChild("Lock")

local petSlotTemplate = ReplicatedStorage.Assets.UI.PetSlot

local RebirthController = {}

local COMPLETED_COLOR = Color3.fromRGB(0, 131, 243)
local INCOMPLETE_COLOR = Color3.fromRGB(27, 29, 42)
local COMPLETED_BG_TRANSPARENCY = 0
local INCOMPLETE_BG_TRANSPARENCY = 0.5

local function getCurrentTier(replicaData)
	local tierIndex = math.min(replicaData.RebirthCount + 1, #RebirthConfig.Tiers)
	return RebirthConfig.Tiers[tierIndex]
end

local function hasPet(pets, petName)
	for _, petEntry in ipairs(pets) do
		if petEntry.name == petName then
			return true
		end
	end
	return false
end

local function syncPetSlots(tier)
	local required = tier.requiredPets

	local requiredSet = {}
	for _, name in ipairs(required) do
		requiredSet[name] = true
	end

	for _, child in ipairs(petSlotsFrame:GetChildren()) do
		if child:IsA("Frame") and not requiredSet[child.Name] then
			child:Destroy()
		end
	end

	for i, petName in ipairs(required) do
		local slot = petSlotsFrame:FindFirstChild(petName)
		if not slot then
			slot = petSlotTemplate:Clone()
			slot.ImageLabel.Image = PetConfig.GetPetByName(petName).icon
			slot.Name = petName
			slot.Parent = petSlotsFrame
			slot.LayoutOrder = i
			slot.Visible = true
		end
	end
end

local function updateSinglePetSlot(petSlot, owned, petName)
	if owned then
		petSlot.BackgroundColor3 = COMPLETED_COLOR
		petSlot.BackgroundTransparency = COMPLETED_BG_TRANSPARENCY
	else
		petSlot.BackgroundColor3 = INCOMPLETE_COLOR
		petSlot.BackgroundTransparency = INCOMPLETE_BG_TRANSPARENCY
	end

	local nameLabel = petSlot:FindFirstChildWhichIsA("TextLabel")
	if nameLabel then
		nameLabel.Text = petName
	end
end

function RebirthController.UpdateCoins(replicaData)
	local tier = getCurrentTier(replicaData)
	if not tier then return end

	local coins = replicaData.Coins or 0
	local ratio = math.clamp(coins / tier.cost, 0, 1)

	amountLabel.Text = "$" .. tostring(math.floor(coins)) .. "/" .. tostring(tier.cost)
	coinFiller.Size = UDim2.new(ratio, 0, 1, 0)
end

function RebirthController.UpdatePets(replicaData)
	local tier = getCurrentTier(replicaData)
	if not tier then return end

	syncPetSlots(tier)

	local pets = replicaData.Pets or {}

	for _, petName in ipairs(tier.requiredPets) do
		local petSlot = petSlotsFrame:FindFirstChild(petName)
		if petSlot and petSlot:IsA("Frame") then
			updateSinglePetSlot(petSlot, hasPet(pets, petName), petName)
		end
	end
end

function RebirthController.UpdateButton(replicaData)
	local tier = getCurrentTier(replicaData)
	if not tier then
		lockFrame.Visible = true
		rebirthButton.Interactable = false
		return
	end

	local coins = replicaData.Coins or 0
	local coinsMet = coins >= tier.cost

	local pets = replicaData.Pets or {}
	local allPetsOwned = true
	for _, petName in ipairs(tier.requiredPets) do
		if not hasPet(pets, petName) then
			allPetsOwned = false
			break
		end
	end

	local allMet = coinsMet and allPetsOwned

	lockFrame.Visible = not allMet
	rebirthButton.Interactable = allMet
end

function RebirthController.UpdateAll(replicaData)
	RebirthController.UpdateCoins(replicaData)
	RebirthController.UpdatePets(replicaData)
	RebirthController.UpdateButton(replicaData)
end

function RebirthController.Init()
	ReplicaClient.OnNew("PlayerData", function(replica)
		RebirthController.UpdateAll(replica.Data)

		replica:OnSet({"Coins"}, function(new)
			replica.Data.Coins = new
			RebirthController.UpdateCoins(replica.Data)
			RebirthController.UpdateButton(replica.Data)
		end)

		replica:OnSet({"Pets"}, function(new)
			replica.Data.Pets = new
			RebirthController.UpdatePets(replica.Data)
			RebirthController.UpdateButton(replica.Data)
		end)

		replica:OnSet({"RebirthCount"}, function(new)
			replica.Data.RebirthCount = new
			RebirthController.UpdateAll(replica.Data)
		end)
	end)
end

function RebirthController.Start()
	rebirthButton.MouseButton1Click:Connect(function()
		Remotes.Rebirth_Perform:InvokeServer()
	end)
end

return RebirthController