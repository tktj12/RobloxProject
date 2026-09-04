local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Modules.Shared.Util)

local LEnum = {}

LEnum.SET_NIL = "SET_NIL"

LEnum.ShotMode = {
	Normal = 0,
	Timed = 1,
	Combo = 2,
	TimedCombo = 3,
}

LEnum.GameState = {
	OnWave = "OnWave",
	WaveLevel = "WaveLevel",
}

LEnum.EnemyEvent = {
	EnemySpawned = "EnemySpawned",
	EnemyRemoved = "EnemyRemoved",
}

LEnum.PlayerAttribute = {
	WaveLevel = "WaveLevel",
	Party = "Party",
	PartyLeader = "PartyLeader",
	PartyVersion = "PartyVersion",
	TotalDamageDealt = "TotalDamageDealt",
	Color = "Color",
}

LEnum.SkillNode = {
	ShotDamage1 = "ShotDamage1",
	Headshot = "Headshot",
	TimedShot = "TimedShot",
	ComboShot = "ComboShot",
	DrawSpeed = "DrawSpeed",
	MovementSpeed = "MovementSpeed",
	WallHP = "WallHP",
	LoadSpeed = "LoadSpeed",
	DrawStrength = "DrawStrength",
}

LEnum.CollisionGroup = {
	Arrow = "Arrow",
	Enemy = "Enemy",
	Default = "Default",
	NoCollision = "NoCollision",
	Player = "Player",
	ArrowLimit = "ArrowLimit",
}

-- TODO: Party Events

Util.deepFreeze(LEnum)
return LEnum
