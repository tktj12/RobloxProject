local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GuiService = require(ReplicatedStorage.Modules.Client.GuiService)
local Party = require(ReplicatedStorage.Modules.Shared.Party)
local SharedData = require(ReplicatedStorage.Modules.Shared.SharedData)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

export type PartyT = Party.PartyT

local UserEvent = ReplicatedStorage.Events.UserEvent
local last_invite: { [Player]: number } = {}
local local_player = Players.LocalPlayer

local module = {}
setmetatable(module, { __index = Party })

local function isInviteCooledDown(target: Player): boolean
	local last = last_invite[target] or -Party.INVITE_COOLDOWN
	if os.clock() - last > Party.INVITE_COOLDOWN then
		return true
	end
	return false
end
module.isInviteCooledDown = isInviteCooledDown

function module.receiveInvite(inviter: Player, party: PartyT): ()
	local gui, is_confirmed = GuiService.spawnMessageBox(
		`{inviter.DisplayName} @{inviter.Name}\nsent you an invite!`,
		"Reject",
		"Accept"
	)

	local is_destroyed = false
	local is_timeout = false
	is_confirmed.Destroying:Connect(function()
		is_destroyed = true
		if is_timeout then
			UserEvent:FireServer("AfkInvite", inviter)
			return
		end

		if not is_confirmed.Value then
			UserEvent:FireServer("RejectInvite", inviter)
			return
		end

		if Party.getPlayerParty(local_player) then
			GuiService.spawnMessageBox(
				`You're already in a party.\nTo leave, click "Leave Party" at the bottom of the party info.`
			)
			return
		end

		if party == nil then
			-- party가 없는 상태에서 초대한 경우
			if not inviter.Parent then
				-- inviter가 게임을 떠난 경우
				GuiService.spawnMessageBox(`{inviter.DisplayName} left the lobby`)
				return
			end

			if Party.getPlayerParty(inviter) and not Party.isLeader(inviter) then
				-- inviter가 리더가 아닌 경우
				GuiService.spawnMessageBox(
					`{inviter.DisplayName} is not the party leader. Ask the party leader to invite.`
				)
				return
			end
		elseif Party.size(party) == 0 then
			-- party가 있었으나 사라진 경우
			GuiService.spawnMessageBox(`The party is no longer available.`)
			return
		end

		UserEvent:FireServer("AcceptInvite", inviter.UserId)
	end)

	task.wait(Party.ACCEPT_TIMEOUT)
	if not is_destroyed then
		is_timeout = true
		gui:Destroy()
	end
end

function module.sendInvite(target: Player): ()
	local party = Party.getPlayerParty(local_player)

	if party then
		local leader = Party.getLeader(party) :: Player
		if leader ~= local_player then
			GuiService.spawnMessageBox(
				`Only the party leader can invite.\nCurrent leader: {leader.DisplayName} @{leader.Name}`
			)
			return
		end

		if Party.size(party) >= SharedData.MAX_PARTY_SIZE then
			GuiService.spawnMessageBox(`Can't invite — your party is full.`)
			return
		end
	end

	if Party.getPlayerParty(target) then
		GuiService.spawnMessageBox(`{target.DisplayName} is already in a party.`)
		return
	end

	if not isInviteCooledDown(target) then
		GuiService.spawnMessageBox(
			`You've recently sent an invite to {target.DisplayName}. Please try again in a moment.`
		)
		return
	end

	UserEvent:FireServer("SendInvite", target)
end

function module.kick(target: Player): ()
	local _, confirmed = GuiService.spawnMessageBox(`Kick {target.DisplayName}?`, "Cancel", "Kick")

	confirmed.Destroying:Connect(function()
		if confirmed.Value == true and Party.areInSameParty(Players.LocalPlayer, target) then
			UserEvent:FireServer("Kick", target)
		end
	end)
end

function module.leaveParty(): ()
	local party = Party.getPlayerParty(local_player)
	if party == nil then
		GuiService.spawnMessageBox("You're not in a party.")
		return
	end

	local _gui, confirmed
	if Util.getPlaceName() == "CastleGate" then
		_gui, confirmed = GuiService.spawnMessageBox(
			"Leave the party? (You will be kicked from the game)",
			"Cancel",
			"Leave"
		)
	else
		_gui, confirmed = GuiService.spawnMessageBox("Leave the party?", "Cancel", "Leave")
	end
	confirmed.Destroying:Connect(function()
		if confirmed.Value == true then
			UserEvent:FireServer("LeaveParty")
		end
	end)
end

function module.onInviteAck(target: Player): ()
	last_invite[target] = os.clock()
	GuiService.spawnMessageBox(`Invitation sent to {target.DisplayName}!`)
end

Players.PlayerRemoving:Connect(function(player)
	last_invite[player] = nil
end)

return module
