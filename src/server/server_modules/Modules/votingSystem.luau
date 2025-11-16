-- Module that allows players to vote for things like gamemodes

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModuleLoader = require(ReplicatedStorage.Shared.ModuleLoader)

local votingSystem = {}

local RemoteEvent

function votingSystem.init()
    RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
    votingSystem.votingStations = Workspace.votingStations:GetChildren()
    votingSystem.votingOptions = {} -- table that holds a table for each gamemode-voting station, which holds indexes of each player that votes

    for i, station in pairs(votingSystem.votingStations) do
        
        -- register this voting station:
        votingSystem.votingOptions[i] = {} -- holds votes for each player
        station:SetAttribute("id", i)

        local selection = station.selection
        
        selection.Touched:Connect(function(touched)
            if not votingSystem.canVote then return end

            local playerWhoTouched = Players:GetPlayerFromCharacter(touched.Parent)
            if playerWhoTouched then
                -- A player touched this selection pad, they can vote

                -- make sure they haven't voted for the same thing already:
                if table.find(votingSystem.votingOptions[i], playerWhoTouched.UserId) then return end


                -- remove a previous vote, if any:
                for i2, _ in pairs(votingSystem.votingStations) do
                    local previousVoteIndex = table.find(votingSystem.votingOptions[i2], playerWhoTouched.UserId)
                    if previousVoteIndex then
                        table.remove(votingSystem.votingOptions[i2], previousVoteIndex)
                    end
                end

                -- register their new vote:
                table.insert(votingSystem.votingOptions[i], playerWhoTouched.UserId)
                RemoteEvent:FireAllClients("updateVotes", {votingOptions = votingSystem.votingOptions})
            end
        end)
    end
end

function votingSystem.activateVoting()

    -- clear votes:
    for _, option in pairs(votingSystem.votingOptions) do
        table.clear(option)
    end

    -- assigning actual meaning to the options:
    for i, station in pairs(votingSystem.votingStations) do
        -- gives as many options for players to vote for as there are stations. So if there are 3 stations, there are 3 options.
        local pickedValue = ModuleLoader.games.gamemodes[i]["gamemode_name"]
        station:SetAttribute("optionName", pickedValue)
    end

    RemoteEvent:FireAllClients("updateVotes", {votingOptions = votingSystem.votingOptions})
    votingSystem.canVote = true

end

function votingSystem.finishVoting()
    votingSystem.canVote = false
    local highestVoteCount = 0
    local mostPopularOption

    for i, voteOption in pairs(votingSystem.votingOptions) do
        if #voteOption > highestVoteCount then
            mostPopularOption = i
        end
    end

    if not mostPopularOption then return nil end
    return votingSystem.votingStations[mostPopularOption]:GetAttribute("optionName")
end

return votingSystem