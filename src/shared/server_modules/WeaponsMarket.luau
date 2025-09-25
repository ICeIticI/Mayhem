local RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")

local DataManager = require(game.ReplicatedStorage.Shared.server_modules.DataManager)

local WeaponsMarket = {}

local cashAccounts = {} -- will hold a name for each player or character that holds currency
local killsAccounts = {} -- stores kills for each shooter in the server
local gunsAccounts = {} -- Will hold the names of guns the player owns, if they're equipped, attachments they have (when I add them), etc

function WeaponsMarket:InitiateAccounts(plr)
    killsAccounts[plr.UserId] = Instance.new("NumberValue")
    killsAccounts[plr.UserId]:GetPropertyChangedSignal("Value"):Connect(function()
        RemoteEvent:FireClient(plr, "changeUiDisplay", {UIToChange = "Kills_Display", killsAmount = killsAccounts[plr.UserId].Value})
    end)

    cashAccounts[plr.UserId] = Instance.new("IntValue")
    cashAccounts[plr.UserId]:GetPropertyChangedSignal("Value"):Connect(function()
        RemoteEvent:FireClient(plr, "changeUiDisplay", {UIToChange = "Cash_Display", cashAmount = cashAccounts[plr.UserId].Value})
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

function WeaponsMarket:AddWeaponToWeaponsAccount(plr, weapon, equipped)
    if not equipped then
        weapon.tool.Parent = plr.unequippedWeapons
    end

    gunsAccounts[plr.UserId][weapon.name] = {name = weapon.name, equipped = equipped}
    DataManager:SetData(plr, "OwnedWeapons", gunsAccounts[plr.UserId])
    print(gunsAccounts[plr.UserId])
end

return WeaponsMarket