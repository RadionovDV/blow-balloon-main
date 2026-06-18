local TweenService = game:GetService("TweenService")

local StatefulObjectController = {}

local activeTweens = {}

function StatefulObjectController.Tween(instance, properties, duration, style, direction)
	if activeTweens[instance] then
		activeTweens[instance]:Cancel()
		activeTweens[instance] = nil
	end

	local tweenInfo = TweenInfo.new(
		duration,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	activeTweens[instance] = tween

	tween.Completed:Connect(function()
		if activeTweens[instance] == tween then
			activeTweens[instance] = nil
		end
	end)

	tween:Play()
	return tween
end

function StatefulObjectController.Cancel(instance)
	if activeTweens[instance] then
		activeTweens[instance]:Cancel()
		activeTweens[instance] = nil
	end
end

function StatefulObjectController.CancelAll()
	for instance, tween in pairs(activeTweens) do
		tween:Cancel()
	end
	activeTweens = {}
end

return StatefulObjectController