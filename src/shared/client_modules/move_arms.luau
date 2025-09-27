local RunService = game:GetService("RunService")

local ClientVariables = require(game.ReplicatedStorage.Shared.client_modules.ClientVariables)

local move_arms = {}

local RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("RemoteEvent")

while not ClientVariables.player.Character do task.wait() end
local originalRightC0 = ClientVariables.player.Character:WaitForChild("Torso"):WaitForChild("Right Shoulder").C0
local originalLeftC0 = ClientVariables.player.Character:WaitForChild("Torso"):WaitForChild("Left Shoulder").C0
local offset = CFrame.new(0, 0, -2)
local event = nil
local eventPlaying = false -- we want to know when an event is playing so when we stop doing the move-arms stuff, the event doesn't run after the disconnect stuff runs.

function move_arms.activate()
    local torso = ClientVariables.player.Character:WaitForChild("Torso")
    event = RunService.RenderStepped:Connect(function() -- runs every frame
        eventPlaying = true
        local screenCenter = game.Workspace.CurrentCamera.ViewportSize / 2
        ClientVariables.ray = game.Workspace.CurrentCamera:ViewportPointToRay(screenCenter.X, screenCenter.Y)
        
		local rightX, rightY, rightZ = torso:WaitForChild("Right Shoulder").C0:ToEulerAnglesYXZ() -- Get each angle (x,y,z) seperately of the Right Shoulder Motor6D in YXZ order and store in these three variables
		torso:WaitForChild("Right Shoulder").C0 = ( torso:WaitForChild("Right Shoulder").C0 * CFrame.Angles(-rightX,0,0) ) * CFrame.Angles(math.asin(ClientVariables.ray.Direction.Y)/1.5,0,0) -- This code runs every frame. First, we multiply the value of Right
		-- Shoulder's C0 value to itself, then on top of that we multiply the negative (-) xAngle because multiplying an angle to itself every frame will make the arm spin, so we counter that with the negative of that. Finally, here comes our trig code. We multiply whatever we did
		-- before to the asin of the mouse position in the 3D world. We take that position, and get the Y unit of it because we're only interested in getting a single number, not an entire Vector3. We leave the rest of the CFrame.Angles() function at 0 because we're only interested
		-- in multiplying this Y-Value of the mouse position.
	
		torso:WaitForChild("Left Shoulder").C0 = torso["Right Shoulder"].C0 * offset * CFrame.Angles(0,math.rad(180),0) -- I set the Left Shoulders' C0 to be equal to the Right Shoulders' C0 times an offset, which left the arm facing the opposite direction, so I rotate the
																														-- Y- coordinate by 180 degrees to turn it around. Then the arm needed slightly adjusted, which was solved thanks to the offset, which I brute-forced until
																								                    	-- it looked right
        RemoteEvent:FireServer("move_arms", {RightC0 = torso:WaitForChild("Right Shoulder").C0, LeftC0 = torso:WaitForChild("Left Shoulder").C0})
		-- MARE:FireServer(torso:WaitForChild("Right Shoulder").C0, torso:WaitForChild("Left Shoulder").C0, ClientVariables.gunTool)
		-- ( torso:WaitForChild("Left Shoulder").C0 * CFrame.Angles(-leftX,0,0) ) * CFrame.Angles(math.asin((-mouse.Hit.Position - -mouse.Origin.Position).Unit.Y),0,0)
        eventPlaying = false
    end)
end

function move_arms.deactivate()
    local torso = ClientVariables.player.Character:WaitForChild("Torso")
    if event then event:Disconnect() end
    while eventPlaying do task.wait() end
    task.wait(0.1)

	torso:WaitForChild("Right Shoulder").C0 = originalRightC0
	torso:WaitForChild("Left Shoulder").C0 = originalLeftC0
    RemoteEvent:FireServer("move_arms", {RightC0 = originalRightC0, LeftC0 = originalLeftC0})
end

return move_arms