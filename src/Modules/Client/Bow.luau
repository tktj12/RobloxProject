local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArrowInfo = require(ReplicatedStorage.Modules.Shared.ArrowInfo)
local ArrowService = require(ReplicatedStorage.Modules.Client.ArrowService)
local SoundManager = require(ReplicatedStorage.Modules.Client.SoundManager)
local VfxManager = require(ReplicatedStorage.Modules.Client.VfxManager)

type ArrowInfo = ArrowInfo.ArrowInfo

local LocalPlayer = Players.LocalPlayer

local Bow = {}

function Bow.getPlayerBow(player: Player)
	local bow
	if player == LocalPlayer then
		bow = workspace.ViewModel.Mesh
	else
		bow = player.Character.Mesh
	end

	if not bow then
		error("Player does not have a bow equipped")
	end

	return bow
end

function Bow.draw(player: Player, shot_mode: number)
	local bow = Bow.getPlayerBow(player)
	SoundManager.onStartDraw(bow, shot_mode)
	VfxManager.onStartDraw(bow, shot_mode)
end

function Bow.release(arrow_info: ArrowInfo)
	ArrowService.fireArrow(arrow_info)

	local bow = Bow.getPlayerBow(arrow_info.shooter)
	SoundManager.onBowRelease(bow, arrow_info)
	VfxManager.onBowRelease(bow, arrow_info)
end

return Bow
