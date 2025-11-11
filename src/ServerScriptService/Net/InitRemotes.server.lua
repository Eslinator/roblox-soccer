local ReplicatedStorage = game:GetService "ReplicatedStorage"
local RateLimiter = require(script.Parent.RateLimiter)

local remotesFolder = ReplicatedStorage:FindFirstChild "Remotes" or Instance.new "Folder"
remotesFolder.Name = "Remotes"
remotesFolder.Parent = ReplicatedStorage

local function getOrCreateRemote(name, className)
    local r = remotesFolder:FindFirstChild(name)
    if not r then
        r = Instance.new(className)
        r.Name = name
        r.Parent = remotesFolder
    end
    return r
end

local ClientPing = getOrCreateRemote("ClientPing", "RemoteFunction")
local RequestJoin = getOrCreateRemote("RequestJoin", "RemoteFunction")
local KickBall = getOrCreateRemote("KickBall", "RemoteEvent")

ClientPing.OnServerInvoke = function(player, payload)
    if not RateLimiter:allowed(RateLimiter:getKey(player), "ClientPing", { calls = 3, per = 1 }) then
        return { ok = false, err = "rate_limited" }
    end
    return { ok = true, serverTime = os.clock(), echo = payload }
end

RequestJoin.OnServerInvoke = function(player)
    if not RateLimiter:allowed(RateLimiter:getKey(player), "RequestJoin", { calls = 2, per = 5 }) then
        return { ok = false, err = "rate_limited" }
    end
    return { ok = true }
end

KickBall.OnServerEvent:Connect(function(player, impulse)
    if not RateLimiter:allowed(RateLimiter:getKey(player), "KickBall", { calls = 4, per = 1 }) then
        return
    end
    -- server-side physics will apply kick later
end)

print "[Net] Remotes initialized."
