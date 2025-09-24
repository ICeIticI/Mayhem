local DataStoreService

local DataManager = {}

local DataStores = {

}

if game.PlaceId ~= 0 then
    DataStoreService = game:GetService("DataStoreService")

    DataStores = {
        ["Kills"] = DataStoreService:GetDataStore("Kills_Store"),
        ["Cash"] = DataStoreService:GetDataStore("Cash_Store")
    }
end

local playerData = {} -- table storing all data for each player in the server retrieved from datastores

function DataManager:LoadData(plr) -- Loads player-saved data into the server
    if plr.UserId < 1 then return end

    playerData[plr.UserId] = {}

    for ds_name, datastore in pairs(DataStores) do
        local datastoreKEY = "id_" .. plr.UserId .. "_" .. ds_name

        local success, result = pcall(function()
            return datastore:GetAsync(datastoreKEY)
        end)

        if success then
            playerData[plr.UserId][datastoreKEY] = result or 0
        else
            warn(result)
        end
    end
end

function DataManager:SaveData(plr) -- Saves player's current data in the server to datastores
    if plr.UserId < 1 then return end
    
    for ds_name, datastore in pairs(DataStores) do
        local datastoreKEY = "id_" .. plr.UserId .. "_" .. ds_name

        local success, result = pcall(function()
            return datastore:SetAsync(datastoreKEY, playerData[plr.UserId][datastoreKEY])
        end)

        if not success then
            print(playerData, playerData[plr.UserId], playerData[plr.UserId][datastoreKEY], datastoreKEY)
            warn(result)
        end
    end
end

function DataManager:GetData(plr, ds_name) -- Retrieves a specific type of data for the player
    if plr.UserId < 1 then return 0 end

    local datastoreKEY = "id_" .. plr.UserId .. "_" .. ds_name
    return playerData[plr.UserId][datastoreKEY] or 0
end

return DataManager