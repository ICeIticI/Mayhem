local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Load UI in on join
if Players.LocalPlayer then
    for _, v in pairs(game:GetService("StarterGui"):GetChildren()) do
        v:Clone().Parent = Players.LocalPlayer.PlayerGui
    end
end
Players.PlayerAdded:Connect(function(player)
    if player ~= Players.LocalPlayer then return end
    for _, v in pairs(game:GetService("StarterGui"):GetChildren()) do
        v:Clone().Parent = player.PlayerGui
    end
end)

local ClientVariables = require(game.ReplicatedStorage.Shared.client_modules.ClientVariables)
require(game.ReplicatedStorage.Shared.client_modules.client_events)
local utilities = require(game.ReplicatedStorage.Shared.utilities)
local ShopManager = require(game.ReplicatedStorage.Shared.client_modules.shopManager)
local move_arms
task.spawn(function()
    move_arms = require(game.ReplicatedStorage.Shared.client_modules.move_arms)
end)

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local camera = workspace.CurrentCamera
local isHolding = false

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    local inputType = utilities.checkInput(input)
    if not inputType then return end

    local inputTable = {} -- Because the server wont let us send the input object, we need to create a table representing input that are strings
    inputTable.UserInputType = input.UserInputType
    inputTable.KeyCode = input.KeyCode

    if gameProcessedEvent then return end
    
    if inputType == "ShootInputs" then
        if ClientVariables.gunTool and not ClientVariables.gunTool.Values.shootDebounce.Value and ClientVariables.gunTool.Activated then
            isHolding = true
            while isHolding and ClientVariables.gunTool.Equipped do
                local screenCenter = camera.ViewportSize / 2
                ClientVariables.ray = camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
                RemoteEvent:FireServer("inputStarted", {input = inputTable, gameProcessedEvent = gameProcessedEvent, ray = ClientVariables.ray})
                task.wait()
            end
        end
    else
        RemoteEvent:FireServer("inputStarted", {input = inputTable, gameProcessedEvent = gameProcessedEvent})
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    local inputType = utilities.checkInput(input)
    if not inputType then return end
    
    local inputTable = {} -- Because the server wont let us send the input object, we need to create a table representing input that are strings
    inputTable.UserInputType = input.UserInputType
    inputTable.KeyCode = input.KeyCode

    if inputType == "ShootInputs" then
        isHolding = false
    elseif inputType == "SprintInputs" then
        RemoteEvent:FireServer("inputEnded", {input = inputTable, gameProcessedEvent = gameProcessedEvent})
    end
end)

ClientVariables.gunTool = utilities.FindChildByAttributes(ClientVariables.player.Backpack, {Gun = true})

ClientVariables.Gun_GUI.PlayButton.Visible = true
ClientVariables.Gun_GUI.Game_Title.Visible = true

ClientVariables.Gun_GUI.PlayButton.Activated:Connect(function()
   print("Received")
    ClientVariables.Gun_GUI.PlayButton.Visible = false
    ClientVariables.Gun_GUI.Game_Title.Visible = false
    
    RemoteEvent:FireServer("play")

end)


-- Change UI parent based on if the gun is equipped or not:

local function onChildChanged(child)
    if child:IsA("Tool") and child:GetAttribute("Gun") then
        if child.Parent == ClientVariables.player.Backpack or child.Parent == ClientVariables.player.Character then
            -- equipped weapon
            ClientVariables.gunTool = child

            if child.Parent == ClientVariables.player.Character then
                move_arms:activate()
            else
                move_arms:deactivate()
            end

            ShopManager.buttons[child.Name]:SwapParents(true)
        else
            ShopManager.buttons[child.Name]:SwapParents(false)
        end
    end
end
ClientVariables.player.Backpack.ChildAdded:Connect(onChildChanged)
ClientVariables.player.Backpack.ChildRemoved:Connect(onChildChanged)
ClientVariables.player.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(onChildChanged)
    character.ChildRemoved:Connect(onChildChanged)
end)