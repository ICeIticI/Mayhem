local ClientVariables = require(game.ReplicatedStorage.Shared.client_modules.ClientVariables)
local utilities = require(game.ReplicatedStorage.Shared.utilities)

local RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")

local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if not utilities.checkInput(input) then return end

    local inputTable = {} -- Because the server wont let us send the input object, we need to create a table representing input that are strings
    inputTable.UserInputType = input.UserInputType
    inputTable.KeyCode = input.KeyCode

    RemoteEvent:FireServer("input", {input = inputTable, gameProcessedEvent = gameProcessedEvent})
end)