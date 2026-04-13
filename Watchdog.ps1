# ============================================================
#  AFK Watchdog — Discord Notifier for Roblox
#  by HANN77
# ============================================================
#  Runs independently in the background. If Roblox is
#  force-closed or crashes, this script detects it and sends
#  a Discord notification IMMEDIATELY.
#
#  HOW TO USE:
#    1. Paste your Discord webhook URL below.
#    2. Double-click this file (or right-click > Run with PowerShell).
#    3. Minimize the window — it runs silently in the background.
#
#  TIP: Add this to Windows Startup so it auto-runs:
#    Press Win+R → type "shell:startup" → paste a shortcut here.
# ============================================================

# ── CONFIG ────────────────────────────────────────────────────
$WebhookUrl     = "PASTE_YOUR_DISCORD_WEBHOOK_URL_HERE"
$CheckInterval  = 8          # seconds between process checks
$ProcessName    = "RobloxPlayerBeta"
# ─────────────────────────────────────────────────────────────

# Colour helpers for the console
function Write-Colour($text, $colour) {
    Write-Host $text -ForegroundColor $colour
}

function Send-Discord($title, $description, $colour) {
    if ($WebhookUrl -eq "PASTE_YOUR_DISCORD_WEBHOOK_URL_HERE") {
        Write-Colour "  [!] Webhook URL not set — edit the script first!" "Red"
        return
    }
    $body = @{
        username = "AFK Watchdog"
        embeds   = @(@{
            title       = $title
            description = $description
            color       = $colour
        })
    } | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Uri $WebhookUrl -Method Post `
            -Body $body -ContentType "application/json" | Out-Null
        Write-Colour "  [>] Notification sent to Discord." "Cyan"
    } catch {
        Write-Colour "  [!] Failed to send webhook: $_" "Red"
    }
}

# ── MAIN LOOP ──────────────────────────────────────────────────
$host.UI.RawUI.WindowTitle = "AFK Watchdog"
Clear-Host

Write-Colour "============================================" "DarkCyan"
Write-Colour "  AFK Watchdog  |  Monitoring Roblox..." "Cyan"
Write-Colour "============================================" "DarkCyan"
Write-Host ""
Write-Colour "  Checking every $CheckInterval seconds. Close this window to stop." "DarkGray"
Write-Host ""

$wasRunning     = $false
$sessionStart   = $null
$crashCount     = 0

while ($true) {
    $proc      = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    $isRunning = ($null -ne $proc)
    $timeStamp = (Get-Date).ToString("HH:mm:ss")

    # ── Roblox just OPENED ──
    if ($isRunning -and -not $wasRunning) {
        $sessionStart = Get-Date
        $wasRunning   = $true
        Write-Colour "  [$timeStamp] Roblox STARTED." "Green"

        Send-Discord `
            "🚀 Roblox Started" `
            "Roblox has launched. AFK session beginning." `
            3329380   # green
    }

    # ── Roblox just CLOSED / CRASHED ──
    if (-not $isRunning -and $wasRunning) {
        $wasRunning = $false
        $crashCount++

        $duration = ""
        if ($null -ne $sessionStart) {
            $elapsed  = (Get-Date) - $sessionStart
            $duration = "`nSession lasted **{0}h {1}m {2}s**." -f `
                [int]$elapsed.Hours, [int]$elapsed.Minutes, [int]$elapsed.Seconds
        }

        Write-Colour "  [$timeStamp] Roblox CLOSED or CRASHED! (#$crashCount)" "Red"

        Send-Discord `
            "💀 Roblox Closed / Crashed" `
            ("Roblox process has **stopped**. Auto-clicking is __offline__." + $duration) `
            15418960   # red
    }

    # ── Steady heartbeat line (visible every ~1 min) ──
    if ($isRunning) {
        $elapsed = if ($null -ne $sessionStart) {
            $e = (Get-Date) - $sessionStart
            "{0:D2}h {1:D2}m {2:D2}s" -f [int]$e.Hours, [int]$e.Minutes, [int]$e.Seconds
        } else { "unknown" }

        Write-Host "  [$timeStamp] Roblox running — session: $elapsed" `
            -ForegroundColor DarkGray
    }

    Start-Sleep -Seconds $CheckInterval
}
