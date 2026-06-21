local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BaseService = require(script.Parent.BaseService)

local PetMovementService = {}

local location = Workspace:WaitForChild("Location")
local balloonStation = location:WaitForChild("BalloonStation")
local poi = location:WaitForChild("POI")

local spawnPets = balloonStation:WaitForChild("SpawnPets")
local petsMovement = poi:WaitForChild("PetsMovement")
local petsQuit = poi:WaitForChild("PetsQuit")

local petsAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Pets")

local APPROACH_DISTANCE = 5
local WANDER_DURATION = 60
local BASE_APPROACH_SPEED = 12
local WANDER_SPEED = 8
local QUIT_SPEED = 14
local HOVER_HEIGHT = 2

local function disableCollision(model)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = false
			desc.Anchored = true
		end
	end
end

local function getGroundPosition(originPos, lastValidPos)
	local rayOrigin = originPos + Vector3.new(0, 10, 0)
	local rayDir = Vector3.new(0, -25, 0)
	local rayResult = workspace:Raycast(rayOrigin, rayDir)
	if rayResult and rayResult.Position then
		return Vector3.new(originPos.X, rayResult.Position.Y + HOVER_HEIGHT, originPos.Z)
	end
	return lastValidPos
end

local function randomPointInPart(part)
	local half = part.Size / 2
	return Vector3.new(
		part.Position.X + math.random() * part.Size.X - half.X,
		part.Position.Y + 1,
		part.Position.Z + math.random() * part.Size.Z - half.Z
	)
end

local function getBaseApproachPosition(player)
	local baseId = BaseService.GetBaseId(player)
	if not baseId then
		return nil
	end

	local baseModel = location:WaitForChild("Bases"):FindFirstChild("Base" .. tostring(baseId))
	if not baseModel then
		return nil
	end

	local baseArea = baseModel:FindFirstChild("BaseArea")
	if not baseArea then
		return nil
	end

	local firstSlot = baseArea:FindFirstChild("StandSlot_1")
	if firstSlot then
		local standMesh = firstSlot:FindFirstChild("StandMesh")
		if standMesh then
			return standMesh.Position + Vector3.new(0, 3, 0)
		end
	end

	return nil
end

function PetMovementService.Init()
end

function PetMovementService.Start()
end

function PetMovementService.SpawnAtSpawnPets(petName)
	local template = petsAssets:FindFirstChild(petName)
	if not template then
		return nil
	end

	local petModel = template:Clone()
	disableCollision(petModel)
	petModel.Parent = Workspace

	local spawnPos = randomPointInPart(spawnPets)
	local initialPos = getGroundPosition(spawnPos, spawnPos)
	petModel:PivotTo(CFrame.lookAt(initialPos, initialPos + Vector3.new(0, 0, -1)))

	return petModel
end

function PetMovementService.MoveToBase(player, petModel, onComplete)
	if not petModel then
		if onComplete then
			onComplete()
		end
		return
	end

	local targetPos = getBaseApproachPosition(player)
	if not targetPos then
		if onComplete then
			onComplete()
		end
		return
	end

	local lastValidPos = petModel:GetPivot().Position
	local connection

	connection = RunService.Heartbeat:Connect(function()
		if not petModel or not petModel.Parent then
			connection:Disconnect()
			return
		end

		local currentPos = petModel:GetPivot().Position
		local direction = targetPos - currentPos
		local distance = direction.Magnitude

		if distance < APPROACH_DISTANCE then
			connection:Disconnect()
			if onComplete then
				onComplete()
			end
			return
		end

		local stepPos = currentPos + direction.Unit * math.min(BASE_APPROACH_SPEED * 0.05, distance)
		local groundPos = getGroundPosition(stepPos, lastValidPos)
		lastValidPos = groundPos

		petModel:PivotTo(CFrame.lookAt(groundPos, targetPos))
	end)
end

function PetMovementService.WanderAndDespawn(petModel)
	if not petModel then
		return
	end

	local lastValidPos = petModel:GetPivot().Position
	local elapsed = 0
	local currentTarget = randomPointInPart(petsMovement)
	local connection

	connection = RunService.Heartbeat:Connect(function(dt)
		if not petModel or not petModel.Parent then
			connection:Disconnect()
			return
		end

		elapsed = elapsed + dt

		local currentPos = petModel:GetPivot().Position

		if elapsed < WANDER_DURATION then
			local direction = currentTarget - currentPos
			local distance = direction.Magnitude

			if distance < APPROACH_DISTANCE then
				currentTarget = randomPointInPart(petsMovement)
				return
			end

			local speed = elapsed < WANDER_DURATION * 0.5 and WANDER_SPEED or WANDER_SPEED * 1.2
			local stepPos = currentPos + direction.Unit * math.min(speed * dt, distance)
			local groundPos = getGroundPosition(stepPos, lastValidPos)
			lastValidPos = groundPos

			petModel:PivotTo(CFrame.lookAt(groundPos, currentTarget))
		else
			local quitDirection = petsQuit.Position - currentPos
			local quitDistance = quitDirection.Magnitude

			if quitDistance < APPROACH_DISTANCE then
				connection:Disconnect()
				petModel:Destroy()
				return
			end

			local stepPos = currentPos + quitDirection.Unit * math.min(QUIT_SPEED * dt, quitDistance)
			local groundPos = getGroundPosition(stepPos, lastValidPos)
			lastValidPos = groundPos

			petModel:PivotTo(CFrame.lookAt(groundPos, petsQuit.Position))
		end
	end)
end

return PetMovementService