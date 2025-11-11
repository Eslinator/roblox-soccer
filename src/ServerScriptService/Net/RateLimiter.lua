local RateLimiter = {}

local DEFAULT_LIMITS = { calls = 10, per = 1 } -- 10 calls per second
local buckets = {} -- [key][name] = {calls, windowStart}

function RateLimiter:getKey(player)
    return player and ("p:" .. player.UserId) or "server"
end

function RateLimiter:allowed(key, name, limits)
    limits = limits or DEFAULT_LIMITS
    local now = os.clock()
    buckets[key] = buckets[key] or {}
    local b = buckets[key][name]
    if not b or now - b.windowStart >= limits.per then
        b = { calls = 0, windowStart = now }
        buckets[key][name] = b
    end
    if b.calls < limits.calls then
        b.calls += 1
        return true
    else
        return false
    end
end

return RateLimiter
