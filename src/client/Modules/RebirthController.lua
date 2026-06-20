local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local hudGui = playerGui:WaitForChild("HudGui")
local rebirthFrame = hudGui:WaitForChild("RebirthFrame")
local coinAmountFrame = rebirthFrame:WaitForChild("CoinAmount")
local coinAmountFiller = coinAmountFrame:WaitForChild("Filler")
local amountLabel = coinAmountFiller:WaitForChild("AmountLabel")
local petSlots = rebirthFrame:WaitForChild("PetSlots")

local rebirthButton = hudGui:WaitForChild("RightSide") 
	and hudGui.RightSide:WaitForChild("RebirthButton")

local RebirthController = {}

function RebirthController.Init()
	
end

return RebirthController
