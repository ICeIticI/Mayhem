local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local ModuleLoader = require(game:GetService("ReplicatedStorage").Shared.ModuleLoader)

local games = {}

function games.init()
    
    games.currentRoundPlayers = {}
    games.playerScores = {}
    games.winnerIdsTable = {} -- will be the id of the game winner to announce to each client
    
    games.gamePeriod = "Ongoing"
    games.countdown = ModuleLoader.utilities.createInstance("IntValue", {Name = "Countdown", Value = 0})
    games.countdown:GetPropertyChangedSignal("Value"):Connect(function()
        RemoteEvent:FireAllClients("CountdownChange", {gamePeriod = games.gamePeriod, Value = games.countdown.Value, playerScores = games.playerScores, winnerIdsTable = games.winnerIdsTable})
    end)
    
    games.gamemodes = { 
        {
            gamemode_name = "Free For All",
            timer = 120,
            roundReward = 200,
            run = function() -- Determines how scoring will work for FFA
                for _, player in pairs(games.currentRoundPlayers) do
    
                    -- for free-for-all, we track kills and add that to playerScores:
                    local killsTrackerConnect
                    killsTrackerConnect = ModuleLoader.WeaponsMarket:GetKillsAccount(player):GetPropertyChangedSignal("Value"):Connect(function()
                        games.playerScores[player.UserId] += 1
                    end)
    
                    -- disconnect tracking kills after the round ends:
                    local timerTrackerConnect
                    timerTrackerConnect = games.countdown:GetPropertyChangedSignal("Value"):Connect(function()
                        if games.countdown.Value == 0 and games:getGamePeriod() == "Ongoing" then
                            
                            killsTrackerConnect:Disconnect()
                            timerTrackerConnect:Disconnect()
    
                            local max = 0 -- starts the comparison with the smallest possible number.
                            for plrId, score in pairs(games.playerScores) do
                                if score > max then
                                    max = score
                                    table.clear(games.winnerIdsTable) -- clear old winner
                                    table.insert(games.winnerIdsTable, plrId) -- add new winner
                                end
                            end
                        end
                    end)
                end
            end
        },
    
        {
            gamemode_name = "Juggernaut",
            timer = 180,
            roundReward = 50,
            run = function()
                
                -- prepare teams:
                local Beast_Team = ServerStorage.TeamsStorage:FindFirstChild("Juggernaut") or Teams:FindFirstChild("Juggernaut")
                local Neutral_Team = ServerStorage.TeamsStorage:FindFirstChild("Neutral") or Teams:FindFirstChild("Neutral")
                Beast_Team.Parent = Teams
                Neutral_Team.Parent = Teams
    
                -- because we wannt randomly pick a player, we cant use a dictionary to choose a random index, so we turn it to a table.
                local currentRoundPlayers_TableVersion = ModuleLoader.utilities.makeTableFromDictionaryValues(games.currentRoundPlayers)
                local randomBeastIndex = math.random(1, #currentRoundPlayers_TableVersion)
    
                local chosenBeast
                local beastHealthMultiplier = 1 -- every player that is in the round will multiply the beast health
                for i, player in pairs(currentRoundPlayers_TableVersion) do
    
                    if i == randomBeastIndex then
                        -- this is our chosen beast
                        chosenBeast = player
                        player.Team = Beast_Team
    
                        if chosenBeast.Character:FindFirstChild("Health") then
                            chosenBeast.Character:WaitForChild("Health"):Destroy() -- take away healing script
                        end
                    else
                        player.Team = Neutral_Team
                        beastHealthMultiplier *= 1.1
                    end
                end
                chosenBeast.Character.Humanoid.MaxHealth *= 8 * beastHealthMultiplier
                chosenBeast.Character.Humanoid.Health = chosenBeast.Character.Humanoid.MaxHealth
                RemoteEvent:FireAllClients("revealJuggernaut", {chosenBeastName = chosenBeast.Name})
    
                local diedConnect
                diedConnect = chosenBeast.CharacterRemoving:Connect(function()
                    for _, plr in pairs(currentRoundPlayers_TableVersion) do
                        if plr ~= chosenBeast then
                            table.insert(games.winnerIdsTable, plr.UserId)
                        end
                    end
                    games.countdown.Value = 0
                    games.gamePeriod = "Ended"
                end)
    
                -- disconnect tracking kills after the round ends:
                local timerTrackerConnect
                timerTrackerConnect = games.countdown:GetPropertyChangedSignal("Value"):Connect(function()
                    if games.countdown.Value == 0 and games.gamePeriod == "Ongoing" then
                        diedConnect:Disconnect()
                        timerTrackerConnect:Disconnect()
                    end
                end)
            end
        },
    
    }
    
    -- function games.sendPlayersInRoundToClients()
    --     RemoteEvent:FireAllClients("sendPlayerScoresToClients", {playerScores = playerScores})
end

function games.getGamePeriod()
    return games.gamePeriod
end

function games.spawnCharacter(plr)
    local char = plr.Character or plr.CharacterAdded:Wait()

    -- Spawn at a random spot on the map. If team deathmatch, make sure to spawn on team SpawnLocation:
    local spawnPoints = game.Workspace.SpawnPoints:GetChildren()
    local spawnCFrame = spawnPoints[math.random(1, #spawnPoints)].CFrame

    char:WaitForChild("HumanoidRootPart").CFrame = spawnCFrame
    if games.gamePeriod ~= "Ongoing" then
        warn("not ongoing")
        char.HumanoidRootPart.Anchored = true
    end
end

function games.addPlayerToRound(player)
    if games.currentRoundPlayers[player.UserId] ~= nil then return end

    games.currentRoundPlayers[player.UserId] = player
    games.playerScores[player.UserId] = 0
    print(player.Name .. " has been added to the games!")

    -- if games.gamePeriod ~= "Ongoing" then
    --     warn("not ongoing")
    --     player.Character.HumanoidRootPart.Anchored = true
    -- end
end

function games.run()

    -- Clear old-round data for the new:
    table.clear(games.currentRoundPlayers)
    table.clear(games.playerScores)

    -- Start voting again for intermission:
    ModuleLoader.votingSystem.activateVoting()

    -- Intermission:
    games.gamePeriod = "Intermission"
    games.countdown.Value = 30
    for i = games.countdown.Value, 0, -1 do
        games.countdown.Value = i
        task.wait(1)
    end

    -- Pick gamemode:
    local chosenGamemode
    local chosenGamemodeName = ModuleLoader.votingSystem.finishVoting()
    warn(chosenGamemodeName)
    if chosenGamemodeName then     
        for _, gamemode in pairs(games.gamemodes) do
            if gamemode.gamemode_name == chosenGamemodeName then
                chosenGamemode = gamemode
            end
        end
    else
        chosenGamemode = games.gamemodes[math.random(1, #games.gamemodes)]
    end
    -- chosenGamemode = games.gamemodes[1] -- ! DELETE WHEN DONE TESTING !


    games.gamePeriod = "Chosen gamemode: " ..tostring(chosenGamemode.gamemode_name)

    -- Gather the players:
    for _, player in pairs(game.Players:GetPlayers()) do -- currentRoundPlayers gets added as players join the game and press Play
        if not player.IsLoaded.Value then continue end

        player.Team = nil
        games.addPlayerToRound(player)
        
        print("Hi")
        if player.Character then
            player.Character:Destroy()
        end
        player:LoadCharacter()
        task.wait()

        print('he')
        RemoteEvent:FireClient(player, "hideSideUI")
    end

    -- Restart intermission if not enough players:
    if game.PlaceId > 0 then -- not concerned about the # of players in studio testing
        if ModuleLoader.utilities.getLength(games.currentRoundPlayers) < 2 then
            games.gamePeriod = "Not enough players. Restarting intermission.."
            games.countdown.Value = 3
            for i = games.countdown.Value, 0, -1 do
                games.countdown.Value = i
                task.wait(1)
            end
            return
        end
    end

    games.countdown.Value = 3
    for i = games.countdown.Value, 0, -1 do
        games.countdown.Value = i
        task.wait(1)
    end
    -- Ready the gamemode:
    chosenGamemode.run()

    for _, weapon in pairs(ModuleLoader.Gun.activeGuns) do
        weapon:SetAmmoToDefault()
    end

    -- Countdown until match starts:
    games.gamePeriod = "Countdown"
    for i = 5, 0, -1 do
        games.countdown.Value = i
        task.wait(1)
    end

    -- if something caused the game to end early, changing gamePeriod to something else, then we dont want to even start it:
    -- for example, The Beast reset before game starts:
    if games.gamePeriod == "Countdown" then
        -- Let the games begin!
        warn("Let the games begin!")
        
        for _, player in pairs(games.currentRoundPlayers) do
            if not player.IsLoaded then continue end
            player.Character.HumanoidRootPart.Anchored = false
        end
        games.gamePeriod = "Ongoing"
    
    
        -- Start a timer to countdown until match ends:
        games.countdown.Value = chosenGamemode.timer
        for i = games.countdown.Value, 0, -1 do
            games.countdown.Value = i
            task.wait(1)
            if games.countdown.Value <= 0 then break end -- if I manually set it to 0 cause round ended early, such as the Beast getting killed.
        end

        -- Match ended! Freeze players, count scores, declare winner!
        games.gamePeriod = "Ended"
        for _, plr in pairs(games.currentRoundPlayers) do
            if plr.Character then
                plr.Character:Destroy()
                task.wait(0.1)
                plr:LoadCharacter()
            end
        end

        if #games.winnerIdsTable > 0 then
            for _, winnerId in pairs(games.winnerIdsTable) do
                local winner = Players:GetPlayerByUserId(winnerId)
                warn(winner)
                ModuleLoader.WeaponsMarket:AwardCash(winner, chosenGamemode.roundReward)
            end
        end
        
        for i = 5, 0, -1 do
            games.countdown.Value = i
            task.wait(1)
        end
        
    end


    -- returning teams
    for _, team in pairs(Teams:GetChildren()) do
        team.Parent = ServerStorage.TeamsStorage
    end

    games.winnerIdsTable = {}
end

return games