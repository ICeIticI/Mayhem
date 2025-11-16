local RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleLoader

local WeaponsMarket = {}

local cashAccounts
local killsAccounts
local gunsAccounts

function WeaponsMarket.init()
    ModuleLoader = require(ReplicatedStorage.Shared.ModuleLoader)

    cashAccounts = {} -- will hold a name for each player or character that holds currency
    killsAccounts = {} -- stores kills for each shooter in the server
    gunsAccounts = {} -- Will hold the names of guns the player owns, if they're equipped, attachments they have (when I add them), etc
end


function WeaponsMarket:InitiateAccounts(plr)
    killsAccounts[plr.UserId] = Instance.new("NumberValue")
    killsAccounts[plr.UserId]:GetPropertyChangedSignal("Value"):Connect(function()
        RemoteEvent:FireClient(plr, "changeUiDisplay", {UIToChange = "Kills_Display", killsAmount = killsAccounts[plr.UserId].Value})
    end)

    local previousCashAmount = 0 -- for the new value, used to track how much has been added/removed from the old
    cashAccounts[plr.UserId] = Instance.new("IntValue")
    cashAccounts[plr.UserId]:GetPropertyChangedSignal("Value"):Connect(function()
        RemoteEvent:FireClient(plr, "changeUiDisplay", {UIToChange = "Cash_Display", cashAmount = cashAccounts[plr.UserId].Value, difference = cashAccounts[plr.UserId].Value - previousCashAmount})
        previousCashAmount = cashAccounts[plr.UserId].Value
    end)

    killsAccounts[plr.UserId].Value = ModuleLoader.DataManager:GetData(plr, "Kills").Value or 0
    cashAccounts[plr.UserId].Value = ModuleLoader.DataManager:GetData(plr, "Cash").Value or 0
    gunsAccounts[plr.UserId] = ModuleLoader.DataManager:GetData(plr, "OwnedWeapons")

    -- new players should start with default weapon, the glock
    if #ModuleLoader.utilities.makeTableFromDictionaryValues(gunsAccounts[plr.UserId]) <= 0 then
        gunsAccounts[plr.UserId] = {["Glock 17"] = {["name"] = "Glock 17", ["equipped"] = true}}
    end

    for _, gun in pairs(gunsAccounts[plr.UserId]) do
        ModuleLoader.utilities.createInstance("BoolValue", {Name = gun.name, Value = gun.equipped,   Parent = plr.ownedWeapons})
    end

    print(gunsAccounts)
end

function WeaponsMarket:AwardKill(plr, amount)
    killsAccounts[plr.UserId].Value += amount
    ModuleLoader.DataManager:SetData(plr, "Kills", {Value = killsAccounts[plr.UserId].Value})
end

function WeaponsMarket:AwardCash(plr, amount)
    cashAccounts[plr.UserId].Value += amount
    ModuleLoader.DataManager:SetData(plr, "Cash", {Value = cashAccounts[plr.UserId].Value})
end

function WeaponsMarket:SubtractCash(plr, amount)
    cashAccounts[plr.UserId].Value -= amount
    ModuleLoader.DataManager:SetData(plr, "Cash", {Value = cashAccounts[plr.UserId].Value})
end

function WeaponsMarket:GetKillsAccount(plr)
    return killsAccounts[plr.UserId]
end

function WeaponsMarket:GetCashAccount(plr)
    return cashAccounts[plr.UserId]
end

function WeaponsMarket:GetWeaponsAccount(plr)
    return gunsAccounts[plr.UserId]
end

function WeaponsMarket:GetEquippedWeaponName(plr)
    for _, weapon in pairs(gunsAccounts[plr.UserId]) do
        if weapon.equipped then
            return weapon.name
        end
    end
    return nil
end

function WeaponsMarket:AddWeaponToWeaponsAccount(plr, weaponName, equipped)
    gunsAccounts[plr.UserId][weaponName] = {name = weaponName, equipped = equipped}
    
    if not plr.ownedWeapons:FindFirstChild(gunsAccounts[plr.UserId][weaponName].name) then
        ModuleLoader.utilities.createInstance("BoolValue", {Name = gunsAccounts[plr.UserId][weaponName].name, Value = gunsAccounts[plr.UserId][weaponName].equipped, Parent = plr.ownedWeapons})
    end
    plr.ownedWeapons:FindFirstChild(gunsAccounts[plr.UserId][weaponName].name).Value = equipped
    
    print(gunsAccounts)
    ModuleLoader.DataManager:SetData(plr, "OwnedWeapons", gunsAccounts[plr.UserId])
end

return WeaponsMarket