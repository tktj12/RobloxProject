local Players = game:GetService("Players")

local LEnum = require(game.ReplicatedStorage.Modules.Shared.LEnum)
local PlayerData = require(game.ReplicatedStorage.Modules.Shared.PlayerData)
local SharedData = require(game.ReplicatedStorage.Modules.Shared.SharedData)
local Util = require(game.ReplicatedStorage.Modules.Shared.Util)

type PlayerData = PlayerData.PlayerData
type PlayerRuntimeData = index<PlayerData, "runtime">

local id_counter = 1

local ArrowInfo = {}
ArrowInfo.__index = ArrowInfo
ArrowInfo.DISAPPEAR_TIME = 35
ArrowInfo.HIT_DISAPPEAR_TIME = 10
export type ArrowInfo = typeof(setmetatable(
	{} :: {
		name: string,
		draw_time: number,
		draw_power: number,
		damage: number,
		critical_damage: number,
		start_cframe: CFrame,
		shot_mode: number,
		shooter: Player,
		id: number,
	},
	ArrowInfo
))

function ArrowInfo.new(params: {
	name: string,
	draw_time: number,
	start_cframe: CFrame,
	shot_mode: number?,
	shooter: Player?,
	damage: number?,
	critical_damage: number?,
}): ArrowInfo
	local self = {
		name = params.name,
		draw_time = params.draw_time,
		draw_power = 0,
		shot_mode = params.shot_mode or LEnum.ShotMode.Normal,
		damage = params.damage or 0,
		critical_damage = params.critical_damage or 0,
		start_cframe = params.start_cframe,
		shooter = params.shooter or Players.LocalPlayer,
		id = id_counter,
	}
	id_counter += 1
	setmetatable(self, ArrowInfo)

	return self
end

function ArrowInfo.calcDamage(self: ArrowInfo, runtime_data: PlayerRuntimeData, combo: number)
	local abilities = runtime_data
	local damage = abilities.ShotDamage

	damage *= math.map(self.draw_power, 0, abilities.DrawStrength, 0, 1)

	damage *= 1 + math.min(combo * abilities.ComboDamage, SharedData.MAX_COMBO_DAMAGE)

	local shot_mode = self.shot_mode
	if Util.hasAllFlags(shot_mode, LEnum.ShotMode.Timed) then
		damage *= abilities.TimedShotPower
	end

	self.critical_damage = math.round(damage * abilities.CriticalShotPower)

	self.damage = math.round(damage)
end

function ArrowInfo.calcDrawPower(self: ArrowInfo, runtime_data: PlayerRuntimeData): number
	local full_draw = SharedData.DEFAULT_DRAW_TIME / runtime_data.DrawSpeed
	self.draw_power = math.clamp(self.draw_time, 0, full_draw)
	self.draw_power = math.map(self.draw_power, 0, full_draw, 0.2, runtime_data.DrawStrength)
	return self.draw_power
end

return ArrowInfo
