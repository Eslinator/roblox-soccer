-- ServerScriptService/Game/00_InitMatchState.server.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local matchState = ReplicatedStorage:FindFirstChild("MatchState")
if not matchState then
    matchState = Instance.new("Folder")
    matchState.Name = "MatchState"
    matchState.Parent = ReplicatedStorage
end

local function ensureInt(name, default)
    local v = matchState:FindFirstChild(name)
    if not v then
        v = Instance.new("IntValue")
        v.Name = name
        v.Value = default
        v.Parent = matchState
    end
    return v
end

local function ensureString(name, default)
    local v = matchState:FindFirstChild(name)
    if not v then
        v = Instance.new("StringValue")
        v.Name = name
        v.Value = default
        v.Parent = matchState
    end
    return v
end

ensureInt("TimeLeft", 300)
ensureInt("HomeScore", 0)
ensureInt("AwayScore", 0)
ensureString("Phase", "PreGame")

print(("[MatchState init] TimeLeft=%d Home=%d Away=%d Phase=%s")
    :format(matchState.TimeLeft.Value, matchState.HomeScore.Value, matchState.AwayScore.Value, matchState.Phase.Value))
