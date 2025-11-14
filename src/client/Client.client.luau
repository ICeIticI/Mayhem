local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")


-- Do some important character stuff before calling in modules:
local EmbersParticles = ReplicatedStorage.EmbersParticles
EmbersParticles.Parent = Workspace

local fogWalls = Workspace:WaitForChild("walls")
while #fogWalls:GetChildren() < 4 do task.wait() end

for _, wall in pairs(fogWalls:GetChildren()) do
    local ParticleEmitter = Instance.new("ParticleEmitter")
    ParticleEmitter.Color = ColorSequence.new(Color3.fromRGB(68,64,46))
    ParticleEmitter.LightEmission = 0.8
    ParticleEmitter.LightInfluence = 0
    ParticleEmitter.Size = NumberSequence.new(10,20)
    ParticleEmitter.Texture = "rbxassetid://258128463"

    ParticleEmitter.EmissionDirection = Enum.NormalId.Top
    ParticleEmitter.Lifetime = NumberRange.new(8,12)
    ParticleEmitter.Rate = 200
    ParticleEmitter.Speed = NumberRange.new(2,6)
    ParticleEmitter.Parent = wall
end

local ModuleLoader = require(ReplicatedStorage.Shared.ModuleLoader)
ModuleLoader.init()

ModuleLoader.Seasonal.init()
ModuleLoader.ClientVariables.init()
ModuleLoader.invite_friends.init()
ModuleLoader.client_events.init()
ModuleLoader.shopManager.init()
task.spawn(function()
    ModuleLoader.move_arms.init()
end)

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local camera = workspace.CurrentCamera
local isHolding = false
ModuleLoader.ClientVariables.menuMusic = ModuleLoader.utilities.createInstance("Sound", {Name = "menuMusic", SoundId = "rbxassetid://1837808628", Looped = true, Parent = game:GetService("SoundService")})

local PlayScreenFocus = game:GetService("Workspace"):WaitForChild("PlayScreenFocus")
-- Mirosoft Copilot object-circling code cause idk how to do it:

local center = PlayScreenFocus.Position -- center of the circle
local radius = 100
local speed = 0.1 -- radians per second
local angle = 0

RunService.Heartbeat:Connect(function(dt)
	angle += speed * dt
	local x = math.cos(angle) * radius
	local z = math.sin(angle) * radius
	PlayScreenFocus.Position = center + Vector3.new(x, 0, z)
end)



-- Change UI parent based on if the gun is equipped or not:

local function onChildChanged(child)
    if child:IsA("Tool") and child:GetAttribute("Gun") then
        if child.Parent == ModuleLoader.ClientVariables.player.Backpack or child.Parent == ModuleLoader.ClientVariables.player.Character then
            -- equipped weapon
            ModuleLoader.ClientVariables.gunTool = child
            ModuleLoader.shopManager.buttons[child.Name]:SwapParents(true)

            if child.Parent == ModuleLoader.ClientVariables.player.Character and ModuleLoader.ClientVariables.player.Character.Parent then
                ModuleLoader.move_arms.activate()
            else
                ModuleLoader.move_arms.deactivate()
            end
        else
            warn("Unequip")
            ModuleLoader.shopManager.buttons[child.Name]:SwapParents(false)
        end
    end
end

local function startInputToServer(inputTable, gameProcessedEvent) -- sends to the server our input and where we're firing at
    local screenCenter = camera.ViewportSize / 2
    ModuleLoader.ClientVariables.ray = camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
    RemoteEvent:FireServer("inputStarted", {input = inputTable, gameProcessedEvent = gameProcessedEvent, ray = ModuleLoader.ClientVariables.ray})

end

