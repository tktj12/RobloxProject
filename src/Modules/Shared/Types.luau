local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Modules.Shared.Fusion)

export type function AssertTable(t: type, index: number?)
	if not t:is("table") then
		if index ~= nil then
			error(`Expected table for argument {index}, got {t.tag}`)
		else
			error(`Expected table, got {t.tag}`)
		end
	end
end

--[[
	키가 겹치고 양쪽 다 테이블이면 재귀적으로 합치고, 그 외에는 t2가 우선한다.
	인덱서와 메타테이블도 같은 규칙을 따른다.
]]
export type function MergedTable(t1: type, t2: type)
	local function assertTable(t: type, index: number)
		if not t:is("table") then
			error(`Expected table for argument {index}, got {t.tag}`)
		end
	end

	local function merge(a: type, b: type): type
		local merged = types.copy(a) -- 인자로 받은 타입은 불변이므로 복사본을 변형

		for key, prop in b:properties() do
			local read = prop.read
			if read ~= nil then
				local prev = merged:readproperty(key)
				if prev ~= nil and prev:is("table") and read:is("table") then
					merged:setreadproperty(key, merge(prev, read))
				else
					merged:setreadproperty(key, read)
				end
			end

			local write = prop.write
			if write ~= nil then
				local prev = merged:writeproperty(key)
				if prev ~= nil and prev:is("table") and write:is("table") then
					merged:setwriteproperty(key, merge(prev, write))
				else
					merged:setwriteproperty(key, write)
				end
			end
		end

		--[[
			luau가 인덱서의 읽기/쓰기 타입 분리를 아직 지원하지 않으므로 setindexer로 한번에 처리.
			인덱스 타입이 같고 결과가 양쪽 다 테이블이면 프로퍼티와 같은 규칙으로 합친다.
		]]
		local indexer = b:readindexer()
		if indexer ~= nil then
			local result = indexer.result
			local prev = merged:readindexer()
			if
				prev ~= nil
				and prev.index == indexer.index
				and prev.result:is("table")
				and result:is("table")
			then
				result = merge(prev.result, result)
			end
			merged:setindexer(indexer.index, result)
		end

		local metatable = b:metatable()
		if metatable ~= nil then
			local prev = merged:metatable()
			merged:setmetatable(if prev ~= nil then merge(prev, metatable) else metatable)
		end

		return merged
	end

	assertTable(t1, 1)
	assertTable(t2, 2)

	return merge(t1, t2)
end

