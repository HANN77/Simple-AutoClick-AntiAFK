-- Simple Auto Clicker By FusedHann
-- Enhanced Edition v2.2

local SCRIPT_VERSION = "2.2"


-- ═══════════════════════════════════════════════════════════
-- Services
-- ═══════════════════════════════════════════════════════════
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService    = game:GetService("RunService")
local HttpService   = game:GetService("HttpService")

-- Safe service access — these services may not exist on all executors
local VirtualInputManager
pcall(function()
	VirtualInputManager = game:GetService("VirtualInputManager")
end)

local VirtualUser
pcall(function()
	VirtualUser = game:GetService("VirtualUser")
end)

-- ═══════════════════════════════════════════════════════════
-- Cleanup previous instance
-- ═══════════════════════════════════════════════════════════
local guiName = "AFK_SimpleAutoclicker_v2"
local existingGui = CoreGui:FindFirstChild(guiName)
if existingGui then
	existingGui:Destroy()
end
local existingNotifGui = CoreGui:FindFirstChild(guiName .. "_Notifs")
if existingNotifGui then
	existingNotifGui:Destroy()
end

-- ═══════════════════════════════════════════════════════════
-- State
-- ═══════════════════════════════════════════════════════════
local isEnabled = true
local interval = 5
local connections = {}        -- Track all connections for clean unload
local running = true          -- Master kill switch for loops
local unloading = false       -- Prevents race conditions during teardown

-- Keybind state (defaults)
local keybinds = {
	toggle = Enum.KeyCode.F,
	hide   = Enum.KeyCode.RightShift,
}
local waitingForBind = nil    -- "toggle" or "hide" when listening

-- Webhook state
local webhookUrl           = ""
local webhookEnabled       = false
local webhookHeartbeatMins = 5
local sessionStart         = tick()
local sessionClicks        = 0        -- track clicks for session stats
local isBeingKicked        = false    -- flag when kicked/disconnected

-- Discord embed colours (decimal RGB)
local DISCORD_GREEN  = 3329380   -- RGB( 50, 205, 100)
local DISCORD_RED    = 15418960  -- RGB(235,  70,  80)
local DISCORD_PURPLE = 7232255   -- RGB(110,  90, 255)
local DISCORD_ORANGE = 16752690  -- RGB(255, 160,  50)

-- ═══════════════════════════════════════════════════════════
-- Color Palette
-- ═══════════════════════════════════════════════════════════
local colors = {
	bg           = Color3.fromRGB(22, 22, 30),
	bgSecondary  = Color3.fromRGB(28, 28, 40),
	surface      = Color3.fromRGB(35, 35, 50),
	surfaceHover = Color3.fromRGB(45, 45, 62),
	accent       = Color3.fromRGB(110, 90, 255),    -- purple accent
	accentGlow   = Color3.fromRGB(140, 120, 255),
	green        = Color3.fromRGB(50, 205, 100),
	red          = Color3.fromRGB(235, 70, 80),
	orange       = Color3.fromRGB(255, 160, 50),
	textPrimary  = Color3.fromRGB(240, 240, 250),
	textMuted    = Color3.fromRGB(140, 140, 165),
	divider      = Color3.fromRGB(50, 50, 70),
}

-- ═══════════════════════════════════════════════════════════
-- Safe Click Helper (tries multiple methods, never crashes)
-- ═══════════════════════════════════════════════════════════
local function safeClick()
	-- Method 1: VirtualInputManager (preferred — works background)
	if VirtualInputManager then
		local ok = pcall(function()
			local cam = workspace.CurrentCamera
			if cam then
				local center = cam.ViewportSize / 2
				VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 1)
				task.wait(0.02)
				VirtualInputManager:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 1)
			end
		end)
		if ok then return end
	end

	-- Method 2: mouse1click (common executor function)
	if typeof(mouse1click) == "function" then
		pcall(mouse1click)
		return
	end

	-- Method 3: VirtualUser click (last resort)
	if VirtualUser then
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end
end

-- ═══════════════════════════════════════════════════════════
-- Discord Webhook Helper
-- ═══════════════════════════════════════════════════════════
local function sendWebhook(title, description, color, fields)
	if not webhookEnabled or webhookUrl == "" then return end
	task.spawn(function()
		local player   = Players.LocalPlayer
		local whoami   = player and player.Name or "AFK User"
		local gameName = game.Name ~= "" and game.Name or ("PlaceId: " .. tostring(game.PlaceId))

		local body
		local ok = pcall(function()
			body = HttpService:JSONEncode({
				username = "AFK Monitor",
				embeds   = {{
					title       = title,
					description = description,
					color       = color or DISCORD_PURPLE,
					fields      = fields or {},
					footer      = { text = "⚡ AutoClicker v" .. SCRIPT_VERSION .. "  •  " .. whoami .. "  •  " .. gameName },
				}},
			})
		end)
		if not ok or not body then return end

		-- Support multiple executor HTTP APIs
		pcall(function()
			local fn = (typeof(request)      == "function" and request)
				    or (typeof(http_request) == "function" and http_request)
				    or (typeof(syn) == "table" and typeof(syn.request) == "function" and syn.request)
			if fn then
				fn({ Url = webhookUrl, Method = "POST",
				     Headers = { ["Content-Type"] = "application/json" }, Body = body })
			end
		end)
	end)
