local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(ReplicatedStorage.Shared.Constants)
local BotAI = require(script.Parent.BotAI)

local function ensureBot()
	local bot = workspace:FindFirstChild("SoccerBot")
	if bot and bot:IsA("Model") and bot:FindFirstChildOfClass("Humanoid") then return bot end
	-- Spawn a simple R15 dummy
	bot = Instance.new("Model")
	bot.Name = "SoccerBot"
	local hrp = Instance.new("Part"); hrp.Name = "HumanoidRootPart"; hrp.Size = Vector3.new(2,2,1); hrp.Anchored = false; hrp.CanCollide = false; hrp.Parent = bot
	local hum = Instance.new("Humanoid"); hum.Parent = bot
	bot.PrimaryPart = hrp
	bot.Parent = workspace
	bot:PivotTo(CFrame.new(0, 5, -10))
	return bot
end

local bot = ensureBot()
local ai = BotAI.new(bot)

RunService.Heartbeat:Connect(function(dt)
	ai:step(dt)
end)

print("[Bot] BotController running (server authority)")
