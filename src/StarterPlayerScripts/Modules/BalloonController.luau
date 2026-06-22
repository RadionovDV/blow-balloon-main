local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
local BalloonConfig = require(ReplicatedStorage.Shared.Config.BalloonConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local StickerConfig = require(ReplicatedStorage.Shared.Config.StickerConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local AudioController = require(script.Parent.AudioController)

local BalloonController = {}

local Phase = {
	Idle      = "idle",
	Near      = "near",
	Inflating = "inflating",
	Viewing   = "viewing",
	Ready     = "ready",
	Roulette  = "roulette",
}
local phase = Phase.Idle

local cachedActiveBalloon = "Default"
local ownedBalloons = {}
local cachedActiveSticker = ""

local inflateConnection = nil
local inflateLoopId = nil
local startTime = 0
local applauseTimer = 0
local readyDelay = nil

local BalloonButtonTemplate = ReplicatedStorage.Assets.UI:WaitForChild("BalloonInventoryButton")

local location = Workspace:WaitForChild("Location")
local balloonStation = location:WaitForChild("BalloonStation")
local balloonModel = balloonStation:WaitForChild("BalloonModel")
local balloonPart = balloonModel:WaitForChild("BalloonPart")
local balloonBasePosition = balloonPart.Position

local balloonDecal = balloonPart:FindFirstChildOfClass("Decal")

local function applySticker(stickerName)
	if not balloonDecal then
		return
	end
	if stickerName and stickerName ~= "" then
		for _, sticker in ipairs(StickerConfig.Stickers) do
			if sticker.name == stickerName then
				balloonDecal.ColorMapContent = sticker.icon or ""
				return
			end
		end
		balloonDecal.ColorMapContent = ""
	else
		balloonDecal.ColorMapContent = ""
	end
end

local billboardGui = PlayerGui:WaitForChild("BillboardGui")
local rewardLabel = billboardGui:WaitForChild("RewardLabel")

local balloonHudGui = PlayerGui:WaitForChild("BalloonHudGui")
local startButtonZone = balloonHudGui:WaitForChild("StartButtonZone")
local imageFrame = startButtonZone:WaitForChild("ImageFrame")
local startButton = imageFrame:WaitForChild("StartButton")
local exitButton = balloonHudGui:WaitForChild("ExitButton")
local balloonFrame = balloonHudGui:WaitForChild("BalloonListFrame")
local balloonListFrame = balloonFrame:WaitForChild("ScrollingFrame")

local luckBarFrame = balloonHudGui:WaitForChild("LuckBarFrame")
local luckLabel = luckBarFrame:WaitForChild("LuckLabel")

local standPlatform = balloonStation:WaitForChild("StandPlatform")

local function resetBalloonSize()
	balloonPart.Size = Vector3.new(1, 1, 1)
	balloonPart.Position = balloonBasePosition
end

local function setStartButtonState(buttonState)
	if buttonState == "idle" then
		startButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
		startButton.Active = true
	elseif buttonState == "active" then
		startButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
		startButton.Active = true
	elseif buttonState == "inactive" then
		startButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
		startButton.Active = false
	end
end

local function setCharacterVisible(visible)
	local character = Players.LocalPlayer.Character
	if not character then return end
	local modifier = visible and 0 or 1
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Decal") then
			part.LocalTransparencyModifier = modifier
		end
	end
end

local function focusCameraOnBalloon()
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	local balloonPos = balloonPart.Position
	camera.CFrame = CFrame.new(balloonPos + Vector3.new(0, 2, 8), balloonPos)
end

local function updateCameraFollow()
	local camera = Workspace.CurrentCamera
	if camera.CameraType ~= Enum.CameraType.Scriptable then return end
	local balloonPos = balloonPart.Position
	local currentCF = camera.CFrame
	local targetCF = CFrame.new(
		Vector3.new(currentCF.Position.X, balloonPos.Y + 2, currentCF.Position.Z),
		balloonPos
	)
	camera.CFrame = currentCF:Lerp(targetCF, 0.1)
end

local function returnCamera()
	local camera = Workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
end

local function refreshBalloonList()
	for _, child in ipairs(balloonListFrame:GetChildren()) do
		if (child :: Instance):IsA("ImageButton") then
			child:Destroy()
		end
	end

	for balloonName, balloonCount in pairs(ownedBalloons) do
		local item = BalloonButtonTemplate:Clone()
		local config = BalloonConfig[balloonName]
		
		item.Visible = true
		item.CountLabel.Text = `x{balloonCount}`
		item.NameLabel.Text = config.displayName
		item.LayoutOrder = config.layoutOrder
		
		if balloonName ~= "Default" then 
			item.IconLabel.ImageColor3 = GameConfig.RARITY_COLORS[config.maxRarity]
		else
			item.CountLabel.Text = `∞`
		end
		
		if balloonName == cachedActiveBalloon then
			item.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		else
			item.BackgroundColor3 = Color3.fromRGB(27, 29, 42)
		end
		
		item.MouseButton1Click:Connect(function()
			Remotes.Balloon_Equip:FireServer(balloonName)
		end)
		item.Parent = balloonListFrame
	end
end

local function startInflateLoop()
	inflateConnection = RunService.Heartbeat:Connect(function(dt)
		if phase ~= Phase.Inflating then
			inflateConnection:Disconnect()
			return
		end

		local elapsed = tick() - startTime
		local t = math.clamp(elapsed / 60, 0, 1)

		local config = BalloonConfig[cachedActiveBalloon]
		local previewReward = math.floor(config.baseReward + (config.maxReward - config.baseReward) * t)
		rewardLabel.Text = "+" .. previewReward

		local inflateLuck = t * 2
		luckLabel.Text = "Удача: " .. string.format("%.1f", inflateLuck)

		local targetSize = Vector3.new(1 + t * 3, 1 + t * 3, 1 + t * 3)
		local pulse = 1 + math.sin(elapsed * 8) * 0.03 * (1 - t)
		balloonPart.Size = targetSize * pulse

		balloonPart.Position = balloonBasePosition + Vector3.new(0, t * 5, 0)

		updateCameraFollow()

		applauseTimer += dt
		if applauseTimer >= GameConfig.APPLAUSE_INTERVAL then
			applauseTimer = 0
			AudioController.Play(AudioController.Sounds.Applause)
		end
	end)
end

local function switchPhase(target)
	if phase == target then return end

	if phase == Phase.Inflating then
		AudioController.Stop(inflateLoopId)
		if inflateConnection then
			inflateConnection:Disconnect()
			inflateConnection = nil
		end
	end
	
	if target ~= Phase.Viewing then
		if readyDelay then coroutine.resume(readyDelay); readyDelay = nil end
	end

	if target == Phase.Inflating then
		startTime = tick()
		applauseTimer = 0
		focusCameraOnBalloon()
		setCharacterVisible(false)
		exitButton.Visible = true
		setStartButtonState("active")
		Remotes.Balloon_Start:FireServer()
		startInflateLoop()
		inflateLoopId = AudioController.PlayLoop(AudioController.Sounds.Inflate)

	elseif target == Phase.Viewing then
		resetBalloonSize()
		rewardLabel.Text = ""
		setStartButtonState("inactive")
		exitButton.Visible = true

	elseif target == Phase.Ready then
		setStartButtonState("idle")

	elseif target == Phase.Roulette then
		resetBalloonSize()
		rewardLabel.Text = ""
		balloonModel.Parent = nil
		setStartButtonState("inactive")
		exitButton.Visible = false

	elseif target == Phase.Near then
		returnCamera()
		setCharacterVisible(true)
		exitButton.Visible = false
		setStartButtonState("idle")
		balloonHudGui.Enabled = true
		refreshBalloonList()

	elseif target == Phase.Idle then
		returnCamera()
		setCharacterVisible(true)
		exitButton.Visible = false
		balloonHudGui.Enabled = false
	end

	phase = target
end

local function autoReady()
	if readyDelay then task.cancel(readyDelay) end
	readyDelay = task.delay(1.5, function()
		if phase == Phase.Viewing then
			switchPhase(Phase.Ready)
		end
	end)
end

function BalloonController.Init()
	ReplicaClient.OnNew("PlayerData", function(replica)
		cachedActiveBalloon = replica.Data.ActiveBalloon
		ownedBalloons = replica.Data.Balloons
		cachedActiveSticker = replica.Data.ActiveSticker or ""
		applySticker(cachedActiveSticker)

		replica:OnSet({"ActiveBalloon"}, function(new)
			cachedActiveBalloon = new
			local config = BalloonConfig[new]
			if new == "Default" then
				balloonPart.Color = Color3.fromRGB(255, 0, 0)
			else
				balloonPart.Color = GameConfig.RARITY_COLORS[config.maxRarity]
			end

			if phase == Phase.Near then
				refreshBalloonList()
			end
		end)

		replica:OnSet({"Balloons"}, function(new)
			ownedBalloons = new
			if phase == Phase.Near then
				refreshBalloonList()
			end
		end)

		replica:OnSet({"ActiveSticker"}, function(new)
			cachedActiveSticker = new or ""
			applySticker(cachedActiveSticker)
		end)
	end)

	Remotes.Balloon_Result.OnClientEvent:Connect(function(result)
		if phase ~= Phase.Inflating then return end

		if result.type == "pop" then
			switchPhase(Phase.Viewing)
			AudioController.Play(AudioController.Sounds.Pop)
			balloonModel.Parent = nil
			task.wait(1)
			balloonModel.Parent = balloonStation
			autoReady()

		elseif result.type == "roulette" then
			switchPhase(Phase.Roulette)

		elseif result.type == "coins_only" then
			switchPhase(Phase.Viewing)
			AudioController.Play(AudioController.Sounds.Coin)
			autoReady()

		elseif result.type == "no_balloon" then
			switchPhase(Phase.Near)
		end
	end)

	startButton.MouseButton1Down:Connect(function()
		if phase ~= Phase.Near and phase ~= Phase.Ready then return end
		switchPhase(Phase.Inflating)
	end)

	startButton.MouseButton1Up:Connect(function()
		if phase ~= Phase.Inflating then return end
		Remotes.Balloon_Stop:FireServer()
	end)

	exitButton.MouseButton1Click:Connect(function()
		if readyDelay then task.cancel(readyDelay); readyDelay = nil end
		if phase == Phase.Inflating then
			Remotes.Balloon_Stop:FireServer()
		end
		if phase ~= Phase.Near and phase ~= Phase.Idle then
			switchPhase(Phase.Near)
		end
	end)

	standPlatform.Touched:Connect(function(hit)
		local character = Players.LocalPlayer.Character
		if not character then return end
		if hit ~= character:FindFirstChild("HumanoidRootPart") then return end
		if phase == Phase.Idle then
			switchPhase(Phase.Near)
		end
	end)

	standPlatform.TouchEnded:Connect(function(hit)
		local character = Players.LocalPlayer.Character
		if not character then return end
		if hit ~= character:FindFirstChild("HumanoidRootPart") then return end
		if phase == Phase.Near or phase == Phase.Ready then
			switchPhase(Phase.Idle)
		end
	end)
end

function BalloonController.Start()
	resetBalloonSize()
	balloonHudGui.Enabled = false
end

function BalloonController.ReturnFromRoulette()
	if phase ~= Phase.Roulette then return end
	balloonModel.Parent = balloonStation
	switchPhase(Phase.Viewing)
end

return BalloonController