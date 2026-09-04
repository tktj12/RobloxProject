local button = script.Parent
button.Activated:Connect(function()
	local gui = button:FindFirstAncestorOfClass("ScreenGui")
	gui.IsConfirmed.Value = true
	gui:Destroy()
end)
