local MarketplaceService = game:GetService("MarketplaceService")
local StarterPlayer = game:GetService("StarterPlayer")

local ClientVariables = require(StarterPlayer.StarterPlayerScripts.Client.client_modules.ClientVariables)
local utilities = require(game.ReplicatedStorage.Shared.utilities)

local RemoteFunction = game.ReplicatedStorage:WaitForChild("RemoteFunction")

local shopManager = {}

local ScreenGui = ClientVariables.player.PlayerGui.ScreenGui
local shop_frame = ScreenGui.shop_frame -- frame containing the shop and equipped
local equipPurchase_screen = shop_frame.equipPurchase_screen -- the screen that pops up every time we want to buy/equip/unequip a weapon, confirming if we do or not
local selectionFrame = shop_frame.selection.selectionFrame -- frame containing all the UIs of avaliable items for purchase
local equippedFrame = shop_frame.equipped
local explanationOfItem = shop_frame.selection.explanationOfItem -- text that describes the item selected
local ShopButton = ScreenGui.ShopButton -- the button that shows/hides the shop_frame

shop_frame.Visible = false


shopManager.buttons = {} -- table that will be filled with each button that will allow the player to purchase/equip/unequip a weapon.

local UI_FONT = Enum.Font.Sarpanch
local UI_PRIMARY_COLOR = Color3.fromRGB(255, 106, 0)
local UI_SECONDARY_COLOR = Color3.fromRGB(0,0,0)

local UI_SELECTION_SIZE = UDim2.fromScale(0.496,0.333)
local UI_EQUIPPED_SIZE = UDim2.fromScale(1,1)

for _, child in pairs(ScreenGui:GetDescendants()) do

    if utilities.HasProperty(child, "BorderSizePixel") then
        child.BorderColor3 = UI_PRIMARY_COLOR
        child.BorderSizePixel = 2
    end

    if child:IsA("TextButton") or child:IsA("TextLabel") then
        child.Font = UI_FONT
    end
end

local PurchaseButton_Template = selectionFrame.PurchaseButton_Template -- template of each button in your shop that will be clicked to purchase said item

local promptToPurchaseWithRobux = false
local currentlySelectedButton

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

    button.instance = PurchaseButton_Template:Clone()
    button.instance.lockImage.Visible = isLocked
    button.instance.Name = "PurchaseButton"
    button.instance.Visible = true

    button.item = itemToDisplay
    button.item:PivotTo(CFrame.new(0, 3.5, 6.5))

    -- Methods:

    function button:MissingRequiredToPurchase(message, amountMissingForPurchase) -- runs if the player is missing kills or cash in order to purchase the weapon
        -- they should be prompted to purchase this gun with robux or purchase more cash
            
        if message == "needMoreKills" then
            equipPurchase_screen.TextLabel.Text = "You need " ..tostring(amountMissingForPurchase) .. " more Kills to be able to purchase the '" ..tostring(self.item.name) .."' gun. Would you like to purchase this gun with Robux?"
        elseif message == "needMoreMoney" then
            equipPurchase_screen.TextLabel.Text = "You need " ..tostring(amountMissingForPurchase) .. " more Cash to purchase the '" ..tostring(self.item.name) .."' gun. Would you like to purchase more Cash?"
        end

        return 
    end

    function button:SwapParents(bool) -- true means equipped, false means unequipped
        -- changes button parent to either equipped selection or unequipped:
        if bool then
            -- change to equipped section:
            self.instance.Size = UI_EQUIPPED_SIZE
            self.instance.Parent = equippedFrame
        else
            -- change to unequipped section:
            self.instance.Size = UI_SELECTION_SIZE
            self.instance.Parent = selectionFrame
        end
        return
    end

    function button:closePurchase() -- will notify the player via the equipPurchase_screen that their purchase was complete
        self.instance.lockImage.Visible = false
        equipPurchase_screen.Yes.Visible = false
        equipPurchase_screen.No.Visible = false

        equipPurchase_screen.Ok.Visible = true
        equipPurchase_screen.purchaseWithRobuxFrame.Visible = false
        equipPurchase_screen.TextLabel.Text = "Thank you! You now own the " ..tostring(self.item.name) .. "!"
        promptToPurchaseWithRobux = false
