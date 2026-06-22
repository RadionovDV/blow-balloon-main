local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StatefulObjectController = require(script.Parent.StatefulObjectController)
local FormatNumber = require(ReplicatedStorage.Shared.Util.FormatNumber)
local MonetizationConfig = require(ReplicatedStorage.Shared.Config.MonetizationConfig)

local HudController = {}

local activeTimed = {}
local boostTemplate = ReplicatedStorage.Assets.UI:FindFirstChild("TemporaryBoost")
local statesFrame = nil
local replicaData = nil
local boostTimerConnection = nil

local function getTimedEntries()
	if not replicaData then
		return {}
	end
	local now = os.time()
	local result = {}
	for _, boost in ipairs(replicaData.MonetizationEntitlements.Timed) do
		if boost.expiresAt > now then
			table.insert(result, boost)
		end
	end
	return result
end

local function rebuildBoostIcons()
	if not statesFrame then
		return
	end
	if not boostTemplate then
		return
	end

	for _, child in ipairs(statesFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "TemporaryBoost" then
			child:Destroy()
		end
	end

	local entries = getTimedEntries()
	activeTimed = {}

	for _, boost in ipairs(entries) do
		local clone = boostTemplate:Clone()
		clone.Name = boost.id .. "_" .. tostring(boost.expiresAt)
		clone.Parent = statesFrame
		clone.Visible = true

		local iconLabel = clone:FindFirstChild("IconLabel")
		if iconLabel and iconLabel:IsA("ImageLabel") then
			local boostIcon = MonetizationConfig.BOOST_ICONS[boost.id]
			if boostIcon then
				iconLabel.Image = boostIcon
			end
		end

		local speedLabel = clone:FindFirstChild("SpeedLabel")
		if speedLabel and speedLabel:IsA("TextLabel") then
			speedLabel.Text = FormatNumber.FormatTime(boost.expiresAt - os.time())
		end

		table.insert(activeTimed, {
			id = boost.id,
			expiresAt = boost.expiresAt,
			speedLabel = speedLabel,
		})
	end

	if boostTimerConnection then
		boostTimerConnection:Disconnect()
		boostTimerConnection = nil
	end

	if #activeTimed > 0 then
		boostTimerConnection = RunService.Heartbeat:Connect(function()
			local anyActive = false
			for _, entry in ipairs(activeTimed) do
				if entry.speedLabel and entry.speedLabel.Parent then
					local remaining = entry.expiresAt - os.time()
					if remaining > 0 then
						entry.speedLabel.Text = FormatNumber.FormatTime(remaining)
						anyActive = true
					else
						entry.speedLabel.Text = "00:00"
					end
				end
			end
			if not anyActive then
				rebuildBoostIcons()
			end
		end)
	end
end

function HudController.Init()
	ReplicaClient.OnNew("PlayerData", function(replica)
		replicaData = replica.Data
		HudController.UpdateCoins(replicaData.Coins)
		HudController.UpdateLuck(replicaData.BaseLuck)

		replica:OnSet({"Coins"}, function(new)
			HudController.UpdateCoins(new)
		end)

		replica:OnSet({"BaseLuck"}, function(new)
			HudController.UpdateLuck(new)
		end)

		replica:OnSet({"MonetizationEntitlements", "Timed"}, function()
			replicaData = replica.Data
			rebuildBoostIcons()
		end)
	end)

	Remotes.Notification.OnClientEvent:Connect(function(data)
		HudController.ShowNotification(data.text, data.style)
	end)
end

function HudController.Start()
	statesFrame = PlayerGui:WaitForChild("HudGui"):FindFirstChild("States")
	if not boostTemplate then
		boostTemplate = ReplicatedStorage.Assets.UI:FindFirstChild("TemporaryBoost")
	end
end

function HudController.UpdateCoins(amount)
	local label = PlayerGui:WaitForChild("HudGui"):WaitForChild("CoinsLabel")
	label.Text = FormatNumber.Format(math.floor(amount))
end

function HudController.UpdateLuck(amount)
	local label = PlayerGui:WaitForChild("HudGui"):WaitForChild("LuckLabel")
	label.Text = "Удача: " .. tostring(amount)
end

function HudController.ShowNotification(text, style)
	local frame = PlayerGui:WaitForChild("NotificationGui"):WaitForChild("NotificationFrame")
	local label = frame:WaitForChild("NotificationText")
	label.Text = text
	frame.Visible = true
	StatefulObjectController.Tween(frame, { BackgroundTransparency = 0 }, 0.2)
	task.delay(2, function()
		StatefulObjectController.Tween(frame, { BackgroundTransparency = 1 }, 0.3)
		task.wait(0.3)
		frame.Visible = false
	end)
end

return HudController