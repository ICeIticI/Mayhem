local Players = game:GetService("Players")
local RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")

local DataManager = require(game.ReplicatedStorage.Shared.server_modules.DataManager)

local WeaponsMarket = {}

local cashAccounts = {} -- will hold a name for each player or character that holds currency
local killsAccounts = {} -- stores kills for each shooter in the server

function WeaponsMarket:InitiateAccounts(plr)
    killsAccounts[plr.UserId] = Instance.new("NumberValue")
    killsAccounts[plr.UserId]:GetPropertyChangedSignal("Value"):Connect(function()
        RemoteEvent:FireClient(plr, "changeUiDisplay", {UIToChange = "Kills_Display", killsAmount = killsAccounts[plr.UserId].Value})
    end)

    cashAccounts[plr.UserId] = Instance.new("IntValue")
    cashAccounts[plr.UserId]:GetPropertyChangedSignal("Value"):Connect(function()
        RemoteEvent:FireClient(plr, "changeUiDisplay", {UIToChange = "Cash_Display", cashAmount = cashAccounts[plr.UserId].Value})
    end)

    killsAccounts[plr.UserId].Value = DataManager:GetData(plr, "Kills")
    cashAccounts[plr.UserId].Value = DataManager:GetData(plr, "Cash")

    print(killsAccounts[plr.UserId].Value, cashAccounts[plr.UserId].Value)
end

function WeaponsMarket:AwardKill(plr, amount)
    killsAccounts[plr.UserId].Value += amount
end

function WeaponsMarket:AwardCash(plr, amount)
    cashAccounts[plr.UserId].Value += amount
end

function WeaponsMarket:SubtractCash(plr, amount)
    cashAccounts[plr.UserId].Value -= amount
end

function WeaponsMarket:GetKillsAccount(plr)
    return killsAccounts[plr.UserId]
end

function WeaponsMarket:GetCashAccount(plr)
    return cashAccounts[plr.UserId]
end

return WeaponsMarket