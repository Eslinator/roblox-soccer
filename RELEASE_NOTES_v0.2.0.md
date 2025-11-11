# Roblox Soccer v0.2.0

## Highlights
- Server-authority bot: seek, intercept, kick/dribble
- Ball spawner & basic match timer
- Rate-limited remotes (Ping/Join/KickBall)
- CI: Selene lint + Rojo build artifact on PR/push

## Tech
- Rojo 7.6.1 build
- rbxcloud 0.17.0 preflight green
- Aftman ecosystem in repo

## Known
- Stylua disabled pending Luau-friendly build
- Bot AI: basic intercept; no team strategy yet

## Rollback
- `git revert` commits from branch `bot/setup-connector` or redeploy v0.1.0 tag
