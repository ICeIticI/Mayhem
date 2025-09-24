local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ClientVariables = require(game.ReplicatedStorage.Shared.client_modules.ClientVariables)
local shopManager = require(game.ReplicatedStorage.Shared.client_modules.shopManager)

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")

local function receiveClientEvent(protocol, data)
    if protocol == "changeUiDisplay" then
		if data.UIToChange == "Ammo_Display" then
			ClientVariables.Main_Display:WaitForChild("Ammo_Display").Text = "Mag: "..tostring(data.magCurrent).. "/" .. tostring(data.magCapacity)
		elseif data.UIToChange == "Kills_Display" then
			ClientVariables.Gun_GUI.Kills_Display.Text = "Kills: " .. tostring(data.killsAmount)
		elseif data.UIToChange == "Cash_Display" then
			ClientVariables.Gun_GUI.Cash_Display.Text = "Cash: " .. tostring(data.cashAmount)
		end
        
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
        ClientVariables.Main_Display:WaitForChild("Ammo_Display").Text = "Mag: "..tostring(data.magCurrent).. "/" .. tostring(data.magCapacity)
	    ClientVariables.Main_Display:WaitForChild("Total_Display").Text = "Total: "..tostring(data.ammoCurrent)

	elseif protocol == "characterHit" then
		data.hitSound:Play()

	-- This event gets called from a script in studio for restocking ammo:
	elseif protocol == "lootBox" then
		ClientVariables.Main_Display:WaitForChild("Total_Display").Text = "Total: "..tostring(data.ammoCurrent)

	elseif protocol == "onEquipped" then
		UserInputService.MouseIcon = ClientVariables.gunCursor
		for _, v in pairs(ClientVariables.player.Character:GetChildren()) do
			ClientVariables.functions.antiTrans(v)
		end
		ClientVariables.Main_Display.Visible = data.isEquipped

	elseif protocol == "onUnequipped" then
		UserInputService.MouseIcon = ClientVariables.previousMouseIcon
		ClientVariables.Main_Display.Visible = data.isEquipped

	elseif protocol == "weaponProductPurchased" then
		shopManager.buttons[data.weaponName]:closePurchase()
	end
end


local function receiveClientInvoke(protocol, data)
	
end

RemoteFunction.OnClientInvoke = receiveClientInvoke
RemoteEvent.OnClientEvent:Connect(receiveClientEvent)

return 0