end

local function formatDuration(secs)
	secs = math.floor(secs)
	local h = math.floor(secs / 3600)
	local m = math.floor((secs % 3600) / 60)
	local s = secs % 60
	if h > 0 then return string.format("%dh %dm", h, m)
	elseif m > 0 then return string.format("%dm %ds", m, s)
	else return string.format("%ds", s) end
end

-- ═══════════════════════════════════════════════════════════
-- Persistent Settings  (auto-save to executor workspace)
-- ═══════════════════════════════════════════════════════════
local CONFIG_FILE = "SimpleAFK_v2.json"

local function saveSettings()
	pcall(function()
		if typeof(writefile) ~= "function" then return end
		writefile(CONFIG_FILE, HttpService:JSONEncode({
			interval             = interval,
			webhookUrl           = webhookUrl,
			webhookEnabled       = webhookEnabled,
			webhookHeartbeatMins = webhookHeartbeatMins,
			toggleKey            = keybinds.toggle.Name,
			hideKey              = keybinds.hide.Name,
		}))
	end)
end

-- ═══════════════════════════════════════════════════════════
-- Helpers
-- ═══════════════════════════════════════════════════════════
local function tween(obj, props, duration, style, dir)
	local info = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(obj, info, props)
	t:Play()
	return t
end

local function addCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function addStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or colors.divider
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function addPadding(parent, t, b, l, r)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.PaddingLeft = UDim.new(0, l or 0)
	p.PaddingRight = UDim.new(0, r or 0)
	p.Parent = parent
	return p
end

local function keyName(keyCode)
	local name = keyCode.Name
	-- Make common names friendlier
	local friendly = {
		LeftShift = "L-Shift", RightShift = "R-Shift",
		LeftControl = "L-Ctrl", RightControl = "R-Ctrl",
		LeftAlt = "L-Alt", RightAlt = "R-Alt",
		BackSlash = "\\", Slash = "/",
		Semicolon = ";", Quote = "'",
		LeftBracket = "[", RightBracket = "]",
		Backquote = "`", Minus = "-", Equals = "=",
		Period = ".", Comma = ",",
	}
	return friendly[name] or name
end

-- ═══════════════════════════════════════════════════════════
-- Toast Notification System (single toast, overwrites itself)
-- ═══════════════════════════════════════════════════════════

-- Separate ScreenGui for notifications so they show even when main UI is hidden
local notifGui = Instance.new("ScreenGui")
notifGui.Name = guiName .. "_Notifs"
notifGui.ResetOnSpawn = false
notifGui.DisplayOrder = 999
notifGui.IgnoreGuiInset = true
notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
notifGui.Enabled = true
pcall(function()
	if typeof(syn) == "table" and syn.protect_gui then
		syn.protect_gui(notifGui)
	end
end)
notifGui.Parent = CoreGui

-- Single toast pill — reused every time
local toast = Instance.new("Frame")
toast.Name = "Toast"
toast.Size = UDim2.new(0, 180, 0, 26)
toast.Position = UDim2.new(1, -190, 0, 12)
toast.BackgroundColor3 = colors.bg
toast.BackgroundTransparency = 1
toast.BorderSizePixel = 0
toast.ClipsDescendants = true
toast.Visible = false
toast.Parent = notifGui
addCorner(toast, 6)
addStroke(toast, colors.divider, 1)

-- Accent dot
local dot = Instance.new("Frame")
dot.Name = "Dot"
dot.Size = UDim2.new(0, 6, 0, 6)
dot.Position = UDim2.new(0, 8, 0.5, -3)
dot.BackgroundColor3 = colors.accent
dot.BorderSizePixel = 0
dot.Parent = toast
addCorner(dot, 3)

