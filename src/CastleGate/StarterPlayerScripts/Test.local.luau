local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ArrowInfo = require(ReplicatedStorage.Modules.Shared.ArrowInfo)
local ArrowService = require(ReplicatedStorage.Modules.Client.ArrowService)

-- task.spawn(function()
-- 	while task.wait(3) do
-- 		local arrow_info = ArrowInfo.new {
-- 			name = "NormalArrow",
-- 			charge = 1,
-- 			start_cframe = workspace.ArrowFirePart.CFrame,
-- 			shot_mode = 0,
-- 			shooter = { UserId = 1234, Character = workspace.ArrowFirePart.Character },
-- 		}
-- 		ArrowService.fireArrow(arrow_info, true)
-- 	end
-- end)
