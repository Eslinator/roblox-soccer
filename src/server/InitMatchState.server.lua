local ReplicatedStorage = game:GetService("ReplicatedStorage")

local matchState = ReplicatedStorage:FindFirstChild("MatchState")
if not matchState then
	matchState = Instance.new("Folder")
	matchState.Name = "MatchState"
	matchState.Parent = ReplicatedStorage
end

local function ensureInt(name: string, default: number)
	local v = matchState:FindFirstChild(name) :: IntValue?
	if not v then
		v = Instance.new("IntValue")
		v.Name = name
		v.Value = default
		v.Parent = matchState
	end
	return v
end

local function ensureString(name: string, default: string)
	local v = matchState:FindFirstChild(name) :: StringValue?
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
