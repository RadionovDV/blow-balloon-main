local PetConfig = {}

PetConfig.RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

PetConfig.Base = {
	{ name = "FluffyCat",   rarity = "Common",   rarityWeight = 100, cost = 0, standIncome = 5   },
	{ name = "WoofyDog",    rarity = "Uncommon", rarityWeight = 50,  cost = 0, standIncome = 12  },
	{ name = "CoolBunny",   rarity = "Rare",     rarityWeight = 20,  cost = 0, standIncome = 30  },
	{ name = "MysticFox",   rarity = "Epic",     rarityWeight = 5,   cost = 0, standIncome = 80  },
	{ name = "GoldenDrake", rarity = "Legendary",rarityWeight = 1,   cost = 0, standIncome = 250 },
}

return PetConfig