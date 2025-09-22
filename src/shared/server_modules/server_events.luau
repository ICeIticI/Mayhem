local ReplicatedStorage = game:GetService("ReplicatedStorage")

local utilities = require(game.ReplicatedStorage.Shared.utilities)
local Gun = require(game.ReplicatedStorage.Shared.server_modules.Gun)

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

local function receiveServerEvent(plr, protocol, data)
    
    
    local inputType = utilities.checkInput(data.input)
    if not inputType then return end -- only allow specific inputs

    local plrGun = Gun.activeGuns[plr.Name]
    if not plrGun.isEquipped then return end -- they should absolutely have their gun equipped to use it


    if protocol == "inputStarted" then

        if inputType == "ShootInputs" then
            if plrGun:Fire(data.ray) == true then
                 -- successfully shot
                 plrGun.shootDebounce.Value = true
                 task.wait(plrGun.fireRate)
                 plrGun.shootDebounce.Value = false
            end
        elseif inputType == "ReloadInputs" then
            plrGun:Reload()
        elseif inputType == "SprintInputs" then
            plrGun:Sprint()
        end

    elseif protocol == "inputEnded" then
        
        if inputType == "SprintInputs" then
            plrGun.isSprintPressed = false
        end

    end
end

RemoteEvent.OnServerEvent:Connect(receiveServerEvent)

return 0