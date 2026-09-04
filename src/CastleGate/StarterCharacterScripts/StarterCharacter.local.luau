local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimManager = require(ReplicatedStorage.Modules.Client.AnimManager)
local LocalData = require(ReplicatedStorage.Modules.Client.LocalData)
local View = require(ReplicatedStorage.Modules.Client.View)

local Humanoid = script.Parent:WaitForChild("Humanoid") :: Humanoid
local Animator = Humanoid:WaitForChild("Animator") :: Animator

AnimManager.initLocalCharacter(Animator)
View.ViewModel.generate()

local con = RunService.RenderStepped:Connect(function(_dt)
	if
		Humanoid:GetMoveVelocity().Magnitude > 0
		and Humanoid:GetState() == Enum.HumanoidStateType.Running
	then
		LocalData.set("moving", true)
	else
		LocalData.set("moving", false)
	end
end)

script.Destroying:Connect(function()
	con:Disconnect()
end)
