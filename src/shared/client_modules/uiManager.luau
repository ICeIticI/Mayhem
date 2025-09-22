local ClientVariables = require(game.ReplicatedStorage.Shared.client_modules.ClientVariables)

local UIManager = {}

local ShopButton = ClientVariables.Gun_GUI.ShopButton
local shop_ui = ClientVariables.Gun_GUI.shop_ui
local selectionFrame = shop_ui.weaponsSelection.selectionFrame

local equipPurchase_screen = shop_ui.equipPurchase_screen

local PurchaseButton_Template = selectionFrame.PurchaseButon
local function newUIButton(gun)
    local button = {}
    button.instance = PurchaseButton_Template:Clone()
    button.locked = true
    button.modelToDisplay = gun.tool:Clone()
    
    button.modelToDisplay.Parnet = button.ViewportFrame
    button.instance.Parent = selectionFrame

    button.instance.Activated:Connect(function()

        selectionFrame.explanationOfWeapon.TextLabel.Text = gun.description

        if currentlySelectedPerk.locked then
            equipPurchase_screen.purchaseWithRobuxFrame.PurchaseWithRobuxButton:WaitForChild("Amount").Text = getPriceOfPerkInRobux(currentlySelectedPerk)
            equipPurchase_screen.purchaseWithRobuxFrame.Visible = true
            equipPurchase_screen.TextLabel.Text = "Would you like to purchase the '" ..tostring(currentlySelectedPerk.name) .. "' perk for " .. tostring(currentlySelectedPerk.cost) .. " Tokens?"
        elseif currentlySelectedPerk.isEquipped then
            equipPurchase_screen.purchaseWithRobuxFrame.Visible = false
            equipPurchase_screen.TextLabel.Text = "Unequip?"
        else
            equipPurchase_screen.purchaseWithRobuxFrame.Visible = false
            equipPurchase_screen.TextLabel.Text = "Equip?"
        end

        equipPurchase_screen.Visible = true

        return
    end)

    return button
end

ShopButton.Activated:Connect(function()
    shop_ui.Visible = not shop_ui.Visible
end)

return UIManager