local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Party = require(ReplicatedStorage.Modules.Shared.Party)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local WaveLevel = require(ReplicatedStorage.Modules.Shared.WaveLevel)

local SELECTED_COLOR = Color3.fromRGB(20, 20, 120)
local DEFAULT_COLOR = Color3.fromRGB(71, 71, 71)

local UserEvent = ReplicatedStorage.Events.UserEvent
local WavePageGui = ReplicatedStorage.UI.Menu.WavePage
local UserFrame = ReplicatedStorage.UI.UserFrame
local Information = WavePageGui.Information
local AvailableLevels = WavePageGui.AvailableLevels
local LevelButton = ReplicatedStorage.UI.LevelButton
local current_level_btn: TextButton = LevelButton

local WavePage = {}
WavePage.Level = WaveLevel

local function newUserFrame(player: Player)
	local user_frame = UserFrame:Clone()
	user_frame.Name = `{player.UserId}`
	user_frame.UserName.Text = `@{player.Name}`
	user_frame.DisplayName.Text = player.DisplayName
	user_frame.Parent = Information.ClearStatus.Uncleared
	user_frame:AddTag("UserFrame")

	task.spawn(function()
		local content, isReady = Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100
		)
		if isReady and user_frame.Parent then
			user_frame.HeadshotImage.Image = content
		end
	end)

	return user_frame
end

local function getUserFrame(user: string): Frame
	local user_frame: Frame
	user_frame = Information.ClearStatus:FindFirstChild(`{user}`, true) :: Frame
	if user_frame then
		return user_frame
	end
	Util.error(`no UserFrame found`)
end

local function loadInformation(): ()
	--TODO: reward 정보

	local clear_status = WaveLevel.getClearStatus(WaveLevel.current())
	local clear_status_frame = Information.ClearStatus

	for _, user_id in clear_status.cleared do
		local user_frame = getUserFrame(user_id)
		user_frame.Parent = clear_status_frame.Cleared
	end

	for _, user_id in clear_status.uncleared do
		local user_frame = getUserFrame(user_id)
		user_frame.Parent = clear_status_frame.Uncleared
	end
end

local function newLevelButton(level: number): TextButton
	local btn = LevelButton:Clone()
	btn.Name = `{level}`
	btn.Text = `Level {level}`
	btn.Visible = true
	btn.ZIndex = level
	btn.Parent = AvailableLevels
	return btn
end

local function selectLevel(level: number, btn: TextButton): ()
	if not WaveLevel.select(level) then
		warn("Invalid level selected: " .. level)
		return
	end

	current_level_btn.BackgroundColor3 = DEFAULT_COLOR
	btn.BackgroundColor3 = SELECTED_COLOR
	current_level_btn = btn
	loadInformation()
end
WavePage.selectLevel = selectLevel

function WavePage.reload(): ()
	for _, btn in AvailableLevels:GetChildren() do
		if btn:IsA("TextButton") then
			btn:Destroy()
		end
	end

	local tp = WaveLevel.current()
	for i = 1, WaveLevel.MAX_LEVEL do
		if WaveLevel.select(i) then
			newLevelButton(i)
		end
	end
	WaveLevel.select(tp)

	local clear_status_frame = Information.ClearStatus
	for _, frame in clear_status_frame:GetDescendants() do
		if frame:IsA("Frame") and frame:HasTag("UserFrame") then
			frame:Destroy()
		end
	end

	local party = Party.getPlayerParty(Players.LocalPlayer)
	if party then
		for _, player in Party.getMembers(party) do
			newUserFrame(player)
		end
	else
		newUserFrame(Players.LocalPlayer)
	end

	selectLevel(
		WaveLevel.current(),
		AvailableLevels:FindFirstChild(`{WaveLevel.current()}`) :: TextButton
	)
end

function WavePage.sendStartRequest(): ()
	UserEvent:FireServer("StartWave", WaveLevel.current())
	print(`sent start request`)
end

function WavePage.sendGiveupRequest(): ()
	UserEvent:FireServer("GiveupWave", WaveLevel.current())
	print(`sent give up request`)
end

function WavePage.get(): ScreenGui
	return WavePageGui
end

WavePage.reload()
return WavePage
