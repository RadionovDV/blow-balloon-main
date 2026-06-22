local BalloonConfig = {}

BalloonConfig.Default = {
	displayName = "Red",
	maxRarity   = "Common",
	price       = 0,
	baseReward  = 0,
	maxReward   = 600,
	layoutOrder = 1,
	popCurve = {
		{ time = 0,  chance = 0.15 },
		{ time = 5,  chance = 0.20 },
		{ time = 15, chance = 0.30 },
		{ time = 30, chance = 0.50 },
		{ time = 60, chance = 1.00 },
	},
}

BalloonConfig.Green = {
	displayName = "Green",
	maxRarity   = "Uncommon",
	price       = 500,
	baseReward  = 20,
	maxReward   = 1200,
	layoutOrder = 2,
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
	displayName = "Blue",
	maxRarity   = "Rare",
	price       = 100,
	baseReward  = 15,
	maxReward   = 900,
	layoutOrder = 3,
	popCurve = {
		{ time = 0,  chance = 0.12 },
		{ time = 5,  chance = 0.18 },
		{ time = 12, chance = 0.28 },
		{ time = 25, chance = 0.45 },
		{ time = 45, chance = 0.75 },
		{ time = 60, chance = 1.00 },
	},
}

BalloonConfig.Purple = {
	displayName = "Purple",
	maxRarity   = "Epic",
	price       = 100,
	baseReward  = 15,
	maxReward   = 900,
	layoutOrder = 3,
	popCurve = {
		{ time = 0,  chance = 0.12 },
		{ time = 5,  chance = 0.18 },
		{ time = 12, chance = 0.28 },
		{ time = 25, chance = 0.45 },
		{ time = 45, chance = 0.75 },
		{ time = 60, chance = 1.00 },
	},
}

BalloonConfig.Yellow = {
	displayName = "Yellow",
	maxRarity   = "Legendary",
	price       = 100,
	baseReward  = 15,
	maxReward   = 900,
	layoutOrder = 3,
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