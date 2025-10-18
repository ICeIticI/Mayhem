--[[ A module with functions, variables, etc for other
     modules to use that are not tied to any specific 
     module.]]

local Utilities = {}

Utilities.userInputTypes = {
    -- User Input Types
    ShootInputs = {[Enum.UserInputType.MouseButton1] = true, [Enum.KeyCode.ButtonR2] = true},
    ReloadInputs = {[Enum.KeyCode.R] = true, [Enum.KeyCode.ButtonX] = true},
    SprintInputs = {[Enum.KeyCode.LeftShift] = true, [Enum.KeyCode.ButtonL3] = true}
    -- AimInputs = {[Enum.UserInputType.MouseButton2] = true, [Enum.KeyCode.ButtonL2] = true},
}

function Utilities.checkInput(input)
    for key, inputType in pairs(Utilities.userInputTypes) do
        if input and (inputType[input.UserInputType] or inputType[input.KeyCode]) then
            return key
        end
    end
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

    return newProduct
end

function Utilities.createInstance(instanceName: string, properties : dictionary) -- One-liner version of creating an instance
    local newInstance = Instance.new(instanceName)
    for i, v in pairs(properties) do
        if newInstance then
            newInstance[i] = v
        else
            warn("No property " .. i .. " for " .. newInstance.Name .. ". Instance type: " .. instanceName)
        end
    end

    return newInstance
end

function Utilities.makeAnimationTracksFromAnimations(animationsTable, animator) -- animationsTable accepts both Animation instances and AnimationIds
    local tracksTable = {}
    for i, v in pairs(animationsTable) do

        local animation
        if typeof(v) == "string" then
            animation = Instance.new("Animation")
            animation.AnimationId = v
        elseif typeof(v) == "Instance" and v:IsA("Animation") then
            animation = v
        end

        -- make sure we have an actual animation:
        if not animation then 
            warn(v .. " is not an animation or animationId. Skipped.") 
            continue 
        end


        tracksTable[i] = animator:LoadAnimation(animation)

        -- "warm up" the AnimationTracks because its delayed on first play:
        tracksTable[i]:Play()
        tracksTable[i]:Stop()
    end

    return tracksTable
end

function Utilities.makeAnimationTracksFromIds(idTable, animator)
    local tracksTable = {}
    for i, v in pairs(idTable) do
        local newAnimation = Utilities.createInstance("Animation", {AnimationId = v})
        tracksTable[i] = animator:LoadAnimation(newAnimation)

        -- "warm up" the AnimationTracks because its delayed on first play:
        tracksTable[i]:Play()
        tracksTable[i]:Stop()
    end

    return tracksTable
end

--[[
	Searches the children of a given instance for one that matches all specified attributes.
	@param parent Instance - The parent to search within.
	@param attributeCriteria table - A dictionary of attribute key-value pairs to match.
	@return Instance? - The first matching child, or nil if none found.
]]
function Utilities.FindChildByAttributes(parent: Instance, attributeCriteria: { [string]: any }): Instance?
	for _, child in ipairs(parent:GetChildren()) do
		local matchesAll = true
		for key, expectedValue in pairs(attributeCriteria) do
			local actualValue = child:GetAttribute(key)
			if actualValue ~= expectedValue then
				matchesAll = false
				break
			end
		end
		if matchesAll then
			return child
		end
	end
	return nil
end

function Utilities.FindChildByNameWhichIsA(parent : Instance, name : string, className : string)
    
    if not parent then return end
    for _, child in pairs(parent:GetChildren()) do
        if not name then name = child.Name end

        if child.Name == name and child:IsA(className) then
            return child
        end
    end
    -- return warn("No child of " .. parent.Name .. " found with the name " .. name .. " that is a " .. className)
end

function Utilities.HasProperty(obj: Instance, prop: string): boolean
	return pcall(function()
		local _ = obj[prop]
	end)
end

function Utilities.getLength(tbl)
	assert(typeof(tbl) == "table", "Expected a table")
	local count = 0
	for _ in pairs(tbl) do
		count += 1
	end
	return count
end

-- Returns a list of properties from a table of values that share a property
function Utilities.getPropertyList(tbl, desiredProperty)
    local propertiesTbl = {}
    for i, v in pairs(tbl) do
        propertiesTbl[i] = v[desiredProperty]
    end
    return propertiesTbl
end

return Utilities