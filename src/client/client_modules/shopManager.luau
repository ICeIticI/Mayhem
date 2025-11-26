local MarketplaceService = game:GetService("MarketplaceService")

local ModuleLoader

local RemoteFunction = game.ReplicatedStorage:WaitForChild("RemoteFunction")

local shopManager = {}

local function trackEquip(plr, valueName) -- for the UI. Will track when a weapon gets equipped or unequipped by the value name
    local value = plr.ownedWeapons:FindFirstChild(valueName)

    if not value then return warn("no value with the given name " .. valueName) end

    print("tracking value: " .. value.Name)
    value:GetPropertyChangedSignal("Value"):Connect(function()
        shopManager.buttons[valueName]:SwapParents(value.Value)
    end)
end

local function getPriceOfProductInRobux(productId)
    local success, productInfo = pcall(function()
        return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
    end)

    if success and productInfo then
        return productInfo.PriceInRobux
    else
        return 0
    end
end

local function initiatePurchaseButton(itemToDisplay, isLocked)
    local button = {}
    button.productId = tonumber(itemToDisplay:GetAttribute("ProductId"))

    button.instance = shopManager.PurchaseButton_Template:Clone()
    button.instance.lockImage.Visible = isLocked
    button.instance.Name = "PurchaseButton"
    button.instance.Visible = true

    button.item = itemToDisplay
    button.item:PivotTo(CFrame.new(0, 3, 5))

    -- Methods:
    
    function button:MissingRequiredToPurchase(message, amountMissingForPurchase) -- runs if the player is missing kills or cash in order to purchase the weapon
        -- they should be prompted to purchase this gun with robux or purchase more cash
            
        if message == "needMoreKills" then
            shopManager.equipPurchase_screen.TextLabel.Text = "You need " ..tostring(amountMissingForPurchase) .. " more Kills to be able to purchase the '" ..tostring(self.item.name) .."' gun. Would you like to purchase this gun with Robux?"
        elseif message == "needMoreMoney" then
            shopManager.equipPurchase_screen.TextLabel.Text = "You need " ..tostring(amountMissingForPurchase) .. " more Cash to purchase the '" ..tostring(self.item.name) .."' gun. Would you like to purchase more Cash?"
        end

        return 
    end

    function button:SwapParents(bool) -- true means equipped, false means unequipped
        -- changes button parent to either equipped selection or unequipped:
        if bool then
            -- change to equipped section:
            self.instance.Size = shopManager.UI_EQUIPPED_SIZE
            self.instance.Parent = shopManager.equippedFrame
        else
            -- change to unequipped section:
            self.instance.Size = shopManager.UI_SELECTION_SIZE
            self.instance.Parent = shopManager.selectionFrame
        end
        return
    end

    function button:closePurchase() -- will notify the player via the equipPurchase_screen that their purchase was complete
        self.instance.lockImage.Visible = false
        shopManager.equipPurchase_screen.Yes.Visible = false
        shopManager.equipPurchase_screen.No.Visible = false

        shopManager.equipPurchase_screen.Ok.Visible = true
        shopManager.equipPurchase_screen.purchaseWithRobuxFrame.Visible = false
        shopManager.equipPurchase_screen.TextLabel.Text = "Thank you! You now own the " ..tostring(self.item.name) .. "!"
        shopManager.promptToPurchaseWithRobux = false
    end

    -- Connections:

    button.instance.Activated:Connect(function()

        if ModuleLoader.ClientVariables.player.ownedWeapons:FindFirstChild(button.item.Name) then
            -- weapon is currently unequipped
            shopManager.equipPurchase_screen.purchaseWithRobuxFrame.Visible = false
            shopManager.equipPurchase_screen.TextLabel.Text = "Equip?"
        elseif ModuleLoader.ClientVariables.gunTool and ModuleLoader.ClientVariables.gunTool.Name == button.item.Name and (ModuleLoader.utilities.FindChildByNameWhichIsA(ModuleLoader.ClientVariables.player.Backpack, ModuleLoader.ClientVariables.gunTool.Name, "Tool") or ModuleLoader.utilities.FindChildByNameWhichIsA(ModuleLoader.ClientVariables.player.Character, ModuleLoader.ClientVariables.gunTool.Name, "Tool")) then
            -- weapon is already equipped
            shopManager.equipPurchase_screen.purchaseWithRobuxFrame.Visible = false
            shopManager.equipPurchase_screen.TextLabel.Text = "Unequip?"
        else
            -- Weapon isn't owned
            shopManager.equipPurchase_screen.purchaseWithRobuxFrame.Visible = true
            shopManager.equipPurchase_screen.purchaseWithRobuxFrame.PurchaseWithRobuxButton:WaitForChild("Amount").Text = getPriceOfProductInRobux(button.productId)
            if tonumber(shopManager.equipPurchase_screen.purchaseWithRobuxFrame.PurchaseWithRobuxButton.Amount.Text) <= 0 then shopManager.equipPurchase_screen.purchaseWithRobuxFrame.Visible = false end

            shopManager.equipPurchase_screen.TextLabel.Text = "Would you like to purchase the " .. button.item.Name .. " for " .. button.item:GetAttribute("Cost") .." cash?"
        end
        
        shopManager.promptToPurchaseWithRobux = false
        shopManager.explanationOfItem.TextLabel.Text = itemToDisplay:GetAttribute("Description")
        shopManager.currentlySelectedButton = button
        shopManager.equipPurchase_screen.Visible = true
    end)

    button.item.Parent = button.instance.ViewportFrame
    
    -- if the gun is already equipped, put it in equipped section. If not, then unequipped section:
    local gunToolBool = ModuleLoader.ClientVariables.player.ownedWeapons:FindFirstChild(button.item.Name)
    if gunToolBool then
        trackEquip(ModuleLoader.ClientVariables.player, button.item.Name)
    end
    if gunToolBool and gunToolBool.Value then
        button:SwapParents(true)
    else
        button:SwapParents(false)
    end
    
    return button
