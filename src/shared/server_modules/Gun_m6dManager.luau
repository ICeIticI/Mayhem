local Gun_m6dManager = {}

function Gun_m6dManager.run(plr)
    local char = plr.Character or plr.CharacterAdded:Wait()
    local Motor
    
    --plr.CharacterAdded:Connect(function(char) -- When the character dies, this provides another way for a motor6D to be added and work with the AK
    Motor = Instance.new("Motor6D")
    Motor.Parent = char:WaitForChild("Right Arm")
    
    -- Motor.Name = "AK6D2" -- For torso
    
    Motor.Name = "AK6D1" -- For Right Arm
    Motor.Part0 = char["Right Arm"]
    --end)
    
    print(char)
    char.ChildAdded:Connect(function(child) -- runs whenever anything is added to the characters inventory
        print(child)
        if child:IsA("Tool") and child:FindFirstChild("BodyAttach") then
            print(true)
            Motor.Part1 = child.BodyAttach
        end
    end)
end

return Gun_m6dManager