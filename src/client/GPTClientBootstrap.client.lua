-- Auto-load every GPT module on the client.
local RS = game:GetService("ReplicatedStorage")
local folder = RS:FindFirstChild("GPTModules")
if not folder then return end

local function loadModule(mod)
    if mod:IsA("ModuleScript") then
        local ok, result = pcall(require, mod)
        if ok and type(result) == "table" then
            if type(result.init) == "function" then
                pcall(result.init, RS)
            end
        else
            warn("[GPTClientBootstrap] require failed:", mod.Name, result)
        end
    end
end

for _, child in ipairs(folder:GetChildren()) do
    loadModule(child)
end

folder.ChildAdded:Connect(loadModule) -- hot-load new modules while Studio runs
print("[GPTClientBootstrap] ready")
