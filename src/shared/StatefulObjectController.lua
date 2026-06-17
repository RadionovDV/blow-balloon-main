local TweenService = game:GetService("TweenService")

local StatefulObjectController = {}
StatefulObjectController.__index = StatefulObjectController

export type StateName = string
export type State = {
	transition: TweenInfo,
	properties: { [string]: any },
}

function StatefulObjectController.hydrate(props: {
		object: Instance,
		states: { [StateName]: State },
		initialStateName: StateName
	})
	local object, states, initialStateName = props.object, props.states, props.initialStateName

	local self = setmetatable({
		states = states,
		currentStateName = initialStateName,
		tweens = {},
	}, StatefulObjectController)

	-- Create tweens for reuse to avoid making new tweens every time state is changed
	for stateName, state in states do
		self.tweens[stateName] = TweenService:Create(object, state.transition, state.properties)
	end

	self:setState(self.currentStateName)

	return self
end

function StatefulObjectController:setState(stateName: StateName)
	local stateTween: Tween = self.tweens[stateName]
	if not stateTween then
		warn(string.format("Attempted to set %s to unknown state '%s'", self.object:GetFullName(), stateName))
		return
	end

	self.currentStateName = stateName

	-- Make sure other tweens aren't conflicting
	for _, tween in self.tweens do
		tween:Cancel()
	end

	stateTween:Play()
end

return StatefulObjectController