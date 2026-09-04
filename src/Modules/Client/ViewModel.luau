local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ArrowInfo = require(ReplicatedStorage.Modules.Shared.ArrowInfo)
local LocalData = require(ReplicatedStorage.Modules.Client.LocalData)
local SoundManager = require(ReplicatedStorage.Modules.Client.SoundManager)
local VfxManager = require(ReplicatedStorage.Modules.Client.VfxManager)

type ArrowInfo = ArrowInfo.ArrowInfo
local run_mul = 1.57
local view_model = nil
local bag = {}
local anim_tracks = {}

local module = {}

function module.get(): Model?
	return view_model
end

function module.destroy()
	if view_model then
		bag.endRunning()
		bag.render_connection:Disconnect()
		bag = {}

		view_model:Destroy()
	end
	view_model = nil
end

function module.generate()
	if view_model then
		module.destroy()
	end

	local player = game.Players.LocalPlayer
	if not player:GetAttribute("CharacterAppearanceLoaded") then
		player:GetAttributeChangedSignal("CharacterAppearanceLoaded"):Wait()
	end
	local character = player.Character
	local humanoid = character.Humanoid
	character.Archivable = true

	view_model = character:Clone()
	view_model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
	view_model.PrimaryPart.Anchored = true

	local VMHumanoid = view_model.Humanoid
	VMHumanoid:ChangeState(Enum.HumanoidStateType.Physics)

	view_model.Parent = workspace
	view_model.Name = "ViewModel"

	for _, ins in view_model:GetDescendants() do
		if ins:IsA("BasePart") then
			ins.CollisionGroup = "NoCollision"
			ins.CanCollide = false
			ins.CanTouch = false
			ins.CanQuery = false
			ins.CastShadow = false
			ins.EnableFluidForces = false
			ins.AudioCanCollide = false

			continue
		end

		if ins:IsA("LuaSourceContainer") then
			ins:Destroy()
			continue
		end

		if ins:IsA("Accessory") then
			local type = ins.AccessoryType
			if
				type == Enum.AccessoryType.Shirt
				or type == Enum.AccessoryType.Jacket
				or type == Enum.AccessoryType.TShirt
				or type == Enum.AccessoryType.Sweater
				or type == Enum.AccessoryType.DressSkirt
			then
				continue
			else
				ins:Destroy()
			end
		end
	end

	for _, ins in view_model:GetChildren() do
		if ins:IsA("BasePart") then
			if
				ins.Name == "LeftUpperArm"
				or ins.Name == "LeftLowerArm"
				or ins.Name == "LeftHand"
				or ins.Name == "RightUpperArm"
				or ins.Name == "RightLowerArm"
				or ins.Name == "RightHand"
			then
				local size =
					ReplicatedStorage.ViewModel.Sizes:FindFirstChild(ins.Name) :: NumberValue
				ins.Size = size.Value
			elseif ins.Name == "Mesh" or ins.Name == "Arrow" then
				continue
			else
				ins.Transparency = 1
			end

			local motor_settings = {
				Root = { "HumanoidRootPart", "LowerTorso" },
				Waist = { "LowerTorso", "UpperTorso" },
				LeftShoulder = { "UpperTorso", "LeftUpperArm" },
				LeftElbow = { "LeftUpperArm", "LeftLowerArm" },
				LeftWrist = { "LeftLowerArm", "LeftHand" },
				RightShoulder = { "UpperTorso", "RightUpperArm" },
				RightElbow = { "RightUpperArm", "RightLowerArm" },
				RightWrist = { "RightLowerArm", "RightHand" },
			}

			for _, c in ins:GetChildren() do
				if motor_settings[c.Name] then
					c:Destroy()
					local motor =
						ReplicatedStorage.ViewModel.Motors:FindFirstChild(c.Name):Clone() :: Motor6D
					local part0 = motor_settings[c.Name][1]
					local part1 = motor_settings[c.Name][2]
					motor.Part0 = view_model:FindFirstChild(part0)
					motor.Part1 = view_model:FindFirstChild(part1)
					motor.Enabled = true
					motor.Parent = ins
				end
			end
		end
	end

	VfxManager.setBowEffects(view_model.Mesh, true)
	SoundManager.setLocalBowSound(view_model.Mesh)

	------------- 애니메이션 세팅, 임시 --------------

	local IdleAnim = Instance.new("Animation")
	local RunAnim = Instance.new("Animation")
	local AimAnim = Instance.new("Animation")
	local ReleaseAnim = Instance.new("Animation")
	local RedrawAnim = Instance.new("Animation")
	local ReloadAnim = Instance.new("Animation")
	local SemiAimAnim = Instance.new("Animation")
	local HidingArrowAnim = Instance.new("Animation")

	IdleAnim.Parent = view_model :: any
	RunAnim.Parent = view_model :: any
	AimAnim.Parent = view_model :: any
	ReleaseAnim.Parent = view_model :: any
	RedrawAnim.Parent = view_model :: any
	ReloadAnim.Parent = view_model :: any
	SemiAimAnim.Parent = view_model :: any
	HidingArrowAnim.Parent = view_model :: any

	IdleAnim.AnimationId = "http://www.roblox.com/asset/?id=130822637126048"
	RunAnim.AnimationId = "http://www.roblox.com/asset/?id=91933744111830"
	AimAnim.AnimationId = "http://www.roblox.com/asset/?id=109107657591848"
	ReleaseAnim.AnimationId = "http://www.roblox.com/asset/?id=97926063364788"
	RedrawAnim.AnimationId = "http://www.roblox.com/asset/?id=107583087739404"
	ReloadAnim.AnimationId = "http://www.roblox.com/asset/?id=111011469545375"
	SemiAimAnim.AnimationId = "http://www.roblox.com/asset/?id=74223106907698"
	HidingArrowAnim.AnimationId = "http://www.roblox.com/asset/?id=102629012614773"

	local VMAnimator = VMHumanoid.Animator

	anim_tracks.idle = VMAnimator:LoadAnimation(IdleAnim)
	anim_tracks.run = VMAnimator:LoadAnimation(RunAnim)
	anim_tracks.aim = VMAnimator:LoadAnimation(AimAnim)
	anim_tracks.release = VMAnimator:LoadAnimation(ReleaseAnim)
	anim_tracks.redraw = VMAnimator:LoadAnimation(RedrawAnim)
	anim_tracks.reload = VMAnimator:LoadAnimation(ReloadAnim)
	anim_tracks.semi_aim = VMAnimator:LoadAnimation(SemiAimAnim)
	anim_tracks.hiding_arrow = VMAnimator:LoadAnimation(HidingArrowAnim)

	anim_tracks.release.Priority = Enum.AnimationPriority.Action3
	anim_tracks.hiding_arrow.Priority = Enum.AnimationPriority.Action2

	anim_tracks.redraw:GetMarkerReachedSignal("DrawingEnd"):Connect(function()
		anim_tracks.aim:Play(0)
		SoundManager.onEndDraw(view_model.Mesh)
	end)

	anim_tracks.idle:Play()

	local pitch_offset = Instance.new("NumberValue")
	local yaw_offset = Instance.new("NumberValue")
	local pitch_tween
	local yaw_tween

	local function wavePitch(mul: number)
		local pitch = math.rad(1.5)
		local t = 0.25 / mul
		while true do
			pitch_tween = TweenService:Create(
				pitch_offset,
				TweenInfo.new(t, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
				{ Value = pitch }
			)
			pitch_tween:Play()
			if pitch == 0 then
				pitch = math.rad(1.5)
			else
				pitch = 0
			end
			task.wait(t)
		end
	end

	local function waveYaw(mul: number)
		local yaw = math.rad(1)
		local t = 0.5 / mul
		while true do
			yaw_tween = TweenService:Create(
				yaw_offset,
				TweenInfo.new(t, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut),
				{ Value = yaw }
			)
			yaw_tween:Play()
			if yaw == 0 then
				yaw = math.rad(1)
			else
				yaw = 0
			end
			task.wait(t)
		end
	end

	local pitch_thread
	local yaw_thread

	local function startRunning(mul: number)
		pitch_thread = task.spawn(wavePitch, mul)
		yaw_thread = task.spawn(waveYaw, mul)
	end

	local function endRunning()
		task.cancel(pitch_thread)
		task.cancel(yaw_thread)

		pitch_tween:Pause()
		yaw_tween:Pause()

		TweenService:Create(pitch_offset, TweenInfo.new(0.2), { Value = 0 }):Play()
		TweenService:Create(yaw_offset, TweenInfo.new(0.2), { Value = 0 }):Play()
	end
	bag.endRunning = endRunning

	local camera = game.Workspace.CurrentCamera
	local running = false
	bag.render_connection = RunService.RenderStepped:Connect(function(_dt)
		view_model.PrimaryPart.CFrame = camera.CFrame
			* CFrame.new(0, 0.01, 0)
			* CFrame.Angles(pitch_offset.Value, yaw_offset.Value, 0)

		if LocalData.get("moving") and not LocalData.get("aiming") then
			if not running then
				running = true
				startRunning(run_mul)
			end
		else
			if running then
				endRunning()
				running = false
			end
		end
	end)
end

function module.startDrawing(shot_mode: number, speed: number)
	anim_tracks.release:Stop(0.0000001)
	if anim_tracks.semi_aim.IsPlaying then
		anim_tracks.semi_aim:Stop(0.0000001)
		anim_tracks.redraw:Play(0, 1, speed)
	else
		anim_tracks.redraw:Play(0.3, 1, speed)
	end
end

function module.releaseBow(arrow_info: ArrowInfo, reload_delay: number)
	anim_tracks.aim:Stop(0.000001)
	anim_tracks.redraw:Stop(0.000001)

	anim_tracks.semi_aim:Play(0)
	anim_tracks.release:Play(0, 1)
	anim_tracks.hiding_arrow:Play(0, 1)

	LocalData.set("arrow_loaded", false)

	task.spawn(function()
		task.wait(reload_delay - 0.3) -- 0.3은 reload 애니메이션 길이
		anim_tracks.reload:Play(0)
		anim_tracks.hiding_arrow:Stop(0.1)
		task.wait(0.3)
		LocalData.set("arrow_loaded", true)
	end)
end

function module.setRunMultiplier(mul: number)
	run_mul = mul
end

return module
