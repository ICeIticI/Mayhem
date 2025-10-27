local invite_friends = {}

function invite_friends.init()
    print("eee")
    local SocialService = game:GetService("SocialService")
    local StarterPlayer = game:GetService("StarterPlayer")
    
    local client_modules = StarterPlayer.StarterPlayerScripts.Client.client_modules
    
    local ClientVariables = require(client_modules.ClientVariables)
    
    local inviteDebounce = false -- makes sure invites cant be spam-sent.
    
    ClientVariables.Gun_GUI.InviteButton.Activated:Connect(function()
        if not inviteDebounce then
            inviteDebounce = true
            local canInvite = SocialService:CanSendCallInviteAsync(ClientVariables.player)
            if canInvite then
                print(canInvite)
                SocialService:PromptGameInvite(ClientVariables.player)
                task.wait(1)
                inviteDebounce = false
            elseif not canInvite then
                ClientVariables.Gun_GUI.InviteButton.Text = "Failed to invite friend!"
                task.wait(5)
                inviteDebounce = false
                ClientVariables.Gun_GUI.InviteButton.Text = "Invite Friends"
            end
        end
    end)
end

return invite_friends