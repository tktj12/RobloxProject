local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Menu = require(ReplicatedStorage.Modules.Client.Menu)
local Party = require(ReplicatedStorage.Modules.Shared.Party)
local PartyInfo = require(ReplicatedStorage.Modules.Client.PartyInfo)

type PartyT = Party.PartyT

local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local MessageBox = ReplicatedStorage.UI.MessageBox

local gui_order = 100
local message_count = 0

local function bringToFront(screen_gui: ScreenGui)
	gui_order += 1
	screen_gui.DisplayOrder = gui_order
end

local function isSelectingInput(input: InputObject): boolean
	if
		input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
	then
		return true
	end
	return false
end

local function setSelectionActions(gui_object: GuiObject)
	gui_object.InputBegan:Connect(function(input)
		if isSelectingInput(input) then
			local screen_gui = gui_object:FindFirstAncestorOfClass("ScreenGui")
			if screen_gui then
				bringToFront(screen_gui)
			end
		end
	end)

	gui_object.SelectionGained:Connect(function()
		local screen_gui = gui_object:FindFirstAncestorOfClass("ScreenGui")
		if screen_gui then
			bringToFront(screen_gui)
		end
	end)
end

local module = {}
module.Menu = Menu
module.PartyInfo = PartyInfo

local function spawnMessageBox(
	text: string,
	close_word: string?,
	confirm_word: string?
): (ScreenGui, BoolValue)
	local message_box = MessageBox:Clone()
	message_box.Parent = PlayerGui
	message_box.Frame.ScrollingFrame.TextLabel.Text = text
	print(`[MessageBox]: {text}`)

	setSelectionActions(message_box.Frame)
	bringToFront(message_box)

	message_box.Frame.Position += UDim2.fromOffset(10 * message_count, 10 * message_count)
	message_count += 1
	message_box.Destroying:Connect(function()
		message_count -= 1
	end)

	if close_word then
		message_box.Frame.CloseButton.TextLabel.Text = close_word
	end

	if confirm_word then
		message_box.Frame.ConfirmButton.TextLabel.Text = confirm_word
		message_box.Frame.ConfirmButton.Visible = true
	end

	return message_box, message_box.IsConfirmed
end

module.spawnMessageBox = spawnMessageBox
return module
