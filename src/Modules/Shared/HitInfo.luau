export type HitInfo = {
	cframe: CFrame,
	normal: Vector3,
	instance: BasePart,
}

export type RemoteHitInfo = {
	world_cframe: CFrame,
	relative_cframe: CFrame,
	normal: Vector3,
	instance: BasePart?,
	enemy_id: string?,
	part_name: string?,
}

export type EnemyHitInfo = {
	cframe: CFrame,
	normal: Vector3,
	instance: BasePart,
	enemy_id: string,
}

local HitInfo = {}

function HitInfo.new(cframe: CFrame, normal: Vector3, instance: BasePart): HitInfo
	return {
		cframe = cframe,
		normal = normal,
		instance = instance,
	}
end

function HitInfo.newEnemyHit(
	cframe: CFrame,
	normal: Vector3,
	instance: BasePart,
	enemy_id: string
): EnemyHitInfo
	return {
		cframe = cframe,
		normal = normal,
		instance = instance,
		enemy_id = enemy_id,
	}
end

return HitInfo
