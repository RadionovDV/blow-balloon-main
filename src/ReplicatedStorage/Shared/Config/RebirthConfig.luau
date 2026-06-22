local RebirthConfig = {}

RebirthConfig.Tiers = {
	{
		cost             = 10000,
		requiredPets     = { "Bluer", "Blue Beast" },
		luckMultiplier   = 1.2,
		rebirthBonusCash = 500,
	},
	{
		cost             = 30000,
		requiredPets     = { "Orange Bull" },
		luckMultiplier   = 1.2,
		rebirthBonusCash = 2000,
	},
	{
		cost             = 50000,
		requiredPets     = { "Bluer", "Orange Bull" },
		luckMultiplier   = 1.2,
		rebirthBonusCash = 5000,
	},
}

return RebirthConfig