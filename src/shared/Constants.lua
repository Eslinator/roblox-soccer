-- ReplicatedStorage/Shared/Constants.lua
local C = {}

C.Match = {
  DefaultTime = 300,      -- seconds
  KickoffPhase = "PreGame",
}

C.Physics = {
  BallMaxSpeed = 150,
  BallDamping = 0.95,
}

C.UI = { Theme = "dark" }

-- Used by BotAI update loop
C.Bot = {
  TICK = 0.10,            -- 10 Hz bot tick
  MAX_SPEED = 16,
  KICK_RANGE = 6,
  KICK_POWER = 120,
}

-- Optional: add uppercase mirror so older code using C.BOT keeps working
C.BOT = {
  TICK = C.Bot.TICK,
  MAX_SPEED = C.Bot.MAX_SPEED,
  KICK_RANGE = C.Bot.KICK_RANGE,
  KICK_POWER = C.Bot.KICK_POWER,
}

C.AWAY_GOAL_POS = Vector3.new(0, 6, 200)

return C
