# ⚡ Simple Auto-Click & Anti-AFK v2.0 (Roblox)

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

## 🚀 How to Use

Simply copy the code below and run it through your preferred Roblox executor. You don't need to download the full script file!

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/HANN77/Simple-AutoClick-AntiAFK/main/RobloxAutoClicker.lua"))()
```

## ⌨️ Default Keybinds & Controls

| Key | Function |
| :--- | :--- |
| **`[F]`** | Toggles the auto-clicker ON/OFF. *(Customizable in UI)* |
| **`[Left Shift]`** | Hides/shows the menu. *(Customizable in UI)* |
| **`[Drag Title Bar]`** | Click and drag the title bar to reposition the menu. |

### Rebinding Keys
1. Click the key button next to **Toggle** or **Hide UI** in the Keybinds section.
2. The button will show `[ ... ]` — press any key to set it.
3. Press `Escape` to cancel without changing.

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
