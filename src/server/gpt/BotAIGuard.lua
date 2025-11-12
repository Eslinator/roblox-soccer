-- ServerScriptService/Game/gpt/BotAIGuard.lua
-- Purpose: read ReplicatedStorage.Shared.Constants if present, but always return safe defaults.

local RS = game:GetService("ReplicatedStorage")

local ok, C = pcall(function()
	return require(RS.Shared.Constants)
end)

-- Normalize both styles: C.Bot and C.BOT
local Bot = ok and (C.Bot or C.BOT) or nil

local Guard = {
	-- Tick rate
	TICK = (Bot and Bot.TICK) or 0.10, -- 10 Hz fallback

	-- Movement & kick defaults (can be overridden in Constants)
	MAX_SPEED  = (Bot and Bot.MAX_SPEED)  or 16,  -- studs/s
	KICK_RANGE = (Bot and Bot.KICK_RANGE) or 6,   -- studs
	KICK_POWER = (Bot and Bot.KICK_POWER) or 120,

	-- Goal position
	AWAY_GOAL_POS = (ok and C.AWAY_GOAL_POS) or Vector3.new(0, 6, 200),
}

return Guard
