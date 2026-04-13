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

Monitor your AFK session from anywhere. Your webhook URL is stored in a **separate private file** that is never uploaded to GitHub.

### Step 1 — Get your Discord Webhook URL

1. Open the Discord **channel** you want to receive notifications in.
2. Click the ⚙️ gear icon → **Integrations** → **Webhooks** → **New Webhook**.
3. Give it a name (e.g. `AFK Monitor`) then click **Copy Webhook URL**.

### Step 2 — Set up `WebhookConfig.lua`

Download **`WebhookConfig.lua`** from this repo and open it in any text editor:

```lua
_G.AFKWebhookURL    = "PASTE_YOUR_DISCORD_WEBHOOK_URL_HERE"
_G.AFKAutoWebhook   = true   -- auto-enable on load
_G.AFKHeartbeatMins = 5      -- heartbeat every 5 minutes (1–60)
```

Replace `PASTE_YOUR_DISCORD_WEBHOOK_URL_HERE` with your copied URL.  
> ✅ This file is `.gitignore`d — your URL will **never** be pushed to GitHub.

### Step 3 — Put both files in auto-execute

Place **both files** in your executor's `autoexec` / `auto-execute` folder:

```
📁 autoexec/
  ├── WebhookConfig.lua        ← your private config (never shared)
  └── RobloxAutoClicker.lua    ← the main script
```

> 💡 `WebhookConfig.lua` must be in the same folder so it runs alongside the main script.

### Step 4 — Done!

Open Roblox. Within a few seconds you'll see a **🟢 AFK Session Started** message appear in your Discord channel. Every time Roblox reloads, it repeats automatically.

---

### 📨 Events sent to Discord

| Event | When it fires | Color |
| :--- | :--- | :---: |
| 🟢 **AFK Session Started** | Script loads | Green |
| ▶ **Auto-Clicker Started** | Toggle ON | Green |
| ⏸ **Auto-Clicker Paused** | Toggle OFF | Orange |
| 💓 **AFK Heartbeat** | Every N minutes | Green/Orange |
| 🔴 **AFK Monitor Stopped** | Unload button pressed | Red |

### 🤔 Is Roblox still open?

If your Discord is **receiving heartbeats** → script & Roblox are both alive.  
If heartbeats **stopped without a 🔴 Stopped message** → Roblox likely crashed or was force-closed.

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
