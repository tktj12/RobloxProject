local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage.Modules
require(Modules.Client.GuiService)
require(Modules.Client.Menu)
local AnimManager = require(Modules.Client.AnimManager)
local ArrowInfo = require(Modules.Shared.ArrowInfo)
local Bow = require(Modules.Client.Bow)
local GameState = require(Modules.Shared.GameState)
local LEnum = require(Modules.Shared.LEnum)
local LocalData = require(Modules.Client.LocalData)
local PlayerAction = require(Modules.Client.PlayerAction)
local SharedData = require(Modules.Shared.SharedData)
local SoundManager = require(Modules.Client.SoundManager)
local Util = require(Modules.Shared.Util)
local VfxManager = require(Modules.Client.VfxManager)
local View = require(Modules.Client.View)

type ArrowInfo = ArrowInfo.ArrowInfo

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local my_shot = 0
local draw_start: number
local mouse1_down = false

local function isTimedShotUnlocked(): boolean
	local skill_state = LocalData.getSkillState()

	if not skill_state[LEnum.SkillNode.TimedShot] then
		return false
	end

	return true
end

local function drawBowSelf()
	local character = LocalPlayer.Character
	if not character or not View.ViewModel.get() then
		return
	end

	draw_start = os.clock()
	LocalData.set("aiming", true)

	local runtime_data = LocalData.player_data.runtime
	local combo = LocalData.get("combo")
	if
		combo * runtime_data.ComboDamage >= SharedData.MAX_COMBO_DAMAGE
		and GameState.get(GameState.Attribute.OnWave)
	then
		my_shot = Util.setFlags(my_shot, LEnum.ShotMode.Combo)
	end

	PlayerAction.drawBow(LocalPlayer, my_shot)
	View.onBowDraw(my_shot, LocalData.player_data.runtime.DrawSpeed)

	character.Humanoid.WalkSpeed = 8
	SoundManager.setWalkSoundSpeed(0.9)
end

local function isTimedShot(charge_time: number): boolean
	-- TODO: 임시
	if 1 <= charge_time and charge_time then
		return true
	else
		return false
	end
end

local function releaseBowSelf()
	local character = LocalPlayer.Character
	if not character or not View.ViewModel.get() then
		return
	end

	LocalData.set("aiming", false)

	local charge_time = os.clock() - draw_start
	if isTimedShot(charge_time) and isTimedShotUnlocked() then
		my_shot = Util.setFlags(my_shot, LEnum.ShotMode.Timed)
	end

	local runtime_data = LocalData.player_data.runtime
	local combo = LocalData.get("combo")
	if
		combo * runtime_data.ComboDamage >= SharedData.MAX_COMBO_DAMAGE
		and GameState.get(GameState.Attribute.OnWave)
	then
		my_shot = Util.setFlags(my_shot, LEnum.ShotMode.Combo)
	else
		my_shot = Util.resetFlags(my_shot, LEnum.ShotMode.Combo)
	end

	local arrow_info = ArrowInfo.new {
		name = "NormalArrow",
		draw_time = charge_time,
		start_cframe = workspace.CurrentCamera.CFrame,
		shot_mode = my_shot,
		shooter = LocalPlayer,
	}
	arrow_info:calcDrawPower(LocalData.player_data.runtime)
	arrow_info:calcDamage(LocalData.player_data.runtime, combo)
	AnimManager.releaseBow()
	PlayerAction.releaseBow(arrow_info)
	View.onBowRelease(arrow_info, SharedData.DEFAULT_RELOAD_TIME / runtime_data.LoadSpeed)
	my_shot = LEnum.ShotMode.Normal

	character.Humanoid.WalkSpeed = 16
	SoundManager.setWalkSoundSpeed(1.85)
end

Mouse.Button1Down:Connect(function()
	mouse1_down = true
end)

Mouse.Button1Up:Connect(function()
	mouse1_down = false
	if LocalData.get("aiming") and LocalData.get("arrow_loaded") then
		releaseBowSelf()
	end
end)

local function waitPlayerBowSetup(player: Player)
	local success, bow
	repeat
		success, bow = pcall(Bow.getPlayerBow, player)
		if not success then
			task.wait(1)
		end
	until success

	return bow
end

local function playerAdded(player: Player)
	if player ~= Players.LocalPlayer then
		VfxManager.setBowEffects(waitPlayerBowSetup(player), false)
	end
end

for _, player in Players:GetPlayers() do
	task.spawn(playerAdded, player)
end

Players.PlayerAdded:Connect(function(player)
	playerAdded(player)
end)

SoundManager.setWalkSoundVolume(0.3)

task.spawn(function()
	while task.wait() do
		if LocalData.get("arrow_loaded") and mouse1_down and not LocalData.get("aiming") then
			drawBowSelf()
		end
	end
end)