-- Message label
local toastLabel = Instance.new("TextLabel")
toastLabel.Name = "Msg"
toastLabel.Size = UDim2.new(1, -24, 1, 0)
toastLabel.Position = UDim2.new(0, 20, 0, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.Text = ""
toastLabel.TextColor3 = colors.textPrimary
toastLabel.Font = Enum.Font.Gotham
toastLabel.TextSize = 11
toastLabel.TextXAlignment = Enum.TextXAlignment.Left
toastLabel.TextTruncate = Enum.TextTruncate.AtEnd
toastLabel.Parent = toast

local notifVersion = 0

local function notify(message, accentColor, duration)
	if not running and not unloading then return end

	accentColor = accentColor or colors.accent
	duration = duration or 2

	-- Bump version so any previous dismiss thread becomes stale
	notifVersion = notifVersion + 1
	local myVersion = notifVersion

	-- Update content in-place (single toast, no new instances)
	toastLabel.Text = message
	dot.BackgroundColor3 = accentColor
	toast.Visible = true

	-- Slide in
	toast.Position = UDim2.new(1, 20, 0, 12)
	toast.BackgroundTransparency = 0.5
	toastLabel.TextTransparency = 0.5
	dot.BackgroundTransparency = 0.5

	tween(toast, {Position = UDim2.new(1, -190, 0, 12), BackgroundTransparency = 0.05}, 0.25, Enum.EasingStyle.Quint)
	tween(toastLabel, {TextTransparency = 0}, 0.2)
	tween(dot, {BackgroundTransparency = 0}, 0.2)

	-- Schedule dismiss — only runs if no newer notification replaced this one
	task.spawn(function()
		task.wait(duration)
		if myVersion ~= notifVersion then return end -- a newer notify() was called, abort

		-- Safety: check objects still exist (could be destroyed during unload)
		pcall(function()
			if not toast or not toast.Parent then return end
			tween(toast, {Position = UDim2.new(1, 20, 0, 12), BackgroundTransparency = 1}, 0.25, Enum.EasingStyle.Quint)
			tween(toastLabel, {TextTransparency = 1}, 0.2)
			tween(dot, {BackgroundTransparency = 1}, 0.2)
			task.wait(0.3)
			if myVersion == notifVersion and toast and toast.Parent then
				toast.Visible = false
			end
		end)
	end)
end

-- ═══════════════════════════════════════════════════════════
-- GUI Construction
-- ═══════════════════════════════════════════════════════════
local gui = Instance.new("ScreenGui")
gui.Name = guiName
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
	if typeof(syn) == "table" and syn.protect_gui then
		syn.protect_gui(gui)
	end
end)
gui.Parent = CoreGui

-- Notification container already created above (in its own ScreenGui)

-- ── Main container ──
local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 240, 0, 0)  -- height set after build
mainFrame.Position = UDim2.new(0.5, -120, 0.5, -140)
mainFrame.BackgroundColor3 = colors.bg
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Active = true
mainFrame.Parent = gui
addCorner(mainFrame, 12)
addStroke(mainFrame, colors.accent, 1.5)

-- Subtle drop shadow via an image or just a secondary stroke
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 8, 1, 8)
shadow.Position = UDim2.new(0, -4, 0, -4)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.BorderSizePixel = 0
shadow.ZIndex = -1
shadow.Parent = mainFrame
addCorner(shadow, 14)

-- ── Title Bar ──
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 38)
titleBar.BackgroundColor3 = colors.bgSecondary
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame
addCorner(titleBar, 12)

-- Flatten bottom corners of title bar
local titleBarMask = Instance.new("Frame")
titleBarMask.Size = UDim2.new(1, 0, 0, 14)
titleBarMask.Position = UDim2.new(0, 0, 1, -14)
titleBarMask.BackgroundColor3 = colors.bgSecondary
titleBarMask.BorderSizePixel = 0
titleBarMask.Parent = titleBar

-- Accent line under title
local accentLine = Instance.new("Frame")
accentLine.Name = "AccentLine"
accentLine.Size = UDim2.new(0.6, 0, 0, 2)
accentLine.Position = UDim2.new(0.2, 0, 1, -1)
accentLine.BackgroundColor3 = colors.accent
accentLine.BorderSizePixel = 0
accentLine.Parent = titleBar
addCorner(accentLine, 1)

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -70, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚡ AutoClicker v" .. SCRIPT_VERSION
titleLabel.TextColor3 = colors.textPrimary
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 14
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

-- Status indicator dot in title bar
local statusDot = Instance.new("Frame")
statusDot.Name = "StatusDot"
statusDot.Size = UDim2.new(0, 8, 0, 8)
statusDot.Position = UDim2.new(1, -55, 0.5, -4)
statusDot.BackgroundColor3 = colors.red
statusDot.BorderSizePixel = 0
statusDot.Parent = titleBar
addCorner(statusDot, 4)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 35, 1, 0)
statusLabel.Position = UDim2.new(1, -42, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "OFF"
statusLabel.TextColor3 = colors.red
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = titleBar

-- ── Content area ──
local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, 0, 0, 250)
content.Position = UDim2.new(0, 0, 0, 40)
content.BackgroundTransparency = 1
content.Parent = mainFrame
addPadding(content, 8, 8, 12, 12)

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 6)
layout.Parent = content

