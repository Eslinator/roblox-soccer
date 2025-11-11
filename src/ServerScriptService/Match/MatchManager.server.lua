local ReplicatedStorage = game:GetService("ReplicatedStorage")

local REMOTES = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
REMOTES.Name = "Remotes"; REMOTES.Parent = ReplicatedStorage

local MatchStateChanged = REMOTES:FindFirstChild("MatchStateChanged") or Instance.new("RemoteEvent")
MatchStateChanged.Name = "MatchStateChanged"; MatchStateChanged.Parent = REMOTES

local StateFolder = ReplicatedStorage:FindFirstChild("MatchState") or Instance.new("Folder")
StateFolder.Name = "MatchState"; StateFolder.Parent = ReplicatedStorage

local function getValue(name, class, initial)
	local v = StateFolder:FindFirstChild(name)
	if not v then
		v = Instance.new(class)
		v.Name = name
		if class == "IntValue" then v.Value = initial or 0 end
		if class == "StringValue" then v.Value = initial or "Init" end
		StateFolder[name] = v; v.Parent = StateFolder
	end
	return v
end

local TimeLeft = getValue("TimeLeft","IntValue", 180) -- 3 minutes
local HomeScore = getValue("HomeScore","IntValue", 0)
local AwayScore = getValue("AwayScore","IntValue", 0)
local Phase = getValue("Phase","StringValue", "Init")

local running = false

local function setPhase(p)
	Phase.Value = p
	MatchStateChanged:FireAllClients({ phase = p, timeLeft = TimeLeft.Value, home = HomeScore.Value, away = AwayScore.Value })
	print("[Match] Phase:", p)
end

local function start()
	running = true
	setPhase("Playing")
	while running do
		if TimeLeft.Value > 0 then
			TimeLeft.Value -= 1
			if TimeLeft.Value % 10 == 0 then
				MatchStateChanged:FireAllClients({ phase = Phase.Value, timeLeft = TimeLeft.Value })
				print("[Match] TimeLeft:", TimeLeft.Value)
			end
			wait(1)
		else
			setPhase("Finished")
			running = false
		end
	end
end

-- Autostart shortly after server boot
spawn(function()
	wait(2)
	start()
end)
