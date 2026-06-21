local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetConfig = require(ReplicatedStorage.Shared.Config.PetConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StatefulObjectController = require(script.Parent.StatefulObjectController)
local AudioController = require(script.Parent.AudioController)
local BalloonController = require(script.Parent.BalloonController)

local RouletteController = {}

local ROULETTE_DURATION = 6.5
local MIN_ITEM_SHOW_TIME = 0.08
local MAX_ITEM_SHOW_TIME = 0.8
local FINAL_ITEMS_BEFORE = 3

local RouletteGui = PlayerGui:WaitForChild("RouletteGui")
local RouletteFrame = RouletteGui:WaitForChild("RouletteFrame")
local ItemDisplay = RouletteFrame:WaitForChild("ItemDisplay")
local ItemIcon = ItemDisplay:WaitForChild("PetIcon")
local RarityLabel = ItemIcon:WaitForChild("RarityLabel")

local ProgressBar = RouletteFrame:WaitForChild("ProgressBar")
local ProgressFill = ProgressBar:WaitForChild("ProgressFill")

local ResultFrame = RouletteFrame:WaitForChild("ResultFrame")
local ResultNameLabel = ResultFrame:WaitForChild("ResultNameLabel")
local ResultRarityLabel = ResultFrame:WaitForChild("ResultRarityLabel")
local TakeButton = ResultFrame:WaitForChild("TakeButton")
local ExitButton = ResultFrame:WaitForChild("ExitButton")

local lastResult = nil
local activeConnection = nil

local function getRandomRouletteItem()
	local base = PetConfig.Base
	local idx = math.random(#base)
	return { type = "pet", name = base[idx].name, rarity = base[idx].rarity, icon = base[idx].icon }
end

local function buildSequence(result)
	local sequence = {}
	for i = 1, 20 do
		table.insert(sequence, getRandomRouletteItem())
	end
	for i = 1, FINAL_ITEMS_BEFORE do
		table.insert(sequence, getRandomRouletteItem())
	end
	table.insert(sequence, result)
	return sequence
end

local function displayItem(item)
	if item.type == "pet" then
		RarityLabel.Text = item.rarity
		RarityLabel.TextColor3 = GameConfig.GetRarityColor(item.rarity)
		ItemIcon.Image = item.icon
	elseif item.type == "key" then
		RarityLabel.Text = "Golden Key"
		RarityLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	elseif item.type == "bomb" then
		RarityLabel.Text = "Bomb"
		RarityLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	end
	ItemDisplay.Size = UDim2.new(0.9, 0, 0.9, 0)
	StatefulObjectController.Tween(ItemDisplay,
		{ Size = UDim2.new(1, 0, 1, 0) }, 0.05, Enum.EasingStyle.Back)
end

local function showResult(result)
	ProgressBar.Visible = false
	ResultFrame.Visible = true

	if result.type == "pet" then
		ResultNameLabel.Text = result.name
		ResultRarityLabel.Text = result.rarity
		ResultRarityLabel.TextColor3 = GameConfig.GetRarityColor(result.rarity)
		ItemIcon.Size = UDim2.new(1, 0, 1, 0)
		StatefulObjectController.Tween(ItemIcon,
			{ Size = UDim2.new(1.2, 0, 1.2, 0) }, 0.3, Enum.EasingStyle.Back)
	elseif result.type == "key" then
		ResultNameLabel.Text = "Golden Key!"
		ResultRarityLabel.Text = ""
	elseif result.type == "bomb" then
		ResultNameLabel.Text = "Bomb!"
		ResultRarityLabel.Text = ""
	end

	AudioController.Play(AudioController.Sounds.RouletteEnd)
	if result.type == "pet" then
		AudioController.Play(AudioController.Sounds.PetGet)
	end
end

local function hideRoulette()
	if activeConnection then
		activeConnection:Disconnect()
		activeConnection = nil
	end
	--StatefulObjectController.Tween(BackgroundFrame, { BackgroundTransparency = 1 }, 0.2)
	task.wait(0.2)
	RouletteGui.Enabled = false
	ProgressBar.Visible = true
	ResultFrame.Visible = false
	ProgressFill.Size = UDim2.new(1, 0, 1, 0)
	lastResult = nil
end

local function playSequence(sequence, finalResult)
	local currentIndex = 1
	local itemTimer = 0
	local totalTime = 0

	activeConnection = RunService.Heartbeat:Connect(function(dt)
		totalTime += dt
		itemTimer += dt

		local progress = math.clamp(totalTime / ROULETTE_DURATION, 0, 1)
		local currentItemDuration = MIN_ITEM_SHOW_TIME
			+ (MAX_ITEM_SHOW_TIME - MIN_ITEM_SHOW_TIME) * (progress ^ 2)

		local fillProgress = 1 - (itemTimer / currentItemDuration)
		ProgressFill.Size = UDim2.fromScale(1, math.clamp(fillProgress, 0, 1))

		if itemTimer >= currentItemDuration then
			itemTimer = 0
			if currentIndex <= #sequence then
				displayItem(sequence[currentIndex])
				currentIndex += 1
			else
				if activeConnection then
					activeConnection:Disconnect()
					activeConnection = nil
				end
				showResult(finalResult)
			end
		end
	end)
end

function RouletteController.Show(result)
	local sequence = buildSequence(result)
	RouletteGui.Enabled = true
	--BackgroundFrame.BackgroundTransparency = 1
	--StatefulObjectController.Tween(BackgroundFrame, { BackgroundTransparency = 0.5 }, 0.3)
	playSequence(sequence, result)
end

function RouletteController.Init()
	Remotes.Balloon_Result.OnClientEvent:Connect(function(res)
		if res.type == "roulette" then
			lastResult = res.result
			RouletteController.Show(res.result)
		end
	end)

	TakeButton.MouseButton1Click:Connect(function()
		AudioController.Play(AudioController.Sounds.ButtonClick)
		local result = lastResult
		hideRoulette()
		if result and result.type == "pet" then
			Remotes.Roulette_ResolvePetChoice:InvokeServer({ choice = "take" })
		end
		BalloonController.ReturnFromRoulette()
	end)

	ExitButton.MouseButton1Click:Connect(function()
		AudioController.Play(AudioController.Sounds.ButtonClick)
		local result = lastResult
		hideRoulette()
		if result and result.type == "pet" then
			Remotes.Roulette_ResolvePetChoice:InvokeServer({ choice = "leave" })
		end
		BalloonController.ReturnFromRoulette()
	end)
end

function RouletteController.Start()
end

return RouletteController