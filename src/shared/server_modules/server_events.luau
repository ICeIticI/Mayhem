local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvent = ReplicatedStorage:WaitForChild("RemoteEvent")
local RemoteFunction = ReplicatedStorage:WaitForChild("RemoteFunction")

local function receiveServerEvent(protocol, data)
    
end

local function receiveServerInvoke(protocol, data)
    print("test")
end

RemoteEvent.OnServerEvent:Connect(receiveServerEvent)
RemoteFunction.OnServerInvoke = receiveServerInvoke

return 0