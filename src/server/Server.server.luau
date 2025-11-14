local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")

local RemoteEvent = Instance.new("RemoteEvent")
RemoteEvent.Name = "RemoteEvent"
RemoteEvent.Parent = ReplicatedStorage

local RemoteFunction = Instance.new("RemoteFunction")
RemoteFunction.Name = "RemoteFunction"
RemoteFunction.Parent = ReplicatedStorage

local ModuleLoader = require(ReplicatedStorage.Shared.ModuleLoader)
ModuleLoader.init()

-- local Seasonal = require(game.ReplicatedStorage.Shared.Seasonal)
-- Seasonal.init()

ModuleLoader.AnimationService_Server.init()
ModuleLoader.refillAmmo.init()
ModuleLoader.Gun.init()
ModuleLoader.DataManager.init()
ModuleLoader.WeaponsMarket.init()
ModuleLoader.games.init()
ModuleLoader.server_events.init()

local function onCharacterAdded(char)

    char:WaitForChild("Humanoid").JumpHeight = 5
    -- char:WaitForChild("HumanoidRootPart").Anchored = true
    char.HumanoidRootPart.CFrame = game:GetService("Workspace").Pre_Spawn.center.CFrame
    
    local player = Players:GetPlayerFromCharacter(char)
    player.CameraMode = Enum.CameraMode.Classic
    -- player.IsLoaded.Value = false

    ModuleLoader.Gun_m6dManager.init(player)

    for _, weaponData in pairs(ModuleLoader.WeaponsMarket:GetWeaponsAccount(player)) do
        if weaponData.equipped then
            local newGun = ModuleLoader.Gun.new(player.Character, ModuleLoader.Gun.gunPresets[weaponData.name .. "_Preset"])
            newGun.tool.Parent = player.Backpack
        else
            ModuleLoader.utilities.createInstance("StringValue", {Name = weaponData.name, Parent = player.unequippedWeapons})
        end
    end

    local diedConnect
    diedConnect = char.Humanoid.Died:Connect(function()
        -- player.IsLoaded.Value = false
        diedConnect:Disconnect()
    end)

    RemoteEvent:FireClient(player, "readyToInitButtons")
end

local function onPlayerAdded(player)
    
    -- Halloween 2025 badge:
    local currentMonth = tonumber(os.date("%m"))
    local currentYear = tonumber(os.date("%Y"))
    if currentMonth == 10 and currentYear == 2025 then -- 10/2025 - oct 2025
        if not BadgeService:UserHasBadgeAsync(player.UserId, 2134625073538853) then
            BadgeService:AwardBadge(player.UserId, 2134625073538853)
        end
    end

    -- utilities.createInstance("Folder", {Name = "equippedWeapons", Parent = player})
    ModuleLoader.utilities.createInstance("Folder", {Name = "unequippedWeapons", Parent = player})
    ModuleLoader.utilities.createInstance("BoolValue", {Name = "IsLoaded", Value = false, Parent = player})

    ModuleLoader.DataManager:LoadData(player)
    ModuleLoader.WeaponsMarket:InitiateAccounts(player)

    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    
end

local function onPlayerRemove(player)
    ModuleLoader.DataManager:SaveData(player)
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
    pcall(function()
        ModuleLoader.games.run()
    end)
end