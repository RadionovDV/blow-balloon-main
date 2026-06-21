local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local indexItemTemplate = ReplicatedStorage.Assets.UI.IndexItem

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local indexGui = playerGui:WaitForChild("IndexGui")
local indexFrame = indexGui:WaitForChild("IndexFrame")
local indexContent = indexFrame:WaitForChild("IndexContent")
local scrollingFrame = indexContent:WaitForChild("ScrollingFrame")
local progressFrame = indexContent:WaitForChild("ProgressFrame")
local progressBar = progressFrame:WaitForChild("ProgressBar")
local filler = progressBar:WaitForChild("Filler")
local amountLabel = progressBar:WaitForChild("AmountLabel")
local closeButton = indexFrame:WaitForChild("CloseButton")

local hudGui = playerGui:WaitForChild("HudGui")
local rightSide = hudGui:WaitForChild("RightSide")
local indexButton = rightSide:WaitForChild("IndexButton")

local IndexController = {}

local catalog = PetConfig.Base
local petItems = {}

local function buildCatalog(unlocked)
	for _, child in ipairs(scrollingFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	table.clear(petItems)

	local openedCount = 0
	for _, pet in ipairs(catalog) do
		
		local item = indexItemTemplate:Clone()
		item.BackgroundColor3 = GameConfig.RARITY_COLORS[pet.rarity]
		item.Name = pet.name
		item.Visible = true
		item.Parent = scrollingFrame

		local iconLabel = item:WaitForChild("IconLabel")
		local nameLabel = item:WaitForChild("NameLabel")

		iconLabel.Image = pet.icon
		nameLabel.Text = pet.name

		local isUnlocked = false
		for _, unlockedName in ipairs(unlocked) do
			if unlockedName == pet.name then
				isUnlocked = true
				break
			end
		end

		if isUnlocked then
			iconLabel.ImageColor3 = Color3.new(1, 1, 1)
			openedCount = openedCount + 1
		else
			iconLabel.ImageColor3 = Color3.new(0, 0, 0)
		end

		petItems[pet.name] = item
	end

	local totalCount = #catalog
	amountLabel.Text = tostring(openedCount) .. " / " .. tostring(totalCount)
	filler.Size = UDim2.new(totalCount > 0 and openedCount / totalCount or 0, 0, 1, 0)
end

function IndexController.Init()
	indexButton.MouseButton1Click:Connect(function()
		indexGui.Enabled = true
	end)

	closeButton.MouseButton1Click:Connect(function()
		indexGui.Enabled = false
	end)

	ReplicaClient.OnNew("PlayerData", function(replica)
		local unlocked = replica.Data.Index or {}
		buildCatalog(unlocked)

		replica:OnSet({"Index"}, function(new)
			buildCatalog(new or {})
		end)
	end)
end

function IndexController.Start()
end

return IndexController
