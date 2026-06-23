local MonetizationConfig = {}

MonetizationConfig.GAMEPASS_IDS = {
	SkipRollAnimation = 1887274271,
	WithoutBombs      = 1883712428,
	RebirthMoney      = 1883700478,
	StarterPack       = 1886950299,
}

MonetizationConfig.ENSURE_ROLL_OFFERS = {
	{ productId = 3606081858, duration = 15 * 60 },
	{ productId = 3606082015, duration = 30 * 60 },
	{ productId = 3606082061, duration = 2 * 60 * 60 },
}

MonetizationConfig.SERVER_LUCK_OFFERS = {
	{ productId = 3606082172, duration = 10 * 60 },
	{ productId = 3606082196, duration = 20 * 60 },
	{ productId = 3606082276, duration = 1 * 60 * 60 },
}

MonetizationConfig.SAVE_PETS_OFFERS = {
	{ productId = 3606082454, duration = 2 * 60 },
	{ productId = 3606082582, duration = 5 * 60 },
	{ productId = 3606082609, duration = 12 * 60 },
}

MonetizationConfig.MONEY_OFFERS = {
	{ productId = 3606082778, amount = 20000 },
	{ productId = 3606082809, amount = 300000 },
	{ productId = 3606082850, amount = 1200000 },
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
	Common    = { productId = 3606096623, priceRobux = 100 },
	Uncommon  = { productId = 3606096658, priceRobux = 250 },
	Rare      = { productId = 3606096772, priceRobux = 500 },
	Epic      = { productId = 3606096845, priceRobux = 1500 },
	Legendary = { productId = 3606096880, priceRobux = 5000 },
}

MonetizationConfig.BOOST_ICONS = {
	EnsureRoll = "rbxassetid://133903352855433",
	SavePets   = "rbxassetid://76927570937072",
}

return MonetizationConfig