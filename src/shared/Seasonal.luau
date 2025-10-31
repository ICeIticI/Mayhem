--[[ 
    Module that handles seasonal events like Halloween
    or Christmas, so it can add decorations and stuff
    
    Will also replace the dog tags of "Kill Confirmed"
    for candies or presents for Halloween or Christmas.
]]
local Seasonal = {}

function Seasonal.init() -- singleton - runs once.

    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    local player = game:GetService("Players").LocalPlayer
    local ScreenGui = player.PlayerGui:WaitForChild("ScreenGui")


    local currentMonth = tonumber(os.date("%m")) -- returns what month number it is (ex. 10 for october).

    if currentMonth == 10 then -- Prepare halloween stuff

        ReplicatedStorage:WaitForChild("JackOLanterns").Parent = Workspace

        local Lighting = game:GetService("Lighting")
        local Atmosphere = Lighting.Atmosphere
        Atmosphere.Density = 0.544
        Atmosphere.Offset = 0.25
        
        Atmosphere.Color = Color3.fromRGB(125,40,0)
        Atmosphere.Decay = Color3.fromRGB(27,27,27)
        Atmosphere.Glare = 0.2
        Atmosphere.Haze = 10

        Lighting.Brightness = 6
        Lighting.TimeOfDay = "21:00:00"

        local Particles = Workspace:WaitForChild("EmbersParticles").ParticleEmitter
        Particles.Texture = "rbxassetid://244982565"

        Workspace:WaitForChild("Baseplate").Material = Enum.Material.LeafyGrass
        Workspace.Baseplate.Color = Color3.fromRGB(143,76,42)

        ScreenGui.Game_Title.Text = "🎃Mayhem🎃"
    end
end

return Seasonal