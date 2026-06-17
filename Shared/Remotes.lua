local Remotes = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTE_EVENTS = {
	"Balloon_Start",
	"Balloon_Stop",
	"Balloon_Equip",
	"Base_Collect",
	"Pet_PlaceStand",
	"Pet_RemoveStand",
	"Balloon_Result",
	"Roulette_Show",
	"Tutorial_Step",
	"Notification",
}

local REMOTE_FUNCTIONS = {
	"Shop_BuyBalloon",
}

if RunService:IsServer() then
	local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = ReplicatedStorage
	end

	for _, name in ipairs(REMOTE_EVENTS) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
		Remotes[name] = remote
	end

	for _, name in ipairs(REMOTE_FUNCTIONS) do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remotesFolder
		Remotes[name] = remote
	end
else
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")

	for _, name in ipairs(REMOTE_EVENTS) do
		Remotes[name] = remotesFolder:WaitForChild(name)
	end

	for _, name in ipairs(REMOTE_FUNCTIONS) do
		Remotes[name] = remotesFolder:WaitForChild(name)
	end
end

return Remotes