local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MatchStateChanged = Remotes:WaitForChild("MatchStateChanged")
local ClientPing = Remotes:WaitForChild("ClientPing")

local screen = Instance.new("ScreenGui"); screen.Name = "MatchHUD"; screen.ResetOnSpawn = false; screen.Parent = player:WaitForChild("PlayerGui")
local label = Instance.new("TextLabel"); label.Size = UDim2.new(0, 420, 0, 28); label.Position = UDim2.new(0, 8, 0, 8)
label.BackgroundTransparency = 0.2; label.BackgroundColor3 = Color3.fromRGB(0,0,0); label.TextColor3 = Color3.fromRGB(255,255,255); label.Font = Enum.Font.GothamBold; label.TextSize = 18; label.Parent = screen

local state = { phase = "Init", timeLeft = 0, home = 0, away = 0 }
local function render()
	label.Text = string.format("%s | Time: %ds | Score %d - %d", state.phase, state.timeLeft, state.home, state.away)
end

MatchStateChanged.OnClientEvent:Connect(function(payload)
	for k,v in pairs(payload) do state[k] = v end
	render()
end)

-- Periodic ping to exercise rate-limited RemoteFunction
spawn(function()
	while true do
		local t0 = os.clock()
		local ok, res = pcall(function()
			return ClientPing:InvokeServer({ clientTime = t0 })
		end)
		if ok and res and res.ok then
			local rtt = (os.clock() - t0) * 1000
			label.Text = label.Text .. string.format(" | ping: %dms", rtt)
		end
		wait(5)
	end
end)

render()
-- HUD tweak to prove PR gates
