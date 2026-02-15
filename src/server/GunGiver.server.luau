local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local remotes = require(ReplicatedStorage.Packages.remotes)

local ShootEvent: RemoteEvent = remotes:getEventAsync("Shoot")

local GunClass = require(ServerScriptService.Classes.Gun)

local playerEquippedTool: {[Player]: Tool} = {}
local gunClassInstances: {[Tool]: typeof(GunClass.new())} = {}

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Wait()
    task.wait(1)
    local gun: Tool = ReplicatedStorage.Guns["AK-47"]:Clone()
    gun.Parent = player.Backpack

    local GunClass = GunClass.new(player, gun)
    gunClassInstances[gun] = GunClass

    gun.Equipped:Connect(function()
        playerEquippedTool[player] = gun
    end)

    gun.Unequipped:Connect(function()
        playerEquippedTool[player] = nil
    end)
end)

ShootEvent.OnServerEvent:Connect(function(player, camera_cframe)
    local tool = playerEquippedTool[player]
    local gun = gunClassInstances[tool]
    if not tool or not gun then return end

    gun:Shoot(camera_cframe)
    print("Shot!")
end)