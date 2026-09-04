local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ArrowInfo = require(ReplicatedStorage.Modules.Shared.ArrowInfo)
local EnemyBase = require(ReplicatedStorage.Modules.Shared.Enemy)
local Fusion = require(ReplicatedStorage.Modules.Shared.Fusion)
local HitInfo = require(ReplicatedStorage.Modules.Shared.HitInfo)
local LEnum = require(ReplicatedStorage.Modules.Shared.LEnum)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local VfxManager = require(ReplicatedStorage.Modules.Client.VfxManager)

type ArrowInfo = ArrowInfo.ArrowInfo
type EnemyStat = EnemyBase.EnemyStat
type HitInfo = HitInfo.HitInfo
type EnemyHitInfo = HitInfo.EnemyHitInfo
type EnemyEntry = {
	name: string,
	model: Model,
	hp: Fusion.Value<number>,
	stat: EnemyStat,
	scope: Fusion.Scope,
}

local peek = Fusion.peek
local hp_gui: BillboardGui & {
	Frame: Frame & { Guage: Frame & { Image: ImageLabel, DamageTrail: Frame } },
}
local enemy_list: { [string]: EnemyEntry } = {}
local RedSphere: BasePart & { Attachment0: Attachment }

local Enemy = {}
setmetatable(Enemy, { __index = EnemyBase })

local function removeEnemy(id: string)
	if not enemy_list[id] then
		return
	end
	local entry = enemy_list[id]
	enemy_list[id] = nil

	entry.model:Destroy()
	entry.scope:doCleanup()
end

local function setHpBar(scope: Fusion.Scope, model: any, hp: Fusion.Value<number>, max_hp: number)
	local hp_bar = hp_gui:Clone()
	hp_bar.Parent = model
	hp_bar.Adornee = model.Head

	local hp_image_size = scope:Computed(function(use)
		local hp_ratio = math.clamp(use<<number>>(hp) / max_hp, 0, 1)
		return UDim2.fromScale(hp_ratio, 1)
	end)
	scope:Hydrate(hp_bar.Frame.Guage.Image) {
		Size = hp_image_size,
	}
	scope:Hydrate(hp_bar.Frame.Guage.DamageTrail) {
		Size = scope:Tween(
			hp_image_size,
			TweenInfo.new(0.3, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
		),
	}
end

local function setDistanceGuide(scope: Fusion.Scope, model: Model)
	local red_sphere = RedSphere:Clone()
	red_sphere.Parent = model
	red_sphere.Attachment0.Parent = model

	local con = RunService.RenderStepped:Connect(function()
		local p = model:GetPivot().Position
		red_sphere.Position = Vector3.new(p.X, 0, p.Z)
	end)
	table.insert(scope, con)
end

local function spawnEnemy(
	name: EnemyBase.EnemyName,
	id: string,
	spawn_cframe: CFrame,
	max_hp: number
)
	local model = ReplicatedStorage.Enemy[name]:Clone()
	model:SetAttribute("EnemyID", id)
	model.Parent = workspace
	model:PivotTo(spawn_cframe)
	model.LocalScript.Enabled = true
	task.spawn(Util.fadeInModel, model, 0.5)

	local scope = Fusion.scoped(Fusion)

	local stat = EnemyBase.Stat.get(name)
	stat.hp = max_hp
	local hp = scope:Value(stat.hp)

	scope:Observer(hp):onChange(function()
		if peek<<number>>(hp) <= 0 then
			removeEnemy(id)
		end
	end)

	setHpBar(scope, model, hp, stat.hp)

	if stat.flying then
		setDistanceGuide(scope, model)
	end

	enemy_list[id] = {
		name = name,
		model = model,
		hp = hp,
		stat = stat,
		scope = scope,
	}
end

function Enemy.hitByArrow(hit_info: EnemyHitInfo, arrow_info: ArrowInfo)
	local id = hit_info.enemy_id

	local enemy = enemy_list[id]
	if enemy == nil then
		return
	end

	Enemy.calcHitDamage(hit_info, arrow_info)
	VfxManager.showDamage(arrow_info.shooter, hit_info.cframe.Position, arrow_info.damage)

	enemy.hp:set(peek<<number>>(enemy.hp) - arrow_info.damage)
end

function Enemy.clearAllEnemies()
	for id, _ in enemy_list do
		removeEnemy(id)
	end
end

function Enemy.getEnemyPart(enemy_id: string, part_name: string): BasePart?
	local enemy = enemy_list[enemy_id]
	if not enemy then
		return nil
	end

	local model = enemy.model
	local part = model:FindFirstChild(part_name, true)
	if part and part:IsA("BasePart") then
		return part
	end

	return nil
end

local function initModule()
	if Util.getPlaceName() ~= "CastleGate" then
		return
	end

	hp_gui = ReplicatedStorage.Enemy.HPGui :: any
	RedSphere = ReplicatedStorage.Enemy.RedSphere :: any

	Enemy.Event.OnClientEvent:Connect(function(event_name: string, ...)
		if event_name == LEnum.EnemyEvent.EnemySpawned then
			spawnEnemy(...)
		elseif event_name == LEnum.EnemyEvent.EnemyRemoved then
			removeEnemy(...)
		end
	end)
end

initModule()
return Enemy
