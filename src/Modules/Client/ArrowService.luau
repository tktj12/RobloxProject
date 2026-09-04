--[[
	화살 발사 및 충돌 처리 모듈
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ArrowInfo = require(ReplicatedStorage.Modules.Shared.ArrowInfo)
local Enemy = require(ReplicatedStorage.Modules.Client.Enemy)
local GameState = require(ReplicatedStorage.Modules.Shared.GameState)
local HitInfo = require(ReplicatedStorage.Modules.Shared.HitInfo)
local LEnum = require(ReplicatedStorage.Modules.Shared.LEnum)
local LocalData = require(ReplicatedStorage.Modules.Client.LocalData)
local SoundManager = require(ReplicatedStorage.Modules.Client.SoundManager)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local VfxManager = require(ReplicatedStorage.Modules.Client.VfxManager)

type ArrowInfo = ArrowInfo.ArrowInfo
type HitInfo = HitInfo.HitInfo
type RemoteHitInfo = HitInfo.RemoteHitInfo

type ArrowEntry = {
	arrow_info: ArrowInfo,
	arrow: MeshPart,
	connection: RBXScriptConnection,
}

local ArrowFired = ReplicatedStorage.Events.ArrowFired
local ArrowHit = ReplicatedStorage.Events.ArrowHit
local ArrowCollision = ReplicatedStorage.ArrowCollision

local arrows: { [string]: ArrowEntry } = {}
local ray_params = RaycastParams.new()

local ArrowService = {}

local function getArrowModel(arrow: string | MeshPart | Folder): MeshPart
	if type(arrow) == "string" then
		return ReplicatedStorage:FindFirstChild(arrow):FindFirstChild("ForShot"):Clone()
	elseif typeof(arrow) == "MeshPart" then
		return arrow
	elseif typeof(arrow) == "Folder" then
		return arrow:FindFirstChild("ForShot") :: MeshPart
	else
		error("Cannot find arrow")
	end
end

local function removeArrowEntry(entry_id: string)
	local entry = arrows[entry_id]
	arrows[entry_id] = nil
	if not entry then
		return
	end

	if Util.isLocalPlayer(entry.arrow_info.shooter) and not entry.arrow:GetAttribute("Hit") then
		LocalData.set("combo", 0)
	end

	entry.connection:Disconnect()
	entry.arrow:Destroy()
end

local function registerArrow(
	arrow_info: ArrowInfo,
	arrow: MeshPart,
	connection: RBXScriptConnection
)
	local entry_id = `{arrow_info.shooter.UserId}_{arrow_info.id}`
	arrows[entry_id] = {
		arrow_info = arrow_info,
		arrow = arrow,
		connection = connection,
	}
	task.delay(ArrowInfo.DISAPPEAR_TIME, removeArrowEntry, entry_id)
end

function ArrowService.onHit(user_id: number, arrow_id: number, hit_info: HitInfo)
	local entry_id = `{user_id}_{arrow_id}`
	local entry = arrows[entry_id]
	if not entry then
		return
	end

	local arrow = entry.arrow
	local arrow_info = entry.arrow_info
	local connection = entry.connection
	local collision = arrow.ArrowCollision :: BasePart

	arrow:SetAttribute("Hit", true)

	connection:Disconnect()
	collision.Anchored = true

	arrow.Parent = hit_info.instance
	arrow.Trail.Enabled = false

	arrow.Position = hit_info.cframe.Position
	local weld = Instance.new("WeldConstraint")
	weld.Parent = arrow
	weld.Part0 = hit_info.instance
	weld.Part1 = arrow
	weld.Enabled = true

	VfxManager.onArrowImpact(arrow, arrow_info, hit_info)
	SoundManager.onArrowImpact(arrow, arrow_info, hit_info)

	task.delay(ArrowInfo.HIT_DISAPPEAR_TIME, removeArrowEntry, entry_id)

	local on_wave = GameState.get(GameState.Attribute.OnWave)
	if on_wave and Enemy.isEnemyPart(hit_info.instance) then
		-- 몹 적중시
		local enemy_id = Enemy.getEnemyIdFromPart(hit_info.instance)
		if Util.isLocalPlayer(arrow_info.shooter) then
			local remote_hit_info: RemoteHitInfo = {
				world_cframe = hit_info.cframe,
				relative_cframe = hit_info.instance.CFrame:ToObjectSpace(hit_info.cframe),
				normal = hit_info.normal,
				enemy_id = enemy_id,
				part_name = hit_info.instance.Name,
			}
			ArrowHit:FireServer(arrow_id, remote_hit_info)

			LocalData.increment("combo", 1)
		end

		local enemy_hit_info =
			HitInfo.newEnemyHit(hit_info.cframe, hit_info.normal, hit_info.instance, enemy_id)
		Enemy.hitByArrow(enemy_hit_info, arrow_info)
	else
		-- 몹이 아닌 오브젝트 적중시
		if Util.isLocalPlayer(arrow_info.shooter) then
			local remote_hit_info: RemoteHitInfo = {
				world_cframe = hit_info.cframe,
				relative_cframe = hit_info.instance.CFrame:ToObjectSpace(hit_info.cframe),
				normal = hit_info.normal,
				instance = hit_info.instance,
			}
			ArrowHit:FireServer(arrow_id, remote_hit_info)

			if on_wave then
				LocalData.set("combo", 0)
			end
		end
	end
end

function ArrowService.fireArrow(arrow_info: ArrowInfo)
	local self_fired = Util.isLocalPlayer(arrow_info.shooter)

	local arrow = getArrowModel(arrow_info.name)
	arrow.Parent = workspace
	if self_fired then
		arrow:PivotTo(workspace.ViewModel.Mesh.Arrow:GetPivot())
		ArrowFired:FireServer(arrow_info)
	else
		arrow:PivotTo(arrow_info.shooter.Character.Mesh.Arrow:GetPivot())
	end

	local collision = ArrowCollision:Clone()
	collision.Parent = arrow
	collision:PivotTo(arrow_info.start_cframe)

	local draw_power = arrow_info.draw_power
	local look_vector = arrow_info.start_cframe.LookVector
	collision.AssemblyLinearVelocity = look_vector * draw_power * 300
	arrow.AssemblyLinearVelocity = look_vector * draw_power * 300

	local prev_pos = collision.Position
	local prev_prev_pos = prev_pos

	local duration = 0.4 / draw_power
	local elapsed = 0
	local connection
	connection = RunService.PreSimulation:Connect(function(dt)
		local dist = (workspace.CurrentCamera.CFrame.Position - collision.Position).Magnitude
		arrow.Trail.WidthScale = NumberSequence.new(math.max(dist / 1500, 0.03))

		local vel = collision.AssemblyLinearVelocity
		elapsed += dt
		if elapsed < duration then
			arrow.CFrame = arrow.CFrame:Lerp(collision.CFrame, elapsed / duration)
		else
			arrow.CFrame = collision.CFrame
		end
		arrow.CFrame = CFrame.lookAlong(arrow.Position, vel)
			* CFrame.Angles(0, 0, math.rad(600) * elapsed)

		SoundManager.calcArrowWindSound(arrow, self_fired)

		if not self_fired then
			return
		end

		local new_pos = collision.Position
		local delta_pos = new_pos - prev_prev_pos
		local hit = workspace:Raycast(prev_prev_pos, delta_pos, ray_params)
		prev_prev_pos = prev_pos
		prev_pos = new_pos

		if hit then
			--print(hit.Instance.Name)
			arrow.Position = hit.Position
			local hit_info = HitInfo.new(arrow.CFrame, hit.Normal, hit.Instance)
			ArrowService.onHit(arrow_info.shooter.UserId, arrow_info.id, hit_info)
		end
	end)

	registerArrow(arrow_info, arrow, connection)

	VfxManager.playArrowFireVfx(arrow, arrow_info)
end

local function initModule()
	ArrowHit.OnClientEvent:Connect(
		function(user_id: number, arrow_id: number, remote_hit: RemoteHitInfo)
			if user_id == Players.LocalPlayer.UserId then
				return
			end

			local hit_info
			if remote_hit.enemy_id then
				local hit_part =
					Enemy.getEnemyPart(remote_hit.enemy_id, remote_hit.part_name :: string)
				if not hit_part then
					return
				end
				local cframe = hit_part.CFrame:ToWorldSpace(remote_hit.relative_cframe)
				hit_info = HitInfo.new(cframe, remote_hit.normal, hit_part)
			else
				local cframe = remote_hit.instance.CFrame:ToWorldSpace(remote_hit.relative_cframe)
				hit_info = HitInfo.new(cframe, remote_hit.normal, remote_hit.instance :: BasePart)
			end

			ArrowService.onHit(user_id, arrow_id, hit_info)
		end
	)

	while task.wait() do
		if Players.LocalPlayer.Character then
			ray_params.ExcludeInstances = { Players.LocalPlayer.Character :: Model }
			break
		end
	end
	ray_params.CollisionGroup = LEnum.CollisionGroup.Arrow
end

initModule()
return ArrowService
