local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Party = require(ReplicatedStorage.Modules.Shared.Party)
local SharedData = require(ReplicatedStorage.Modules.Shared.SharedData)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

local PartyInfoGui = ReplicatedStorage.UI.Menu.PartyInfo
local UserFrame = ReplicatedStorage.UI.UserFrame
local local_player = Players.LocalPlayer

type UserFrameT = typeof(UserFrame)

local PartyInfo = {}

local function newUserFrame(player: Player): UserFrameT
	local user_frame: UserFrameT = UserFrame:Clone()
	user_frame.Name = `{player.UserId}`
	user_frame.UserName.Text = `@{player.Name}`
	user_frame.DisplayName.Text = player.DisplayName
	user_frame.Parent = PartyInfoGui.Frame.Lobby.ScrollingFrame

	task.spawn(function()
		local content, isReady = Players:GetUserThumbnailAsync(
			player.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size100x100
		)
		if isReady then
			user_frame.HeadshotImage.Image = content
		end
	end)

	return user_frame
end

local function getUserFrame(user: number | Player | UserFrameT): UserFrameT
	local user_frame: UserFrameT
	if typeof(user) == "Instance" then
		if user:IsA("Frame") then
			user_frame = user
		elseif user:IsA("Player") then
			user_frame = PartyInfoGui:FindFirstChild(`{user.UserId}`, true) :: UserFrameT
		end
	elseif type(user) == "number" then
		user_frame = PartyInfoGui:FindFirstChild(`{user}`, true) :: UserFrameT
	end

	if user_frame then
		return user_frame
	end

	local player = user :: Player
	if typeof(user) == "number" then
		player = Players:GetPlayerByUserId(user :: number) :: Player
	end

	if player and Util.isValidPlayer(player) then
		return newUserFrame(player)
	end

	Util.error(`invalid user`)
end

local function moveUserFrame(
	user: number | Player | UserFrameT,
	where: "Lobby" | "Party" | "OtherParty",
	is_leader: boolean?,
	kickable: boolean?
)
	local user_frame: UserFrameT = getUserFrame(user)

	if where == "Lobby" then
		user_frame.Parent = PartyInfoGui.Frame.Lobby.ScrollingFrame
		user_frame.KickButton.Visible = false
		user_frame.InviteButton.Visible = true
		user_frame.LeaderMark.Visible = false
	elseif where == "Party" then
		user_frame.Parent = PartyInfoGui.Frame.PartyMembers.ScrollingFrame
		user_frame.KickButton.Visible = (kickable == true)
		user_frame.InviteButton.Visible = false
		user_frame.LeaderMark.Visible = (is_leader == true)
	elseif where == "OtherParty" then
		user_frame.Parent = PartyInfoGui.Frame.Lobby.ScrollingFrame
		user_frame.KickButton.Visible = false
		user_frame.InviteButton.Visible = false
		user_frame.LeaderMark.Visible = false
	end
end

local function clearPartyMembers()
	for _, user_frame in PartyInfoGui.Frame.PartyMembers.ScrollingFrame:GetChildren() do
		if user_frame:IsA("Frame") then
			moveUserFrame(user_frame, "Lobby")
		end
	end
end

local function refreshLobby()
	for _, user_frame in PartyInfoGui.Frame.Lobby.ScrollingFrame:GetChildren() do
		if user_frame:IsA("Frame") then
			moveUserFrame(user_frame, "Lobby")
			local player = Players:GetPlayerByUserId(tonumber(user_frame.Name) :: number)
			if player and Party.getPlayerParty(player) or player == local_player then
				user_frame.InviteButton.Visible = false
			end
		end
	end
end

local function removeUserFrame(user: number | Player | UserFrameT)
	getUserFrame(user):Destroy()
end

function PartyInfo.refresh()
	clearPartyMembers()
	refreshLobby()

	local MAX_PARTY_SIZE = SharedData.MAX_PARTY_SIZE
	local party = Party.getPlayerParty(local_player)
	if not party then
		PartyInfoGui.Frame.PartyMembersText.Text = `Party Members | 0/{MAX_PARTY_SIZE}`
		return
	end

	local is_local_leader = Party.isLeader(local_player)
	local members = Party.getMembers(party)
	for _, player in members do
		local kickable = (player ~= local_player and is_local_leader)
		moveUserFrame(player, "Party", Party.isLeader(player), kickable)
	end

	PartyInfoGui.Frame.PartyMembersText.Text = `Party Members | {#members}/{MAX_PARTY_SIZE}`
end

function PartyInfo.reload()
	for _, user_frame in PartyInfoGui.Frame.PartyMembers.ScrollingFrame:GetChildren() do
		if user_frame:IsA("Frame") then
			user_frame:Destroy()
		end
	end

	for _, user_frame in PartyInfoGui.Frame.Lobby.ScrollingFrame:GetChildren() do
		if user_frame:IsA("Frame") then
			user_frame:Destroy()
		end
	end

	for _, player in Players:GetPlayers() do
		task.spawn(newUserFrame, player)
	end

	PartyInfo.refresh()
end

function PartyInfo.get(): ScreenGui
	return PartyInfoGui
end

local function playerAdded(player: Player): ()
	PartyInfo.reload()
	Party.partyUpdated(player):Connect(function()
		PartyInfo.refresh()
	end)
end

local function initModule()
	for _, player in Players:GetPlayers() do
		task.spawn(playerAdded, player)
	end
	Players.PlayerAdded:Connect(playerAdded)
	Players.PlayerRemoving:Connect(removeUserFrame)
end

initModule()
return PartyInfo
