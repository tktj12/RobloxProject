local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Error = require(ReplicatedStorage.Modules.Shared.Error)
local Types = require(ReplicatedStorage.Modules.Shared.Types)

local DFAULT_RETRY = 10
local DFAULT_DELAY = 1
local LOBBY_ID = 133675877005375
local CASTLE_GATE_ID = 95002990938665

type PlaceName = "Lobby" | "CastleGate"

local place_name: PlaceName

local Util = {}
Util.Error = Error

local function initModule()
	if game.PlaceId == LOBBY_ID then
		place_name = "Lobby"
	elseif game.PlaceId == CASTLE_GATE_ID then
		place_name = "CastleGate"
	else
		error(`Unknown PlaceId: {game.PlaceId}`)
	end
end

function Util.isNaN(n: number): boolean
	-- NaN is never equal to itself
	return n ~= n
end

function Util.isInf(n: number): boolean
	-- Number could be -inf or +inf
	return math.abs(n) == math.huge
end

local CLONERS = {
	["Instance"] = function(v)
		return v:Clone()
	end,
	["Random"] = function(v)
		return v:Clone()
	end,
	-- ["RaycastParams"] TODO
	-- ["OverlapParams"]
	-- ["SharedTable"]
}

--[[
	v must not have circular references, causing stack overflow
]]
function Util.deepCopy<T>(v: T): T
	local t = type(v)
	if t == "table" then
		local copy = table.clone(v :: any) -- 메타테이블 유지됨
		for k, val in copy do
			copy[k] = Util.deepCopy(val)
		end
		return copy :: any
	elseif t == "buffer" then
		local new = buffer.create(buffer.len(v :: any))
		buffer.copy(new, 0, v :: any)
		return new :: any
	elseif t == "userdata" then
		return CLONERS[typeof(v)] and CLONERS[typeof(v)](v) or v
	else
		return v -- 불변 타입
	end
end

function Util.deepFreeze<T>(t: T & {}): T
	-- Freezing a frozen table occurs an error
	if not table.isfrozen(t) then
		table.freeze(t)
	end

	for _, value in t do
		if type(value) == "table" then
			Util.deepFreeze(value)
		end
	end

	return t
end

function Util.pcallWithRetry<A..., R...>(
	func: (A...) -> R...,
	retries: number?,
	delay_sec: number?,
	...: A...
): (boolean, R...)
	retries = retries or DFAULT_RETRY
	delay_sec = delay_sec or DFAULT_DELAY

	local res = {} :: { any }
	for i = 1, retries do
		res = { pcall(func, ...) }
		if res[1] then
			break
		end
		task.wait(delay_sec)
		print(`{debug.info(func, "n")}, retry: {i}`)
	end
	return res[1], table.unpack(res, 2)
end

function Util.assert(condition: boolean?, code: string?, level: number?)
	local trace
	if level == nil or level > 0 then
		level = (level or 1) + 1
		trace = debug.traceback(nil, level)
	end

	if not condition then
		error(Error.new(code, nil, trace), 0)
	end
end

function Util.isValidPlayer(player: Player?): boolean
	if
		player ~= nil
		and typeof(player) == "Instance"
		and player:IsA("Player")
		and Players:GetPlayerByUserId(player.UserId) == player
	then
		return true
	end
	return false
end

function Util.isPlayerPart(part: BasePart): boolean
	return part.CollisionGroup == "Player"
end

function Util.error(code: string?, level: number?)
	local trace
	if level == nil or level > 0 then
		level = (level or 1) + 1
		trace = debug.traceback(nil, level)
	end

	error(Error.new(code, nil, trace), 0)
end

function Util.getPlaceName(): "Lobby" | "CastleGate"
	return place_name
end

function Util.hasAnyFlags(flags: number, test: number): boolean
	return bit32.band(flags, test) ~= 0
end

function Util.hasAllFlags(flags: number, test: number): boolean
	return bit32.band(flags, test) == test
end

function Util.setFlags(state: number, flag: number): number
	return bit32.bor(state, flag)
end

function Util.resetFlags(state: number, flag: number): number
	return bit32.band(state, bit32.bnot(flag))
end

function Util.isLocalPlayer(player: Player): boolean
	return player == Players.LocalPlayer
end

function Util.spawnPivotPart(cframe: CFrame, lifetime: number?): BasePart
	local pivot = ReplicatedStorage.PivotPart:Clone()
	pivot.Parent = workspace :: any
	pivot:PivotTo(cframe)

	if lifetime ~= nil then
		Debris:AddItem(pivot, lifetime)
	end

	return pivot
end

function Util.isEmptyTable<T>(t: T & {}): boolean
	return next(t) == nil
end

function Util.waitChild(parent: Instance, name: string, timeoutSeconds: number): Instance?
	local found = parent:FindFirstChild(name)
	if found then
		return found
	end
	local deadline = os.clock() + timeoutSeconds
	while os.clock() < deadline do
		found = parent:FindFirstChild(name)
		if found then
			return found
		end
		task.wait(0.1)
	end
	return nil
end

function Util.reconcile<T, U>(target: T & {}, source: U & {}): ()
	for key, val in source :: { [any]: any } do
		if target[key] == nil then
			target[key] = Util.deepCopy(val)
		elseif type(target[key]) == "table" and type(val) == "table" then
			Util.reconcile(target[key], val)
		end
	end
end

function Util.deepUpdate<T, U>(target: T & {}, source: U & {}): ()
	for k, v in source :: { [any]: any } do
		if type(v) == "table" then
			if type(target[k]) ~= "table" then
				target[k] = {}
			end
			Util.deepUpdate(target[k], v)
		else
			target[k] = Util.deepCopy(v)
		end
	end
end

function Util.nonNil<T>(val: T): Types.NonNil<T>
	if val == nil then
		error(`Util.nonNil: Value is nil`)
	end
	return val
end

function Util.fadeInModel(model: Model, duration: number)
	local parts = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			table.insert(parts, { part, part.Transparency })
			part.Transparency = 1
		end
	end

	local start_time = tick()
	while tick() - start_time < duration do
		local elapsed = tick() - start_time
		local alpha = elapsed / duration
		for _, part_info in parts do
			local part: BasePart, base_transparency: number = part_info[1], part_info[2]
			part.Transparency = math.max(1 - alpha, base_transparency)
		end
		task.wait()
	end
end

function Util.getLuminanceFromColor3(color: Color3): number
	local r, g, b = color.R, color.G, color.B
	return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

initModule()
return Util
