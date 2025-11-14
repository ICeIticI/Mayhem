local refillAmmo = {}

function refillAmmo.init()
    local Workspace = game:GetService("Workspace")
    local ServerScriptService = game:GetService("ServerScriptService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    
    local ammoBoxes = Workspace:WaitForChild("ammoBoxes")
    
    for _, ammoBox in pairs(ammoBoxes:GetChildren()) do
        
        local box = ammoBox.Box
        local lid = ammoBox.Lid
        local prompt = box.reloadProx
        local lootSFX = box.lootSFX
        
        local ammoRestockGUI = ReplicatedStorage:WaitForChild("ammoRestockGUI"):Clone()
        ammoRestockGUI.Parent = lid

        local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
        local Gun = require(ServerScriptService.Server.server_modules.Gun)
        
        prompt.Triggered:Connect(function(player)
            local plrGun = Gun.activeGuns[player.Name]
            
            plrGun.ammoCurrent = plrGun.ammoMax
            RemoteEvent:FireClient(player, "lootBox", {ammoCurrent = plrGun.ammoCurrent})
            lootSFX:Play()
        end)
    end
end

return refillAmmo