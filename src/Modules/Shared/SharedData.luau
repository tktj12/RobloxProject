local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Util = require(ReplicatedStorage.Modules.Shared.Util)

local SharedData = {}
SharedData.DEFAULT_DRAW_TIME = 0.8
SharedData.DEFAULT_RELOAD_TIME = 1
SharedData.MAX_COMBO_DAMAGE = 0.1
SharedData.MAX_PARTY_SIZE = 10

Util.deepFreeze(SharedData)
return SharedData
