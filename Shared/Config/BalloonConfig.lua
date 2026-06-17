local BalloonConfig = {}

BalloonConfig.Default = {
	displayName = "Default Balloon",
	maxRarity = "Common",
	baseReward = 10,
	maxReward = 600,
	popCurve = {
		{ time = 0,  chance = 0.15 },
		{ time = 5,  chance = 0.20 },
		{ time = 15, chance = 0.30 },
		{ time = 30, chance = 0.50 },
		{ time = 60, chance = 1.00 },
	},
}

BalloonConfig.Pink = {
	displayName = "Pink Balloon",
	maxRarity = "Rare",
	baseReward = 20,
	maxReward = 1200,
	popCurve = {
		{ time = 0,  chance = 0.20 },
		{ time = 5,  chance = 0.25 },
		{ time = 12, chance = 0.35 },
		{ time = 25, chance = 0.55 },
		{ time = 60, chance = 1.00 },
	},
}

BalloonConfig.Blue = {
	displayName = "Blue Balloon",
	maxRarity = "Uncommon",
	baseReward = 15,
	maxReward = 900,
	popCurve = {
		{ time = 0,  chance = 0.18 },
		{ time = 5,  chance = 0.22 },
		{ time = 14, chance = 0.32 },
		{ time = 28, chance = 0.52 },
		{ time = 60, chance = 1.00 },
	},
}

return BalloonConfig