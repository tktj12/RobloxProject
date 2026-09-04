local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Modules.Shared.Util)

export type EnemyStat = {
	hp: number,
	soul: number,
	flying: boolean,
}

local stats = {
	TestMob = { hp = 100, soul = 10, flying = true },
	Snail = { hp = 21, soul = 10 },
	GreenSnail = { hp = 30, soul = 15 },
	BlueSnail = { hp = 45, soul = 25 },
	RedSnail = { hp = 120, soul = 60 },
	Frog = { hp = 60, soul = 40 },
	BlueFrog = { hp = 90, soul = 60 },
	Turtle = { hp = 200, soul = 100 },
}
export type EnemyName = keyof<typeof(stats)>

local EnemyStat = {}

function EnemyStat.get(name: EnemyName): EnemyStat
	local stat = stats[name]
	if not stat then
		error("EnemyStat.get: No base stat found for enemy name: " .. name)
	end

	return {
		hp = stat.hp,
		soul = stat.soul,
		flying = stat.flying :: boolean? or false,
	}
end

Util.deepFreeze(EnemyStat)
return EnemyStat
