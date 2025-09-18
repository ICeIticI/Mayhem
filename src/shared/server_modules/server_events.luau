local ReplicatedStorage = game:GetService("ReplicatedStorage")

local utilities = require(game.ReplicatedStorage.Shared.utilities)
local Gun = require(game.ReplicatedStorage.Shared.server_modules.Gun)

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

local function receiveServerEvent(plr, protocol, data)
    if protocol == "input" then
        local inputType = utilities.checkInput(data.input)
        if not inputType then return end

        if inputType == "ReloadInputs" then
            Gun.activeGuns[plr.Name]:Reload()
        end
    end
end

RemoteEvent.OnServerEvent:Connect(receiveServerEvent)

return 0