export type function Partial(tbl: type)
	if not (tbl:is("table") or tbl:is("union") or tbl:is("intersection")) then
		error(`Partial: expected table, union or intersection, got {tbl.tag}`)
	end

	local function partialTable(src: type): type
		local ret = types.newtable()

		for key, prop in src:properties() do
			local read, write = prop.read, prop.write
			if read ~= nil and read == write then
				-- 읽기/쓰기가 같으면 일반 프로퍼티로 되돌려 표시를 단순하게 유지
				ret:setproperty(key, types.optional(read))
			else
				if read ~= nil then
					ret:setreadproperty(key, types.optional(read))
				end
				if write ~= nil then
					ret:setwriteproperty(key, types.optional(write))
				end
			end
		end

		-- luau가 인덱서의 읽기/쓰기 타입 분리를 아직 지원하지 않으므로 setindexer로 한번에 처리
		local indexer = src:readindexer()
		if indexer ~= nil then
			ret:setindexer(indexer.index, types.optional(indexer.result))
		end

		local mt = src:metatable()
		if mt ~= nil then
			ret:setmetatable(mt)
		end

		return ret
	end

	--[[
		유니온/인터섹션은 성분을 따라 내려가며 테이블만 변환한다.
		테이블 프로퍼티 안으로는 들어가지 않으므로 얕은 변환이라는 성질은 그대로다.
	]]
	local function apply(src: type): type
		if src:is("table") then
			return partialTable(src)
		end

		local is_union = src:is("union")
		if not is_union and not src:is("intersection") then
			return src
		end

		local components = src:components()
		if #components < 2 then
			return src
		end

		local parts = table.create(#components)
		for i, component in components do
			parts[i] = apply(component)
		end

		if is_union then
			return types.unionof(table.unpack(parts))
		end
		return types.intersectionof(table.unpack(parts))
	end

	return apply(tbl)
end

--[[
	메타테이블은 메서드 저장소로 보고 옵셔널로 만들지 않는다.
]]
export type function DeepPartial(tbl: type)
	if not (tbl:is("table") or tbl:is("union") or tbl:is("intersection")) then
		error(`DeepPartial: expected table, union or intersection, got {tbl.tag}`)
	end

	-- 순환 타입에서 캐시가 빗나갈 경우를 대비한 안전장치. 넘어가면 그 아래는 그대로 둔다
	local MAX_DEPTH = 16

	local converted = {} :: { [type]: type } -- 원본 -> 변환 결과, 순환 참조 차단용

	-- 테이블이면 프로퍼티를 옵셔널로 바꾸며 재귀, 유니온/인터섹션이면 성분만 재귀, 나머지는 그대로
	local function convert(src: type, depth: number): type
		local is_union = src:is("union")
		if is_union or src:is("intersection") then
			local components = src:components()
			if depth > MAX_DEPTH or #components < 2 then
				return src
			end

			-- 유니온/인터섹션은 중첩 단계가 아니므로 depth를 늘리지 않는다
			local parts = table.create(#components)
			for i, component in components do
				parts[i] = convert(component, depth)
			end

			if is_union then
				return types.unionof(table.unpack(parts))
			end
			return types.intersectionof(table.unpack(parts))
		end

		if not src:is("table") then
			return src
		end

		local cached = converted[src]
		if cached ~= nil then
			return cached
		end
		if depth > MAX_DEPTH then
			return src
		end

		local ret = types.newtable()
		converted[src] = ret -- 자기 참조가 완성 전의 ret을 가리키도록 먼저 등록

		local next_depth = depth + 1

		for key, prop in src:properties() do
			local read, write = prop.read, prop.write
			if read ~= nil and read == write then
				-- 읽기/쓰기가 같으면 일반 프로퍼티로 되돌려 표시를 단순하게 유지
				ret:setproperty(key, types.optional(convert(read, next_depth)))
			else
				if read ~= nil then
					ret:setreadproperty(key, types.optional(convert(read, next_depth)))
				end
				if write ~= nil then
					ret:setwriteproperty(key, types.optional(convert(write, next_depth)))
				end
			end
		end

		-- luau가 인덱서의 읽기/쓰기 타입 분리를 아직 지원하지 않으므로 setindexer로 한번에 처리
		local indexer = src:readindexer()
		if indexer ~= nil then
			local result = types.optional(convert(indexer.result, next_depth))
			ret:setindexer(indexer.index, result)
		end

		local mt = src:metatable()
		if mt ~= nil then
			ret:setmetatable(mt)
		end

		return ret
	end

	return convert(tbl, 1)
end

--[[
	value가 union의 성분이면 value를 그대로 돌려주고, 아니면 에러를 낸다.
	union 자리에는 문자열 싱글턴 하나만 와도 된다(성분이 하나인 유니온으로 취급).

	type Color = "red" | "green" | "blue"
	type Ok = MemberOf<"red", Color> -- "red"
	type Err = MemberOf<"pink", Color> -- 타입 에러
]]
export type function MemberOf(value: type, union: type)
	local function stringValue(t: type, label: string): string
		if not t:is("singleton") then
			error(`MemberOf: expected string singleton for {label}, got {t.tag}`)
		end

		local v = t:value()
		if typeof(v) ~= "string" then
			-- 싱글턴 값은 string | boolean | nil 뿐이므로 여기 오면 문자열이 아니다
			error(`MemberOf: expected string singleton for {label}, got {tostring(v)}`)
		end

		return v :: string
	end

	local needle = stringValue(value, "argument 1")

	-- 별칭을 거치면 유니온이 중첩될 수 있으므로 평탄화하며 모은다
	local members: { string } = {}
	local function collect(t: type)
		if t:is("union") then
			for _, component in t:components() do
				collect(component)
			end
			return
		end
		table.insert(members, stringValue(t, "argument 2"))
	end

	collect(union)

	for _, member in members do
		if member == needle then
			return value
		end
	end

	local quoted = table.create(#members)
	for i, member in members do
		quoted[i] = `"{member}"`
	end

	error(`MemberOf: "{needle}" is not a member of {table.concat(quoted, " | ")}`)
end

--[[
	유니온에서 nil 성분만 걷어낸다.
	인자가 nil 자체면 never가 된다.
]]
export type function NonNil(t: type)
	local function isNil(component: type): boolean
		if component:is("nil") then
			return true
		end
		-- 경로에 따라 nil이 값 없는 싱글턴으로 들어올 수 있다
		return component:is("singleton") and component:value() == nil
	end

	if not t:is("union") then
		return if isNil(t) then types.never else t
	end

	-- 별칭을 거치면 유니온이 중첩될 수 있으므로 평탄화하며 모은다
	local kept: { type } = {}
	local found = false

	local function collect(component: type)
		if component:is("union") then
			for _, inner in component:components() do
				collect(inner)
			end
			return
		end

		if isNil(component) then
			found = true
			return
		end

		table.insert(kept, component)
	end

	collect(t)

	if not found then
		return t -- nil이 없으면 원본을 그대로 둬서 별칭 표시를 유지한다
	end
	if #kept == 0 then
		return types.never
	end
	if #kept == 1 then
		return kept[1] -- unionof는 성분이 둘 이상이어야 한다
	end
	return types.unionof(table.unpack(kept))
end

-- 타입 함수 안에서는 모듈 경로로 타입을 쓸 수 없으므로 별칭을 만들어 호출한다
type FusionValue<T> = Fusion.Value<T>

--[[
	테이블의 프로퍼티를 전부 Fusion.Value로 감싼다. 한 겹만 감싸므로 중첩 테이블은 통째로 들어간다.

	type Base = { p1: number, p2: string }
	type State = FusionValueProperty<Base> -- { p1: Fusion.Value<number>, p2: Fusion.Value<string> }
]]
export type function FusionValueProperty(t: type)
	if not t:is("table") then
		error(`FusionValueProperty: expected table, got {t.tag}`)
	end

	local ret = types.newtable()

	for key, prop in t:properties() do
		local read, write = prop.read, prop.write
		if read ~= nil and read == write then
			-- 읽기/쓰기가 같으면 일반 프로퍼티로 되돌려 표시를 단순하게 유지
			ret:setproperty(key, FusionValue(read))
		else
			if read ~= nil then
				ret:setreadproperty(key, FusionValue(read))
			end
			if write ~= nil then
				ret:setwriteproperty(key, FusionValue(write))
			end
		end
	end

	-- luau가 인덱서의 읽기/쓰기 타입 분리를 아직 지원하지 않으므로 setindexer로 한번에 처리
	local indexer = t:readindexer()
	if indexer ~= nil then
		ret:setindexer(indexer.index, FusionValue(indexer.result))
	end

	-- 메타테이블은 메서드 저장소로 보고 감싸지 않는다
	local mt = t:metatable()
	if mt ~= nil then
		ret:setmetatable(mt)
	end

	return ret
end

return {}
