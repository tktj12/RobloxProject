local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LEnum = require(ReplicatedStorage.Modules.Shared.LEnum)

local value = ReplicatedStorage.GameState

local GameState = {
	-- Flags = Flags,
	_value = value,
	Attribute = LEnum.GameState,
}
GameState.__index = GameState

function GameState.get(att: string): any
	return value:GetAttribute(att)
end

function GameState.onChange(att: string): RBXScriptSignal
	return value:GetAttributeChangedSignal(att)
end

return GameState
