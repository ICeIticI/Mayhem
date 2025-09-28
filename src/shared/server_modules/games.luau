local Players = game:GetService("Players")

local utilities = require(game.ReplicatedStorage.Shared.utilities)
local WeaponsMarket = require(game.ReplicatedStorage.Shared.server_modules.WeaponsMarket)

local games = {}

local matchStarted = false
local countdown = utilities.createInstance("IntValue", {Name = "Countdown", Value = 0})

local currentRoundPlayers = {}
local playerScores = {}

function games.spawnCharacter(char)
    -- Spawn at a random spot on the map. If team deathmatch, make sure to spawn on team SpawnLocation:
    char.HumanoidRootPart.CFrame = CFrame.new(0, 1, 0)
end

function games.addPlayerToRound(player)
    if currentRoundPlayers[player.Name] ~= nil then return end

    currentRoundPlayers[player.Name] = player
    playerScores[player.Name] = 0
    print(player.Name .. "Has been added to the games!")

    if not matchStarted then
        player.Character.HumanoidRootPart.Anchored = true
    end
end

local gamemodes = { 
    {
        gamemode_name = "Free For All",
        timer = 120,
        run = function() -- will initiate a FreeForAll match
            for _, player in pairs(currentRoundPlayers) do

                -- for free-for-all, we track kills and add that to playerScores:
                local killsTrackerConnect
                killsTrackerConnect = WeaponsMarket:GetKillsAccount(player):GetPropertyChangedSignal("Value"):Connect(function()
                    playerScores[player.Name] += 1
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


    -- Gather the players:
    matchStarted = false
    for _, player in pairs(currentRoundPlayers) do -- currentRoundPlayers gets added as players join the game and press Play
        if player.IsLoaded.Value then
            games.spawnCharacter(player.Character)
        end
    end


    -- Countdown until match starts:
    for i = 5, 0, -1 do
        countdown.Value = i
        warn(countdown.Value)
        task.wait(1)
    end


    -- Let the games begin!
    warn("Let the games begin!")
    chosenGamemode.run()
    for _, player in pairs(currentRoundPlayers) do
        if not player.IsLoaded then continue end
        player.Character.HumanoidRootPart.Anchored = false
    end
    matchStarted = true


    -- Start a timer to countdown until match ends:
    countdown.Value = chosenGamemode.timer
    for i = countdown.Value, 0, -1 do
        countdown.Value = i
        print(countdown.Value)
        task.wait(1)
    end

    -- Match ended! Freeze players, count scores, declare winner!
    matchStarted = false
    for _, plr in pairs(currentRoundPlayers) do
        if plr.Character then
            plr.Character.HumanoidRootPart.Anchored = true
        end
    end

    local max = -math.huge -- starts the comparison with the smallest possible number.
    local winner = nil
    for plr, score in pairs(playerScores) do
        if score > max then
            max = score
            winner = plr
        end
    end
    WeaponsMarket:AwardCash(winner, 200)

    -- Intermission:
    countdown.Value = 15
    for i = countdown.Value, 0, -1 do
        countdown.Value = i
    end
end

return games