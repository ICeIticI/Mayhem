-- Services:

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local ModuleLoader

local server_events = {}

local RemoteEvent
local RemoteFunction

local function receiveServerEvent(plr, protocol, data)

    if protocol == "play" then
        if plr.IsLoaded.Value then return end -- character should not exist when the play button is pressed
        
        if game.PlaceId > 0 then -- we dont wanna force lock in studio for testing stuff
            plr.CameraMode = Enum.CameraMode.LockFirstPerson
        end

        print("Hey")
        -- make sure bullets cant collide with accessories
        ModuleLoader.utilities.filterCharacterObjects(plr.Character, {["Accessory"] = true})
        
        plr.Character.HumanoidRootPart.Anchored = false
        plr.IsLoaded.Value = true
        if ModuleLoader.games.getGamePeriod() == "Ongoing" then
            ModuleLoader.games.addPlayerToRound(plr)
        end
        ModuleLoader.games.spawnCharacter(plr.Character)
        return
    end


    local inputType = ModuleLoader.utilities.checkInput(data.input)
    if not inputType and protocol ~= "move_arms" then return end -- only allow specific inputs

    local plrGun = ModuleLoader.Gun.activeGuns[plr.Name]
    if (not plrGun or not plrGun.isEquipped or ModuleLoader.games.getGamePeriod() ~= "Ongoing") and protocol ~= "move_arms" then return end -- they should absolutely have their gun equipped to use it


    if protocol == "inputStarted" then

        print(plr.IsLoaded.Value)
        if not plr.IsLoaded.Value then return end

        if inputType == "ShootInputs" then
            plrGun:Fire(data.ray)
        elseif inputType == "ReloadInputs" then
            plrGun:Reload()
        elseif inputType == "SprintInputs" then
            plrGun:Sprint()
        end

    elseif protocol == "inputEnded" then
        
        if inputType == "SprintInputs" then
            plrGun.isSprintPressed = false
        end

    elseif protocol == "move_arms" then
        -- if plrGun.tool.Equipped then
            plr.Character:WaitForChild("Torso"):WaitForChild("Right Shoulder").C0 = data.RightC0
            plr.Character:WaitForChild("Torso"):WaitForChild("Left Shoulder").C0 = data.LeftC0
        -- end
    end
end

local function receiveServerInvoke(plr, protocol, data)
    if protocol == "getItem" then
        local plrGun = ModuleLoader.Gun.activeGuns[plr.Name]

        local money = ModuleLoader.WeaponsMarket:GetCashAccount(plr).Value
        local kills = ModuleLoader.WeaponsMarket:GetKillsAccount(plr).Value
        
        local config = ModuleLoader.Gun.gunPresets[data.name .. "_Preset"]
        
        if config then
            
            -- do we own the gun?
            local ownedWeapons = ModuleLoader.WeaponsMarket:GetWeaponsAccount(plr)
            -- Checks if the desired weapon is equipped:
            local equippedWeapon = ModuleLoader.utilities.FindChildByNameWhichIsA(plr.Backpack, data.name, "Tool") or ModuleLoader.utilities.FindChildByNameWhichIsA(plr.Character, data.name, "Tool")
            
            if ownedWeapons[data.name] and ownedWeapons[data.name].equipped then -- The weapon is equipped already
                
                if plrGun and plrGun.name then
                    ModuleLoader.WeaponsMarket:AddWeaponToWeaponsAccount(plr, plrGun.name, false)
                    plrGun:Remove()
                end

            elseif ownedWeapons[data.name] and not ownedWeapons[data.name].equipped then -- The weapon is unequipped

                -- For now we only allow one weapon to be equipped, which is intended to be changed later:
                if plrGun and plrGun.name then -- unequips current weapon:
                    ModuleLoader.WeaponsMarket:AddWeaponToWeaponsAccount(plr, plrGun.name, false)
                    plrGun:Remove()
                end
            
                plrGun = ModuleLoader.Gun.new(plr.Character, config)
                plrGun.tool.Parent = plr.Backpack
                ModuleLoader.WeaponsMarket:AddWeaponToWeaponsAccount(plr, plrGun.name, true)

            else -- The weapon isn't owned yet
                -- make sure they have enough moneys and enough kills:
                if money >= config.cost
                and kills >= config.killsRequired
                then
                    -- charge and give weapon:
                    ModuleLoader.WeaponsMarket:SubtractCash(plr, config.cost)
                    -- local desiredWeapon = Gun.new(plr.Character, config)
                    -- desiredWeapon.tool.Parent = plr.unequippedWeapons

                    ModuleLoader.WeaponsMarket:AddWeaponToWeaponsAccount(plr, config.name, false)

                    return "purchased"
                else
                    if kills < config.killsRequired then
                        return "needMoreKills", (config.killsRequired - kills)
                    elseif money < config.cost then
                        return "needMoreMoney", (config.cost - kills)
                    end
                    return false
                end
            end
            return true
        end
        return false

    end
end

local function onProcessReceipt(receiptInfo)
    local player = game:GetService("Players"):GetPlayerByUserId(receiptInfo.PlayerId) -- receiptInfo is a dictionary of stuff when the buy button is pressed, which includes the playerId of what player purchased.
	
	
	if not player then -- player left before we can do anything with this purchase
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- if the script makes it here, then the player is still in the game and we can do stuff in return because of their purchase
	
    local presetWithGivenProductId = ModuleLoader.Gun.presetProductIds[receiptInfo.ProductId]
	if presetWithGivenProductId then
		-- local desiredWeapon = Gun.new(player.Character, Gun.gunPresets[presetWithGivenProductId])
        -- desiredWeapon.tool.Parent = player.unequippedWeapons

        local desiredWeaponName = ModuleLoader.Gun.gunPresets[presetWithGivenProductId].name
        ModuleLoader.WeaponsMarket:AddWeaponToWeaponsAccount(player, desiredWeaponName, false)
		RemoteEvent:FireClient(player, "weaponProductPurchased", {weaponName = desiredWeaponName})
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted -- We can now safely close the purchase

end

function server_events.init()
    ModuleLoader = require(ReplicatedStorage.Shared.ModuleLoader)

    RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
    RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")


    RemoteEvent.OnServerEvent:Connect(receiveServerEvent)
    RemoteFunction.OnServerInvoke = receiveServerInvoke
    
    MarketplaceService.ProcessReceipt = onProcessReceipt
end


return server_events