-- Helper: section label
local function sectionLabel(text, order)
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 0, 16)
	lbl.BackgroundTransparency = 1
	lbl.Text = text
	lbl.TextColor3 = colors.textMuted
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 10
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.LayoutOrder = order
	lbl.Parent = content
	return lbl
end

-- Helper: standard button
local function makeButton(text, bgColor, order, height)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, height or 34)
	btn.BackgroundColor3 = bgColor
	btn.TextColor3 = colors.textPrimary
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.Text = text
	btn.AutoButtonColor = false
	btn.LayoutOrder = order
	btn.Parent = content
	addCorner(btn, 8)

	-- Hover effect
	btn.MouseEnter:Connect(function()
		tween(btn, {BackgroundColor3 = Color3.new(
			math.min(bgColor.R * 1.15, 1),
			math.min(bgColor.G * 1.15, 1),
			math.min(bgColor.B * 1.15, 1)
		)}, 0.15)
	end)
	btn.MouseLeave:Connect(function()
		tween(btn, {BackgroundColor3 = bgColor}, 0.15)
	end)

	return btn
end

-- ── Toggle Button ──
sectionLabel("CLICKER", 1)

local toggleBtn = makeButton("▶  Start", colors.accent, 2, 38)

local function updateToggleVisuals()
	if isEnabled then
		toggleBtn.Text = "■  Stop"
		tween(toggleBtn, {BackgroundColor3 = colors.green}, 0.3)
		tween(statusDot, {BackgroundColor3 = colors.green}, 0.3)
		tween(statusLabel, {TextColor3 = colors.green}, 0.3)
		statusLabel.Text = "ON"
	else
		toggleBtn.Text = "▶  Start"
		tween(toggleBtn, {BackgroundColor3 = colors.accent}, 0.3)
		tween(statusDot, {BackgroundColor3 = colors.red}, 0.3)
		tween(statusLabel, {TextColor3 = colors.red}, 0.3)
		statusLabel.Text = "OFF"
	end
end

-- ── Interval Row ──
sectionLabel("INTERVAL (SECONDS)", 3)

local intervalRow = Instance.new("Frame")
intervalRow.Size = UDim2.new(1, 0, 0, 32)
intervalRow.BackgroundTransparency = 1
intervalRow.LayoutOrder = 4
intervalRow.Parent = content

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 32, 1, 0)
minusBtn.Position = UDim2.new(0, 0, 0, 0)
minusBtn.BackgroundColor3 = colors.surface
minusBtn.TextColor3 = colors.textPrimary
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = 18
minusBtn.Text = "−"
minusBtn.AutoButtonColor = false
minusBtn.Parent = intervalRow
addCorner(minusBtn, 6)

local intervalBox = Instance.new("TextBox")
intervalBox.Size = UDim2.new(1, -72, 1, 0)
intervalBox.Position = UDim2.new(0, 36, 0, 0)
intervalBox.Text = tostring(interval)
intervalBox.PlaceholderText = "sec"
intervalBox.BackgroundColor3 = colors.surface
intervalBox.TextColor3 = colors.textPrimary
intervalBox.Font = Enum.Font.GothamBold
intervalBox.TextSize = 14
intervalBox.Parent = intervalRow
addCorner(intervalBox, 6)
addStroke(intervalBox, colors.divider, 1)

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 32, 1, 0)
plusBtn.Position = UDim2.new(1, -32, 0, 0)
plusBtn.BackgroundColor3 = colors.surface
plusBtn.TextColor3 = colors.textPrimary
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 18
plusBtn.Text = "+"
plusBtn.AutoButtonColor = false
plusBtn.Parent = intervalRow
addCorner(plusBtn, 6)

-- Interval logic
local function setInterval(val)
	val = math.clamp(math.floor(val * 10 + 0.5) / 10, 0.1, 999) -- 1 decimal, min 0.1
	interval = val
	intervalBox.Text = tostring(val)
	saveSettings()
end

minusBtn.MouseButton1Click:Connect(function()
	setInterval(interval - (interval > 1 and 1 or 0.1))
	notify("Interval: " .. tostring(interval) .. "s", colors.accent, 1.5)
end)
plusBtn.MouseButton1Click:Connect(function()
	setInterval(interval + (interval >= 1 and 1 or 0.1))
	notify("Interval: " .. tostring(interval) .. "s", colors.accent, 1.5)
end)
intervalBox.FocusLost:Connect(function()
	local val = tonumber(intervalBox.Text)
	if val and val > 0 then
		setInterval(val)
	else
		intervalBox.Text = tostring(interval)
	end
end)

-- ── Keybind Settings ──
sectionLabel("KEYBINDS", 5)

