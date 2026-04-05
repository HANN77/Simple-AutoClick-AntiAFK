-- Simple Auto Clicker By Antigravity
-- Hide GUI: Left or Right Shift
-- Start/Stop Toggle: F

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local VirtualUser = game:GetService("VirtualUser")

-- Clean up any previous execution to prevent duplicates
local guiName = "AFK_SimpleAutoclicker"
local existingGui = CoreGui:FindFirstChild(guiName)
if existingGui then
    existingGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = guiName
gui.ResetOnSpawn = false
-- Attempt to protect gui using syn.protect_gui if available (for executors like Synapse/Krnl)
pcall(function()
    if typeof(syn) == "table" and syn.protect_gui then
        syn.protect_gui(gui)
    end
end)
gui.Parent = CoreGui

-- Frame setup
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 140)
frame.Position = UDim2.new(0.5, -100, 0.5, -70)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

-- Add rounded corners
local corner1 = Instance.new("UICorner")
corner1.CornerRadius = UDim.new(0, 8)
corner1.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 12
title.Text = "Auto Clicker (Hide: Shift)"
title.Parent = frame

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 8)
corner2.Parent = title

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0.8, 0, 0, 35)
toggleBtn.Position = UDim2.new(0.1, 0, 0, 45)
toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 14
toggleBtn.Text = "Start [F]"
toggleBtn.Parent = frame

local corner3 = Instance.new("UICorner")
corner3.CornerRadius = UDim.new(0, 6)
corner3.Parent = toggleBtn

local intervalBox = Instance.new("TextBox")
intervalBox.Size = UDim2.new(0.8, 0, 0, 30)
intervalBox.Position = UDim2.new(0.1, 0, 0, 95)
intervalBox.Text = "5"
intervalBox.PlaceholderText = "Interval (s)"
intervalBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
intervalBox.TextColor3 = Color3.fromRGB(255, 255, 255)
intervalBox.Font = Enum.Font.Gotham
intervalBox.TextSize = 14
intervalBox.Parent = frame

local corner4 = Instance.new("UICorner")
corner4.CornerRadius = UDim.new(0, 6)
corner4.Parent = intervalBox

-- Draggable Logic
local dragging = false
local dragInput, dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Clicker State
local isEnabled = false
local interval = 5

local function toggleAutoClicker()
    isEnabled = not isEnabled
    if isEnabled then
        toggleBtn.Text = "Stop [F]"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 60)
    else
        toggleBtn.Text = "Start [F]"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end

toggleBtn.MouseButton1Click:Connect(toggleAutoClicker)

intervalBox.FocusLost:Connect(function()
    local val = tonumber(intervalBox.Text)
    if val and val > 0 then
        interval = val
    else
        intervalBox.Text = tostring(interval)
    end
end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    -- Ignore if typing in chat, UNLESS we are specifically tying to hide the UI which shouldn't interfere with chat typing
    local typing = gameProcessed and UserInputService:GetFocusedTextBox() ~= nil
    
    if input.KeyCode == Enum.KeyCode.F and not typing then
        toggleAutoClicker()
    elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
        -- We allow shift to hide UI even if typing just to be safe, or you can restrict it
        gui.Enabled = not gui.Enabled
    end
end)

-- Autoclicker Loop
task.spawn(function()
    while true do
        if isEnabled then
            local cam = workspace.CurrentCamera
            if cam then
                -- Get screen center dynamically
                local center = cam.ViewportSize / 2
                
                -- Simulate Mouse Left Click Down + Up at center of screen.
                -- This uses Roblox's internal input mechanism so the OS cursor isn't hijacked.
                VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
                task.wait(0.02)
                VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
            end
            task.wait(interval)
        else
            task.wait(0.1)
        end
    end
end)

-- Anti-AFK Hook
-- Prevents Roblox from disconnecting you for inactivity after 20 minutes
local LocalPlayer = Players.LocalPlayer
if LocalPlayer then
    LocalPlayer.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new()) 
    end)
end
