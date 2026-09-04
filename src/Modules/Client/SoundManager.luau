local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local ArrowInfo = require(ReplicatedStorage.Modules.Shared.ArrowInfo)
local EnemyService = require(ReplicatedStorage.Modules.Client.Enemy)
local HitInfo = require(ReplicatedStorage.Modules.Shared.HitInfo)
local LEnum = require(ReplicatedStorage.Modules.Shared.LEnum)
local LocalData = require(ReplicatedStorage.Modules.Client.LocalData)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

type ArrowInfo = ArrowInfo.ArrowInfo
type HitInfo = HitInfo.HitInfo

local LocalPlayer = Players.LocalPlayer

local module = {}

local function adjustRandomPitch(sound: Sound)
	local base_speed = sound:GetAttribute("BaseSpeed") :: number
	sound.PlaybackSpeed = base_speed * (1.1 - math.random() * 0.2)
end

function module.onStartDraw(bow, shot_mode: number)
	bow.DrawSoundRef.Value:Play()

	if Util.hasAllFlags(shot_mode, LEnum.ShotMode.Combo) then
		bow.ElectricSparkSoundRef.Value:Play()
	end
end

local function onEndDraw(bow)
	bow.DrawSoundRef.Value:Stop()
end
module.onEndDraw = onEndDraw

function module.onBowRelease(bow, arrow_info: ArrowInfo)
	local sounds = {}

	local release_sound = bow.ReleaseSoundRef.Value
	adjustRandomPitch(release_sound)
	local power =
		math.map(arrow_info.draw_power, 0, LocalData.player_data.runtime.DrawStrength, 0, 1)
	release_sound.Volume = release_sound:GetAttribute("BaseVolume") :: number * power
	table.insert(sounds, bow.ReleaseSoundRef.Value)

	if Util.hasAllFlags(arrow_info.shot_mode, LEnum.ShotMode.Timed) then
		table.insert(sounds, bow.TimedReleaseSoundRef.Value)
	end

	if Util.hasAllFlags(arrow_info.shot_mode, LEnum.ShotMode.Combo) then
		bow.ElectricSparkSoundRef.Value:Stop()
		table.insert(sounds, bow.ElectricFireSoundRef.Value)
	end

	if arrow_info.shooter == LocalPlayer then
		for _, sound in sounds do
			SoundService:PlayLocalSound(sound)
		end
	else
		for _, sound in sounds do
			sound:Play()
		end
	end

	onEndDraw(bow)
end

function module.onArrowImpact(arrow, arrow_info: ArrowInfo, hit: HitInfo)
	module.stopArrowWindSound(arrow)

	if hit.instance.CollisionGroup == LEnum.CollisionGroup.ArrowLimit then
		return
	end

	local sound: Sound
	if EnemyService.isEnemyPart(hit.instance) or Util.isPlayerPart(hit.instance) then
		if EnemyService.isShield(hit.instance) then
			sound = SoundService.EnemyShieldHitSound
		elseif EnemyService.isVitalPart(hit.instance) then
			sound = SoundService.EnemyHitCriticalSound
		else
			sound = SoundService.EnemyHitSound
		end
	else
		sound = arrow.HitSound
		sound.Volume = sound:GetAttribute("BaseVolume") :: number * arrow_info.draw_power
	end

	adjustRandomPitch(sound)
	if not Util.isLocalPlayer(arrow_info.shooter) then
		sound = sound:Clone() :: Sound
		sound.Parent = arrow
	end
	sound:Play()
end

function module.calcArrowWindSound(arrow: BasePart, is_local: boolean)
	local sound = arrow.WindSound :: Sound
	local speed = arrow.AssemblyLinearVelocity.Magnitude

	if is_local or speed < 150 then
		sound.Volume = 0
		return
	end

	sound.Volume = speed / 60
	sound.PlaybackSpeed = speed / 60
end

function module.stopArrowWindSound(arrow: BasePart)
	local sound = arrow.WindSound :: Sound
	sound.Volume = 0
end

function module.setLocalBowSound(bow)
	bow.TimedReleaseSound.Parent = game.SoundService
	bow.ElectricFireSound.Parent = game.SoundService
	bow.ReleaseSound.Parent = game.SoundService
	bow.DrawSound.Parent = game.SoundService
	bow.ElectricSparkSound.Parent = game.SoundService
end

function module.setWalkSoundVolume(volume: number)
	local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")

	hrp:WaitForChild("Running").Volume = volume
end

function module.setWalkSoundSpeed(speed: number)
	local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")

	hrp:WaitForChild("Running").PlaybackSpeed = speed
end

return module