local function onCharacterAdded(character)
    -- ModuleLoader.ClientVariables.camera.CameraSubject = game:GetService("Workspace"):WaitForChild("PlayScreenFocus")
    -- ModuleLoader.ClientVariables.camera.CameraType = Enum.CameraType.Orbital
    -- ModuleLoader.ClientVariables.Gun_GUI:WaitForChild("PlayButton").Visible = true
    -- ModuleLoader.ClientVariables.Gun_GUI.Game_Title.Visible = true
    ModuleLoader.ClientVariables.Gun_GUI.ShopButton.Visible = true
    ModuleLoader.ClientVariables.Gun_GUI.Cash_Display.Visible = true
    ModuleLoader.ClientVariables.Gun_GUI.Kills_Display.Visible = true
    ModuleLoader.ClientVariables.Gun_GUI.InviteButton.Visible = true
    ModuleLoader.ClientVariables.Gun_GUI.round_leaderboard.Visible = false

    ModuleLoader.ClientVariables.menuMusic:Play()

    local onChildAddedConnect, onChildRemovedConnect
    local parent = ModuleLoader.ClientVariables.player.Backpack
    onChildAddedConnect = parent.ChildAdded:Connect(function(child)
        parent:WaitForChild(child.Name)
        onChildChanged(child)
    end)
    onChildRemovedConnect = parent.ChildRemoved:Connect(function(child)
        onChildChanged(child)
    end)

    local diedConnect
    diedConnect = ModuleLoader.ClientVariables.player.Character.Humanoid.Died:Connect(function()
        diedConnect:Disconnect()
        onChildAddedConnect:Disconnect()
        onChildRemovedConnect:Disconnect()
    end)
end

if ModuleLoader.ClientVariables.player.Character then
    onCharacterAdded(ModuleLoader.ClientVariables.player.Character)
end
ModuleLoader.ClientVariables.player.CharacterAdded:Connect(function(character)
    onCharacterAdded(character)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    local inputType = ModuleLoader.utilities.checkInput(input)
    if not inputType then return end

    local inputTable = {} -- Because the server wont let us send the input object, we need to create a table representing input that are strings
    inputTable.UserInputType = input.UserInputType
    inputTable.KeyCode = input.KeyCode

    if gameProcessedEvent then return end
    
    if inputType == "ShootInputs" then
        if ModuleLoader.ClientVariables.gunTool and (not ModuleLoader.ClientVariables.gunTool:WaitForChild("Values"):WaitForChild("shootDebounce").Value or not ModuleLoader.ClientVariables.gunTool.Values.IsFullAuto.Value) and ModuleLoader.ClientVariables.gunTool.Activated then
            isHolding = true
            if ModuleLoader.ClientVariables.gunTool.Values.IsFullAuto.Value then
                while isHolding and ModuleLoader.ClientVariables.gunTool.Equipped do
                    startInputToServer(inputTable, gameProcessedEvent)
                    task.wait()
                end
            else
                startInputToServer(inputTable, gameProcessedEvent)
            end
        end
    else
        RemoteEvent:FireServer("inputStarted", {input = inputTable, gameProcessedEvent = gameProcessedEvent})
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
    local inputType = ModuleLoader.utilities.checkInput(input)
    if not inputType then return end
    
    local inputTable = {} -- Because the server wont let us send the input object, we need to create a table representing input that are strings
    inputTable.UserInputType = input.UserInputType
    inputTable.KeyCode = input.KeyCode

    if inputType == "ShootInputs" then
        isHolding = false
    elseif inputType == "SprintInputs" then
        RemoteEvent:FireServer("inputEnded", {input = inputTable, gameProcessedEvent = gameProcessedEvent})
    end
end)

ModuleLoader.ClientVariables.gunTool = ModuleLoader.utilities.FindChildByAttributes(ModuleLoader.ClientVariables.player.Backpack, {Gun = true})

ModuleLoader.ClientVariables.Gun_GUI.PlayButton.Visible = true
ModuleLoader.ClientVariables.Gun_GUI.Game_Title.Visible = true

ModuleLoader.ClientVariables.Gun_GUI.PlayButton.Activated:Connect(function()
    ModuleLoader.ClientVariables.camera.CameraSubject = ModuleLoader.ClientVariables.player.Character:WaitForChild("Humanoid")
    ModuleLoader.ClientVariables.camera.CameraType = Enum.CameraType.Custom
    
    ModuleLoader.ClientVariables.Gun_GUI.PlayButton.Visible = false
    ModuleLoader.ClientVariables.Gun_GUI.Game_Title.Visible = false
    ModuleLoader.ClientVariables.Gun_GUI.ShopButton.Visible = false
    ModuleLoader.ClientVariables.Gun_GUI.shop_frame.Visible = false
    ModuleLoader.ClientVariables.Gun_GUI.Cash_Display.Visible = false
    ModuleLoader.ClientVariables.Gun_GUI.Kills_Display.Visible = false
    ModuleLoader.ClientVariables.Gun_GUI.InviteButton.Visible = false
    ModuleLoader.ClientVariables.Gun_GUI.round_leaderboard.Visible = true

    ModuleLoader.ClientVariables.menuMusic:Stop()
    
    RemoteEvent:FireServer("play")

end)