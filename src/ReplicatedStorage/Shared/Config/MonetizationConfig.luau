local MonetizationConfig = {}

MonetizationConfig.GAMEPASS_IDS = {
	SkipRollAnimation = 0,
	WithoutBombs      = 0,
	RebirthMoney      = 0,
	StarterPack       = 0,
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

MonetizationConfig.STRAY_PRICES = {
	Common    = 100,
	Uncommon  = 250,
	Rare      = 500,
	Epic      = 1500,
	Legendary = 5000,
}

MonetizationConfig.BOOST_ICONS = {
	EnsureRoll = "rbxassetid://0",
	SavePets   = "rbxassetid://0",
}

return MonetizationConfig