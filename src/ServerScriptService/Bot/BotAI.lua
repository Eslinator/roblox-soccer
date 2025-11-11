local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage.Shared.Constants)

local BotAI = {}
BotAI.__index = BotAI

local function getBall()
	local b = workspace:FindFirstChild("Ball")
	if b and b:IsA("BasePart") then return b end
	return nil
end

local function distance(a: Vector3, b: Vector3)
	return (a - b).Magnitude
end

function BotAI.new(model: Model)
	local self = setmetatable({}, BotAI)
	self.model = model
	self.hum = model:FindFirstChildOfClass("Humanoid")
	self.root = model:FindFirstChild("HumanoidRootPart")
	self._accum = 0
	self._retarget = 0
	return self
end

function BotAI:step(dt)
	if not self.hum or not self.root then return end
	self._accum = self._accum + dt
	self._retarget = self._retarget + dt
	if self._accum < Constants.BOT.TICK then return end
	self._accum = 0

	local ball = getBall()
	if not ball then return end

	local botPos = self.root.Position
	local ballPos = ball.Position
	local dist = distance(botPos, ballPos)

	-- Predictive intercept: estimate where the ball will be shortly
	local ballVel = ball.AssemblyLinearVelocity or Vector3.zero
	local botSpeed = Constants.BOT.MAX_SPEED
	local t = math.clamp(dist / math.max(botSpeed, 0.01), 0.2, 0.8)
	local predicted = ballPos + ballVel * t

	-- Move toward predicted intercept point until in kick range
	if (botPos - ballPos).Magnitude > Constants.BOT.KICK_RANGE then
		self.hum.WalkSpeed = botSpeed
		self.hum:MoveTo(predicted)
		return
	end

	-- Kick/dribble on contact range (server authority)
	local dir = (ballPos - botPos)
	if dir.Magnitude <= 0 then return end
	dir = dir.Unit
	local power = Constants.BOT.KICK_POWER
	local goalDir = (Constants.AWAY_GOAL_POS - ballPos).Unit
	local impulse = (dir + goalDir) * power
	local lv = Instance.new("LinearVelocity")
	lv.Name = "BotKickLV"
	lv.VectorVelocity = impulse
	lv.Attachment0 = nil
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.MaxForce = math.huge
	lv.Parent = ball
	game.Debris:AddItem(lv, 0.15)
end

return BotAI
