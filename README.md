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
- **📳 Discord Webhook Monitor**: Get real-time AFK status updates in Discord. The script **auto-saves your webhook URL** — so even when Roblox reloads, notifications resume instantly with zero effort.

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

The script **auto-saves** your webhook URL. You only need to do this once — even after Roblox restarts, the URL will already be there.

### Step 1 — Get your webhook URL
1. Open the Discord channel you want notifications in.
2. Click ⚙️ **Channel Settings → Integrations → Webhooks → New Webhook**.
3. Give it a name (e.g. `AFK Monitor`), then click **Copy Webhook URL**.

### Step 2 — Paste it in-game (once!)
1. Run the script (or let auto-execute do it).
2. In the GUI, find the **"Paste Discord Webhook URL…"** field.
3. Paste your URL and click anywhere else to confirm — you'll see a `Webhook URL saved ✓` notification.
4. Click the **🔕 Webhook OFF** button to turn it **ON**.
5. Done! The URL is now saved to your executor's local storage.

> ✅ **Next time Roblox opens**, the URL loads automatically and Discord notifications resume immediately.

### 📨 Events sent to Discord

| Event | When it fires | Color |
| :--- | :--- | :---: |
| 🟢 **AFK Session Started** | Script loads with saved webhook active | Green |
| ▶ **Auto-Clicker Started** | Toggle ON | Green |
| ⏸ **Auto-Clicker Paused** | Toggle OFF | Orange |
| 💓 **AFK Heartbeat** | Every N minutes (configurable 1–60) | Green/Orange |
| 🔴 **AFK Monitor Stopped** | Unload button pressed | Red |

### 🤔 Is Roblox still open?
If Discord is **receiving heartbeats** → script & Roblox are both running.  
If heartbeats **stop without a 🔴 Stopped message** → Roblox likely crashed or was force-closed.

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

## 🐕 Watchdog — Get Notified When Roblox Crashes

> **Why does this exist?** When Roblox is force-closed or crashes, the Lua script dies instantly — it has no time to send a notification. The **Watchdog** runs *outside* of Roblox on Windows, so it always detects when the process disappears.

### How it works

| Lua Script (inside Roblox) | Watchdog (on Windows) |
| :--- | :--- |
| Notifies: Toggle ON/OFF, Unload | Notifies: Roblox started, Roblox **closed/crashed** |
| Dies if Roblox crashes | Runs independently — always alive |

Together they cover **every possible scenario**.

### Setup (one time)

1. Download **`Watchdog.ps1`** from this repo.
2. Open it in Notepad and paste your webhook URL:
   ```
   $WebhookUrl = "https://discord.com/api/webhooks/..."
   ```
3. Right-click the file → **Run with PowerShell**. Minimize the window.
4. That's it — it monitors Roblox and sends a Discord alert the instant it closes or crashes.

**Optional — Auto-start with Windows:**
Press `Win+R`, type `shell:startup`, and paste a shortcut to `Watchdog.ps1` in that folder. It'll run silently every time you log in.

---

*Authored by HANN77 / Antigravity*
