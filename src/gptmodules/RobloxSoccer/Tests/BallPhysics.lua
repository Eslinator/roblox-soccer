-- Ball Physics Test (client-aware)
-- If required on server: no-op. If client: show basic HUD + FPS monitor.

local RunService = game:GetService "RunService"
local ReplicatedStorage = game:GetService "ReplicatedStorage"
local GuiService = game:GetService "GuiService"
local Players = game:GetService "Players"

local M = { ok = true }

-- Server contexts should not run UI / LocalPlayer code
if not RunService:IsClient() then
    M.clientOnly = true
    return M
end

-- Safe inset (top-left / bottom-right)
local topLeftInset, _ = GuiService:GetGuiInset()
local safeX, safeY = topLeftInset.X, topLeftInset.Y

-- FPS EMA monitor
local fps = 60
local emaAlpha = 0.1
RunService.RenderStepped:Connect(function(dt)
    local currentFPS = 1 / math.max(dt, 1 / 240)
    fps = fps * (1 - emaAlpha) + currentFPS * emaAlpha
    if fps < 45 then
        warn("[BallPhysics] Low FPS:", math.floor(fps + 0.5))
    end
end)

-- Minimal HUD
local function createHUD()
    local player = Players.LocalPlayer
    if not player then
        return
    end
    local pg = player:WaitForChild "PlayerGui"

    local gui = Instance.new "ScreenGui"
    gui.Name = "PerfHUD"
    gui.IgnoreGuiInset = true
    gui.Parent = pg

    local label = Instance.new "TextLabel"
    label.Name = "Stats"
    label.Size = UDim2.new(0, 260, 0, 36)
    label.Position = UDim2.new(0, safeX, 0, safeY)
    label.BackgroundTransparency = 0.35
    label.BackgroundColor3 = Color3.new(0, 0, 0)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Parent = gui

    RunService.Heartbeat:Connect(function()
        label.Text = string.format("FPS: %.1f", fps)
    end)
end

createHUD()

return M
