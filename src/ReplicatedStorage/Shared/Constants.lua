local Constants = {}

Constants.FIELD_CENTER = Vector3.new(0,0,0)
Constants.HOME_GOAL_POS = Vector3.new(-150,5,0)
Constants.AWAY_GOAL_POS = Vector3.new(150,5,0)

Constants.BOT = {
	TICK = 0.10,
	MAX_SPEED = 18,
	CHASE_RADIUS = 300,
	KICK_RANGE = 7.5,
	KICK_POWER = 60,
	DRIBBLE_POWER = 18,
	RETARGET_SEC = 0.5,
}

return Constants
