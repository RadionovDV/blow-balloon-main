local MonetizationConfig = {}

MonetizationConfig.GAMEPASS_IDS = {
	BalloonCosmetics = 0,
	SkipAnimation    = 0,
	StarterPack      = 0,
	SavePet          = 0,
}

MonetizationConfig.ENSURE_ROLL_OFFERS = {
	-- { productId = <id>, duration = <seconds> }
}

MonetizationConfig.SERVER_LUCK_OFFERS = {
	-- { productId = <id>, duration = <seconds> }
}

MonetizationConfig.SAVE_PETS_OFFERS = {
	-- { productId = <id>, duration = <seconds> }
}

MonetizationConfig.MONEY_OFFERS = {
	-- { productId = <id>, amount = <coins> }
}

MonetizationConfig.STARTER_PACK_BUNDLE = {
	coins = 200000,
	balloons = {
		Blue   = 25,
		Yellow = 3,
	},
	pet = {
		name           = "Forgot",
		rarity         = "Uncommon",
		collectionName = "Base",
	},
	savePetsDuration = 900,
}

return MonetizationConfig