local PetConfig = {}

PetConfig.RARITIES = { "Common", "Uncommon", "Rare", "Epic", "Legendary" }

PetConfig.Base = {
	{ name = "Bluer",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://73756667829286"},
	{ name = "Chomper",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://81900141804008"},
	{ name = "Jolly",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://103357997214085"},
	{ name = "Fluffball",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://83811835396039"},
	{ name = "Pudgy",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://79543884643194"},
	{ name = "Grumpy",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://89666556027247"},
	{ name = "Violet",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://101833856161037"},
	{ name = "Spotty",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://93122040922084"},
	{ name = "Gnomey",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://114565200405507"},
	{ name = "Sunny",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://134763592559781"},
	{ name = "Cube",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://108666091533781"},
	{ name = "Strange",   rarity = "Common",   rarityWeight = 100, cost = 20, standIncome = 5, icon = "rbxassetid://124612808940042"},
	
	{ name = "Forgot",    rarity = "Uncommon", rarityWeight = 100,  cost = 30, standIncome = 12, icon = "rbxassetid://129844812997236"  },
	{ name = "Prank",    rarity = "Uncommon", rarityWeight = 100,  cost = 30, standIncome = 12, icon = "rbxassetid://73941003632392"  },
	{ name = "Threat",    rarity = "Uncommon", rarityWeight = 100,  cost = 30, standIncome = 12, icon = "rbxassetid://112799246584876"  },
	{ name = "Arrow",    rarity = "Uncommon", rarityWeight = 100,  cost = 30, standIncome = 12, icon = "rbxassetid://139629215267050"  },
	{ name = "Yellow Scoundrel",    rarity = "Uncommon", rarityWeight = 100,  cost = 30, standIncome = 12, icon = "rbxassetid://101019572519126"  },
	{ name = "Blurred",    rarity = "Uncommon", rarityWeight = 100,  cost = 30, standIncome = 12, icon = "rbxassetid://87428458550990"  },
	
	{ name = "Blue Beast",   rarity = "Rare",     rarityWeight = 20,  cost = 50, standIncome = 30, icon = "rbxassetid://105800133561274"  },
	{ name = "Purple Menace",   rarity = "Rare",     rarityWeight = 20,  cost = 50, standIncome = 30, icon = "rbxassetid://82638430032146"  },
	{ name = "Octopus",   rarity = "Rare",     rarityWeight = 20,  cost = 50, standIncome = 30, icon = "rbxassetid://87256225358457"  },
	{ name = "Frog",   rarity = "Rare",     rarityWeight = 20,  cost = 50, standIncome = 30, icon = "rbxassetid://77974639619329"  },
	{ name = "Scorpio",   rarity = "Rare",     rarityWeight = 20,  cost = 50, standIncome = 30, icon = "rbxassetid://85919178073334"  },
	
	{ name = "Square",   rarity = "Epic",     rarityWeight = 5,   cost = 150, standIncome = 80, icon = "rbxassetid://82088622142311"  },
	{ name = "Orange Bull",   rarity = "Epic",     rarityWeight = 5,   cost = 150, standIncome = 80, icon = "rbxassetid://125084622929646"  },
	{ name = "Blue Dragon",   rarity = "Epic",     rarityWeight = 5,   cost = 150, standIncome = 80, icon = "rbxassetid://76877367060713"  },
	{ name = "Three Eyed",   rarity = "Epic",     rarityWeight = 5,   cost = 150, standIncome = 80, icon = "rbxassetid://70760516799915"  },
	
	{ name = "Dragon King", rarity = "Legendary", rarityWeight = 1,   cost = 300, standIncome = 250, icon = "rbxassetid://108370112836878" },
	{ name = "Space Octopus", rarity = "Legendary", rarityWeight = 1,   cost = 300, standIncome = 250, icon = "rbxassetid://125044865229659" },
}

function PetConfig.GetPetByName(name)
	for _, petTire in PetConfig.Base do
		if petTire.name == name then
			return petTire
		end
	end
end

return PetConfig