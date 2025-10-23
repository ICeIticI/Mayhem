local RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")
local ServerScriptService = game:GetService("ServerScriptService")

local DataManager = require(ServerScriptService.Server.server_modules.DataManager)
local utilities = require(game.ReplicatedStorage.Shared.utilities)

local WeaponsMarket = {}

local cashAccounts = {} -- will hold a name for each player or character that holds currency
local killsAccounts = {} -- stores kills for each shooter in the server
local gunsAccounts = {} -- Will hold the names of guns the player owns, if they're equipped, attachments they have (when I add them), etc

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

    killsAccounts[plr.UserId].Value = DataManager:GetData(plr, "Kills").Value or 0
    cashAccounts[plr.UserId].Value = DataManager:GetData(plr, "Cash").Value or 0
    gunsAccounts[plr.UserId] = DataManager:GetData(plr, "OwnedWeapons") or {}

end

function WeaponsMarket:AwardKill(plr, amount)
    killsAccounts[plr.UserId].Value += amount
    DataManager:SetData(plr, "Kills", {Value = killsAccounts[plr.UserId].Value})
end

function WeaponsMarket:AwardCash(plr, amount)
    cashAccounts[plr.UserId].Value += amount
    DataManager:SetData(plr, "Cash", {Value = cashAccounts[plr.UserId].Value})
end

function WeaponsMarket:SubtractCash(plr, amount)
    cashAccounts[plr.UserId].Value -= amount
    DataManager:SetData(plr, "Cash", {Value = cashAccounts[plr.UserId].Value})
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
    if not equipped then
        utilities.createInstance("StringValue", {Name = weaponName, Parent = plr.unequippedWeapons})
    else
        if plr.unequippedWeapons:FindFirstChild(weaponName) then
            plr.unequippedWeapons[weaponName]:Destroy()
        end
    end

    gunsAccounts[plr.UserId][weaponName] = {name = weaponName, equipped = equipped}
    DataManager:SetData(plr, "OwnedWeapons", gunsAccounts[plr.UserId])
end

return WeaponsMarket