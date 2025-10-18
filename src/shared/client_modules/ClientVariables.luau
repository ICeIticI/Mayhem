local ClientVariables = {}

ClientVariables.player = game:GetService("Players").LocalPlayer
ClientVariables.camera = game:GetService("Workspace").CurrentCamera

ClientVariables.Gun_GUI = ClientVariables.player.PlayerGui:WaitForChild("ScreenGui")
ClientVariables.Main_Display = ClientVariables.Gun_GUI:WaitForChild("Ammo_Display")

ClientVariables.gunCursor = "rbxasset://textures/GunCursor.png"
ClientVariables.reloadingCursor = "rbxasset://textures/GunWaitCursor.png"
ClientVariables.previousMouseIcon = game:GetService("UserInputService").MouseIcon

ClientVariables.tracks = {} -- dictionary of AnimationTracks the player can play. Their Ids are sent from the server.

ClientVariables.functions = {
    antiTrans = function(part)
        if part and part:IsA("BasePart") and (part.Name == "Left Arm" or part.Name == "Right Arm") then -- checks each of the characters parts to see if any of them is a base part and a left/right arm
            part.LocalTransparencyModifier = 0 -- part.LocalTransparencyModifier is the client-side transparency of a BasePart. Your character goes invisible in first person, thats called LocalTransparencyModifier. We set it equal to the actual part's real transparency
            part:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function(property) -- the .Changed event runs whenever a property of a given object changes. This will run whenever the LocalTransparencyModifier is at work making the character invisible in first person
                part.LocalTransparencyModifier = 0 -- Instead of the arms going invisible whenever the player goes in first person, they will stay fully visible.	
            end)
        end
    end,

    -- Micorosft Copilot did this:
    getSortedPlayers = function(playerScores)
        local sorted = {}

        for playerId, score in pairs(playerScores) do
            table.insert(sorted, {player = game:GetService("Players"):GetPlayerByUserId(playerId), score = score})
        end

        table.sort(sorted, function(a, b)
            return a.score > b.score -- descending
        end)

        return sorted

    end,

    -- Microsoft Copilot also did this:
    updateLeaderboard = function(sortedPlayers)
        local leaderboardFrame = ClientVariables.Gun_GUI.round_leaderboard -- your GUI container
    
        -- Clear old entries
        for _, child in pairs(leaderboardFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end

        -- print(sortedPlayers)
    
        -- Rebuild leaderboard
        for rank, entry in ipairs(sortedPlayers) do
            local player = entry.player
            local score = entry.score
    
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 30)
            row.Position = UDim2.new(0, 0, 0, (rank - 1) * 30)
            row.Parent = leaderboardFrame
    
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Text = player.Name
            nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
            nameLabel.Parent = row
    
            local scoreLabel = Instance.new("TextLabel")
            scoreLabel.Text = tostring(score)
            scoreLabel.Size = UDim2.new(0.4, 0, 1, 0)
            scoreLabel.Position = UDim2.new(0.6, 0, 0, 0)
            scoreLabel.Parent = row
        end
    end


}

return ClientVariables