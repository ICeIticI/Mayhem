local ClientVariables = {}

ClientVariables.player = game:GetService("Players").LocalPlayer

ClientVariables.Gun_GUI = ClientVariables.player.PlayerGui:WaitForChild("Gun_GUI")
ClientVariables.Main_Display = ClientVariables.Gun_GUI:WaitForChild("Main_Display")

ClientVariables.gunCursor = "rbxasset://textures/GunCursor.png"
ClientVariables.reloadingCursor = "rbxasset://textures/GunWaitCursor.png"
ClientVariables.previousMouseIcon = game:GetService("UserInputService").MouseIcon

ClientVariables.functions = {
    antiTrans = function(part)
        if part and part:IsA("BasePart") and (part.Name == "Left Arm" or part.Name == "Right Arm") then -- checks each of the characters parts to see if any of them is a base part and a left/right arm
            part.LocalTransparencyModifier = 0 -- part.LocalTransparencyModifier is the client-side transparency of a BasePart. Your character goes invisible in first person, thats called LocalTransparencyModifier. We set it equal to the actual part's real transparency
            part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function(property) -- the .Changed event runs whenever a property of a given object changes. This will run whenever the LocalTransparencyModifier is at work making the character invisible in first person
                part.LocalTransparencyModifier = 0 -- Instead of the arms going invisible whenever the player goes in first person, they will stay fully visible.	
            end)
        end
    end
}

return ClientVariables