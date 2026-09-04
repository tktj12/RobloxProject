local button = script.Parent
button.Activated:Connect(function()
	local gui = button:FindFirstAncestorOfClass("ScreenGui")
	gui:Destroy()
end)
