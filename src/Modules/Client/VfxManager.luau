local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ArrowInfo = require(ReplicatedStorage.Modules.Shared.ArrowInfo)
local EnemyService = require(ReplicatedStorage.Modules.Shared.Enemy)
local HitInfo = require(ReplicatedStorage.Modules.Shared.HitInfo)
local LEnum = require(ReplicatedStorage.Modules.Shared.LEnum)
local PlayerData = require(ReplicatedStorage.Modules.Shared.PlayerData)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

type ArrowInfo = ArrowInfo.ArrowInfo
type HitInfo = HitInfo.HitInfo

local PIVOT_DISAPPEAR_TIME = 2

local ArrowWindEffect
local ArrowImpactEffects
local CurrentCamera = workspace.CurrentCamera
local PivotPart = ReplicatedStorage.PivotPart

local damage_zindex: number = 10000

local VfxManager = {}

local function initModule()
	if Util.getPlaceName() == "CastleGate" then
		ArrowWindEffect = ReplicatedStorage.Effects.ArrowWindEffect
		ArrowImpactEffects = ReplicatedStorage.Effects.ArrowImpactEffects
	end
end

local function calcConstantScreenSpaceSize(
	size: NumberSequence,
	base_dist: number,
	dist: number
): NumberSequence
	local keypoints = {}
	local ratio = dist / base_dist
	for _, v in size.Keypoints do
		table.insert(
			keypoints,
			NumberSequenceKeypoint.new(v.Time, v.Value * ratio, v.Envelope * ratio)
		)
	end
	return NumberSequence.new(keypoints)
end

local function onComboShotDraw(bow, shot_mode: number)
	bow.Arrow.Highlight.FillTransparency = 1
	bow.Arrow.Highlight.OutlineTransparency = 1

	if not bow.Arrow.Highlight:FindFirstChild("ComboShotTween") then
		local tween = TweenService:Create(
			bow.Arrow.Highlight,
			TweenInfo.new(1.5),
			{ FillTransparency = 0.3, OutlineTransparency = 0.5 }
		)
		tween.Parent = bow.Arrow.Highlight
		tween.Name = "ComboShotTween"
	end

	bow.Arrow.Highlight.ComboShotTween:Play()

	for _, e in bow.PopElectricityEffect:GetChildren() do
		if e:IsA("ParticleEmitter") then
			e.Enabled = true
		end
	end
end

local function onComboShotRelease(pivot, bow, shot_mode: number)
	if bow.Arrow.Highlight:FindFirstChild("ComboShotTween") then
		bow.Arrow.Highlight.ComboShotTween:Cancel()
	end
	bow.Arrow.Highlight.FillTransparency = 1
	bow.Arrow.Highlight.OutlineTransparency = 1

	for _, e in bow.PopElectricityEffect:GetChildren() do
		if e:IsA("ParticleEmitter") then
			e.Enabled = false
		end
	end

	for _, e in pivot.FiringElectricityEffect:GetChildren() do
		if e:IsA("ParticleEmitter") then
			if Util.hasAllFlags(shot_mode, LEnum.ShotMode.Timed) then
				e.Color = ColorSequence.new(Color3.new(1, 1, 0))
				e.Brightness = 1
			else
				e.Color = ColorSequence.new(Color3.new(1, 0.1, 0.1))
				e.Brightness = 6
			end
			e:Emit(math.random(1, 2))
		end
	end
end

local function onTimedShotRelease(pivot, shot_mode: number)
	local donut = pivot.EffectPos1.DonutEffect
	if Util.hasAllFlags(shot_mode, LEnum.ShotMode.Combo) then
		donut.Color = ColorSequence.new(Color3.new(1, 1, 0))
	else
		donut.Color = ColorSequence.new(Color3.new(1, 1, 1))
	end
	donut:Emit(1)
end

local function emitArrowDusts(pos: Vector3, normal: Vector3)
	local cam_right = workspace.CurrentCamera.CFrame.RightVector
	local world_up = Vector3.new(0, 1, 0)

	local h = normal:Dot(cam_right)
	local w = normal:Dot(world_up)
	local angle = math.deg(math.atan2(h, w))

	local eff = ArrowImpactEffects.DustEffect:Clone()
	eff:PivotTo(CFrame.lookAlong(pos, normal:Cross(Vector3.new(0.1, 0.2, 0.3)), normal))
	eff.Parent = workspace
	Debris:AddItem(eff, 1)

	for _, e in eff.Part:GetChildren() do
		if e:IsA("ParticleEmitter") then
			e.Rotation = NumberRange.new(angle)
			e:Emit(math.random(1, 3))
		end
	end
	eff.Part.Center1.CenterDustEmitter:Emit(1)
