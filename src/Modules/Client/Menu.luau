local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")

local PartyInfo = require(ReplicatedStorage.Modules.Client.PartyInfo)
local SkillPage = require(ReplicatedStorage.Modules.Client.SkillPage)
local Util = require(ReplicatedStorage.Modules.Shared.Util)
local WavePage = require(ReplicatedStorage.Modules.Client.WavePage)

local SELECTED_COLOR = Color3.fromRGB(62, 62, 62)
local DEFAULT_COLOR = Color3.fromRGB(0, 0, 0)

local PlayerGui = Players.LocalPlayer.PlayerGui
local MenuFolder = ReplicatedStorage.UI.Menu
local Background = MenuFolder.Background
local TopBar = MenuFolder.TopBar

local current_menu_page: ScreenGui = PartyInfo.get()
local current_menu_btn: GuiButton = MenuFolder.TopBar.Frame.Party :: GuiButton
local chat_active_saved = false

local Menu = {}

local function getPage(): ScreenGui
	return current_menu_page
end

function Menu.setPage(
	page: "Party" | "Wave" | "Skills" | "Shop" | "Inventory" | "Settings",
	btn: GuiButton
)
	current_menu_btn.BackgroundColor3 = DEFAULT_COLOR
	btn.BackgroundColor3 = SELECTED_COLOR
	current_menu_btn = btn

	current_menu_page.Enabled = false
	if page == "Party" then
		current_menu_page = PartyInfo.get()
	elseif page == "Wave" then
		current_menu_page = WavePage.get()
	elseif page == "Skills" then
		current_menu_page = SkillPage.get()
	end
	current_menu_page.Enabled = true
end

function Menu.toggle()
	local enabled = not Background.Enabled
	Background.Enabled = enabled
	TopBar.Frame.Visible = enabled
	TopBar.MenuButton.Visible = not enabled

	if Util.getPlaceName() == "CastleGate" then
		UIS.MouseIconEnabled = enabled
	end

	if enabled then
		chat_active_saved = StarterGui:GetCore("ChatActive")
		StarterGui:SetCore("ChatActive", not enabled)
	else
		local chat_active = StarterGui:GetCore("ChatActive")
		StarterGui:SetCore("ChatActive", chat_active or chat_active_saved)
	end

	getPage().Enabled = enabled

	--TODO: 메뉴 열린 상태에서 화살 draw 불가 및 취소
end

function Menu.enable(value: boolean)
	Background.Enabled = value
	TopBar.Frame.Visible = value
	TopBar.MenuButton.Visible = not value
	getPage().Enabled = value
end

local function initModule()
	MenuFolder.Parent = PlayerGui :: any

	-- Tab 키를 가로채 메뉴 키로 사용
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	UIS.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode ~= Enum.KeyCode.Tab or gameProcessed then
			return
		end
		Menu.toggle()
	end)
end

initModule()
return Menu
