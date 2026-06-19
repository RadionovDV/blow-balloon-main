local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local BaseService = {}

local baseAssignments = {}

local location = Workspace:WaitForChild("Location")
local basesFolder = location:WaitForChild("Bases")

local baseOwnerLabels = {}
do
	for i = 1, GameConfig.BASE_COUNT do
		local baseModel = basesFolder:FindFirstChild("Base" .. tostring(i))
		if baseModel then
			local ownerSign = baseModel:FindFirstChild("OwnerSign")
			local ownerLabel = ownerSign
				and ownerSign:FindFirstChild("Sign2")
				and ownerSign.Sign2:FindFirstChild("Background")
				and ownerSign.Sign2.Background:FindFirstChild("SurfaceGui")
				and ownerSign.Sign2.Background.SurfaceGui:FindFirstChild("Frame")
				and ownerSign.Sign2.Background.SurfaceGui.Frame:FindFirstChild("OwnerLabel")
				or nil
			baseOwnerLabels[i] = ownerLabel
		else
			baseOwnerLabels[i] = nil
		end
	end
end

function BaseService.Init()
end

function BaseService.Start()
	Players.PlayerAdded:Connect(function(player)
		local taken = {}
		for _, id in pairs(baseAssignments) do
			taken[id] = true
		end

		local baseId = nil
		for i = 1, GameConfig.BASE_COUNT do
			if not taken[i] then
				baseId = i
				break
			end
		end

		if not baseId then
			warn("[BaseService] No free base for player:", player.Name)
			return
		end

		local ownerLabel = baseOwnerLabels[baseId]
		if ownerLabel then
			ownerLabel.Text = player.Name
		end

		baseAssignments[player] = baseId

		Remotes.Base_Assigned:FireClient(player, baseId)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local baseId = baseAssignments[player]
		if baseId then
			local ownerLabel = baseOwnerLabels[baseId]
			if ownerLabel then
				ownerLabel.Text = ""
			end

			baseAssignments[player] = nil
		end
	end)
end

function BaseService.GetBaseId(player)
	return baseAssignments[player]
end

function BaseService.GetSpawnCFrame(player)
	local baseId = BaseService.GetBaseId(player)
	if not baseId then
		return nil
	end
	local baseModel = basesFolder:FindFirstChild("Base" .. tostring(baseId))
	if not baseModel then
		return nil
	end
	local spawnPoint = baseModel:FindFirstChild("SpawnPoint")
	if not spawnPoint or not spawnPoint:IsA("BasePart") then
		return nil
	end
	return spawnPoint.CFrame
end

return BaseService