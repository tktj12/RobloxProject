local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LEnum = require(ReplicatedStorage.Modules.Shared.LEnum)
local SharedData = require(ReplicatedStorage.Modules.Shared.SharedData)
local Signal = require(ReplicatedStorage.Modules.Shared.Signal)
local Types = require(ReplicatedStorage.Modules.Shared.Types)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

type Signal = Signal.Signal
export type DataField = {
	id: number,
	runtime: {
		ShotDamage: number,
		CriticalShotPower: number,
		TimedShotPower: number,
		ComboDamage: number,
		DrawSpeed: number,
		LoadSpeed: number,
		DrawStrength: number,
		MovementSpeed: number,
		WallHP: number,
		[PlayerRuntimeDataKey]: number,
	},
	saved: {
		Gold: number,
		Soul: number,
		WaveLevelInfo: buffer,
		TotalDamageDealt: number,
		SkillRanks: { [string]: number },
	},
	on_update: Signal,
}

export type PlayerRuntimeDataKey = keyof<index<DataField, "runtime">>

local Defaults: DataField = Util.deepFreeze {
	id = 0,
	runtime = {
		ShotDamage = 10,
		CriticalShotPower = 1.1,
		TimedShotPower = 1,
		ComboDamage = 0,
		DrawSpeed = 1,
		LoadSpeed = 1,
		DrawStrength = 1,
		MovementSpeed = 1,
		WallHP = 50,
	},
	saved = {
		Gold = 0,
		Soul = 0,
		WaveLevelInfo = buffer.create(4),
		TotalDamageDealt = 0,
		SkillRanks = {},
	},
	on_update = Signal.new(),
}

local PlayerData = {}
PlayerData.__index = PlayerData
PlayerData.Event = ReplicatedStorage.Events.PlayerDataSync
PlayerData.Defaults = Defaults

export type PlayerData = typeof(setmetatable({} :: DataField, PlayerData))

function PlayerData.new(t: Types.DeepPartial<DataField>): PlayerData
	local self = Util.deepCopy(t) :: DataField
	Util.reconcile(self, Defaults)
	self.on_update = Signal.new()

	if RunService:IsClient() then
		PlayerData.Event.OnClientEvent:Connect(function(data: PlayerData)
			Util.deepUpdate(self, data)
		end)
	end

	return setmetatable(self :: DataField, PlayerData)
end

function PlayerData.update(self: PlayerData, t: Types.DeepPartial<DataField>): ()
	Util.deepUpdate(self, t)
	self.on_update:fire(t)
end

type ShotTimingData = { read runtime: { read DrawSpeed: number, read LoadSpeed: number } }

function PlayerData.getFullDrawTime(self: ShotTimingData): number
	return SharedData.DEFAULT_DRAW_TIME / self.runtime.DrawSpeed
end

function PlayerData.getReloadTime(self: ShotTimingData): number
	return SharedData.DEFAULT_RELOAD_TIME / self.runtime.LoadSpeed
end

function PlayerData.getColor(player: Player): Color3
	local color_value = player:GetAttribute(LEnum.PlayerAttribute.Color) :: BrickColor
	if not color_value then
		error("Player does not have a color attribute set.")
	end
	return color_value.Color
end

return PlayerData
