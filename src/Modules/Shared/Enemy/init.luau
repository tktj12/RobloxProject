local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArrowInfo = require(ReplicatedStorage.Modules.Shared.ArrowInfo)
local HitInfo = require(ReplicatedStorage.Modules.Shared.HitInfo)
local LEnum = require(ReplicatedStorage.Modules.Shared.LEnum)
local Stat = require(script.Stat)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

type ArrowInfo = ArrowInfo.ArrowInfo
type HitInfo = HitInfo.HitInfo
type EnemyHitInfo = HitInfo.EnemyHitInfo

export type EnemyStat = Stat.EnemyStat
export type EnemyName = Stat.EnemyName

local Enemy = {
	HitInfo = HitInfo,
	Stat = Stat,
	Enum = {
		Event = LEnum.EnemyEvent,
	},
}
Enemy.__index = Enemy

function Enemy.getEnemyIdFromPart(part: BasePart): string
	local model = part:FindFirstAncestorOfClass("Model") :: Model
	return model:GetAttribute("EnemyID") :: string
end

function Enemy.isEnemyPart(part: BasePart): boolean
	return part.CollisionGroup == LEnum.CollisionGroup.Enemy
end

function Enemy.isVitalPart(part: BasePart): boolean
	return part:GetAttribute("Vital") == true
end

function Enemy.isShield(part: BasePart): boolean
	return part:GetAttribute("Shield") == true
end

function Enemy.getDamageReductionRate(part: BasePart): number
	return part:GetAttribute("DamageReductionRate") :: number or 0
end

function Enemy.calcHitDamage(hit_info: EnemyHitInfo, arrow_info: ArrowInfo)
	if Enemy.isShield(hit_info.instance) then
		local reduction_rate = Enemy.getDamageReductionRate(hit_info.instance)
		arrow_info.damage *= 1 - reduction_rate
	elseif Enemy.isVitalPart(hit_info.instance) then
		arrow_info.damage = arrow_info.critical_damage
	end
end

local function initModule()
	if Util.getPlaceName() == "CastleGate" then
		Enemy.Event = ReplicatedStorage.Events.EnemyEvent
	end
end

initModule()
return Enemy
