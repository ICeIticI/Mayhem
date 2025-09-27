local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "RemoteEvent"
RemoteEvent.Parent = ReplicatedStorage

local RemoteFunction = Instance.new("RemoteFunction")
RemoteFunction.Name = "RemoteFunction"
RemoteFunction.Parent = ReplicatedStorage

local DataManager = require(game.ReplicatedStorage.Shared.server_modules.DataManager)
local WeaponsMarket = require(game.ReplicatedStorage.Shared.server_modules.WeaponsMarket)
require(game.ReplicatedStorage.Shared.server_modules.server_events) -- Activate remote event & function listeners on the server-side
local utilities = require(game.ReplicatedStorage.Shared.utilities)
local Gun = require(game.ReplicatedStorage.Shared.server_modules.Gun)
local Gun_m6dManager = require(game.ReplicatedStorage.Shared.server_modules.Gun_m6dManager)

local function onCharacterAdded(char)
    local player = Players:GetPlayerFromCharacter(char)

    Gun_m6dManager.run(player)

    for _, weaponData in pairs(WeaponsMarket:GetWeaponsAccount(player)) do
        local newGun = Gun.new(player.Character, Gun.gunPresets[weaponData.name .. "_Preset"])
        if weaponData.equipped then
            newGun.tool.Parent = player.Backpack
        else
            newGun.tool.Parent = player:WaitForChild("unequippedWeapons")
        end
    end
end

local function onPlayerAdded(player)
    -- Lock player's camera in first person:
    -- player.CameraMode = Enum.CameraMode.LockFirstPerson

    -- utilities.createInstance("Folder", {Name = "equippedWeapons", Parent = player})
    utilities.createInstance("Folder", {Name = "unequippedWeapons", Parent = player})

    DataManager:LoadData(player)
    WeaponsMarket:InitiateAccounts(player)

    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

local function onPlayerRemove(player)
    DataManager:SaveData(player)
end

for _, player in pairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemove)
game:BindToClose(function()
    for _, player in pairs(Players:GetPlayers()) do
        onPlayerRemove(player)
    end
end)

Players.CharacterAutoLoads = false