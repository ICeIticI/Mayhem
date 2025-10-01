local Players = game:GetService("Players")

local RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")

local utilities = require(game.ReplicatedStorage.Shared.utilities)
local WeaponsMarket = require(game.ReplicatedStorage.Shared.server_modules.WeaponsMarket)

local games = {}

local currentRoundPlayers = {}
local playerScores = {}
local winnerId = nil -- will be the id of the game winner to announce to each client

local gamePeriod = "Ongoing"
local countdown = utilities.createInstance("IntValue", {Name = "Countdown", Value = 0})
countdown:GetPropertyChangedSignal("Value"):Connect(function()
    RemoteEvent:FireAllClients("CountdownChange", {gamePeriod = gamePeriod, Value = countdown.Value, playerScores = playerScores, winnerId = winnerId})
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
        timer = 12,
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
                    end
                end)
            end
        end
    },

}

function games.run()

    -- Pick gamemode:
    local chosenGamemode = gamemodes[math.random(1, #gamemodes)]


    -- Clear old-round data for the new:
    table.clear(currentRoundPlayers)
    table.clear(playerScores)

    -- Intermission:
    gamePeriod = "Intermission"
    countdown.Value = 10
    for i = countdown.Value, 0, -1 do
        countdown.Value = i
        task.wait(1)
    end


    -- Gather the players:
    for _, player in pairs(game.Players:GetPlayers()) do -- currentRoundPlayers gets added as players join the game and press Play
        games.addPlayerToRound(player)
        if player.IsLoaded.Value then
            games.spawnCharacter(player.Character)
        end
    end


    -- Restart intermission if not enough players:
    if utilities.getLength(currentRoundPlayers) < 2 then
        gamePeriod = "Not enough players. Restarting intermission.."
        countdown.Value = 3
        for i = countdown.Value, 0, -1 do
            countdown.Value = i
            task.wait(1)
        end
        return
    end


    -- Countdown until match starts:
    gamePeriod = "Countdown"
    for i = 5, 0, -1 do
        countdown.Value = i
        task.wait(1)
    end


    -- Let the games begin!
    warn("Let the games begin!")
    chosenGamemode.run()
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
    end

    -- Match ended! Freeze players, count scores, declare winner!
    gamePeriod = "Ended"
    for _, plr in pairs(currentRoundPlayers) do
        if plr.Character then
            plr.Character.HumanoidRootPart.Anchored = true
        end
    end

    local max = 0 -- starts the comparison with the smallest possible number.
    
    for plrId, score in pairs(playerScores) do
        if score > max then
            max = score
            winnerId = plrId
        end
    end

    if winnerId then
        local winner = Players:GetPlayerByUserId(winnerId)
        warn(winner)
        WeaponsMarket:AwardCash(winner, 200)
    end
    
    for i = 5, 0, -1 do
        countdown.Value = i
        task.wait(1)
    end
    winnerId = nil
end

return games