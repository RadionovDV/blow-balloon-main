local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local REMOTE_EVENT_NAMES = {
	"Balloon_Start",
	"Balloon_Stop",
	"Balloon_Equip",
	"Pet_PlaceStand",
	"Pet_RemoveStand",
	"Pet_SpawnWorld",
	"Balloon_Result",
	"Roulette_Show",
	"Tutorial_Step",
	"Notification",
	"Base_Assigned",
}

local REMOTE_FUNCTION_NAMES = {
	"Shop_BuyBalloon",
	"Base_Collect",
	"Rebirth_Perform",
	"Roulette_ResolvePetChoice",
}

if RunService:IsServer() then
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	for _, name in ipairs(REMOTE_EVENT_NAMES) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
		Remotes[name] = remote
	end

	for _, name in ipairs(REMOTE_FUNCTION_NAMES) do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remotesFolder
		Remotes[name] = remote
	end
else
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

	for _, name in ipairs(REMOTE_EVENT_NAMES) do
		Remotes[name] = remotesFolder:WaitForChild(name)
	end

	for _, name in ipairs(REMOTE_FUNCTION_NAMES) do
		Remotes[name] = remotesFolder:WaitForChild(name)
	end
end

return Remotes