local function makeKeybindRow(label, bindKey, order)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 30)
	row.BackgroundTransparency = 1
	row.LayoutOrder = order
	row.Parent = content

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(0.5, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = label
	lbl.TextColor3 = colors.textMuted
	lbl.Font = Enum.Font.Gotham
	lbl.TextSize = 12
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.Parent = row

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.45, 0, 0, 26)
	btn.Position = UDim2.new(0.55, 0, 0, 2)
	btn.BackgroundColor3 = colors.surface
	btn.TextColor3 = colors.orange
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.Text = "[ " .. keyName(keybinds[bindKey]) .. " ]"
	btn.AutoButtonColor = false
	btn.Parent = row
	addCorner(btn, 6)
	addStroke(btn, colors.divider, 1)

	btn.MouseButton1Click:Connect(function()
		if waitingForBind then return end -- already waiting
		waitingForBind = bindKey
		btn.Text = "[ ... ]"
		btn.TextColor3 = colors.accentGlow
		tween(btn, {BackgroundColor3 = colors.surfaceHover}, 0.15)

		-- A single-fire listener
		local bindConn
		bindConn = UserInputService.InputBegan:Connect(function(input, gp)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			-- Don't allow Escape or Enter as binds
			if input.KeyCode == Enum.KeyCode.Escape then
				-- Cancel rebind
				btn.Text = "[ " .. keyName(keybinds[bindKey]) .. " ]"
				btn.TextColor3 = colors.orange
				tween(btn, {BackgroundColor3 = colors.surface}, 0.15)
				waitingForBind = nil
				bindConn:Disconnect()
				return
			end
			if input.KeyCode == Enum.KeyCode.Return then return end

			keybinds[bindKey] = input.KeyCode
			btn.Text = "[ " .. keyName(input.KeyCode) .. " ]"
			btn.TextColor3 = colors.orange
			tween(btn, {BackgroundColor3 = colors.surface}, 0.15)
			waitingForBind = nil
			bindConn:Disconnect()
			notify(label .. " → [ " .. keyName(input.KeyCode) .. " ]", colors.orange, 2)
			saveSettings()
		end)
	end)

	return btn
end

local toggleBindBtn = makeKeybindRow("Toggle", "toggle", 6)
local hideBindBtn = makeKeybindRow("Hide UI", "hide", 7)

-- ── Discord Webhook Section ──
sectionLabel("DISCORD WEBHOOK", 8)

local webhookToggleBtn = makeButton("🔕  Webhook OFF", colors.surface, 9, 30)
webhookToggleBtn.TextColor3 = colors.textMuted
webhookToggleBtn.TextSize   = 12

local updateWebhookToggleVisuals
updateWebhookToggleVisuals = function()
	if webhookEnabled then
		webhookToggleBtn.Text = "🔔  Webhook ON"
		tween(webhookToggleBtn, {BackgroundColor3 = colors.green}, 0.3)
		webhookToggleBtn.TextColor3 = colors.textPrimary
	else
		webhookToggleBtn.Text = "🔕  Webhook OFF"
		tween(webhookToggleBtn, {BackgroundColor3 = colors.surface}, 0.3)
		webhookToggleBtn.TextColor3 = colors.textMuted
	end
end

webhookToggleBtn.MouseButton1Click:Connect(function()
	if webhookUrl == nil or #webhookUrl == 0 then
		notify('Enter a Webhook URL first!', colors.red, 2)
		return
	end
	webhookEnabled = not webhookEnabled
	updateWebhookToggleVisuals()
	if webhookEnabled then
		sendWebhook(
			'🟢 AFK Monitor Active',
			'Script is live. You will receive heartbeat and status updates here.' ..
				'\n' ..
				'Heartbeat every **' .. webhookHeartbeatMins .. ' minutes**.',
			DISCORD_GREEN
		)
	else
		sendWebhook(
			'🔴 AFK Monitor Disabled',
			'The webhook has been **disabled** manually.\nHeartbeat updates will stop.',
			DISCORD_ORANGE
		)
	end
	saveSettings()
end)

-- Webhook URL text box
local urlBox = Instance.new("TextBox")
urlBox.Size              = UDim2.new(1, 0, 0, 28)
urlBox.BackgroundColor3  = colors.surface
urlBox.TextColor3        = colors.textPrimary
urlBox.PlaceholderColor3 = colors.textMuted
urlBox.PlaceholderText   = "Paste Discord Webhook URL…"
urlBox.Text              = (webhookUrl ~= "") and string.rep("*", 30) or ""
urlBox.Font              = Enum.Font.Gotham
urlBox.TextSize          = 9
urlBox.ClearTextOnFocus  = false
urlBox.LayoutOrder       = 10
urlBox.Parent            = content
addCorner(urlBox, 6)
addStroke(urlBox, colors.divider, 1)
addPadding(urlBox, 0, 0, 8, 8)

