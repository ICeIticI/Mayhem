local WeaponsMarket = {}

local cashAccounts = {} -- will hold a name for each player or character that holds currency
local killsAccounts = {} -- stores kills for each shooter in the server

function WeaponsMarket:AwardKill(name, amount)
    killsAccounts[name] += amount
end

function WeaponsMarket:AwardCash(name, amount)
    cashAccounts[name] += amount
end

return WeaponsMarket