local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
local BalloonConfig = require(ReplicatedStorage.Shared.Config.BalloonConfig)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local AudioController = require(script.Parent.AudioController)

local BalloonController = {}

local state = {
	isInflating     = false,
	isNearBalloon   = false,
	startTime       = 0,
	currentBalloon  = nil,
	cameraReturning = false,
	applauseTimer   = 0,
	activeBalloon   = "Default",
	ownedBalloons   = {},
}

local inflateConnection = nil
local inflateLoopId = nil

local balloonStation = Workspace:WaitForChild("BalloonStation")
local balloonModel = balloonStation:WaitForChild("BalloonModel")
local balloonPart = balloonModel:WaitForChild("BalloonPart")
local billboardGui = balloonStation:WaitForChild("BillboardGui")
local rewardLabel = billboardGui:WaitForChild("RewardLabel")
local balloonBasePosition = balloonPart.Position

local balloonHudGui = PlayerGui:WaitForChild("BalloonHudGui")
local startButton = balloonHudGui:WaitForChild("StartButton")
local exitButton = balloonHudGui:WaitForChild("ExitButton")
local balloonListFrame = balloonHudGui:WaitForChild("BalloonListFrame")
local balloonItemTemplate = balloonListFrame:WaitForChild("BalloonItemTemplate")
local luckBarFrame = balloonHudGui:WaitForChild("LuckBarFrame")
local luckLabel = luckBarFrame:WaitForChild("LuckLabel")

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
		if child ~= balloonItemTemplate then
			child:Destroy()
		end
	end

	for balloonName, _ in pairs(state.ownedBalloons) do
		local item = balloonItemTemplate:Clone()
		item.Name = balloonName
		item.Visible = true
		local config = BalloonConfig[balloonName]
		if config then
			item:WaitForChild("NameLabel").Text = config.displayName
		end
		if balloonName == state.activeBalloon then
			item.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
		else
			item.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		end
		item.MouseButton1Click:Connect(function()
			Remotes.Balloon_Equip:FireServer(balloonName)
		end)
		item.Parent = balloonListFrame
	end
end

local function showBalloonHud()
	state.isNearBalloon = true
	balloonHudGui.Enabled = true
	refreshBalloonList()
	setStartButtonState("idle")
end

local function hideBalloonHud()
	if state.isInflating then return end
	state.isNearBalloon = false
	balloonHudGui.Enabled = false
end

local function startInflateLoop()
	inflateConnection = RunService.Heartbeat:Connect(function(dt)
		if not state.isInflating then
			inflateConnection:Disconnect()
			return
		end

		local elapsed = tick() - state.startTime
		local t = math.clamp(elapsed / 60, 0, 1)

		local config = BalloonConfig[state.activeBalloon]
		local previewReward = math.floor(config.baseReward + (config.maxReward - config.baseReward) * t)
		rewardLabel.Text = "+" .. previewReward

		local inflateLuck = t * 2
		luckLabel.Text = "Удача: " .. string.format("%.1f", inflateLuck)

		local targetSize = Vector3.new(1 + t * 3, 1 + t * 3, 1 + t * 3)
		local pulse = 1 + math.sin(elapsed * 8) * 0.03 * (1 - t)
		balloonPart.Size = targetSize * pulse

		balloonPart.Position = balloonBasePosition + Vector3.new(0, t * 5, 0)

		updateCameraFollow()

		state.applauseTimer += dt
		if state.applauseTimer >= GameConfig.APPLAUSE_INTERVAL then
			state.applauseTimer = 0
			AudioController.Play(AudioController.Sounds.Applause)
		end
	end)
end

local function startInflating()
	state.isInflating = true
	state.startTime = tick()
	state.applauseTimer = 0

	setCharacterVisible(false)
	focusCameraOnBalloon()

	exitButton.Visible = true
	setStartButtonState("active")

	Remotes.Balloon_Start:FireServer()

	startInflateLoop()

	inflateLoopId = AudioController.PlayLoop(AudioController.Sounds.Inflate)
end

local function stopInflating()
	if not state.isInflating then return end
	state.isInflating = false

	AudioController.Stop(inflateLoopId)

	setStartButtonState("inactive")
	exitButton.Visible = false

	Remotes.Balloon_Stop:FireServer()
end

function BalloonController.Init()
	ReplicaClient.OnNew("PlayerData", function(replica)
		state.activeBalloon = replica.Data.ActiveBalloon
		state.ownedBalloons = replica.Data.Balloons

		replica:OnSet({"ActiveBalloon"}, function(new)
			state.activeBalloon = new
			refreshBalloonList()
		end)

		replica:OnSet({"Balloons"}, function(new)
			state.ownedBalloons = new
			refreshBalloonList()
		end)
	end)

	Remotes.Balloon_Result.OnClientEvent:Connect(function(result)
		if result.type == "pop" then
			AudioController.Play(AudioController.Sounds.Pop)

			balloonModel.Parent = nil
			task.wait(1)
			balloonModel.Parent = balloonStation
			resetBalloonSize()

			returnCamera()
			setCharacterVisible(true)
			setStartButtonState("idle")

		elseif result.type == "roulette" then
			AudioController.Play(AudioController.Sounds.Coin)
			returnCamera()
			setCharacterVisible(true)
			setStartButtonState("idle")

		elseif result.type == "coins_only" then
			AudioController.Play(AudioController.Sounds.Coin)
			returnCamera()
			setCharacterVisible(true)
			setStartButtonState("idle")

		elseif result.type == "no_balloon" then
			setStartButtonState("idle")
		end

		resetBalloonSize()
	end)

	startButton.MouseButton1Down:Connect(function()
		if state.isInflating or not state.isNearBalloon then return end
		startInflating()
	end)

	startButton.MouseButton1Up:Connect(function()
		if not state.isInflating then return end
		stopInflating()
	end)

	exitButton.MouseButton1Click:Connect(function()
		if state.isInflating then
			stopInflating()
		end
		hideBalloonHud()
		returnCamera()
		setCharacterVisible(true)
	end)

	local proximityPrompt = balloonStation:FindFirstChildWhichIsA("ProximityPrompt")
	if proximityPrompt then
		proximityPrompt.Triggered:Connect(function()
			showBalloonHud()
		end)
	end
end

function BalloonController.Start()
	Workspace:WaitForChild("BalloonStation")
	resetBalloonSize()
end

return BalloonController