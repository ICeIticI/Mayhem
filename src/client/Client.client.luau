local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")


-- Do some important character stuff before calling in modules:
local EmbersParticles = ReplicatedStorage.EmbersParticles
EmbersParticles.Parent = Workspace

local fogWalls = Workspace:WaitForChild("walls")
while #fogWalls:GetChildren() < 4 do task.wait() end
print("yos")
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

local Seasonal = require(game.ReplicatedStorage.Shared.Seasonal)
Seasonal.init()

local ClientVariables = require(game.ReplicatedStorage.Shared.client_modules.ClientVariables)
require(game.ReplicatedStorage.Shared.client_modules.client_events)
local ShopManager = require(game.ReplicatedStorage.Shared.client_modules.shopManager)
local utilities = require(game.ReplicatedStorage.Shared.utilities)
local move_arms
task.spawn(function()
    move_arms = require(game.ReplicatedStorage.Shared.client_modules.move_arms)
end)

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local camera = workspace.CurrentCamera
local isHolding = false
ClientVariables.menuMusic = utilities.createInstance("Sound", {Name = "menuMusic", SoundId = "rbxassetid://87753640000210", Looped = true, Parent = game:GetService("SoundService")})

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
        if child.Parent == ClientVariables.player.Backpack or child.Parent == ClientVariables.player.Character then
            warn("Equip")
            -- equipped weapon
            ClientVariables.gunTool = child
            ShopManager.buttons[child.Name]:SwapParents(true)

            if child.Parent == ClientVariables.player.Character and ClientVariables.player.Character.Parent then
                move_arms.activate()
            else
                move_arms.deactivate()
            end
        else
            warn("Unequip")
            ShopManager.buttons[child.Name]:SwapParents(false)
        end
    end
end

local function startInputToServer(inputTable, gameProcessedEvent) -- sends to the server our input and where we're firing at
    local screenCenter = camera.ViewportSize / 2
    ClientVariables.ray = camera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
    RemoteEvent:FireServer("inputStarted", {input = inputTable, gameProcessedEvent = gameProcessedEvent, ray = ClientVariables.ray})

end

local function onCharacterAdded(character)
    ClientVariables.camera.CameraSubject = game:GetService("Workspace"):WaitForChild("PlayScreenFocus")
    ClientVariables.camera.CameraType = Enum.CameraType.Orbital
    ClientVariables.Gun_GUI:WaitForChild("PlayButton").Visible = true
    ClientVariables.Gun_GUI.Game_Title.Visible = true
    ClientVariables.Gun_GUI.ShopButton.Visible = true
    ClientVariables.Gun_GUI.Cash_Display.Visible = true
    ClientVariables.Gun_GUI.Kills_Display.Visible = true
    ClientVariables.Gun_GUI.round_leaderboard.Visible = false

    ClientVariables.menuMusic:Play()


    local onChildAddedConnect, onChildRemovedConnect
    local parent = ClientVariables.player.Backpack
    onChildAddedConnect = parent.ChildAdded:Connect(function(child)
        parent:WaitForChild(child.Name)
        onChildChanged(child)
    end)
    onChildRemovedConnect = parent.ChildRemoved:Connect(function(child)
        onChildChanged(child)
    end)

    local diedConnect
    diedConnect = ClientVariables.player.Character.Humanoid.Died:Connect(function()
        diedConnect:Disconnect()
        onChildAddedConnect:Disconnect()
        onChildRemovedConnect:Disconnect()
    end)
end

if ClientVariables.player.Character then
    onCharacterAdded(ClientVariables.player.Character)
end
ClientVariables.player.CharacterAdded:Connect(function(character)
    onCharacterAdded(character)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    local inputType = utilities.checkInput(input)
    if not inputType then return end

    local inputTable = {} -- Because the server wont let us send the input object, we need to create a table representing input that are strings
    inputTable.UserInputType = input.UserInputType
    inputTable.KeyCode = input.KeyCode

    if gameProcessedEvent then return end
    
    if inputType == "ShootInputs" then
        if ClientVariables.gunTool and (not ClientVariables.gunTool.Values.shootDebounce.Value or not ClientVariables.gunTool.Values.IsFullAuto.Value) and ClientVariables.gunTool.Activated then
            isHolding = true
            if ClientVariables.gunTool.Values.IsFullAuto.Value then
                while isHolding and ClientVariables.gunTool.Equipped do
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
    local inputType = utilities.checkInput(input)
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

ClientVariables.gunTool = utilities.FindChildByAttributes(ClientVariables.player.Backpack, {Gun = true})

ClientVariables.Gun_GUI.PlayButton.Visible = true
ClientVariables.Gun_GUI.Game_Title.Visible = true

ClientVariables.Gun_GUI.PlayButton.Activated:Connect(function()
    ClientVariables.camera.CameraSubject = ClientVariables.player.Character:WaitForChild("Humanoid")
    ClientVariables.camera.CameraType = Enum.CameraType.Custom
    
    ClientVariables.Gun_GUI.PlayButton.Visible = false
    ClientVariables.Gun_GUI.Game_Title.Visible = false
    ClientVariables.Gun_GUI.ShopButton.Visible = false
    ClientVariables.Gun_GUI.shop_frame.Visible = false
    ClientVariables.Gun_GUI.Cash_Display.Visible = false
    ClientVariables.Gun_GUI.Kills_Display.Visible = false
    ClientVariables.Gun_GUI.round_leaderboard.Visible = true

    ClientVariables.menuMusic:Stop()
    
    RemoteEvent:FireServer("play")

end)