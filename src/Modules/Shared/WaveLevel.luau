local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bitset = require(ReplicatedStorage.Modules.Shared.Bitset)

local MAX_LEVEL = 100 --TODO: 임시

type Bitset = Bitset.Bitset

local selected: number = 1
local clear_status: { [string]: Bitset } = {}
local is_available: { boolean } = { true }

local module = {}
module.MAX_LEVEL = MAX_LEVEL

function module.getClearStatus(
	level: number
): { ["cleared"]: { string }, ["uncleared"]: { string } }
	local cleared = {}
	local uncleared = {}
	for user_id, is_cleared in clear_status do
		if is_cleared[level] then
			table.insert(cleared, user_id)
		else
			table.insert(uncleared, user_id)
		end
	end

	return {
		cleared = cleared,
		uncleared = uncleared,
	}
end

local function calcAvailableLevels(): ()
	is_available = { true }
	for i = 2, MAX_LEVEL do
		if is_available[i] then
			continue
		end

		for _id, is_cleared in clear_status do
			if is_cleared[i] then
				table.insert(is_available, true)
				table.insert(is_available, true)
				break
			elseif is_cleared[i - 1] then
				table.insert(is_available, true)
				break
			end
		end

		if is_available[i] then
			continue
		end

		table.insert(is_available, false)
	end

	is_available[MAX_LEVEL + 1] = nil
end

function module.current(): number
	return selected
end

function module.select(level: number): boolean
	if not is_available[level] then
		return false
	end

	selected = level
	return true
end

function module.setClearStatus(serialized_data: { [string]: buffer }): ()
	clear_status = {}
	for user_id, buf in serialized_data do
		clear_status[user_id] = Bitset.deserialize(buf, MAX_LEVEL + 1)
	end

	calcAvailableLevels()
end

function module.setPlayerClearStatus(player_id: string, buf: buffer?): ()
	if buf then
		clear_status[player_id] = Bitset.deserialize(buf, MAX_LEVEL + 1)
	else
		clear_status[player_id] = nil
	end
	calcAvailableLevels()
end

return module
