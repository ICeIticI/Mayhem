local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ClientVariables = require(game.ReplicatedStorage.Shared.client_modules.ClientVariables)
local utilities = require(game.ReplicatedStorage.Shared.utilities)
require(game.ReplicatedStorage.Shared.client_modules.client_events)
require(game.ReplicatedStorage.Shared.client_modules.shopManager)

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
                local ray = camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
                RemoteEvent:FireServer("inputStarted", {input = inputTable, gameProcessedEvent = gameProcessedEvent, ray = ray})
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

ClientVariables.player.Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") and child:GetAttribute("Gun") then
        ClientVariables.gunTool = child
    end
end)