local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)

local StarterPlayerScripts = game:GetService("StarterPlayerScripts")
local PlayerScripts = game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts")

local StatefulObjectController = require(PlayerScripts.Modules.StatefulObjectController)
local AudioController          = require(PlayerScripts.Modules.AudioController)
local HudController            = require(PlayerScripts.Modules.HudController)

AudioController.Init()
HudController.Init()

HudController.Start()

ReplicaClient.RequestData()