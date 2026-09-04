local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArrowInfo = require(ReplicatedStorage.Modules.Shared.ArrowInfo)
local Bow = require(ReplicatedStorage.Modules.Client.Bow)

type ArrowInfo = ArrowInfo.ArrowInfo
local module = {}

function module.drawBow(plr: Player, shot_mode: number)
	Bow.draw(plr, shot_mode)
end

function module.releaseBow(arrow_info: ArrowInfo)
	Bow.release(arrow_info)
end

return module
