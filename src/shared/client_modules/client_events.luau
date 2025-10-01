local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ClientVariables = require(game.ReplicatedStorage.Shared.client_modules.ClientVariables)
local shopManager = require(game.ReplicatedStorage.Shared.client_modules.shopManager)

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")

local displayDebounce
local totalDifference = 0

local function receiveClientEvent(protocol, data)
    if protocol == "changeUiDisplay" then
		if data.UIToChange == "Ammo_Display" then
			ClientVariables.Main_Display:WaitForChild("Ammo_Display").Text = "Mag: "..tostring(data.magCurrent).. "/" .. tostring(data.magCapacity)
		elseif data.UIToChange == "Kills_Display" then
			ClientVariables.Gun_GUI.Kills_Display.Text = "Kills: " .. tostring(data.killsAmount)
		elseif data.UIToChange == "Cash_Display" then
			ClientVariables.Gun_GUI.Cash_Display.Text = "Cash: " .. tostring(data.cashAmount)
			
			-- Behavior for the little cash-addition display that pops up whenever you earn money:
			totalDifference += data.difference

			if totalDifference >= 0 then
				ClientVariables.Gun_GUI.AddCash_Display.TextColor3 = Color3.fromRGB(0,255,0)
				ClientVariables.Gun_GUI.AddCash_Display.Text = "+" .. tostring(totalDifference) .. " Cash"
			else
				ClientVariables.Gun_GUI.AddCash_Display.TextColor3 = Color3.fromRGB(255, 0, 0)
				ClientVariables.Gun_GUI.AddCash_Display.Text = tostring(totalDifference) .. " Cash"
			end
			ClientVariables.Gun_GUI.AddCash_Display.Visible = true
			if displayDebounce then task.cancel(displayDebounce) end
			
			-- resets the 2 second wait for each new cash earned
			displayDebounce = task.delay(2, function()
				ClientVariables.Gun_GUI.AddCash_Display.Visible = false
				displayDebounce = nil
				totalDifference = 0
			end)
			
		end

	elseif protocol == "readyToInitButtons" then
		ClientVariables.readyToInitButtons = true
        
    elseif protocol == "iconChange" then
			UserInputService.MouseIcon = ClientVariables.reloadingCursor
    elseif protocol == "reload" then
        ClientVariables.Main_Display:WaitForChild("Ammo_Display").Text = "Mag: "..tostring(data.magCurrent).. "/" .. tostring(data.magCapacity)
	    ClientVariables.Main_Display:WaitForChild("Total_Display").Text = "Total: "..tostring(data.ammoCurrent)
		UserInputService.MouseIcon = ClientVariables.gunCursor

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
		ClientVariables.Main_Display.Ammo_Display.Text = "Mag: " .. tostring(data.magCurrent) .. "/" .. tostring(data.magCapacity)
		ClientVariables.Main_Display.Total_Display.Text = "Total: " .. data.ammoCurrent
		ClientVariables.Main_Display.Visible = data.isEquipped

	elseif protocol == "onUnequipped" then
		UserInputService.MouseIcon = ClientVariables.previousMouseIcon
		ClientVariables.Main_Display.Visible = data.isEquipped

	elseif protocol == "weaponProductPurchased" then
		shopManager.buttons[data.weaponName]:closePurchase()

	elseif protocol == "CountdownChange" then

		if data.winnerId then
			-- the game ended and we announce winner
			ClientVariables.Gun_GUI.Round_Timer.Text = Players:GetPlayerByUserId(data.winnerId).Name .. " has won the round!"
		else
			ClientVariables.Gun_GUI.Round_Timer.Text = data.gamePeriod .. " " .. data.Value
			ClientVariables.functions.updateLeaderboard(ClientVariables.functions.getSortedPlayers(data.playerScores))
		end
	-- elseif protocol == "sendPlayerScoresToClients" then
		
	elseif protocol == "onCurrentSprintStaminaChanged" then
		ClientVariables.Gun_GUI.staminaBar.currentStamina.Size = UDim2.fromScale(data.staminaFraction, ClientVariables.Gun_GUI.staminaBar.currentStamina.Size.Y.Scale)
	end
end


local function receiveClientInvoke(protocol, data)
	
end

RemoteFunction.OnClientInvoke = receiveClientInvoke
RemoteEvent.OnClientEvent:Connect(receiveClientEvent)

return 0