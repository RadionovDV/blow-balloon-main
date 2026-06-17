local GameConfig = {}

GameConfig.ROULETTE_CHANCE = 10

GameConfig.KEY_CHANCE = 0.01
GameConfig.BOMB_CHANCE = 0.10
GameConfig.KEY_CHANCE_MAX_INFLATE = 0.05

GameConfig.STAND_INCOME_INTERVAL = 60
GameConfig.BASE_SLOTS_PER_FLOOR = 10
GameConfig.BASE_UPGRADE_KEY_COST = 1

GameConfig.REBIRTH_COIN_REQUIREMENT = 100000
GameConfig.REBIRTH_LUCK_MULTIPLIER = 0.5

GameConfig.SERVER_BOOST_AMOUNT = 5
GameConfig.SERVER_BOOST_DURATION = 1800

GameConfig.GAMEPASS_IDS = {
	BalloonCosmetics = 0,
	SkipAnimation    = 0,
	StarterPack      = 0,
	SavePet          = 0,
}

GameConfig.DEVPRODUCT_IDS = {
	ServerLuck      = 0,
	BalloonWithPet  = 0,
	AdoptPet        = 0,
}

GameConfig.TUTORIAL_STEPS = {
	INFLATE_FIRST   = 1,
	INFLATE_SECOND  = 2,
	BUY_BALLOON     = 3,
	EQUIP_BALLOON   = 4,
	INFLATE_NEW     = 5,
	GET_PET         = 6,
	PLACE_STAND     = 7,
	COLLECT_INCOME  = 8,
	BUY_PINK        = 9,
	COMPLETED       = -1,
}

GameConfig.APPLAUSE_INTERVAL = 10

return GameConfig