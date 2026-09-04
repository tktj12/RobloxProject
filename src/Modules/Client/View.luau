local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ViewModel = require(ReplicatedStorage.Modules.Client.ViewModel)

local DEFAULT_FOV = 70
local ZOOM_FOV = 68.5

local local_player = Players.LocalPlayer
local crosshair = local_player.PlayerGui:WaitForChild("CrosshairGui")
local camera = workspace.CurrentCamera

local module = {}
module.ViewModel = ViewModel

function module.switchToFirstPerson()
	local_player.CameraMode = Enum.CameraMode.LockFirstPerson
	UserInputService.MouseIconEnabled = false
	crosshair.Enabled = true
end

function module.switchToClassicCameraMode()
	local_player.CameraMode = Enum.CameraMode.Classic
	UserInputService.MouseIconEnabled = true
	crosshair.Enabled = false

	local_player.CameraMinZoomDistance = 10
	local_player.CameraMaxZoomDistance = 10
	task.wait(0.2)
	local_player.CameraMinZoomDistance = 0.5
	local_player.CameraMaxZoomDistance = 50
end

local function quickZoom()
	local t = TweenService:Create(camera, TweenInfo.new(0.02), { FieldOfView = ZOOM_FOV })
	t:Play()
	t.Completed:Connect(function()
		TweenService:Create(camera, TweenInfo.new(0.02), { FieldOfView = DEFAULT_FOV }):Play()
	end)
end

function module.onBowDraw(shot_mode, speed)
	ViewModel.startDrawing(shot_mode, speed)
end

function module.onBowRelease(arrow_info, reload_delay)
	ViewModel.releaseBow(arrow_info, reload_delay)
	if arrow_info.draw_power >= 0.9 then
		quickZoom()
	end
end

return module

--[[
local PEAK = math.rad(0.8)
local HALF = 0.05 -- 올라가기 0.05 + 복귀 0.05 = 총 0.1초
local startTime = nil -- 효과 시작 시각(없으면 비활성)
RunService:BindToRenderStep("CameraTilt", Enum.RenderPriority.Camera.Value + 1, function()
	if not startTime then
		return
	end
	local t = os.clock() - startTime
	local pitch
	if t < HALF then
		pitch = PEAK * (t / HALF) 
	elseif t < HALF * 2 then
		pitch = -(PEAK * (t - HALF) / HALF)
	else
		startTime = nil -- 종료
		return
	end
	camera.CFrame *= CFrame.Angles(pitch, 0, 0) -- X축 = 위/아래 피치
end)

function module.bump()
	startTime = os.clock()
end
]]
