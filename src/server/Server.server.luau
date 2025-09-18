local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "RemoteEvent"
RemoteEvent.Parent = ReplicatedStorage

local RemoteFunction = Instance.new("RemoteFunction")
RemoteFunction.Name = "RemoteFunction"
RemoteFunction.Parent = ReplicatedStorage

require(game.ReplicatedStorage.Shared.server_modules.server_events) -- Activate remote event & function listeners on the server-side

local function onPlayerAdded(player)

end

for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)