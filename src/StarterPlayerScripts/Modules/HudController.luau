local Players = game:GetService("Players")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicaClient = require(ReplicatedStorage.Lib.ReplicaClient)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StatefulObjectController = require(script.Parent.StatefulObjectController)

local HudController = {}

function HudController.Init()
	ReplicaClient.OnNew("PlayerData", function(replica)
		HudController.UpdateCoins(replica.Data.Coins)
		HudController.UpdateLuck(replica.Data.BaseLuck)

		replica:OnSet({"Coins"}, function(new)
			HudController.UpdateCoins(new)
		end)

		replica:OnSet({"BaseLuck"}, function(new)
			HudController.UpdateLuck(new)
		end)
	end)

	Remotes.Notification.OnClientEvent:Connect(function(data)
		HudController.ShowNotification(data.text, data.style)
	end)
end

function HudController.Start()
end

function HudController.UpdateCoins(amount)
	local label = PlayerGui:WaitForChild("HudGui"):WaitForChild("CoinsLabel")
	label.Text = "Монет: " .. tostring(math.floor(amount))
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