local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local utilities = require(game.ReplicatedStorage.Shared.utilities)
local Gun = require(game.ReplicatedStorage.Shared.server_modules.Gun)
local WeaponsMarket = require(game.ReplicatedStorage.Shared.server_modules.WeaponsMarket)

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")

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

local function receiveServerInvoke(plr, protocol, data)
    if protocol == "getItem" then
        local plrGun = Gun.activeGuns[plr.Name]

        local money = WeaponsMarket:GetCashAccount(plr).Value
        local kills = WeaponsMarket:GetKillsAccount(plr).Value
        
        local config = Gun.gunPresets[data.name .. "_Preset"]
        
        if config then
            
            -- do we own the gun?
            local equippedWeapon = utilities.FindChildByNameWhichIsA(plr.Backpack, data.name, "Tool") or utilities.FindChildByNameWhichIsA(plr.Character, data.name, "Tool")
            
            if equippedWeapon then -- The weapon is equipped already
                equippedWeapon.Parent = plr.unequippedWeapons
                -- plrGun:Remove()

            elseif plr.unequippedWeapons:FindFirstChild(data.name) then -- The weapon is unequipped
                plr.unequippedWeapons:FindFirstChild(data.name).Parent = plr.Backpack

                -- For now we only allow one weapon to be equipped, which is intended to be changed later:
                -- plrGun.tool.Parent = plr.unequippedWeapons
                -- plrGun:Remove()

            else -- The weapon isn't owned yet
                -- make sure they have enough moneys and enough kills:
                if money >= config.cost
                and kills >= config.killsRequired
                then
                    -- charge and give weapon:
                    WeaponsMarket:SubtractCash(plr, config.cost)
                    local desiredWeapon = Gun.new(plr.Character, config)
                    desiredWeapon.tool.Parent = plr.unequippedWeapons
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
	
    local presetWithGivenProductId = Gun.presetProductIds[receiptInfo.ProductId]
	if presetWithGivenProductId then
		local desiredWeapon = Gun.new(player.Character, Gun.gunPresets[presetWithGivenProductId])
        desiredWeapon.tool.Parent = player.unequippedWeapons
		RemoteEvent:FireClient(player, "weaponProductPurchased", {weaponName = desiredWeapon.name})
	end

	return Enum.ProductPurchaseDecision.PurchaseGranted -- We can now safely close the purchase

end

RemoteEvent.OnServerEvent:Connect(receiveServerEvent)
RemoteFunction.OnServerInvoke = receiveServerInvoke

MarketplaceService.ProcessReceipt = onProcessReceipt

return 0