local ServerScriptService = game:GetService("ServerScriptService")

local PlayerService     = require(ServerScriptService.Modules.PlayerService)
local EconomyService    = require(ServerScriptService.Modules.EconomyService)
local LuckService       = require(ServerScriptService.Modules.LuckService)
local RouletteService   = require(ServerScriptService.Modules.RouletteService)
local BalloonService    = require(ServerScriptService.Modules.BalloonService)

PlayerService.Init()
EconomyService.Init()
LuckService.Init()
RouletteService.Init()
BalloonService.Init()

PlayerService.Start()
EconomyService.Start()
LuckService.Start()
RouletteService.Start()
BalloonService.Start()