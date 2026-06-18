local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AudioController = {}

AudioController.Sounds = {
	Pop         = "Pop",
	Inflate     = "Inflate",
	Applause    = "Applause",
	PetGet      = "PetGet",
	Coin        = "Coin",
	ButtonClick = "ButtonClick",
	RouletteEnd = "RouletteEnd",
	Music1      = "Music_1",
}

local soundsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Sounds")
local loopingTracks = {}

function AudioController.Init()
end

function AudioController.Play(soundName)
	local sound = soundsFolder:FindFirstChild(soundName)
	if sound then
		sound:Play()
	else
		warn("[AudioController] Sound not found:", soundName)
	end
end

function AudioController.PlayLoop(soundName)
	local sound = soundsFolder:FindFirstChild(soundName)
	if not sound then
		warn("[AudioController] Sound not found:", soundName)
		return ""
	end
	local id = soundName .. "_" .. tostring(tick())
	local clone = sound:Clone()
	clone.Looped = true
	clone.Parent = workspace
	clone:Play()
	loopingTracks[id] = clone
	return id
end

function AudioController.Stop(id)
	if loopingTracks[id] then
		loopingTracks[id]:Stop()
		loopingTracks[id]:Destroy()
		loopingTracks[id] = nil
	end
end

return AudioController