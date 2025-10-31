--[[

* Service that plays animations securely and 
efficiently.
* Sends the client animations that need to be created
and played
* Server overhauls the AnimationMarkers that would
normally be used to track animation events, as doing
that on the client is insecure. Instead the server
manually waits for when these events would happen
and execute code accordingly.

]]

local ModuleLoader

local AnimationService_Server = {}
AnimationService_Server.__index = AnimationService_Server

local ReplicatedStorage
local RemoteEvent

-- run to initialize this service
function AnimationService_Server.init()
    ReplicatedStorage = game:GetService("ReplicatedStorage")
    ModuleLoader = require(ReplicatedStorage.Shared.ModuleLoader)
    RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
end

-- This will run for every animation called inside .setupAnimations()
function AnimationService_Server.newAnimation(plr, animation)
    local newAnimation = {}
    newAnimation.isPlaying = false
    newAnimation.name = animation.Name
    newAnimation.animationId = animation.AnimationId

    function newAnimation:PlayAnimation()
        RemoteEvent:FireClient(plr, "playAnimation", {animName = self.name})
        self.isPlaying = true
    end

    function newAnimation:StopAnimation()
        RemoteEvent:FireClient(plr, "stopAnimation", {animName = self.name})
        self.isPlaying = false
    end

    return newAnimation
end

-- on a table of animations, send it to this function to set them up for this service
function AnimationService_Server.setupAnimations(plr, animations : table)
    local animTbl = {}
    for _, animation in pairs(animations) do
        animTbl[animation.Name] = AnimationService_Server.newAnimation(plr, animation)
    end

    RemoteEvent:FireClient(plr, "setupAnimations", {animationIds = ModuleLoader.utilities.getPropertyList(animTbl, "animationId")})
    return animTbl
end

return AnimationService_Server