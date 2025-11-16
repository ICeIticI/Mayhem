local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ModuleLoader

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")

local client_events = {}

local displayDebounce
local totalDifference -- tracks how much cash the player has earned in a small period of time. It stacks what the +{cashAmount} says.

local function receiveClientEvent(protocol, data)
    if protocol == "changeUiDisplay" then
		if data.UIToChange == "Ammo_Display" then
			ModuleLoader.ClientVariables.Main_Display:WaitForChild("Ammo_Display").Text = "Mag: "..tostring(data.magCurrent).. "/" .. tostring(data.magCapacity)
		elseif data.UIToChange == "Kills_Display" then
			ModuleLoader.ClientVariables.Gun_GUI.Kills_Display.Text = "Kills: " .. tostring(data.killsAmount)
		elseif data.UIToChange == "Cash_Display" then
			ModuleLoader.ClientVariables.Gun_GUI.Cash_Display.Text = "Cash: " .. tostring(data.cashAmount)
			
			-- Behavior for the little cash-addition display that pops up whenever you earn money:
			totalDifference += data.difference

			if totalDifference >= 0 then
				ModuleLoader.ClientVariables.Gun_GUI.AddCash_Display.TextColor3 = Color3.fromRGB(0,255,0)
				ModuleLoader.ClientVariables.Gun_GUI.AddCash_Display.Text = "+" .. tostring(totalDifference) .. " Cash"
			else
				ModuleLoader.ClientVariables.Gun_GUI.AddCash_Display.TextColor3 = Color3.fromRGB(255, 0, 0)
				ModuleLoader.ClientVariables.Gun_GUI.AddCash_Display.Text = tostring(totalDifference) .. " Cash"
			end
			ModuleLoader.ClientVariables.Gun_GUI.AddCash_Display.Visible = true
			if displayDebounce then task.cancel(displayDebounce) end
			
			-- resets the 2 second wait for each new cash earned
			displayDebounce = task.delay(2, function()
				ModuleLoader.ClientVariables.Gun_GUI.AddCash_Display.Visible = false
				displayDebounce = nil
				totalDifference = 0
			end)
			
		end

	elseif protocol == "readyToInitButtons" then
		ModuleLoader.ClientVariables.readyToInitButtons = true
        
    elseif protocol == "iconChange" then
			UserInputService.MouseIcon = ModuleLoader.ClientVariables.reloadingCursor
    elseif protocol == "reload" then
        ModuleLoader.ClientVariables.Main_Display:WaitForChild("Ammo_Display").Text = "Mag: "..tostring(data.magCurrent).. "/" .. tostring(data.magCapacity)
	    ModuleLoader.ClientVariables.Main_Display:WaitForChild("Total_Display").Text = "Total: "..tostring(data.ammoCurrent)
		UserInputService.MouseIcon = ModuleLoader.ClientVariables.gunCursor

	elseif protocol == "characterHit" then
		data.hitSound:Play()

	-- This event gets called from a script in studio for restocking ammo:
	elseif protocol == "lootBox" then
		ModuleLoader.ClientVariables.Main_Display:WaitForChild("Total_Display").Text = "Total: "..tostring(data.ammoCurrent)

	elseif protocol == "onEquipped" then
		UserInputService.MouseIcon = ModuleLoader.ClientVariables.gunCursor
		for _, v in pairs(ModuleLoader.ClientVariables.player.Character:GetChildren()) do
			ModuleLoader.ClientVariables.functions.antiTrans(v)
		end
		ModuleLoader.ClientVariables.Main_Display.Ammo_Display.Text = "Mag: " .. tostring(data.magCurrent) .. "/" .. tostring(data.magCapacity)
		ModuleLoader.ClientVariables.Main_Display.Total_Display.Text = "Total: " .. data.ammoCurrent
		ModuleLoader.ClientVariables.Main_Display.Visible = data.isEquipped

	elseif protocol == "onUnequipped" then
		UserInputService.MouseIcon = ModuleLoader.ClientVariables.previousMouseIcon
		ModuleLoader.ClientVariables.Main_Display.Visible = data.isEquipped

	elseif protocol == "weaponProductPurchased" then
		ModuleLoader.shopManager.buttons[data.weaponName]:closePurchase()

	elseif protocol == "CountdownChange" then

		if data.winnerIdsTable and #data.winnerIdsTable > 0 then

			-- the game ended and we announce winner
			if #data.winnerIdsTable > 1 then
				-- multiple winners. Announce team name
				ModuleLoader.ClientVariables.Gun_GUI.Round_Timer.Text = Players:GetPlayerByUserId(data.winnerIdsTable[1]).Team.Name .. " Team has won the round!" -- all indexes should have the same team, so no matter the index we pull.
			else
				-- One winner. Announce player name
				ModuleLoader.ClientVariables.Gun_GUI.Round_Timer.Text = Players:GetPlayerByUserId(data.winnerIdsTable	[1]).Name .. " has won the round!"
			end
		else
			ModuleLoader.ClientVariables.Gun_GUI.Round_Timer.Text = data.gamePeriod .. " " .. data.Value
			ModuleLoader.ClientVariables.functions.updateLeaderboard(ModuleLoader.ClientVariables.functions.getSortedPlayers(data.playerScores))
		end
	-- elseif protocol == "sendPlayerScoresToClients" then
		
	elseif protocol == "onCurrentSprintStaminaChanged" then
		ModuleLoader.ClientVariables.Gun_GUI.staminaBar.currentStamina.Size = UDim2.fromScale(data.staminaFraction, ModuleLoader.ClientVariables.Gun_GUI.staminaBar.currentStamina.Size.Y.Scale)

	elseif protocol == "setupAnimations" then
		ModuleLoader.ClientVariables.tracks = ModuleLoader.utilities.makeAnimationTracksFromIds(data.animationIds, ModuleLoader.ClientVariables.player.Character:WaitForChild("Humanoid"):WaitForChild("Animator"))

	elseif protocol == "playAnimation" then
		ModuleLoader.ClientVariables.tracks[data.animName]:Play()

	elseif protocol == "stopAnimation" then
		ModuleLoader.ClientVariables.tracks[data.animName]:Stop()


	elseif protocol == "revealJuggernaut" then
		ModuleLoader.ClientVariables.revealGUI.Parent = Players:FindFirstChild(data.chosenBeastName).Character:WaitForChild("Head")

	elseif protocol == "updateVotes" then
		for _, v in pairs(ModuleLoader.ClientVariables.votingStations:GetDescendants()) do
			if not v:IsA("Frame") then continue end
			-- deal with the children of the frame:

			print("He")
			local specificOption = v:FindFirstAncestorWhichIsA("Model"):GetAttribute("optionName")
			local specificStationId = v:FindFirstAncestorWhichIsA("Model"):GetAttribute("id")

			v.optionName.Text = specificOption
			v.voteCount.Text = #data.votingOptions[specificStationId]
		end

	elseif protocol == "hideSideUI" then
		print("cj")
		ModuleLoader.ClientVariables.Gun_GUI.ShopButton.Visible = false
		ModuleLoader.ClientVariables.Gun_GUI.shop_frame.Visible = false
		ModuleLoader.ClientVariables.Gun_GUI.Cash_Display.Visible = false
		ModuleLoader.ClientVariables.Gun_GUI.Kills_Display.Visible = false

	end
end


local function receiveClientInvoke(protocol, data)
	
end

function client_events.init()
	ModuleLoader = require(ReplicatedStorage.Shared.ModuleLoader)

	totalDifference = 0

	RemoteFunction.OnClientInvoke = receiveClientInvoke
	RemoteEvent.OnClientEvent:Connect(receiveClientEvent)
end


return client_events