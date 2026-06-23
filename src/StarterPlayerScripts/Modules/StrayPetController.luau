local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local StrayPetController = {}

local function updatePrompt(prompt)
	local attachment = prompt.Parent
	if not attachment then
		return
	end

	local ownerUserId = attachment:GetAttribute("OwnerUserId")
	if not ownerUserId then
		return
	end

	local isOwner = ownerUserId == Players.LocalPlayer.UserId
	local savePetsActive = attachment:GetAttribute("SavePetsActive")

	if isOwner then
		prompt.ActionText = "Claim"
		prompt.Enabled = true
	elseif savePetsActive then
		prompt.Enabled = false
	else
		local price = attachment:GetAttribute("StrayPrice") or 0
		prompt.ActionText = "Buy"
		prompt.ObjectText = string.format("%s - %d Robux", prompt.ObjectText, price)
		prompt.Enabled = true
	end
end

local function onDescendantAdded(descendant)
	if descendant:IsA("ProximityPrompt") then
		updatePrompt(descendant)
	end
end

function StrayPetController.Init()
end

function StrayPetController.Start()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		onDescendantAdded(descendant)
	end

	Workspace.DescendantAdded:Connect(onDescendantAdded)
end

return StrayPetController