end

    -- Connections:

    button.instance.Activated:Connect(function()

        if ClientVariables.player.unequippedWeapons:FindFirstChild(button.item.Name) then
            -- weapon is currently unequipped
            equipPurchase_screen.purchaseWithRobuxFrame.Visible = false
            equipPurchase_screen.TextLabel.Text = "Equip?"
        elseif ClientVariables.gunTool and ClientVariables.gunTool.Name == button.item.Name and (utilities.FindChildByNameWhichIsA(ClientVariables.player.Backpack, ClientVariables.gunTool.Name, "Tool") or utilities.FindChildByNameWhichIsA(ClientVariables.player.Character, ClientVariables.gunTool.Name, "Tool")) then
            -- weapon is already equipped
            equipPurchase_screen.purchaseWithRobuxFrame.Visible = false
            equipPurchase_screen.TextLabel.Text = "Unequip?"
        else
            -- Weapon isn't owned
            equipPurchase_screen.purchaseWithRobuxFrame.Visible = true
            equipPurchase_screen.purchaseWithRobuxFrame.PurchaseWithRobuxButton:WaitForChild("Amount").Text = getPriceOfProductInRobux(button.productId)
            if tonumber(equipPurchase_screen.purchaseWithRobuxFrame.PurchaseWithRobuxButton.Amount.Text) <= 0 then equipPurchase_screen.purchaseWithRobuxFrame.Visible = false end

            equipPurchase_screen.TextLabel.Text = "Would you like to purchase the " .. button.item.Name .. " for " .. button.item:GetAttribute("Cost") .." cash?"
        end
        
        promptToPurchaseWithRobux = false
        explanationOfItem.TextLabel.Text = itemToDisplay:GetAttribute("Description")
        currentlySelectedButton = button
        equipPurchase_screen.Visible = true
    end)

    button.item.Parent = button.instance.ViewportFrame
    button.instance.Parent = selectionFrame
    
    return button
end


ClientVariables.readyToInitButtons = false
task.spawn(function()
    while not ClientVariables.readyToInitButtons do task.wait() end

    for _, weapon in pairs(game:GetService("ReplicatedStorage").GunToolPresets:GetChildren()) do
        if weapon:IsA("Tool") then
            local isLocked
            if (ClientVariables.player.unequippedWeapons:FindFirstChild(weapon.Name)) or (ClientVariables.gunTool and ClientVariables.gunTool.Name == weapon.Name and (utilities.FindChildByNameWhichIsA(ClientVariables.player.Backpack, ClientVariables.gunTool.Name, "Tool"))) then
                -- we own the weapon. Dont add the lock image
                isLocked = false
            else
                isLocked = true
            end
            shopManager.buttons[weapon.Name] = initiatePurchaseButton(weapon, isLocked)
        end
    end
end)

equipPurchase_screen.Yes.Activated:Connect(function()

    if promptToPurchaseWithRobux then
        MarketplaceService:PromptProductPurchase(ClientVariables.player, currentlySelectedButton.productId)
        return
    end

    local getItem, amountMissingForPurchase
    local success, result = pcall(function()
        getItem, amountMissingForPurchase = RemoteFunction:InvokeServer("getItem", {name = currentlySelectedButton.item.name})
    end)

    if not success then
        getItem = false
        warn(result)
        return
    end

    if getItem ~= true and getItem ~= "purchased" then
        currentlySelectedButton:MissingRequiredToPurchase(getItem, amountMissingForPurchase)
        promptToPurchaseWithRobux = true
        return 
    end

    if getItem ~= "purchased" then -- we dont want to switch button parents on purchase, only on equip/unequip.
        -- changes button parent to either equipped selection or unequipped:
        -- currentlySelectedButton:SwapParents()

        ClientVariables.gunTool = utilities.FindChildByAttributes(ClientVariables.player.Backpack, {Gun = true})
        equipPurchase_screen.Visible = false
        explanationOfItem.TextLabel.Text = ""
        return
    end

    -- purchased weapon:
    currentlySelectedButton:closePurchase()
end)

equipPurchase_screen.No.Activated:Connect(function()
    equipPurchase_screen.Visible = false
    explanationOfItem.TextLabel.Text = ""
    promptToPurchaseWithRobux = false
end)

equipPurchase_screen.Ok.Activated:Connect(function()
    equipPurchase_screen.Visible = false
    equipPurchase_screen.Ok.Visible = false

    equipPurchase_screen.Yes.Visible = true
    equipPurchase_screen.No.Visible = true
    explanationOfItem.TextLabel.Text = ""
end)

local purchaseWithRobuxButton = equipPurchase_screen.purchaseWithRobuxFrame.PurchaseWithRobuxButton
purchaseWithRobuxButton.Activated:Connect(function()
    MarketplaceService:PromptProductPurchase(ClientVariables.player, currentlySelectedButton.productId)
end)

ShopButton.Activated:Connect(function()
    shop_frame.Visible = not shop_frame.Visible
end)

return shopManager