local MASK_STR = string.rep("*", 30)
urlBox.Focused:Connect(function()
	if urlBox.Text == MASK_STR then urlBox.Text = "" end
end)

urlBox.FocusLost:Connect(function()
	local txt = urlBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if txt ~= "" and txt ~= MASK_STR then
		webhookUrl = txt
		urlBox.Text = MASK_STR
		notify("Webhook URL saved  ✓", colors.accent, 1.5)
	elseif txt == "" then
		webhookUrl = ""
		if webhookEnabled then
			webhookEnabled = false
			updateWebhookToggleVisuals()
			notify("Webhook disabled — no URL", colors.red, 2)
		end
	else
		urlBox.Text = MASK_STR
	end
	saveSettings()
end)

-- Heartbeat interval row
sectionLabel("HEARTBEAT (MINUTES)", 11)

local hbRow = Instance.new("Frame")
hbRow.Size               = UDim2.new(1, 0, 0, 32)
hbRow.BackgroundTransparency = 1
hbRow.LayoutOrder         = 12
hbRow.Parent              = content

local hbMinus = Instance.new("TextButton")
hbMinus.Size             = UDim2.new(0, 32, 1, 0)
hbMinus.BackgroundColor3 = colors.surface
hbMinus.TextColor3       = colors.textPrimary
hbMinus.Font             = Enum.Font.GothamBold
hbMinus.TextSize         = 18
hbMinus.Text             = "−"
hbMinus.AutoButtonColor  = false
hbMinus.Parent           = hbRow
addCorner(hbMinus, 6)

local hbBox = Instance.new("TextBox")
hbBox.Size               = UDim2.new(1, -72, 1, 0)
hbBox.Position           = UDim2.new(0, 36, 0, 0)
hbBox.Text               = tostring(webhookHeartbeatMins)
hbBox.PlaceholderText    = "min"
hbBox.BackgroundColor3   = colors.surface
hbBox.TextColor3         = colors.textPrimary
hbBox.Font               = Enum.Font.GothamBold
hbBox.TextSize           = 14
hbBox.Parent             = hbRow
addCorner(hbBox, 6)
addStroke(hbBox, colors.divider, 1)

local hbPlus = Instance.new("TextButton")
hbPlus.Size              = UDim2.new(0, 32, 1, 0)
hbPlus.Position          = UDim2.new(1, -32, 0, 0)
hbPlus.BackgroundColor3  = colors.surface
hbPlus.TextColor3        = colors.textPrimary
hbPlus.Font              = Enum.Font.GothamBold
hbPlus.TextSize          = 18
hbPlus.Text              = "+"
hbPlus.AutoButtonColor   = false
hbPlus.Parent            = hbRow
addCorner(hbPlus, 6)

local function setHbInterval(val)
	val = math.clamp(math.floor(val), 1, 60)
	webhookHeartbeatMins = val
	hbBox.Text = tostring(val)
	saveSettings()
end

hbMinus.MouseButton1Click:Connect(function()
	setHbInterval(webhookHeartbeatMins - 1)
	notify("Heartbeat: " .. webhookHeartbeatMins .. "m", colors.accent, 1.5)
end)
hbPlus.MouseButton1Click:Connect(function()
	setHbInterval(webhookHeartbeatMins + 1)
	notify("Heartbeat: " .. webhookHeartbeatMins .. "m", colors.accent, 1.5)
end)
hbBox.FocusLost:Connect(function()
	local val = tonumber(hbBox.Text)
	if val and val > 0 then setHbInterval(val)
	else hbBox.Text = tostring(webhookHeartbeatMins) end
end)

-- ── Divider ──
local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.8, 0, 0, 1)
divider.BackgroundColor3 = colors.divider
divider.BorderSizePixel = 0
divider.LayoutOrder = 14
divider.Parent = content

-- Center the divider
local dividerLayout = Instance.new("Frame")
dividerLayout.Size = UDim2.new(1, 0, 0, 8)
dividerLayout.BackgroundTransparency = 1
dividerLayout.LayoutOrder = 14
dividerLayout.Parent = content

-- ── Unload Button ──
local unloadBtn = makeButton("⏻  Unload Script", colors.surface, 15, 32)
unloadBtn.TextSize = 12
unloadBtn.TextColor3 = colors.red

-- ── Credit ──
local creditLabel = Instance.new("TextLabel")
creditLabel.Size = UDim2.new(1, 0, 0, 16)
creditLabel.BackgroundTransparency = 1
creditLabel.Text = "by FusedHann  ·  v" .. SCRIPT_VERSION
creditLabel.TextColor3 = Color3.fromRGB(60, 60, 80)
creditLabel.Font = Enum.Font.Gotham
creditLabel.TextSize = 10
creditLabel.LayoutOrder = 16
creditLabel.Parent = content

