local Error = {}
Error.__index = Error

local function __tostring(self: Error): string
	local str = self.code
	if self.msg then
		str = `{str}: {self.msg}`
	end
	if self.stack then
		str = `{str}\nSTACK BEGIN\n{self.stack} STACK END`
	end
	return str
end

Error.__tostring = __tostring
Error._class_type = "Error"
export type Error = typeof(setmetatable(
	{} :: {
		code: string,
		msg: string?,
		stack: string?,
	},
	Error
))

function Error.new(code: string?, msg: string?, stack: string?): Error
	local self = {
		code = code or "Error",
		msg = msg,
		stack = stack,
	}
	setmetatable(self, Error)
	return self
end

table.freeze(Error)
return Error
