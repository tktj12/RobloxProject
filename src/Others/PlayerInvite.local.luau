local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Party = require(ReplicatedStorage.Modules.Client.Party)

local SHOW_DURATION = 1.2
local SHOW_DISTANCE = 30
local TWEEN_TIME = 0.3
local FLICKER_PREVENTION_SEC = SHOW_DURATION + TWEEN_TIME + 0.2

local LocalPlayer = Players.LocalPlayer
local gui = script.Parent
local selected_player: Player
local token = 0
local tween = TweenService:Create(gui.Button, TweenInfo.new(0.5), { Transparency = 1 })
local last_player: Player = nil
local last_enter = -100

gui.Button.Activated:Connect(function()
	Party.sendInvite(selected_player)
end)

local function showFor(duration, player: Player)
	if
		Party.getPlayerParty(player)
		or (Party.getPlayerParty(LocalPlayer) and not Party.isLeader(LocalPlayer))
	then
		return
	end

	if player == last_player and os.clock() - last_enter < FLICKER_PREVENTION_SEC then
		return
	end
	last_player = player
	last_enter = os.clock()

	gui.Enabled = true
	gui.Adornee = player.Character.Head
	selected_player = player

	tween:Pause()
	gui.Button.Transparency = 1
	tween = TweenService:Create(gui.Button, TweenInfo.new(TWEEN_TIME), { Transparency = 0 })
	tween:Play()

	token += 1
	local my = token
	task.wait(duration)
	if token ~= my then
		return
	end

	tween = TweenService:Create(gui.Button, TweenInfo.new(TWEEN_TIME), { Transparency = 1 })
	tween:Play()
	task.wait(TWEEN_TIME)
	if token ~= my then
		return
	end
	gui.Enabled = false
end

local function setup(player: Player)
	if player == Players.LocalPlayer then
		return
	end
	local character = player.Character

	local cd = Instance.new("ClickDetector")
	cd.MaxActivationDistance = SHOW_DISTANCE
	cd.CursorIcon = "a" -- use default cursor
	cd.Parent = character

	cd.MouseHoverEnter:Connect(function()
		showFor(SHOW_DURATION, player)
	end)

	cd.MouseClick:Connect(function() -- 모바일 터치 (+ 마우스 클릭)
		showFor(SHOW_DURATION, player)
	end)
end

local function onPlayerAdded(player: Player): ()
	if player.Character then
		setup(player)
	end
	player.CharacterAdded:Connect(function()
		setup(player)
	end)
end

for _, p in Players:GetPlayers() do
	task.spawn(onPlayerAdded, p)
end
Players.PlayerAdded:Connect(onPlayerAdded)
