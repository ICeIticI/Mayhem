local DataStoreService

local DataManager = {}


local DataStores = {

}
local playerData -- wanna keep this local because data is super sensitive and confidential info so it should only be known to THIS script

function DataManager.init()
    if game.PlaceId ~= 0 then
        DataStoreService = game:GetService("DataStoreService")
    
        DataStores = {
            ["Kills"] = DataStoreService:GetDataStore("Kills_Store"),
            ["Cash"] = DataStoreService:GetDataStore("Cash_Store"),
            ["OwnedWeapons"] = DataStoreService:GetDataStore("OwnedWeapons_Store")
        }
    end
    
    playerData = {} -- table storing all data for each player in the server retrieved from datastores
end


function DataManager:LoadData(plr) -- Loads player-saved data into the server
    if plr.UserId < 1 then return end

    playerData[plr.UserId] = {}

    for ds_name, datastore in pairs(DataStores) do
        local datastoreKEY = "id_" .. plr.UserId .. "_" .. ds_name

        local success, result = pcall(function()
            return datastore:GetAsync(datastoreKEY)
        end)

        if success then
            playerData[plr.UserId][datastoreKEY] = result or {}
        else
            warn(result)
        end
    end
end

function DataManager:GetData(plr, ds_name) -- Retrieves a specific type of data for the player
    if plr.UserId < 1 then return {} end

    local datastoreKEY = "id_" .. plr.UserId .. "_" .. ds_name
    return playerData[plr.UserId][datastoreKEY] or {}
end

function DataManager:SetData(plr, ds_name, value) -- Puts the data to the data table that stores it. This allows the data to actually save to DataStores when we need to call :SaveData()
    if plr.UserId < 1 then return end

	local datastoreKEY = "id_" .. plr.UserId .. "_" .. ds_name

	-- playerData[userId] = playerData[userId] or {}
	playerData[plr.UserId][datastoreKEY] = value

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

return DataManager