end

local function emitImpactElecricity(arrow: BasePart, arrow_info: ArrowInfo)
	local eff = ArrowImpactEffects.ImpactElectricity:Clone()
	eff.Parent = arrow
	eff:PivotTo(arrow:GetPivot())

	for _, e in eff:GetChildren() do
		if e:IsA("ParticleEmitter") then
			if Util.hasAllFlags(arrow_info.shot_mode, LEnum.ShotMode.Timed) then
				e.Color = ColorSequence.new(Color3.new(1, 1, 0))
			else
				e.Color = ColorSequence.new(Color3.new(1, 0, 0))
			end

			e:Emit(math.random(1, 2))
		end
	end
end

local function spawnArrowWindEffect(arrow: BasePart, shot_mode: number)
	local wind = ArrowWindEffect:Clone()
	wind.Parent = arrow
	wind:PivotTo(arrow:GetPivot() * CFrame.Angles(math.rad(180), 0, 0))

	wind.WeldConstraint.Part0 = arrow
	wind.WeldConstraint.Enabled = true

	if Util.hasAllFlags(shot_mode, LEnum.ShotMode.Combo) then
		for _, e in wind:GetChildren() do
			if e:IsA("Beam") then
				e.Color = ColorSequence.new(Color3.new(1, 1, 0))
			end
		end
	end
end

function VfxManager.setBowEffects(bow, is_local_player: boolean)
	local folder
	if is_local_player then
		folder = bow.Effects.LocalPlayer
	else
		folder = bow.Effects.OtherPlayer
	end

	for _, c in folder:GetChildren() do
		c.Parent = bow
	end
end

function VfxManager.onStartDraw(bow, shot_mode: number)
	if Util.hasAllFlags(shot_mode, LEnum.ShotMode.Combo) then
		onComboShotDraw(bow, shot_mode)
	end
end

function VfxManager.onBowRelease(bow, arrow_info: ArrowInfo)
	local pivot = bow :: any
	if Util.isLocalPlayer(arrow_info.shooter) then
		if arrow_info.draw_power > 0.5 then
			pivot.EffectPos1.FiringEffect:Emit(1)
		end
	else
		pivot = PivotPart:Clone()
		pivot.Parent = workspace
		pivot:PivotTo(arrow_info.start_cframe)
		Debris:AddItem(pivot, PIVOT_DISAPPEAR_TIME)
	end

	if Util.hasAllFlags(arrow_info.shot_mode, LEnum.ShotMode.Timed) then
		onTimedShotRelease(pivot, arrow_info.shot_mode)
	end

	if Util.hasAllFlags(arrow_info.shot_mode, LEnum.ShotMode.Combo) then
		onComboShotRelease(pivot, bow, arrow_info.shot_mode)
	end
end

function VfxManager.playArrowFireVfx(arrow: BasePart, arrow_info: ArrowInfo)
	if Util.hasAllFlags(arrow_info.shot_mode, LEnum.ShotMode.Timed) then
		task.spawn(function()
			if not arrow:GetAttribute("Hit") then
				spawnArrowWindEffect(arrow, arrow_info.shot_mode)
			end
		end)
		arrow.Trail.Brightness = 1
	end

	if Util.hasAllFlags(arrow_info.shot_mode, LEnum.ShotMode.Combo) then
		arrow.Trail.Color = ColorSequence.new(Color3.new(1, 0.1, 0.1))
		arrow.Trail.Brightness = 6
	end

	if Util.hasAllFlags(arrow_info.shot_mode, LEnum.ShotMode.TimedCombo) then
		arrow.Trail.Color = ColorSequence.new(Color3.new(1, 1, 0))
		arrow.Trail.Brightness = 1
	end
end

