# ⚡ Simple Auto-Click & Anti-AFK v2.2 (Roblox)

A lightweight, background-friendly Auto-Clicker and Anti-AFK script for Roblox with a polished UI, customizable keybinds, and clean unload support.

Farm your favorite games effectively without ever losing control of your PC!

---

## ✨ Features

- **👻 Background Clicking**: Uses Roblox's native `VirtualInputManager` to click the center of the screen. Your actual computer mouse is never hijacked—you can minimize Roblox, watch YouTube, or browse the web while it farms for you!
- **🛡️ True Anti-AFK**: Automatically hooks into Roblox's idle detection system to totally bypass the 20-minute disconnection kick. Leave your PC on overnight with zero worry.
- **🎨 Polished Dark UI**: A sleek, dark-themed interface with accent colors, smooth tween animations, status indicators, and a satisfying intro/outro animation.
- **🎛️ Custom Keybinds**: Don't like the default keys? Click any keybind button in the UI to set it to whatever key you prefer. Press `Escape` to cancel rebinding.
- **⏱️ Precise Interval Control**: Use the `+` / `−` buttons or type directly to set your click interval (supports decimals, minimum 0.1s).
- **⏻ Clean Unload**: Done using the script? Hit the **Unload** button to cleanly disconnect everything and remove the UI—no need to close Roblox!
- **👁️ Concealable**: Easily hide the interface so it doesn't clutter your gameplay. Uses executor GUI protection (like `syn.protect_gui`) to hide from in-game anti-cheats as well.
- **⚡ Auto-Execute Ready**: Starts running the moment it's loaded. Perfect for placing in your executor's `auto-execute` folder for a fully automated AFK experience—if Roblox reloads, the script starts clickin' again instantly!
- **📳 Discord Webhook Monitor**: Get real-time AFK status updates directly in Discord. Periodic heartbeats confirm both the script *and* Roblox are still running. If the heartbeats stop, something went wrong.

## 🚀 How to Use

Simply copy the code below and run it through your preferred Roblox executor. You don't need to download the full script file!

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/HANN77/Simple-AutoClick-AntiAFK/main/RobloxAutoClicker.lua"))()
```

## ⌨️ Default Keybinds & Controls

| Key | Function |
| :--- | :--- |
| **`[F]`** | Toggles the auto-clicker ON/OFF. *(Customizable in UI)* |
| **`[Right Shift]`** | Hides/shows the menu. *(Customizable in UI)* |
| **`[Drag Title Bar]`** | Click and drag the title bar to reposition the menu. |

### Rebinding Keys
1. Click the key button next to **Toggle** or **Hide UI** in the Keybinds section.
2. The button will show `[ ... ]` — press any key to set it.
3. Press `Escape` to cancel without changing.

## 📳 Discord Webhook Setup

Monitor your AFK session from anywhere by connecting a Discord webhook.

**Method A — Permanent (recommended for auto-execute):**

Open `RobloxAutoClicker.lua` and fill in the two config lines at the very top:
```lua
local DEFAULT_WEBHOOK_URL   = "https://discord.com/api/webhooks/YOUR/WEBHOOK"
local AUTO_START_WEBHOOK    = true   -- enable webhook automatically on load
local DEFAULT_HEARTBEAT_MIN = 5      -- heartbeat every 5 minutes
```
The webhook will activate automatically every time the script loads.

**Method B — In-session via the GUI:**
1. Paste your Discord webhook URL into the **"Paste Discord Webhook URL…"** field.
2. Click **🔕 Webhook OFF** to toggle it **ON**.
3. A confirmation message is sent to Discord immediately.

### ⚡ Events Sent to Discord

| Event | When it fires | Embed color |
| :--- | :--- | :---: |
| **🟢 AFK Session Started** | Script loads (auto-execute) | Green |
| **▶ Auto-Clicker Started** | User enables clicking | Green |
| **⏸ Auto-Clicker Paused** | User disables clicking | Orange |
| **💓 AFK Heartbeat** | Every N minutes (configurable) | Green/Orange |
| **🔴 AFK Monitor Stopped** | Script is unloaded | Red |

### 🤔 How to tell if Roblox is still open
The heartbeat itself answers this question: **if Discord is receiving heartbeats, both the script and Roblox are running.** If heartbeats stop arriving and you never received a "Stopped" message, Roblox most likely crashed or was force-closed.

### Creating a Discord webhook
1. Open the Discord channel you want notifications in.
2. Go to **Channel Settings → Integrations → Webhooks → New Webhook**.
3. Copy the webhook URL and paste it into the script or the GUI.

---

## ⏻ Unloading
Click the **⏻ Unload Script** button at the bottom of the menu. The script will:
1. Stop all clicking and anti-AFK hooks.
2. Disconnect every event listener cleanly.
3. Fade out the UI with a smooth animation.
4. Destroy itself completely — as if it was never there.

## ⚠️ Disclaimer

Use this script responsibly. While it is designed to be as undetectable as possible and doesn't hijack your OS cursor, abusing auto-clickers goes against the Terms of Service for many Roblox games. Enjoy, play smart, and have fun!

---

*Authored by HANN77 / Antigravity*
