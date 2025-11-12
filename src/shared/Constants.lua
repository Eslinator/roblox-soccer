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
}

return C
