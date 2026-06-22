local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local MonetizationConfig = require(ReplicatedStorage.Shared.Config.MonetizationConfig)
local StickerConfig = require(ReplicatedStorage.Shared.Config.StickerConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerService = require(ServerScriptService.Modules.PlayerService)
local EconomyService = require(ServerScriptService.Modules.EconomyService)
local LuckService = require(ServerScriptService.Modules.LuckService)
local PetService = require(ServerScriptService.Modules.PetService)

local MonetizationService = {}

local grantedReceipts = {}
local productHandlers = {}

function MonetizationService.Init()
	for _, offer in ipairs(MonetizationConfig.ENSURE_ROLL_OFFERS) do
		local productId = offer.productId
		local duration = offer.duration
		productHandlers[productId] = function(player)
			local data = PlayerService.GetData(player)
			if not data then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local entitlements = data.MonetizationEntitlements
			local now = os.time()
			for _, boost in ipairs(entitlements.Timed) do
				if boost.id == "EnsureRoll" and boost.expiresAt > now then
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end

			table.insert(entitlements.Timed, {
				id = "EnsureRoll",
				startsAt = now,
				expiresAt = now + duration,
			})
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	for _, offer in ipairs(MonetizationConfig.SERVER_LUCK_OFFERS) do
		local productId = offer.productId
		local duration = offer.duration
		productHandlers[productId] = function()
			LuckService.AddServerBoost(GameConfig.SERVER_BOOST_AMOUNT, duration)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	for _, offer in ipairs(MonetizationConfig.SAVE_PETS_OFFERS) do
		local productId = offer.productId
		local duration = offer.duration
		productHandlers[productId] = function(player)
			local data = PlayerService.GetData(player)
			if not data then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			local entitlements = data.MonetizationEntitlements
			local now = os.time()
			for _, boost in ipairs(entitlements.Timed) do
				if boost.id == "SavePets" and boost.expiresAt > now then
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end

			table.insert(entitlements.Timed, {
				id = "SavePets",
				startsAt = now,
				expiresAt = now + duration,
			})
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	for _, offer in ipairs(MonetizationConfig.MONEY_OFFERS) do
		local productId = offer.productId
		local amount = offer.amount
		productHandlers[productId] = function(player)
			local data = PlayerService.GetData(player)
			if not data then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			EconomyService.AddCoins(player, amount)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	for _, sticker in ipairs(StickerConfig.Stickers) do
		if not sticker.productId then
			continue
		end
		local stickerName = sticker.name
		productHandlers[sticker.productId] = function(player)
			local data = PlayerService.GetData(player)
			if not data then
				return Enum.ProductPurchaseDecision.NotProcessedYet
			end

			data.Stickers = data.Stickers or {}
			for _, existing in ipairs(data.Stickers) do
				if existing == stickerName then
					return Enum.ProductPurchaseDecision.PurchaseGranted
				end
			end

			table.insert(data.Stickers, stickerName)
			local replica = PlayerService.GetReplica(player)
			if replica then
				replica:Set({"Stickers"}, data.Stickers)
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		if grantedReceipts[receiptInfo.PurchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local handler = productHandlers[receiptInfo.ProductId]
		if not handler then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local result = handler(player)
		if result == Enum.ProductPurchaseDecision.PurchaseGranted then
			grantedReceipts[receiptInfo.PurchaseId] = true
		end

		return result
	end
end

function MonetizationService.Start()
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if not wasPurchased then
			return
		end

		local passName = nil
		for name, id in pairs(MonetizationConfig.GAMEPASS_IDS) do
			if id == gamePassId then
				passName = name
				break
			end
		end
		if not passName then
			return
		end

		local data = PlayerService.GetData(player)
		if not data then
			return
		end

		local entitlements = data.MonetizationEntitlements
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
		end)
		if ok and owns then
			entitlements.GamePasses[passName] = true
		end

		PlayerService.SyncPassCache(player)

		local replica = PlayerService.GetReplica(player)
		if replica then
			replica:Set({"MonetizationEntitlements", "GamePasses"}, entitlements.GamePasses)
		end

		if passName == "StarterPack" and entitlements.GamePasses.StarterPack and not entitlements.Claims.StarterPack then
			local bundle = MonetizationConfig.STARTER_PACK_BUNDLE

			EconomyService.AddCoins(player, bundle.coins)

			data.Balloons["Blue"] = (data.Balloons["Blue"] or 0) + bundle.balloons.Blue
			data.Balloons["Yellow"] = (data.Balloons["Yellow"] or 0) + bundle.balloons.Yellow
			if replica then
				replica:Set({"Balloons"}, data.Balloons)
			end

			PetService.AddPet(player, bundle.pet)

			table.insert(entitlements.Timed, {
				id = "SavePets",
				startsAt = os.time(),
				expiresAt = os.time() + bundle.savePetsDuration,
			})
			if replica then
				replica:Set({"MonetizationEntitlements", "Timed"}, entitlements.Timed)
			end

			entitlements.Claims.StarterPack = true
			if replica then
				replica:Set({"MonetizationEntitlements", "Claims"}, entitlements.Claims)
			end
		end
	end)
end

return MonetizationService