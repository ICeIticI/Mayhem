local ReplicatedStorage = game:GetService("ReplicatedStorage")

local afkButton = {}

local ModuleLoader

function afkButton.init()
    ModuleLoader = require(ReplicatedStorage.Shared.ModuleLoader)

    local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

    local afkButtonInstance = ModuleLoader.ClientVariables.Gun_GUI:WaitForChild("AfkButton")
    afkButtonInstance.Activated:Connect(function()
        RemoteEvent:FireServer("afkSwap", {})
        task.wait(0.1)
        if ModuleLoader.ClientVariables.player.IsLoaded.Value then
            afkButtonInstance.Text = "AFK: OFF"
        else
            afkButtonInstance.Text = "AFK: ON"
        end
    end)
end

return afkButton