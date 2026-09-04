local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LEnum = require(ReplicatedStorage.Modules.Shared.LEnum)

local INVITE_COOLDOWN = 17
local ACCEPT_TIMEOUT = 20
if RunService:IsClient() then
	INVITE_COOLDOWN = 20
	ACCEPT_TIMEOUT = 17
end

export type PartyT = string

local Party = {}

Party.INVITE_COOLDOWN = INVITE_COOLDOWN
Party.ACCEPT_TIMEOUT = ACCEPT_TIMEOUT
Party.DEFAULT_PARTY = "Party1"

--[[
	player의party가 없을 경우 return nil
]]
function Party.getPlayerParty(player: Player): PartyT?
	return player:GetAttribute(LEnum.PlayerAttribute.Party) :: PartyT?
end

function Party.getMembers(party: PartyT): { Player }
	local members = {}
	for _, player in Players:GetPlayers() do
		if Party.getPlayerParty(player) == party then
			table.insert(members, player)
		end
	end
	return members
end

function Party.getLeader(party: PartyT): Player?
	for _, member in Party.getMembers(party) do
		if member:GetAttribute(LEnum.PlayerAttribute.PartyLeader) then
			return member
		end
	end
	return nil
end

function Party.size(party: PartyT): number
	return #Party.getMembers(party)
end

function Party.partyUpdated(player: Player): RBXScriptSignal
	return player:GetAttributeChangedSignal(LEnum.PlayerAttribute.PartyVersion)
end

function Party.getPartyVersion(party: PartyT): number
	local members = Party.getMembers(party)
	if #members == 0 then
		return 0
	else
		local ver = members[1]:GetAttribute(LEnum.PlayerAttribute.PartyVersion) :: number?
		return ver or 1
	end
end

function Party.areInSameParty(p1: Player, p2: Player): boolean?
	local p1_party = Party.getPlayerParty(p1)
	return p1_party and p1_party == Party.getPlayerParty(p2)
end

function Party.isLeader(player: Player): boolean?
	return player:GetAttribute(LEnum.PlayerAttribute.PartyLeader) :: boolean?
end

return Party
