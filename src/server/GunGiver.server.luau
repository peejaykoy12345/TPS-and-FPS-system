local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Wait()
    task.wait(1)
    local gun = ReplicatedStorage.Guns["AK-47"]:Clone()
    gun.Parent = player.Backpack
end)