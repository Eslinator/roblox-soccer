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

C.UI = {
  Theme = "dark",
}

-- >>> New: bot tick rate used by BotAI
C.Bot = {
  TICK = 0.1,             -- seconds between AI updates (10 Hz)
}

return C
