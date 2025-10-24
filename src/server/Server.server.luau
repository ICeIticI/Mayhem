local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "RemoteEvent"
RemoteEvent.Parent = ReplicatedStorage

local RemoteFunction = Instance.new("RemoteFunction")
RemoteFunction.Name = "RemoteFunction"
RemoteFunction.Parent = ReplicatedStorage

local ModuleLoader = require(ReplicatedStorage.Shared.ModuleLoader)


-- local Seasonal = require(game.ReplicatedStorage.Shared.Seasonal)
-- Seasonal.init()
local AnimationService_Server = require(ServerScriptService.Server.server_modules.AnimationService_Server)
AnimationService_Server.init()

local refillAmmo = require(ServerScriptService.Server.server_modules.Modules.refillAmmo)
refillAmmo.init()

local DataManager = require(ServerScriptService.Server.server_modules.DataManager)
local WeaponsMarket = require(ServerScriptService.Server.server_modules.WeaponsMarket)
require(ServerScriptService.Server.server_modules.server_events) -- Activate remote event & function listeners on the server-side
local utilities = require(ReplicatedStorage.Shared.utilities)
local Gun = require(ServerScriptService.Server.server_modules.Gun)
local Gun_m6dManager = require(ServerScriptService.Server.server_modules.Gun_m6dManager)
local games = require(ServerScriptService.Server.server_modules.games)

local function onCharacterAdded(char)

    char:WaitForChild("Humanoid").JumpHeight = 5
    char:WaitForChild("HumanoidRootPart").Anchored = true
    char.HumanoidRootPart.CFrame = game:GetService("Workspace").Pre_Spawn.PrimaryPart.CFrame
    
    local player = Players:GetPlayerFromCharacter(char)
    player.CameraMode = Enum.CameraMode.Classic
    player.IsLoaded.Value = false

    Gun_m6dManager.run(player)    

    for _, weaponData in pairs(WeaponsMarket:GetWeaponsAccount(player)) do
        if weaponData.equipped then
            local newGun = Gun.new(player.Character, Gun.gunPresets[weaponData.name .. "_Preset"])
            newGun.tool.Parent = player.Backpack
        else
            utilities.createInstance("StringValue", {Name = weaponData.name, Parent = player.unequippedWeapons})
        end
    end
    RemoteEvent:FireClient(player, "readyToInitButtons")
end

local function onPlayerAdded(player)
    -- Lock player's camera in first person:

    -- utilities.createInstance("Folder", {Name = "equippedWeapons", Parent = player})
    utilities.createInstance("Folder", {Name = "unequippedWeapons", Parent = player})
    utilities.createInstance("BoolValue", {Name = "IsLoaded", Value = false, Parent = player})

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

while true do
    games.run()
end