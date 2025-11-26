local invite_friends = {}

local ModuleLoader

function invite_friends.init()
    local SocialService = game:GetService("SocialService")
    
    ModuleLoader = require(game:GetService("ReplicatedStorage").Shared.ModuleLoader)

    
    local inviteDebounce = false -- makes sure invites cant be spam-sent.
    
    ModuleLoader.ClientVariables.Gun_GUI.InviteButton.Activated:Connect(function()
        if not inviteDebounce then
            inviteDebounce = true
            local canInvite = SocialService:CanSendCallInviteAsync(ModuleLoader.ClientVariables.player)
            if canInvite then
                print(canInvite)
                SocialService:PromptGameInvite(ModuleLoader.ClientVariables.player)
                task.wait(1)
                inviteDebounce = false
            elseif not canInvite then
                ModuleLoader.ClientVariables.Gun_GUI.InviteButton.Text = "Failed to invite friend!"
                task.wait(5)
                inviteDebounce = false
                ModuleLoader.ClientVariables.Gun_GUI.InviteButton.Text = "Invite Friends"
            end
        end
    end)
end

return invite_friends