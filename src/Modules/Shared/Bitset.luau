local MASK = table.create(32)
for i = 0, 31 do
	MASK[i + 1] = bit32.lshift(1, i)
end

local INV_MASK = table.create(32)
for i = 0, 31 do
	INV_MASK[i + 1] = bit32.bnot(MASK[i + 1])
end

export type Bitset = {
	data: { number },
	size: number,
	clone: (self: Bitset) -> Bitset,
	count: (self: Bitset) -> number,
	countro: (self: Bitset) -> number,
	band: (self: Bitset, other: Bitset) -> Bitset,
	bor: (self: Bitset, other: Bitset) -> Bitset,
	resize: (self: Bitset, new_size: number) -> (),
	serialize: (self: Bitset) -> buffer,
	deserialize: (buf: buffer, size: number?) -> Bitset,
	[number]: boolean,
}

local function get(self: Bitset, index: number): boolean
	assert(index >= 0 and index < self.size, "index out of bounds")

	local word = (index // 32) + 1
	local bit = bit32.band(index, 31) -- index mod 32
	return bit32.btest(self.data[word], MASK[bit + 1])
end

local function set(self: Bitset, index: number, value: boolean)
	assert(index >= 0 and index < self.size, "index out of bounds")

	local word = (index // 32) + 1
	local bit = bit32.band(index, 31) -- index mod 32
	if value then
		self.data[word] = bit32.bor(self.data[word], MASK[bit + 1])
	else
		self.data[word] = bit32.band(self.data[word], INV_MASK[bit + 1])
	end
end

local Bitset = {}
Bitset.__index = function(t, k)
	if type(k) == "number" then
		return get(t, k)
	else
		return function(...)
			return Bitset[k](...)
		end
	end
end
Bitset.__newindex = function(t, k, v)
	if type(k) == "number" then
		set(t, k, v)
	else
		rawset(t, k, v)
	end
end

function Bitset.new(size: number): Bitset
	assert(size > 0 and size == size // 1, "size must be a positive integer")

	local obj = {
		data = table.create(math.ceil(size / 32), 0),
		size = size,
	}

	setmetatable(obj, Bitset)
	return (obj :: any) :: Bitset
end

function Bitset:clone(): Bitset
	local copy = {
		data = table.clone(self.data),
		size = self.size,
	}

	setmetatable(copy, Bitset)
	return (copy :: any) :: Bitset
end

local function popcount(x: number): number
	local n = 0
	while x ~= 0 do
		x = bit32.band(x, x - 1) -- 가장 낮은 세트 비트를 제거 (Kernighan's algorithm)
		n += 1
	end
	return n
end

function Bitset:count(): number
	local total = 0
	for _, word in self.data do
		total += popcount(word)
	end
	return total
end

-- 인덱스 0부터 연속으로 1인 비트 수 반환.
function Bitset:countro(): number
	local total = 0
	for _, word in self.data do
		if word == 0xFFFFFFFF then
			total += 32
		else
			total += bit32.countrz(bit32.bnot(word))
			break
		end
	end
	return math.min(total, self.size)
end

function Bitset:band(other: Bitset): Bitset
	assert(self.size == other.size, "size mismatch")

	local result = Bitset.new(self.size)
	for i, word in self.data do
		result.data[i] = bit32.band(word, other.data[i])
	end
	return result
end

function Bitset:bor(other: Bitset): Bitset
	assert(self.size == other.size, "size mismatch")

	local result = Bitset.new(self.size)
	for i, word in self.data do
		result.data[i] = bit32.bor(word, other.data[i])
	end
	return result
end

function Bitset:__tostring(): string
	local parts = table.create(self.size)
	for i = 0, self.size - 1 do
		parts[i + 1] = self[i] and "1" or "0"
	end
	return table.concat(parts)
end

function Bitset:resize(new_size: number)
	assert(new_size > 0 and new_size == new_size // 1, "size must be a positive integer")
	if new_size == self.size then
		return
	end

	local new_word_count = math.ceil(new_size / 32)
	local old_word_count = #self.data

	if new_word_count > old_word_count then
		for i = old_word_count + 1, new_word_count do
			self.data[i] = 0
		end
	elseif new_word_count < old_word_count then
		for i = old_word_count, new_word_count + 1, -1 do
			self.data[i] = nil
		end
	end

	-- 마지막 워드에서 new_size를 초과하는 비트 클리어
	local last_bits = new_size % 32
	if last_bits ~= 0 then
		local mask = bit32.lshift(1, last_bits) - 1
		self.data[new_word_count] = bit32.band(self.data[new_word_count], mask)
	end

	self.size = new_size
end

function Bitset:serialize(): buffer
	local b = buffer.create(#self.data * 4)
	for i, word in self.data :: { number } do
		buffer.writeu32(b, (i - 1) * 4, word)
	end
	return b
end

--[[
	buffer는 Bitset.serialize로 생성된 버퍼여야 합니다.
]]
function Bitset.deserialize(buf: buffer, size: number?): Bitset
	local data = {}
	for i = 1, (buffer.len(buf) / 4) do
		table.insert(data, buffer.readu32(buf, (i - 1) * 4))
	end

	local obj = {
		data = data,
		size = #data * 32,
	} :: any
	setmetatable(obj, Bitset)
	if size then
		obj:resize(size)
	end
	return obj :: Bitset
end

return Bitset
