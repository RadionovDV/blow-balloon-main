local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local MarketplaceService = game:GetService("MarketplaceService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
local MonetizationConfig = require(ReplicatedStorage.Shared.Config.MonetizationConfig)
local StickerConfig = require(ReplicatedStorage.Shared.Config.StickerConfig)
local FormatNumber = require(ReplicatedStorage.Shared.Util.FormatNumber)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local RobuxShopController = {}

local shopGui
local shopContent
local shopFrame
local player = Players.LocalPlayer
local replicaData = nil

local function now()
	return os.time()
end

local function refreshStarterPack()
	local section = shopContent:FindFirstChild("StarterPack")
	if not section then return end
	local content = section:FindFirstChild("Content")
	local purchased = section:FindFirstChild("Purchased")
	local data = replicaData
	if not data then return end
	local entitlements = data.MonetizationEntitlements
	local bought = entitlements.GamePasses.StarterPack == true and entitlements.Claims.StarterPack == true
	if content then content.Visible = not bought end
	if purchased then purchased.Visible = bought end
	if not bought and content then
		local textLabel = content:FindFirstChild("BuyButton"):FindFirstChildWhichIsA("TextLabel")
		if textLabel then textLabel.Text = "BUY STARTER PACK" end
	end
end

local function refreshEnsureRoll()
	local section = shopContent:FindFirstChild("EnsureRoll")
	if not section then return end
	local offersFrame = section:FindFirstChild("Offers")
	if not offersFrame then return end
	local data = replicaData
	if not data then return end
	local t = now()
	local activeExpires = 0
	for _, boost in ipairs(data.MonetizationEntitlements.Timed) do
		if boost.id == "EnsureRoll" and boost.expiresAt > t and boost.expiresAt > activeExpires then
			activeExpires = boost.expiresAt
		end
	end
	for i, offer in ipairs(MonetizationConfig.ENSURE_ROLL_OFFERS) do
		local f = offersFrame:FindFirstChild("Offer" .. tostring(i))
		if not f then continue end
		local content = f:FindFirstChild("Content")
		if not content then continue end
		local buyButton = content:FindFirstChild("BuyButton")
		if not buyButton then continue end
		local textLabel = buyButton:FindFirstChildWhichIsA("TextLabel")
		if not textLabel then continue end
		if activeExpires > t then
			textLabel.Text = FormatNumber.FormatTime(activeExpires - t)
			buyButton.Active = false
		else
			textLabel.Text = offer.duration and FormatNumber.FormatTime(offer.duration) or ""
			buyButton.Active = true
		end
	end
end

local function refreshServerLuck()
	local section = shopContent:FindFirstChild("ServerLuck")
	if not section then return end
	local offersFrame = section:FindFirstChild("Offers")
	if not offersFrame then return end
	for i, offer in ipairs(MonetizationConfig.SERVER_LUCK_OFFERS) do
		local f = offersFrame:FindFirstChild("Offer" .. tostring(i))
		if not f then continue end
		local content = f:FindFirstChild("Content")
		if not content then continue end
		local buyButton = content:FindFirstChild("BuyButton")
		if not buyButton then continue end
		local textLabel = buyButton:FindFirstChildWhichIsA("TextLabel")
		if textLabel then
			textLabel.Text = offer.duration and FormatNumber.FormatTime(offer.duration) or ""
		end
	end
end

local function refreshGamePassItems()
	local section = shopContent:FindFirstChild("GamePass")
	if not section then return end
	local data = replicaData
	if not data then return end
	local entitlements = data.MonetizationEntitlements
	for _, pair in ipairs({
		{ "SkipRollAnimation", true },
		{ "WithoutBombs", true },
		{ "RebirthMoney", true },
	}) do
		local passName = pair[1]
		local item = section:FindFirstChild(passName)
		if not item then continue end
		local content = item:FindFirstChild("Content")
		local purchased = item:FindFirstChild("Purchased")
		local bought = entitlements.GamePasses[passName] == true
		if content then content.Visible = not bought end
		if purchased then purchased.Visible = bought end
	end
end

local function refreshSavePets()
	local section = shopContent:FindFirstChild("SavePets")
	if not section then return end
	local offersFrame = section:FindFirstChild("Offers")
	if not offersFrame then return end
	local data = replicaData
	if not data then return end
	local t = now()
	local activeExpires = 0
	for _, boost in ipairs(data.MonetizationEntitlements.Timed) do
		if boost.id == "SavePets" and boost.expiresAt > t and boost.expiresAt > activeExpires then
			activeExpires = boost.expiresAt
		end
	end
	for i, offer in ipairs(MonetizationConfig.SAVE_PETS_OFFERS) do
		local f = offersFrame:FindFirstChild("Offer" .. tostring(i))
		if not f then continue end
		local content = f:FindFirstChild("Content")
		if not content then continue end
		local buyButton = content:FindFirstChild("BuyButton")
		if not buyButton then continue end
		local textLabel = buyButton:FindFirstChildWhichIsA("TextLabel")
		if not textLabel then continue end
		if activeExpires > t then
			textLabel.Text = FormatNumber.FormatTime(activeExpires - t)
			buyButton.Active = false
		else
			textLabel.Text = offer.duration and FormatNumber.FormatTime(offer.duration) or ""
			buyButton.Active = true
		end
	end
end

local function refreshMoney()
	local section = shopContent:FindFirstChild("Money")
	if not section then return end
	local offersFrame = section:FindFirstChild("Offers")
	if not offersFrame then return end
	for i, offer in ipairs(MonetizationConfig.MONEY_OFFERS) do
		local f = offersFrame:FindFirstChild("Offer" .. tostring(i))
		if not f then continue end
		local content = f:FindFirstChild("Content")
		if not content then continue end
		local buyButton = content:FindFirstChild("BuyButton")
		if not buyButton then continue end
		local textLabel = buyButton:FindFirstChildWhichIsA("TextLabel")
		if textLabel then
			textLabel.Text = "+" .. FormatNumber.Format(offer.amount or 0)
		end
	end
end

local function refreshStickers()
	local section = shopContent:FindFirstChild("Stickers")
	if not section then return end
	local offersFrame = section:FindFirstChild("Offers")
	if not offersFrame then return end
	local data = replicaData
	if not data then return end
	local ownedStickers = data.Stickers or {}
	local activeSticker = data.ActiveSticker or ""
	for i, sticker in ipairs(StickerConfig.Stickers) do
		local f = offersFrame:FindFirstChild("Offer" .. tostring(i))
		if not f then continue end
		local content = f:FindFirstChild("Content")
		if not content then continue end
		local buyButton = content:FindFirstChild("BuyButton")
		local equipButton = content:FindFirstChild("EuipButton")
		local owned = false
		for _, name in ipairs(ownedStickers) do
			if name == sticker.name then
				owned = true
				break
			end
		end
		if buyButton then buyButton.Visible = not owned end
		if equipButton and equipButton:IsA("TextButton") then
			if owned then
				equipButton.Visible = true
				if activeSticker == sticker.name then
					equipButton.Text = "Unequip"
				else
					equipButton.Text = "Equip"
				end
			else
				equipButton.Visible = false
			end
		end
	end
end

local function refreshShop()
	refreshStarterPack()
	refreshEnsureRoll()
	refreshServerLuck()
	refreshGamePassItems()
	refreshSavePets()
	refreshMoney()
	refreshStickers()
end

local function wireButtons()
	-- StarterPack Buy
	local function wireStarterPack()
		local section = shopContent:FindFirstChild("StarterPack")
		if not section then return end
		local content = section:FindFirstChild("Content")
		if not content then return end
		local buyButton = content:FindFirstChild("BuyButton")
		if buyButton then
			buyButton.MouseButton1Click:Connect(function()
				local id = MonetizationConfig.GAMEPASS_IDS.StarterPack
				if id and id > 0 then MarketplaceService:PromptGamePassPurchase(player, id) end
			end)
		end
	end

	-- EnsureRoll Buy buttons
	local function wireEnsureRoll()
		local section = shopContent:FindFirstChild("EnsureRoll")
		if not section then return end
		local offersFrame = section:FindFirstChild("Offers")
		if not offersFrame then return end
		for i, offer in ipairs(MonetizationConfig.ENSURE_ROLL_OFFERS) do
			local f = offersFrame:FindFirstChild("Offer" .. tostring(i))
			if not f then continue end
			local content = f:FindFirstChild("Content")
			if not content then continue end
			local buyButton = content:FindFirstChild("BuyButton")
			if buyButton then
				local productId = offer.productId
				buyButton.MouseButton1Click:Connect(function()
					if productId and productId > 0 then MarketplaceService:PromptProductPurchase(player, productId) end
				end)
			end
		end
	end

	-- ServerLuck Buy buttons
	local function wireServerLuck()
		local section = shopContent:FindFirstChild("ServerLuck")
		if not section then return end
		local offersFrame = section:FindFirstChild("Offers")
		if not offersFrame then return end
		for i, offer in ipairs(MonetizationConfig.SERVER_LUCK_OFFERS) do
			local f = offersFrame:FindFirstChild("Offer" .. tostring(i))
			if not f then continue end
			local content = f:FindFirstChild("Content")
			if not content then continue end
			local buyButton = content:FindFirstChild("BuyButton")
			if buyButton then
				local productId = offer.productId
				buyButton.MouseButton1Click:Connect(function()
					if productId and productId > 0 then MarketplaceService:PromptProductPurchase(player, productId) end
				end)
			end
		end
	end

	-- GamePass Buy buttons
	local function wireGamePass()
		local section = shopContent:FindFirstChild("GamePass")
		if not section then return end
		for _, pair in ipairs({
			{ "SkipRollAnimation", true },
			{ "WithoutBombs", true },
			{ "RebirthMoney", true },
		}) do
			local passName = pair[1]
			local item = section:FindFirstChild(passName)
			if not item then continue end
			local content = item:FindFirstChild("Content")
			if not content then continue end
			local buyButton = content:FindFirstChild("BuyButton")
			if buyButton then
				local id = MonetizationConfig.GAMEPASS_IDS[passName]
				buyButton.MouseButton1Click:Connect(function()
					if id and id > 0 then MarketplaceService:PromptGamePassPurchase(player, id) end
				end)
			end
		end
	end

	-- SavePets Buy buttons
	local function wireSavePets()
		local section = shopContent:FindFirstChild("SavePets")
		if not section then return end
		local offersFrame = section:FindFirstChild("Offers")
		if not offersFrame then return end
		for i, offer in ipairs(MonetizationConfig.SAVE_PETS_OFFERS) do
			local f = offersFrame:FindFirstChild("Offer" .. tostring(i))
			if not f then continue end
			local content = f:FindFirstChild("Content")
			if not content then continue end
			local buyButton = content:FindFirstChild("BuyButton")
			if buyButton then
				local productId = offer.productId
				buyButton.MouseButton1Click:Connect(function()
					if productId and productId > 0 then MarketplaceService:PromptProductPurchase(player, productId) end
				end)
			end
		end
	end

	-- Money Buy buttons
	local function wireMoney()
		local section = shopContent:FindFirstChild("Money")
		if not section then return end
		local offersFrame = section:FindFirstChild("Offers")
		if not offersFrame then return end
		for i, offer in ipairs(MonetizationConfig.MONEY_OFFERS) do
			local f = offersFrame:FindFirstChild("Offer" .. tostring(i))
			if not f then continue end
			local content = f:FindFirstChild("Content")
			if not content then continue end
			local buyButton = content:FindFirstChild("BuyButton")
			if buyButton then
				local productId = offer.productId
				buyButton.MouseButton1Click:Connect(function()
					if productId and productId > 0 then MarketplaceService:PromptProductPurchase(player, productId) end
				end)
			end
		end
	end

	-- Sticker Buy and Equip/Unequip buttons
	local function wireStickers()
		local section = shopContent:FindFirstChild("Stickers")
		if not section then return end
		local offersFrame = section:FindFirstChild("Offers")
		if not offersFrame then return end
		for i, sticker in ipairs(StickerConfig.Stickers) do
			local f = offersFrame:FindFirstChild("Offer" .. tostring(i))
			if not f then continue end
			local content = f:FindFirstChild("Content")
			if not content then continue end
			local buyButton = content:FindFirstChild("BuyButton")
			local equipButton = content:FindFirstChild("EuipButton")

			if buyButton then
				local productId = sticker.productId
				buyButton.MouseButton1Click:Connect(function()
					if productId and productId > 0 then MarketplaceService:PromptProductPurchase(player, productId) end
				end)
			end

			if equipButton and equipButton:IsA("TextButton") then
				local stickerName = sticker.name
				equipButton.MouseButton1Click:Connect(function()
					local data = replicaData
					if not data then return end
					local active = data.ActiveSticker or ""
					if active == stickerName then
						Remotes.Sticker_Unequip:InvokeServer()
					else
						Remotes.Sticker_Equip:InvokeServer({ stickerName = stickerName })
					end
				end)
			end
		end
	end

	wireStarterPack()
	wireEnsureRoll()
	wireServerLuck()
	wireGamePass()
	wireSavePets()
	wireMoney()
	wireStickers()
end

function RobuxShopController.Init()
	shopGui = PlayerGui:WaitForChild("ShopGui")
	shopContent = shopGui:WaitForChild("ShopFrame"):WaitForChild("ShopContent")

	ReplicaClient.OnNew("PlayerData", function(replica)
		replicaData = replica.Data
		replica:OnSet({"MonetizationEntitlements", "GamePasses"}, function()
			replicaData = replica.Data
			if shopGui.Enabled then refreshShop() end
		end)
		replica:OnSet({"MonetizationEntitlements", "Claims"}, function()
			replicaData = replica.Data
			if shopGui.Enabled then refreshShop() end
		end)
		replica:OnSet({"MonetizationEntitlements", "Timed"}, function()
			replicaData = replica.Data
			if shopGui.Enabled then refreshShop() end
		end)
		replica:OnSet({"Stickers"}, function()
			replicaData = replica.Data
			if shopGui.Enabled then refreshShop() end
		end)
		replica:OnSet({"ActiveSticker"}, function()
			replicaData = replica.Data
			if shopGui.Enabled then refreshShop() end
		end)
	end)
end

function RobuxShopController.Start()
	local hudGui = PlayerGui:WaitForChild("HudGui")
	local rightSide = hudGui:WaitForChild("RightSide")
	local shopButton = rightSide:FindFirstChild("ShopButton")

	if shopButton then
		shopButton.MouseButton1Click:Connect(function()
			shopGui.Enabled = not shopGui.Enabled
			if shopGui.Enabled then refreshShop() end
		end)
	end

	shopFrame = shopGui:WaitForChild("ShopFrame")
	local closeButton = shopFrame:FindFirstChild("CloseButton")
	if closeButton then
		closeButton.MouseButton1Click:Connect(function()
			shopGui.Enabled = false
		end)
	end

	wireButtons()
end

return RobuxShopController