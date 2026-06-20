local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BalloonConfig = require(ReplicatedStorage.Shared.Config.BalloonConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local itemTemplate = ReplicatedStorage.Assets.UI.BalloonItemTemplate

local ShopController = {}

local shopGui
local balloonList
local selectedBalloonName = nil
local selectedItem = nil

function ShopController.Init()
end

function ShopController.Start()
	local hudGui = PlayerGui:WaitForChild("HudGui")
	local rightSide = hudGui:WaitForChild("RightSide")
	local shopButton = rightSide:WaitForChild("ShopButton")

	shopGui = PlayerGui:WaitForChild("ShopGui")
	local shopFrame = shopGui:WaitForChild("ShopFrame")
	local closeButton = shopFrame:WaitForChild("CloseButton")
	balloonList = shopFrame:WaitForChild("BalloonListFrame")

	shopButton.MouseButton1Click:Connect(function()
		toggleShop()
	end)

	closeButton.MouseButton1Click:Connect(function()
		toggleShop()
	end)

	populateBalloonList()
end

function toggleShop()
	shopGui.Enabled = not shopGui.Enabled
end

function populateBalloonList()
	for _, child in ipairs(balloonList:GetChildren()) do
		if child ~= itemTemplate then
			if (child :: Instance):IsA("Frame") then
				child:Destroy()
			end
		end
	end

	for name, config in pairs(BalloonConfig) do
		local item = itemTemplate:Clone()
		item.Name = name
		item.Parent = balloonList
		item.Visible = true
		item.LayoutOrder = config.price

		local nameLabel = item:WaitForChild("BalloonNameLabel")
		local priceLabel = item:WaitForChild("BalloonPriceLabel")
		local rarityLabel = item:WaitForChild("BalloonRarityLabel")
		local buyButton = item:WaitForChild("BuyButton")

		nameLabel.Text = config.displayName
		priceLabel.Text = "Цена: " .. tostring(config.price)
		rarityLabel.Text = "Редкость: " .. config.maxRarity

		item.MouseEnter:Connect(function() -- сделать hover
			selectBalloon(name, item)
		end)

		buyButton.Visible = true

		buyButton.MouseButton1Click:Connect(function()
			Remotes.Shop_BuyBalloon:InvokeServer({ balloonName = name })
		end)
	end
end

function selectBalloon(name, item)
	if selectedItem then
		selectedItem.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	end
	
	selectedBalloonName = name
	selectedItem = item
	item.BackgroundColor3 = Color3.fromRGB(200, 230, 255)
end

return ShopController