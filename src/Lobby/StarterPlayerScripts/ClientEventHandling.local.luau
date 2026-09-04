local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bitset = require(ReplicatedStorage.Modules.Shared.Bitset)
local GameState = require(ReplicatedStorage.Modules.Shared.GameState)
local GuiService = require(ReplicatedStorage.Modules.Client.GuiService)
local Party = require(ReplicatedStorage.Modules.Client.Party)
local WaveLevel = require(ReplicatedStorage.Modules.Shared.WaveLevel)
local WavePage = require(ReplicatedStorage.Modules.Client.WavePage)

local DataSync = ReplicatedStorage.Events.DataSync
local UserEvent = ReplicatedStorage.Events.UserEvent

local dataEventHandlers = {
	-- LevelInfo = WaveLevel.setClearTable,
	WaveLevelInfo = function(serialized_data): ()
		WaveLevel.setClearStatus(serialized_data)
		WavePage.reload()
		print("LevelInfo received")
	end,
}

local function onDataEvent(req: string, ...)
	local handler = dataEventHandlers[req]
	if handler then
		handler(...)
	end
end
DataSync.OnClientEvent:Connect(onDataEvent)

local handlers = {
	Message = GuiService.spawnMessageBox,
	PartyInvite = Party.receiveInvite,
	InviteAck = Party.onInviteAck,
}

UserEvent.OnClientEvent:Connect(function(event: string, ...)
	local handler = handlers[event]
	if handler then
		handler(...)
	end
end)
