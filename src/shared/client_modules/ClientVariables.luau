local ClientVariables = {}

ClientVariables.player = game:GetService("Players").LocalPlayer

ClientVariables.Gun_GUI = ClientVariables.player.PlayerGui:WaitForChild("Gun_GUI")
ClientVariables.Main_Display = ClientVariables.Gun_GUI:WaitForChild("Main_Display")

ClientVariables.reloadingCursor = "rbxasset://textures/GunWaitCursor.png"
ClientVariables.gunCursor = "rbxasset://textures/GunCursor.png"

return ClientVariables