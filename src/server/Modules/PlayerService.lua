local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local ReplicaServer = require(ServerScriptService.Lib.ReplicaServer)
local ProfileStore = require(ServerScriptService.Lib.ProfileStore)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local PlayerService = {}

local ProfileTemplate = {
	Coins         = 0,
	Balloons      = { Default = 1 },
	ActiveBalloon = "Default",
	Pets          = {},
	StandPets     = {},
	BaseLevel     = 1,
	BaseSlots     = 10,
	RebirthCount  = 0,
	BaseLuck      = 1,
	LuckBonuses   = {
		temporary = {},
		permanent = 0,
	},
	TutorialStep  = 0,
	GamePasses    = {},
}

local profileStore
local PlayerDataToken

local profiles = {}
local replicas = {}
local passCache = {}

function PlayerService.Init()
	profileStore = ProfileStore.New("PlayerData", ProfileTemplate)
	PlayerDataToken = ReplicaServer.Token("PlayerData")

	Players.PlayerAdded:Connect(function(player)
		local success, profile = pcall(function()
			return profileStore:StartSessionAsync(tostring(player.UserId))
		end)

		if not success or not profile then
			player:Kick("Failed to load player data. Please rejoin.")
			return
		end

		profile:OnSessionEnd(function()
			player:Kick("Data session ended. Please rejoin.")
		end)

		profile:Reconcile()

		local playerPasses = {}
		for passName, passId in pairs(GameConfig.GAMEPASS_IDS) do
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
			end)
			playerPasses[passName] = ok and owns or false
		end
		profile.Data.GamePasses = playerPasses
		passCache[player] = playerPasses

		local now = os.time()
		local tempLuck = profile.Data.LuckBonuses.temporary
		local filtered = {}
		for _, boost in ipairs(tempLuck) do
			if boost.expiresAt > now then
				table.insert(filtered, boost)
			end
		end
		profile.Data.LuckBonuses.temporary = filtered

		local replica = ReplicaServer.New({
			Token = PlayerDataToken,
			Tags  = { UserId = player.UserId },
			Data  = profile.Data,
		})
		replica:Subscribe(player)

		profiles[player] = profile
		replicas[player] = replica
	end)

	Players.PlayerRemoving:Connect(function(player)
		local replica = replicas[player]
		if replica then
			replica:Destroy()
			replicas[player] = nil
		end

		local profile = profiles[player]
		if profile then
			profile:EndSession()
			profiles[player] = nil
		end

		passCache[player] = nil
	end)
end

function PlayerService.Start()
end

function PlayerService.GetData(player)
	return profiles[player] and profiles[player].Data or nil
end

function PlayerService.GetReplica(player)
	return replicas[player] or nil
end

function PlayerService.HasPass(player, passName)
	return passCache[player] and passCache[player][passName] == true
end

function PlayerService.SetData(player, path, value)
	local data = PlayerService.GetData(player)
	if not data then
		return
	end

	local pointer = data
	for i = 1, #path - 1 do
		pointer = pointer[path[i]]
		if pointer == nil then
			return
		end
	end
	pointer[path[#path]] = value

	local replica = PlayerService.GetReplica(player)
	if replica then
		replica:Set(path, value)
	end
end

return PlayerService