-- ── Finalize main frame height ──
local totalHeight = 40 -- title bar
	+ 8 + 8   -- content padding top/bottom
	+ 16 + 38 -- clicker section
	+ 16 + 32 -- interval section
	+ 16 + 30 + 30 -- keybinds section
	+ 16 + 30 -- webhook toggle
	+ 28      -- webhook URL box
	+ 16 + 32 -- heartbeat interval
	+ 8       -- divider spacer
	+ 32      -- unload
	+ 16      -- credit
	+ (6 * 16) -- spacing for all items
totalHeight = math.max(totalHeight, 530) -- minimum
mainFrame.Size = UDim2.new(0, 240, 0, totalHeight)

-- Sync visuals to the auto-started state
updateToggleVisuals()

-- ═══════════════════════════════════════════════════════════
-- Draggable Logic
-- ═══════════════════════════════════════════════════════════
local dragging = false
local dragInput, dragStart, startPos

table.insert(connections, titleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end))

table.insert(connections, titleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end))

-- ═══════════════════════════════════════════════════════════
-- Toggle Logic
-- ═══════════════════════════════════════════════════════════
local function toggleAutoClicker()
	isEnabled = not isEnabled
	updateToggleVisuals()
	if isEnabled then
		notify("Auto-Clicker Started  ✓", colors.green)
		sendWebhook("▶ Auto-Clicker Started",
			"The clicker is now **active**.\nClick interval: **" .. interval .. "s**",
			DISCORD_GREEN)
	else
		notify("Auto-Clicker Stopped  ✗", colors.red)
		sendWebhook("⏸ Auto-Clicker Paused",
			"The clicker was **paused** manually.\nSession so far: **" .. formatDuration(tick() - sessionStart) .. "**",
			DISCORD_ORANGE)
	end
end

toggleBtn.MouseButton1Click:Connect(toggleAutoClicker)

-- ═══════════════════════════════════════════════════════════
-- Keybind Listener
-- ═══════════════════════════════════════════════════════════
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- If currently rebinding a key, don't process normal keybinds
	if waitingForBind then return end

	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

	-- Ignore if typing in a text box
	local focused = UserInputService:GetFocusedTextBox()
	if focused then return end

	if input.KeyCode == keybinds.toggle then
		toggleAutoClicker()
	elseif input.KeyCode == keybinds.hide then
		gui.Enabled = not gui.Enabled
		if gui.Enabled then
			notify("UI Visible", colors.accent, 1.5)
		else
			notify("UI Hidden", colors.textMuted, 1.5)
		end
	end
end))

-- ═══════════════════════════════════════════════════════════
-- Autoclicker Loop
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while running do
		local ok, err = pcall(function()
			if isEnabled then
				safeClick()
				sessionClicks = sessionClicks + 1
				task.wait(math.max(interval, 0.05)) -- floor at 50ms to prevent freeze
			else
				task.wait(0.1)
			end
		end)
		if not ok then
			-- If anything errors, wait a bit and retry instead of dying
			warn("[AutoClicker] Loop error: " .. tostring(err))
			task.wait(1)
		end
	end
end)

-- ═══════════════════════════════════════════════════════════
-- Anti-AFK Hook
-- ═══════════════════════════════════════════════════════════
local LocalPlayer = Players.LocalPlayer
if LocalPlayer and VirtualUser then
	table.insert(connections, LocalPlayer.Idled:Connect(function()
		if not running then return end
		pcall(function()
			VirtualUser:CaptureController()
			VirtualUser:ClickButton2(Vector2.new())
		end)
	end))
end

-- ═══════════════════════════════════════════════════════════
-- Game-exit / Executor-unload kill switch
-- Stops the click loop when: the game closes, the player is
-- removed, or the executor unloads the script mid-session.
-- ═══════════════════════════════════════════════════════════
local function killScript()
	running    = false
	isEnabled  = false
end

-- game:BindToClose fires when the Roblox client is closing
pcall(function()
	game:BindToClose(killScript)
end)

-- LocalPlayer.AncestryChanged fires when the player is removed
-- from the DataModel (kicked, disconnected, left game)
if LocalPlayer then
	table.insert(connections, LocalPlayer.AncestryChanged:Connect(function()
		if not LocalPlayer.Parent then
			killScript()
		end
	end))
end

