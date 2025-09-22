local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "RemoteEvent"
RemoteEvent.Parent = ReplicatedStorage

local RemoteFunction = Instance.new("RemoteFunction")
RemoteFunction.Name = "RemoteFunction"
RemoteFunction.Parent = ReplicatedStorage

require(game.ReplicatedStorage.Shared.server_modules.server_events) -- Activate remote event & function listeners on the server-side
local Gun = require(game.ReplicatedStorage.Shared.server_modules.Gun)
local Gun_m6dManager = require(game.ReplicatedStorage.Shared.server_modules.Gun_m6dManager)

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(char)
        Gun_m6dManager.run(player)
        local newGun = Gun.new(char, Gun.gunPresets.AK15_Preset)
        newGun.tool.Parent = player.Backpack

    end)
end

for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)