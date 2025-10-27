local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")
local ServerStorage = game:GetService("ServerStorage")
local Teams = game:GetService("Teams")

local utilities = require(game.ReplicatedStorage.Shared.utilities)
local WeaponsMarket = require(ServerScriptService.Server.server_modules.WeaponsMarket)
local Gun = require(game:GetService("ServerScriptService").Server.server_modules.Gun)

local games = {}

local currentRoundPlayers = {}
local playerScores = {}
local winnerIdsTable = {} -- will be the id of the game winner to announce to each client

local gamePeriod = "Ongoing"
local countdown = utilities.createInstance("IntValue", {Name = "Countdown", Value = 0})
countdown:GetPropertyChangedSignal("Value"):Connect(function()
    RemoteEvent:FireAllClients("CountdownChange", {gamePeriod = gamePeriod, Value = countdown.Value, playerScores = playerScores, winnerIdsTable = winnerIdsTable})
end)


-- function games.sendPlayersInRoundToClients()
--     RemoteEvent:FireAllClients("sendPlayerScoresToClients", {playerScores = playerScores})
-- end

function games.getGamePeriod()
    return gamePeriod
end

function games.spawnCharacter(char)
    -- Spawn at a random spot on the map. If team deathmatch, make sure to spawn on team SpawnLocation:
    local spawnPoints = game.Workspace.SpawnPoints:GetChildren()
    local spawnCFrame = spawnPoints[math.random(1, #spawnPoints)].CFrame

    char.HumanoidRootPart.CFrame = spawnCFrame
    if gamePeriod ~= "Ongoing" then
        char.HumanoidRootPart.Anchored = true
    end
end

function games.addPlayerToRound(player)
    if currentRoundPlayers[player.UserId] ~= nil then return end

    currentRoundPlayers[player.UserId] = player
    playerScores[player.UserId] = 0
    print(player.Name .. " has been added to the games!")

    if gamePeriod ~= "Ongoing" then
        player.Character.HumanoidRootPart.Anchored = true
    end
end

local gamemodes = { 
    {
        gamemode_name = "Free For All",
        timer = 120,
        roundReward = 200,
        run = function() -- Determines how scoring will work for FFA
            for _, player in pairs(currentRoundPlayers) do

                -- for free-for-all, we track kills and add that to playerScores:
                local killsTrackerConnect
                killsTrackerConnect = WeaponsMarket:GetKillsAccount(player):GetPropertyChangedSignal("Value"):Connect(function()
                    playerScores[player.UserId] += 1
                end)

                -- disconnect tracking kills after the round ends:
                local timerTrackerConnect
                timerTrackerConnect = countdown:GetPropertyChangedSignal("Value"):Connect(function()
                    if countdown.Value == 0 then
                        
                        killsTrackerConnect:Disconnect()
                        timerTrackerConnect:Disconnect()

                        local max = 0 -- starts the comparison with the smallest possible number.
                        for plrId, score in pairs(playerScores) do
                            if score > max then
                                max = score
                                table.clear(winnerIdsTable) -- clear old winner
                                table.insert(winnerIdsTable, plrId) -- add new winner
                            end
                        end
                    end
                end)
            end
        end
    },

    {
        gamemode_name = "Juggernaut",
        timer = 600,
        roundReward = 50,
        run = function()
            
            -- prepare teams:
            local Beast_Team = ServerStorage.TeamsStorage:WaitForChild("Juggernaut")
            local Neutral_Team = ServerStorage.TeamsStorage:WaitForChild("Neutral")
            Beast_Team.Parent = Teams
            Neutral_Team.Parent = Teams

            -- because we wannt randomly pick a player, we cant use a dictionary to choose a random index, so we turn it to a table.
            local currentRoundPlayers_TableVersion = utilities.makeTableFromDictionaryValues(currentRoundPlayers)
            local randomBeastIndex = math.random(1, #currentRoundPlayers_TableVersion)
            print(randomBeastIndex, currentRoundPlayers_TableVersion)

            local chosenBeast
            local beastHealthMultiplier = 1 -- every player that is in the round will multiply the beast health
            for i, player in pairs(currentRoundPlayers_TableVersion) do

                print(randomBeastIndex, i)
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
            print(chosenBeast.Character.Humanoid.MaxHealth, beastHealthMultiplier)
            RemoteEvent:FireAllClients("revealJuggernaut", {chosenBeastName = chosenBeast.Name})

            local diedConnect
            diedConnect = chosenBeast.Character.Humanoid.Died:Connect(function()
                for _, plr in pairs(currentRoundPlayers_TableVersion) do
                    if plr ~= chosenBeast then
                        table.insert(winnerIdsTable, plr.UserId)
                    end
                end
                countdown.Value = 0
                gamePeriod = "Ended"
            end)

            -- disconnect tracking kills after the round ends:
            local timerTrackerConnect
            timerTrackerConnect = countdown:GetPropertyChangedSignal("Value"):Connect(function()
                if countdown.Value == 0 and gamePeriod == "Ongoing" then
                    diedConnect:Disconnect()
                    timerTrackerConnect:Disconnect()
                end
            end)
        end
    },

}

function games.run()

    -- Pick gamemode:
    local chosenGamemode = gamemodes[math.random(1, #gamemodes)]
    -- chosenGamemode = gamemodes[2] -- ! DELETE WHEN DONE TESTING !

    -- Clear old-round data for the new:
    table.clear(currentRoundPlayers)
    table.clear(playerScores)

    -- Intermission:
    gamePeriod = "Intermission"
    countdown.Value = 3
    for i = countdown.Value, 0, -1 do
        countdown.Value = i
        task.wait(1)
    end


    -- Gather the players:
    for _, player in pairs(game.Players:GetPlayers()) do -- currentRoundPlayers gets added as players join the game and press Play
        player.Team = nil
        games.addPlayerToRound(player)
        if player.IsLoaded.Value then
            games.spawnCharacter(player.Character)
        end
    end


    -- Restart intermission if not enough players:
    if game.PlaceId > 0 then -- not concerned about the # of players in studio testing
        if utilities.getLength(currentRoundPlayers) < 2 then
            gamePeriod = "Not enough players. Restarting intermission.."
            countdown.Value = 3
            for i = countdown.Value, 0, -1 do
                countdown.Value = i
                task.wait(1)
            end
            return
        end
    end

    gamePeriod = "Chosen gamemode: " ..tostring(chosenGamemode.gamemode_name)
    countdown.Value = 3
    for i = countdown.Value, 0, -1 do
        countdown.Value = i
        task.wait(1)
    end

    -- Ready the gamemode:
    chosenGamemode.run()

    for _, weapon in pairs(Gun.activeGuns) do
        weapon:SetAmmoToDefault()
    end

    -- Countdown until match starts:
    gamePeriod = "Countdown"
    for i = 5, 0, -1 do
        countdown.Value = i
        task.wait(1)
    end

    -- if something caused the game to end early, changing gamePeriod to something else, then we dont want to even start it:
    -- for example, The Beast reset before game starts:
    if gamePeriod == "Countdown" then
        -- Let the games begin!
        warn("Let the games begin!")
        for _, player in pairs(currentRoundPlayers) do
            if not player.IsLoaded then continue end
            player.Character.HumanoidRootPart.Anchored = false
        end
        gamePeriod = "Ongoing"
    
    
        -- Start a timer to countdown until match ends:
        countdown.Value = chosenGamemode.timer
        for i = countdown.Value, 0, -1 do
            countdown.Value = i
            task.wait(1)
            if countdown.Value <= 0 then break end -- if I manually set it to 0 cause round ended early, such as the Beast getting killed.
        end

        -- Match ended! Freeze players, count scores, declare winner!
        gamePeriod = "Ended"
        for _, plr in pairs(currentRoundPlayers) do
            if plr.Character then
                plr.Character.HumanoidRootPart.Anchored = true
            end
        end

        if #winnerIdsTable > 0 then
            for _, winnerId in pairs(winnerIdsTable) do
                local winner = Players:GetPlayerByUserId(winnerId)
                warn(winner)
                WeaponsMarket:AwardCash(winner, chosenGamemode.roundReward)
            end
        end
        
        for i = 5, 0, -1 do
            countdown.Value = i
            task.wait(1)
        end
        
    end


    -- returning teams
    for _, team in pairs(Teams:GetChildren()) do
        team.Parent = ServerStorage.TeamsStorage
    end

    winnerIdsTable = {}
end

return games