-- ═══════════════════════════════════════════════════════════
-- Unload — clean teardown
-- ═══════════════════════════════════════════════════════════
local function unloadScript()
	if unloading then return end  -- prevent double-unload crash
	unloading = true

	-- Kill the click loop IMMEDIATELY before any awaits
	running   = false
	isEnabled = false

	-- Show farewell notification before teardown
	notify('Script Unloaded  — Goodbye!', colors.red, 1.5)

	task.wait(0.65) -- let webhook fire, toast animate

	-- Disconnect every tracked connection
	for _, conn in ipairs(connections) do
		pcall(function() conn:Disconnect() end)
	end
	connections = {}

	-- Fade out animation then destroy
	tween(mainFrame, {BackgroundTransparency = 1}, 0.3)
	for _, child in ipairs(mainFrame:GetDescendants()) do
		pcall(function()
			if child:IsA("GuiObject") then
				tween(child, {BackgroundTransparency = 1}, 0.25)
			end
			if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
				tween(child, {TextTransparency = 1}, 0.25)
			end
		end)
	end

	task.wait(0.35)
	gui:Destroy()

	-- Clean up notification gui after toasts finish
	task.delay(2, function()
		if notifGui and notifGui.Parent then
			notifGui:Destroy()
		end
	end)
end

unloadBtn.MouseButton1Click:Connect(unloadScript)

-- ═══════════════════════════════════════════════════════════
-- Intro animation — slide in from top
-- ═══════════════════════════════════════════════════════════
do
	local targetPos = mainFrame.Position
	mainFrame.Position = UDim2.new(targetPos.X.Scale, targetPos.X.Offset, targetPos.Y.Scale, targetPos.Y.Offset - 40)
	mainFrame.BackgroundTransparency = 0.5
	task.wait(0.05)
	tween(mainFrame, {
		Position = targetPos,
		BackgroundTransparency = 0,
	}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	-- Welcome notification (auto-start active)
	task.wait(0.4)
	notify("⚡ AutoClicker v" .. SCRIPT_VERSION .. " Running  ✓", colors.green, 3)

	-- ── Load saved settings (webhook URL, interval, keybinds) ──
	pcall(function()
		if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then return end
		if not isfile(CONFIG_FILE) then return end
		local ok, data = pcall(function()
			return HttpService:JSONDecode(readfile(CONFIG_FILE))
		end)
		if not ok or type(data) ~= "table" then return end

		-- Interval
		if type(data.interval) == "number" then
			setInterval(data.interval)
		end
		-- Keybinds
		if type(data.toggleKey) == "string" then
			pcall(function()
				local kc = Enum.KeyCode[data.toggleKey]
				if kc then keybinds.toggle = kc ; toggleBindBtn.Text = "[ " .. keyName(kc) .. " ]" end
			end)
		end
		if type(data.hideKey) == "string" then
			pcall(function()
				local kc = Enum.KeyCode[data.hideKey]
				if kc then keybinds.hide = kc ; hideBindBtn.Text = "[ " .. keyName(kc) .. " ]" end
			end)
		end
		-- Webhook URL
		if type(data.webhookUrl) == "string" and data.webhookUrl ~= "" then
			webhookUrl  = data.webhookUrl
			urlBox.Text = string.rep("*", 30)
		end
		-- Heartbeat interval
		if type(data.webhookHeartbeatMins) == "number" then
			setHbInterval(data.webhookHeartbeatMins)
		end
		-- Webhook enabled — restore last state and fire startup ping if active
		if type(data.webhookEnabled) == "boolean" then
			webhookEnabled = data.webhookEnabled and webhookUrl ~= ""
			updateWebhookToggleVisuals()
			if webhookEnabled then
				notify("Webhook Active  🔔", colors.green, 2)
				sendWebhook("🟢 AFK Session Started",
					"Script loaded & auto-clicking **started**.\n" ..
					"Heartbeats every **" .. webhookHeartbeatMins .. " minutes**.",
					DISCORD_GREEN,
					{
						{ name = "Game",           value = game.Name,       inline = true },
						{ name = "Click Interval", value = interval .. "s",  inline = true },
					})
			end
		end
	end)
end

-- ═══════════════════════════════════════════════════════════
-- Webhook Heartbeat Loop
-- Proves to Discord that both the script AND Roblox are alive.
-- If heartbeats stop arriving, Roblox likely crashed / was closed.
-- ═══════════════════════════════════════════════════════════
task.spawn(function()
	while running do
		task.wait(webhookHeartbeatMins * 60)
		if not running then break end
		local hbRunning = webhookEnabled and webhookUrl ~= ""
		if hbRunning then
			local status  = isEnabled and "🟢 **AUTO-CLICKING**" or "⏸ **PAUSED**"
			local session = formatDuration(tick() - sessionStart)

			sendWebhook(
				"💓 AFK Heartbeat",
				status .. "\nSession running for **" .. session .. "**",
				isEnabled and DISCORD_GREEN or DISCORD_ORANGE,
				{
					{ name = "Clicks", value = sessionClicks, inline = true },
					{ name = "Click Interval", value = interval .. "s", inline = true },
					{ name = "Game",           value = game.Name,        inline = true },
				}
			)
		end
	end
end)
