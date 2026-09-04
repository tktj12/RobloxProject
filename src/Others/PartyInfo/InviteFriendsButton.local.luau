local SocialService = game:GetService("SocialService")

local Util = require(game.ReplicatedStorage.Modules.Shared.Util)

local player = game.Players.LocalPlayer
local button = script.Parent
local can_invite = false
local success = false

button.Activated:Connect(function()
	if can_invite then
		SocialService:PromptGameInvite(player)
	end
end)

button.Visible = false
success, can_invite = Util.pcallWithRetry(function()
	return SocialService:CanSendGameInviteAsync(player)
end)
if not success then
	warn(`SocialService:CanSendGameInviteAsync() failed with error: {can_invite}`)
elseif can_invite then
	button.Visible = true
end

if not can_invite then
	print("local player cannot send game invites")
end
