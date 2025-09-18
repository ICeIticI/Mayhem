local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ClientVariables = require(game.ReplicatedStorage.Shared.client_modules.ClientVariables)

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")

local function receiveClientEvent(protocol, data)
    if protocol == "changeUiDisplay" then
        ClientVariables.Gun_GUI:WaitForChild("Ammo_Display").Text = "Mag: "..tostring(data.magCurrent).. tostring(data.magCapacity)
        
    elseif protocol == "iconChange" then
        if data.magCurrent == 0 then
		UserInputService.MouseIcon = ClientVariables.reloadingCursor
		wait(3.5)
		if data.isEquipped then
			UserInputService.MouseIcon = ClientVariables.gunCursor
		end
	elseif data.magCurrent > 0 then
		UserInputService.MouseIcon = ClientVariables.reloadingCursor
		wait(2.3)
		if data.isEquipped then
			UserInputService.MouseIcon = ClientVariables.gunCursor
		end
	end
    elseif protocol == "reload" then
        ClientVariables.Main_Display:WaitForChild("Ammo_Display").Text = "Mag: "..tostring(data.Mag_Current).. tostring(data.magCapacity)
	    ClientVariables.Main_Display:WaitForChild("Total_Display").Text = "Total: "..tostring(data.Ammo_Current)
	end
end

RemoteEvent.OnClientEvent:Connect(receiveClientEvent)