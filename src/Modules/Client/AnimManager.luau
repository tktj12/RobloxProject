local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalData = require(ReplicatedStorage.Modules.Client.LocalData)
local SharedData = require(ReplicatedStorage.Modules.Shared.SharedData)

local lc_tracks = {} -- Local character's animation tracks
local move_dir = { forward = 0, right = 0 }
local move_dir_tween: thread?

local AnimManager = {}

local function tweenMoveDir(target: { forward: number, right: number }, duration: number)
	if target.forward == move_dir.forward and target.right == move_dir.right then
		return
	end

	if move_dir_tween then
		task.cancel(move_dir_tween)
	end

	move_dir_tween = task.spawn(function()
		local elapsed = 0
		repeat
			elapsed += task.wait()
			local alpha = elapsed / duration
			move_dir.forward = move_dir.forward + (target.forward - move_dir.forward) * alpha
			move_dir.right = move_dir.right + (target.right - move_dir.right) * alpha
		until elapsed >= duration

		move_dir_tween = nil
	end)
end

local function calcMoveDir(humanoid: Humanoid): ()
	local cam = workspace.CurrentCamera
	local move = humanoid.MoveDirection
	local res = { forward = 0, right = 0 }
	if move.Magnitude < 0.1 then
		tweenMoveDir(res, 0.1)
		return
	end

	-- 카메라의 상하 각도를 제거해 위에서 본 방향만 남김
	local look = cam.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-4 then
		-- 카메라가 정확히 수직일 때
		tweenMoveDir(res, 0.1)
		return
	end

	local flatCam = CFrame.lookAlong(Vector3.zero, flat)

	local rel = flatCam:VectorToObjectSpace(move) -- 카메라 기준 좌표
	res.forward = -rel.Z
	res.right = rel.X
	tweenMoveDir(res, 0.1)
end

-- pitch를 -1 ~ 1로 매핑 (90도 = 1, -90도 = -1)
local function getPitch(): number
	local pitch, _, _ = workspace.CurrentCamera.CFrame:ToOrientation() -- 라디안
	return math.map(pitch, -math.pi / 2, math.pi / 2, -1, 1)
end

function AnimManager.initLocalCharacter(animator: Animator)
	local idle = Instance.new("Animation")
	local movement = Instance.new("Animation")
	local aiming = Instance.new("Animation")
	local drawing = Instance.new("Animation")
	local release_reload = Instance.new("Animation")
	local jumping = Instance.new("Animation")
	local falling = Instance.new("Animation")
	local landing = Instance.new("Animation")
	local aiming_jump = Instance.new("Animation")

	idle.Parent = animator.Parent
	movement.Parent = animator.Parent
	aiming.Parent = animator.Parent
	drawing.Parent = animator.Parent
	release_reload.Parent = animator.Parent
	jumping.Parent = animator.Parent
	falling.Parent = animator.Parent
	landing.Parent = animator.Parent
	aiming_jump.Parent = animator.Parent

	idle.AnimationId = "rbxassetid://134917774857649"
	movement.AnimationId = "rbxassetid://83380540190614"
	aiming.AnimationId = "rbxassetid://76203013653991"
	drawing.AnimationId = "rbxassetid://87629476941053"
	release_reload.AnimationId = "rbxassetid://85925249942738"
	jumping.AnimationId = "rbxassetid://118483378267369"
	falling.AnimationId = "rbxassetid://99220665855919"
	landing.AnimationId = "rbxassetid://101733048636696"
	aiming_jump.AnimationId = "rbxassetid://72830574373723"

	lc_tracks.idle = animator:LoadAnimation(idle)
	lc_tracks.movement = animator:LoadAnimation(movement)
	lc_tracks.aiming = animator:LoadAnimation(aiming)
	lc_tracks.drawing = animator:LoadAnimation(drawing)
	lc_tracks.release_reload = animator:LoadAnimation(release_reload)
	lc_tracks.jumping = animator:LoadAnimation(jumping)
	lc_tracks.falling = animator:LoadAnimation(falling)
	lc_tracks.landing = animator:LoadAnimation(landing)
	lc_tracks.aiming_jump = animator:LoadAnimation(aiming_jump)

	lc_tracks.aiming_jump.Looped = false
	lc_tracks.aiming_jump.Priority = Enum.AnimationPriority.Action

	while task.wait() do
		if animator:FindFirstAncestorWhichIsA("WorldRoot") then
			break
		end
	end
	lc_tracks.idle:Play()
	lc_tracks.aiming.Priority = Enum.AnimationPriority.Action3
	lc_tracks.movement.Priority = Enum.AnimationPriority.Movement
	lc_tracks.movement:SetParameter("WalkSpeed", 1.9)
	lc_tracks.movement:SetParameter("RunSpeed", 1.5)

	local disconnects = {}
	table.insert(
		disconnects,
		LocalData.onChange("moving", function()
			if LocalData.get("moving") then
				lc_tracks.movement:Play(0.2, 1)
			else
				lc_tracks.movement:Stop(0.3)
			end
		end)
	)

	table.insert(
		disconnects,
		LocalData.onChange("aiming", function()
			local value = LocalData.get("aiming")
			lc_tracks.movement:SetParameter("Aiming", value)

			if value then
				lc_tracks.aiming:Play(
					SharedData.DEFAULT_DRAW_TIME / LocalData.player_data.runtime.DrawSpeed
				)
			end
		end)
	)

	local connection = RunService.RenderStepped:Connect(function()
		local Humanoid = animator.Parent :: Humanoid
		calcMoveDir(Humanoid)
		lc_tracks.movement:SetParameter("MoveForward", move_dir.forward)
		lc_tracks.movement:SetParameter("MoveRight", move_dir.right)

		if LocalData.get("aiming") then
			lc_tracks.aiming:SetParameter("Pitch", getPitch())
		end

		local state = Humanoid:GetState()
		if state == Enum.HumanoidStateType.Jumping then
			if LocalData.get("aiming") then
				if not lc_tracks.aiming_jump.IsPlaying then
					lc_tracks.aiming_jump:Play(0)
				end
			elseif not lc_tracks.jumping.IsPlaying then
				lc_tracks.jumping:Play(0.1)
			end
		elseif state == Enum.HumanoidStateType.Freefall and not lc_tracks.falling.IsPlaying then
			lc_tracks.falling:Play(0.1)
		elseif state == Enum.HumanoidStateType.Landed and not lc_tracks.landing.IsPlaying then
			lc_tracks.jumping:Stop(0.01)
			lc_tracks.aiming_jump:Stop(0.01)
			lc_tracks.falling:Stop(0.1)
			lc_tracks.landing:Play(0.1)
			task.wait(0.1)
			lc_tracks.landing:Stop(0.3)
		end
	end)

	animator.Destroying:Connect(function()
		for _, disconnect in disconnects do
			disconnect()
		end
		connection:Disconnect()
	end)
end

function AnimManager.releaseBow()
	lc_tracks.aiming:Stop(0.000001)
	lc_tracks.release_reload:Play(0, 1, LocalData.player_data.runtime.LoadSpeed)
end

return AnimManager
