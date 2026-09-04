local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArrowInfo = require(ReplicatedStorage.Modules.Shared.ArrowInfo)
local Enemy = require(ReplicatedStorage.Modules.Client.Enemy)
local GameState = require(ReplicatedStorage.Modules.Shared.GameState)
local GuiService = require(ReplicatedStorage.Modules.Client.GuiService)
local LocalData = require(ReplicatedStorage.Modules.Client.LocalData)
local PlayerAction = require(ReplicatedStorage.Modules.Client.PlayerAction)
local WaveLevel = require(ReplicatedStorage.Modules.Shared.WaveLevel)
local WavePage = require(ReplicatedStorage.Modules.Client.WavePage)
require(ReplicatedStorage.Modules.Client.Party)

type ArrowInfo = ArrowInfo.ArrowInfo

local ArrowFired = ReplicatedStorage.Events.ArrowFired
local DataSync = ReplicatedStorage.Events.DataSync
local UserEvent = ReplicatedStorage.Events.UserEvent

local LocalPlayer = Players.LocalPlayer

local data_event_handlers = {
	WaveLevelInfo = function(serialized_data): ()
		WaveLevel.setClearStatus(serialized_data)
		WavePage.reload()
		print("LevelInfo received")
	end,
}

local function onDataEvent(req: string, ...)
	local handler = data_event_handlers[req]
	if handler then
		handler(...)
	end
end
DataSync.OnClientEvent:Connect(onDataEvent)

local user_event_handlers = {
	Message = GuiService.spawnMessageBox,
}

UserEvent.OnClientEvent:Connect(function(event: string, ...)
	local handler = user_event_handlers[event]
	if handler then
		handler(...)
	end
end)

ArrowFired.OnClientEvent:Connect(function(arrow_info: ArrowInfo)
	if arrow_info.shooter ~= LocalPlayer then
		PlayerAction.releaseBow(arrow_info)
	end
end)

GameState.onChange(GameState.Attribute.OnWave):Connect(function()
	local on_wave = GameState.get(GameState.Attribute.OnWave)
	if not on_wave then
		Enemy.clearAllEnemies()
	else
		LocalData.set("combo", 0)
	end
end)
