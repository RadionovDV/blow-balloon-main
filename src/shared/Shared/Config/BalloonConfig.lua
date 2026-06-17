local BalloonConfig = {}

BalloonConfig.Default = {
	displayName = "Default Balloon",
	maxRarity   = "Common",
	baseReward  = 10,
	maxReward   = 600,
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
	maxRarity   = "Rare",
	baseReward  = 20,
	maxReward   = 1200,
	popCurve = {
		{ time = 0,  chance = 0.10 },
		{ time = 5,  chance = 0.15 },
		{ time = 10, chance = 0.25 },
		{ time = 25, chance = 0.40 },
		{ time = 45, chance = 0.70 },
		{ time = 60, chance = 1.00 },
	},
}

BalloonConfig.Blue = {
	displayName = "Blue Balloon",
	maxRarity   = "Uncommon",
	baseReward  = 15,
	maxReward   = 900,
	popCurve = {
		{ time = 0,  chance = 0.12 },
		{ time = 5,  chance = 0.18 },
		{ time = 12, chance = 0.28 },
		{ time = 25, chance = 0.45 },
		{ time = 45, chance = 0.75 },
		{ time = 60, chance = 1.00 },
	},
}

return BalloonConfig