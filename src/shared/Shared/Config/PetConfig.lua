local PetConfig = {}

PetConfig.RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

PetConfig.Base = {
	{ name = "Bluer",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5   },
	{ name = "Forgot",    rarity = "Uncommon", rarityWeight = 50,  cost = 30, standIncome = 12  },
	{ name = "Blue Beast",   rarity = "Rare",     rarityWeight = 20,  cost = 50, standIncome = 30  },
	{ name = "Orange Bull",   rarity = "Epic",     rarityWeight = 5,   cost = 150, standIncome = 80  },
	{ name = "Dragon King", rarity = "Legendary", rarityWeight = 1,   cost = 300, standIncome = 250 },
}

return PetConfig