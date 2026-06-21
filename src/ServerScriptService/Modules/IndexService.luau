local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerService = require(ServerScriptService.Modules.PlayerService)

local IndexService = {}

function IndexService.Init()
end

function IndexService.Start()
end

function IndexService.AddToIndex(player, petName)
	local data = PlayerService.GetData(player)
	if not data then
		return false
	end

	for _, name in ipairs(data.Index) do
		if name == petName then
			return true
		end
	end

	table.insert(data.Index, petName)
	PlayerService.GetReplica(player):Set({"Index"}, data.Index)
	return true
end

return IndexService