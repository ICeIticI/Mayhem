--[[ A module with functions, variables, etc for other
     modules to use that are not tied to any specific 
     module.]]

local Utilities = {}
Utilities.__index = Utilities

Utilities.userInputTypes = {
    -- User Input Types
ShootInputs = {[Enum.UserInputType.MouseButton1] = true, [Enum.KeyCode.ButtonR2] = true},
ReloadInputs = {[Enum.KeyCode.R] = true, [Enum.KeyCode.ButtonX] = true}
-- AimInputs = {[Enum.UserInputType.MouseButton2] = true, [Enum.KeyCode.ButtonL2] = true},
}

function Utilities.checkInput(input)
    for key, inputType in pairs(Utilities.userInputTypes) do
        if inputType[input.UserInputType] or inputType[input.KeyCode] then
            return key
        end
    end
    -- warn("given input doesn't match allowed inputs:")
    -- print(Utilities.userInputTypes)
    return false
end

function Utilities.setCharacterNetworkOwnershipTo(character, owner)
    for _, child in pairs(character:GetChildren()) do
        if child:IsA("BasePart") then
            child:SetNetworkOwner(owner)
        end
    end
end

function Utilities.TurnInstancesToVariables(tbl)
    local stringedTbl = {}
    for _, v in pairs(tbl) do
        if v:IsA("StringValue") then -- add more value types if needed
            stringedTbl[v.Name] = v.Value
        end
    end
    return stringedTbl
end

function Utilities.makeDictionaryFromFolder(folder)
    local newDictionary = {}
    for _, inst in pairs(folder:GetChildren()) do
        newDictionary[inst.Name] = inst
    end
    print(newDictionary)
    return newDictionary
end

function Utilities.multiplyTableValuesTogether(tbl)
    local newProduct = 1 -- will be multiplied, can be less or more than 1
    for _, value in pairs(tbl) do
        if typeof(value) == "number" then
            newProduct*= value
        else
            warn(value .. " is not a number! Didn't multiply it")
        end
    end

    warn(newProduct)
    return newProduct
end

function Utilities.makeAnimationTracksFromAnimations(animationsTable, animator)
    local tracksTable = {}
    for _, animation in pairs(animationsTable) do
        tracksTable[animation.Name] = animator:LoadAnimation(animation)
    end

    return tracksTable
end

return Utilities