end

function shopManager.init()
    ModuleLoader = require(game:GetService("ReplicatedStorage").Shared.ModuleLoader)

    shopManager.ScreenGui = ModuleLoader.ClientVariables.player.PlayerGui.ScreenGui
    shopManager.shop_frame = shopManager.ScreenGui.shop_frame -- frame containing the shop and equipped
    shopManager.equipPurchase_screen = shopManager.shop_frame.equipPurchase_screen -- the screen that pops up every time we want to buy/equip/unequip a weapon, confirming if we do or not
    shopManager.selectionFrame = shopManager.shop_frame.selection.selectionFrame -- frame containing all the UIs of avaliable items for purchase
    shopManager.equippedFrame = shopManager.shop_frame.equipped
    shopManager.explanationOfItem = shopManager.shop_frame.selection.explanationOfItem -- text that describes the item selected
    shopManager.ShopButton = shopManager.ScreenGui.ShopButton -- the button that shows/hides the shop_frame

    shopManager.shop_frame.Visible = false


    shopManager.buttons = {} -- table that will be filled with each button that will allow the player to purchase/equip/unequip a weapon.

    shopManager.UI_FONT = Enum.Font.Sarpanch
    shopManager.UI_PRIMARY_COLOR = Color3.fromRGB(255, 106, 0)
    shopManager.UI_SECONDARY_COLOR = Color3.fromRGB(0,0,0)

    shopManager.UI_SELECTION_SIZE = UDim2.fromScale(0.32, 0.15)
    shopManager.UI_EQUIPPED_SIZE = UDim2.fromScale(1,1)

    for _, child in pairs(shopManager.ScreenGui:GetDescendants()) do

        if ModuleLoader.utilities.HasProperty(child, "BorderSizePixel") then
            child.BorderColor3 = shopManager.UI_PRIMARY_COLOR
            child.BorderSizePixel = 2
        end

        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child.Font = shopManager.UI_FONT
        end
    end

    shopManager.PurchaseButton_Template = shopManager.selectionFrame.PurchaseButton_Template -- template of each button in your shop that will be clicked to purchase said item

    shopManager.promptToPurchaseWithRobux = false
    shopManager.currentlySelectedButton = nil


    ModuleLoader.ClientVariables.readyToInitButtons = false
    task.spawn(function()
        while not ModuleLoader.ClientVariables.readyToInitButtons do task.wait() end
    
        for _, weapon in pairs(game:GetService("ReplicatedStorage").GunToolPresets:GetChildren()) do
            if weapon:IsA("Tool") then
                local isLocked
                if (ModuleLoader.ClientVariables.player.ownedWeapons:FindFirstChild(weapon.Name)) or (ModuleLoader.ClientVariables.gunTool and ModuleLoader.ClientVariables.gunTool.Name == weapon.Name and (ModuleLoader.utilities.FindChildByNameWhichIsA(ModuleLoader.ClientVariables.player.Backpack, ModuleLoader.ClientVariables.gunTool.Name, "Tool"))) then
                    -- we own the weapon. Dont add the lock image
                    isLocked = false
                else
                    isLocked = true
                end
                shopManager.buttons[weapon.Name] = initiatePurchaseButton(weapon, isLocked)
            end
        end
    end)
    
    shopManager.equipPurchase_screen.Yes.Activated:Connect(function()
    
        if shopManager.promptToPurchaseWithRobux then
            MarketplaceService:PromptProductPurchase(ModuleLoader.ClientVariables.player, shopManager.currentlySelectedButton.productId)
            return
        end
    
        local getItem, amountMissingForPurchase
        local success, result = pcall(function()
            getItem, amountMissingForPurchase = RemoteFunction:InvokeServer("getItem", {name = shopManager.currentlySelectedButton.item.name})
        end)
    
        if not success then
            getItem = false
            warn(result)
            return
        end
    
        print(getItem)
        if getItem ~= true and getItem ~= false and getItem ~= "purchased" then
            shopManager.currentlySelectedButton:MissingRequiredToPurchase(getItem, amountMissingForPurchase)
            shopManager.promptToPurchaseWithRobux = true
            return 
        end
    
        if getItem ~= "purchased" then -- we dont want to switch button parents on purchase, only on equip/unequip.
            -- changes button parent to either equipped selection or unequipped:
            warn(getItem)
            shopManager.currentlySelectedButton:SwapParents(getItem)
    
            ModuleLoader.ClientVariables.gunTool = ModuleLoader.utilities.FindChildByAttributes(ModuleLoader.ClientVariables.player.Backpack, {Gun = true})
            shopManager.equipPurchase_screen.Visible = false
            shopManager.explanationOfItem.TextLabel.Text = ""
            return
        end
    
        -- purchased weapon:
        shopManager.currentlySelectedButton:closePurchase()
    end)
    
    shopManager.equipPurchase_screen.No.Activated:Connect(function()
        shopManager.equipPurchase_screen.Visible = false
        shopManager.explanationOfItem.TextLabel.Text = ""
        shopManager.promptToPurchaseWithRobux = false
    end)
    
    shopManager.equipPurchase_screen.Ok.Activated:Connect(function()
        shopManager.equipPurchase_screen.Visible = false
        shopManager.equipPurchase_screen.Ok.Visible = false
    
        shopManager.equipPurchase_screen.Yes.Visible = true
        shopManager.equipPurchase_screen.No.Visible = true
        shopManager.explanationOfItem.TextLabel.Text = ""
    end)
    
    local purchaseWithRobuxButton = shopManager.equipPurchase_screen.purchaseWithRobuxFrame.PurchaseWithRobuxButton
    purchaseWithRobuxButton.Activated:Connect(function()
        MarketplaceService:PromptProductPurchase(ModuleLoader.ClientVariables.player, shopManager.currentlySelectedButton.productId)
    end)
    
    shopManager.ShopButton.Activated:Connect(function()
        shopManager.shop_frame.Visible = not shopManager.shop_frame.Visible
    end)

    ModuleLoader.ClientVariables.player.ownedWeapons.ChildAdded:Connect(function(child)
        trackEquip(ModuleLoader.ClientVariables.player, child.Name)
    end)
end


return shopManager