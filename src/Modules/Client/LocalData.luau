local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Modules.Shared.Fusion)
local PlayerData = require(ReplicatedStorage.Modules.Shared.PlayerData)
local SkillTree = require(ReplicatedStorage.Modules.Client.SkillTree)
local Util = require(ReplicatedStorage.Modules.Shared.Util)

type LocalDataFusionValue = "combo" | "arrow_loaded" | "aiming" | "moving"

local peek = Fusion.peek
local scope = Fusion.scoped(Fusion) -- this will never be cleaned up
local values = {} :: { [LocalDataFusionValue]: Fusion.Value<any> }

local LocalData = {}

function LocalData.getSkillState()
	return LocalData.skill_tree:getState().unlockedNodes
end

function LocalData.set(att: LocalDataFusionValue, value): ()
	values[att]:set(value)
end

function LocalData.increment(att: LocalDataFusionValue, value: number)
	values[att]:set(peek(values[att]) + value)
end

function LocalData.get(att: LocalDataFusionValue): any
	return peek(values[att])
end

function LocalData.onChange(att: LocalDataFusionValue, callback: (any) -> ())
	return scope:Observer(values[att]):onChange(callback)
end

local function initModule()
	local unlockRequest = Util.waitChild(ReplicatedStorage, "SkillTreeUnlockRequest", 30)
	local upgradeRequest = ReplicatedStorage:FindFirstChild("SkillTreeUpgradeRequest")
	local stateUpdated = ReplicatedStorage:FindFirstChild("SkillTreeStateUpdated")

	if not unlockRequest or not unlockRequest:IsA("RemoteEvent") then
		error(
			"[SkillTree demo] RemoteEvents missing after 30s. Ensure ServerScriptService.SkillTreeDemoServer.Example runs (creates SkillTree + remotes)."
		)
	end
	if
		not upgradeRequest
		or not upgradeRequest:IsA("RemoteEvent")
		or not stateUpdated
		or not stateUpdated:IsA("RemoteEvent")
	then
		error("[SkillTree demo] Upgrade/state remotes missing. Check Example server script.")
	end

	local remoteConfig = {
		unlockRequest = unlockRequest,
		upgradeRequest = upgradeRequest,
		stateUpdated = stateUpdated,
	}

	LocalData.scope = scope
	LocalData.values = values
	LocalData.skill_tree = SkillTree.new(remoteConfig)
	LocalData.player_data = PlayerData.new {
		id = Players.LocalPlayer.UserId,
	}

	values["combo"] = scope:Value(0)
	values["arrow_loaded"] = scope:Value(true)
	values["aiming"] = scope:Value(false)
	values["moving"] = scope:Value(false)
end

initModule()
return LocalData
