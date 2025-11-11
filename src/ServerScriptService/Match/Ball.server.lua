local function ensureBall()
    local ball = workspace:FindFirstChild "Ball"
    if ball and ball:IsA "BasePart" then
        return ball
    end
    ball = Instance.new "Part"
    ball.Name = "Ball"
    ball.Shape = Enum.PartType.Ball
    ball.Size = Vector3.new(2, 2, 2)
    ball.Material = Enum.Material.SmoothPlastic
    ball.Color = Color3.fromRGB(245, 245, 245)
    ball.Massless = false
    ball.CanCollide = true
    ball.CastShadow = true
    ball.Position = Vector3.new(0, 6, 0)
    ball.Parent = workspace
    -- Physics helpers
    local as = Instance.new "Attachment"
    as.Name = "BallAttachment"
    as.Parent = ball
    local lv = Instance.new "LinearVelocity"
    lv.Name = "DampenLV"
    lv.Attachment0 = as
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.MaxForce = 0
    lv.Parent = ball
    return ball
end

local ball = ensureBall()
print("[Match] Ball ready at", ball.Position)