local function emitEnemyHitEffect(
	pivot: BasePart,
	arrow_info: ArrowInfo,
	hit_instance: BasePart,
	dist: number
)
	if EnemyService.isShield(hit_instance) then
		return
	end

	local effect: ParticleEmitter
	if Util.isLocalPlayer(arrow_info.shooter) then
		if EnemyService.isVitalPart(hit_instance) then
			effect = ArrowImpactEffects.CriticalHit:Clone()
		else
			effect = ArrowImpactEffects.NormalHit:Clone()
		end
	else
		effect = ArrowImpactEffects.HitEffectOther:Clone()
		if EnemyService.isVitalPart(hit_instance) then
			effect.Color = ColorSequence.new(Color3.new(1, 0, 0))
		end
	end
	effect.Parent = pivot.ArrowImpact

	effect.Size =
		calcConstantScreenSpaceSize(effect.Size, effect:GetAttribute("BaseDist") :: number, dist)
	effect:Emit(1)
end

local function emitHitLights(pivot: BasePart, dist: number)
	-- local star_effect = ReplicatedStorage.Effects.ArrowImpactEffects.Star:Clone()
	local shard_effect = ReplicatedStorage.Effects.ArrowImpactEffects.Shards:Clone()

	-- star_effect.Parent = pivot.ArrowImpact
	shard_effect.Parent = pivot.ArrowImpact

	-- star_effect.Size = calcConstantScreenSpaceSize(
	-- 	star_effect.Size,
	-- 	star_effect:GetAttribute("BaseDist") :: number,
	-- 	dist
	-- )
	shard_effect.Size = calcConstantScreenSpaceSize(
		shard_effect.Size,
		shard_effect:GetAttribute("BaseDist") :: number,
		dist
	)

	-- star_effect:Emit(1)
	shard_effect:Emit(5)
end

function VfxManager.onArrowImpact(arrow: BasePart, arrow_info: ArrowInfo, hit: HitInfo)
	local pivot = Util.spawnPivotPart(arrow.CFrame, 3)
	local dist = (CurrentCamera.CFrame.Position - arrow.Position).Magnitude

	if arrow:FindFirstChild("ArrowWindEffect") then
		--TODO: Flying Effect로 다 묶기
		arrow.ArrowWindEffect:Destroy()
	end

	if hit.instance.CollisionGroup == LEnum.CollisionGroup.ArrowLimit then
		return
	end

	if EnemyService.isEnemyPart(hit.instance) or Util.isPlayerPart(hit.instance) then
		emitEnemyHitEffect(pivot, arrow_info, hit.instance, dist)
	else
		if arrow_info.draw_power > 0.4 then
			emitArrowDusts(hit.cframe.Position, hit.normal)
		end
	end

	if Util.hasAllFlags(arrow_info.shot_mode, LEnum.ShotMode.Combo) then
		emitImpactElecricity(arrow, arrow_info)
	end

	if Util.isLocalPlayer(arrow_info.shooter) then
		emitHitLights(pivot, dist)
	end
end

local function getStrokeColor(text_color: Color3): Color3
	local luminance = Util.getLuminanceFromColor3(text_color)
	if luminance < 0.33 then
		return Color3.new(1, 1, 1)
	elseif luminance < 0.66 then
		return Color3.new(0.5, 0.5, 0.5)
	else
		return Color3.new(0, 0, 0)
	end
end

function VfxManager.showDamage(shooter: Player, hit_position: Vector3, damage: number)
	local pivot = Util.spawnPivotPart(CFrame.new(hit_position), 1.2)

	local gui = Instance.new("BillboardGui")
	gui.Parent = pivot
	gui.Adornee = pivot
	gui.Size = UDim2.fromOffset(200, 50)
	gui.AlwaysOnTop = true

	local label = Instance.new("TextLabel")
	label.Parent = gui
	label.Size = UDim2.fromScale(1, 1)
	label.Text = tostring(damage)
	label.TextSize = 30
	label.BackgroundTransparency = 1
	label.TextColor3 = PlayerData.getColor(shooter)
	label.FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold)
	label.TextTransparency = 1
	label.AutoLocalize = false
	label.ZIndex = damage_zindex
	damage_zindex += 1

	local stroke = Instance.new("UIStroke")
	stroke.Parent = label
	stroke.Color = getStrokeColor(label.TextColor3)
	stroke.Thickness = 3

	local gui_tween = TweenService:Create(gui, TweenInfo.new(1), {
		SizeOffset = Vector2.new(0, 1),
	})
	local text_tween = TweenService:Create(
		label,
		TweenInfo.new(1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{
			TextTransparency = 0,
		}
	)
	gui_tween:Play()
	text_tween:Play()
end

initModule()
return VfxManager
