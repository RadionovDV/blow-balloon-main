local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlayerService = require(ServerScriptService.Modules.PlayerService)

local StickerService = {}

function StickerService.Init()
	Remotes.Sticker_Equip.OnServerInvoke = function(player, payload)
		if type(payload) ~= "table" or type(payload.stickerName) ~= "string" then
			return false
		end

		local stickerName = payload.stickerName
		local data = PlayerService.GetData(player)
		if not data then
			return false
		end

		local owned = false
		for _, name in ipairs(data.Stickers) do
			if name == stickerName then
				owned = true
				break
			end
		end
		if not owned then
			return false
		end

		data.ActiveSticker = stickerName
		PlayerService.SetData(player, {"ActiveSticker"}, stickerName)
		return true
	end

	Remotes.Sticker_Unequip.OnServerInvoke = function(player)
		local data = PlayerService.GetData(player)
		if not data then
			return false
		end

		data.ActiveSticker = ""
		PlayerService.SetData(player, {"ActiveSticker"}, "")
		return true
	end
end

function StickerService.Start()
end

return StickerService