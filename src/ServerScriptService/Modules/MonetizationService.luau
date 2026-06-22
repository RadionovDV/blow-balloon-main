local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerService = require(ServerScriptService.Modules.PlayerService)
local EconomyService = require(ServerScriptService.Modules.EconomyService)
local LuckService = require(ServerScriptService.Modules.LuckService)

local MonetizationService = {}

local grantedReceipts = {}
local productHandlers = {}

function MonetizationService.Init()
	for _, offer in ipairs(GameConfig.ENSURE_ROLL_OFFERS) do
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

	productHandlers[GameConfig.DEVPRODUCT_IDS.ServerLuck] = function()
		LuckService.AddServerBoost(GameConfig.SERVER_BOOST_AMOUNT, GameConfig.SERVER_BOOST_DURATION)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	productHandlers[GameConfig.DEVPRODUCT_IDS.SavePets] = function(player)
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
			expiresAt = now + GameConfig.SAVE_PETS_DURATION,
		})
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	productHandlers[GameConfig.DEVPRODUCT_IDS.Money] = function(player)
		local data = PlayerService.GetData(player)
		if not data then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		EconomyService.AddCoins(player, GameConfig.MONEY_REWARD)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	for productId, stickerName in pairs(GameConfig.STICKERS_PRODUCT_MAP) do
		productHandlers[productId] = function(player)
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
		for name, id in pairs(GameConfig.GAMEPASS_IDS) do
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
		if ok then
			entitlements.GamePasses[passName] = owns
		else
			entitlements.GamePasses[passName] = true
		end

		PlayerService.SyncPassCache(player)

		local replica = PlayerService.GetReplica(player)
		if replica then
			replica:Set({"MonetizationEntitlements", "GamePasses"}, entitlements.GamePasses)
		end

		if passName == "StarterPack" and entitlements.GamePasses.StarterPack and not entitlements.Claims.StarterPack then
			EconomyService.AddCoins(player, GameConfig.STARTER_PACK_REWARD)
			entitlements.Claims.StarterPack = true
			if replica then
				replica:Set({"MonetizationEntitlements", "Claims"}, entitlements.Claims)
			end
		end
	end)
end

return MonetizationService