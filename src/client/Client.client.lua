local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)

local StarterPlayerScripts = game:GetService("StarterPlayerScripts")
local PlayerScripts = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")

local StatefulObjectController = require(PlayerScripts.Modules.StatefulObjectController)
local AudioController          = require(PlayerScripts.Modules.AudioController)
local HudController            = require(PlayerScripts.Modules.HudController)
local ShopController           = require(PlayerScripts.Modules.ShopController)
local BalloonController        = require(PlayerScripts.Modules.BalloonController)
local RouletteController       = require(PlayerScripts.Modules.RouletteController)
local PetController            = require(PlayerScripts.Modules.PetController)

AudioController.Init()
HudController.Init()
ShopController.Init()
BalloonController.Init()
RouletteController.Init()
PetController.Init()

HudController.Start()
ShopController.Start()
BalloonController.Start()
RouletteController.Start()
PetController.Start()

ReplicaClient.RequestData()