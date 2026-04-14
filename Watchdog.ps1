# ============================================================
#  AFK Watchdog -- Discord Notifier for Roblox
#  by HANN77
# ============================================================
#  HOW TO USE:
#    1. Paste your Discord webhook URL below (line 19).
#    2. Run via RunWatchdog.bat (do NOT run .ps1 directly).
#    3. Minimize the window -- it monitors Roblox silently.
# ============================================================

# -- CONFIG --------------------------------------------------
$WebhookUrl    = "https://discord.com/api/webhooks/1493206004500922469/eb2u0VfGoKwahEONqDAB-qTRkD2Sr31bvFXR8A0pWfqzSgw-V2HyF6pYhXmrSKOCy_Vd"
$CheckInterval = 8          # seconds between each check
$ProcessName   = "RobloxPlayerBeta"
# ------------------------------------------------------------

function Send-Discord {
    param($Title, $Description, $Color)

    if ($WebhookUrl -eq "PASTE_YOUR_DISCORD_WEBHOOK_URL_HERE") {
        Write-Host "  [!] Webhook URL not set!" -ForegroundColor Red
        return
    }

    $body = ConvertTo-Json -Depth 10 @{
        username = "AFK Watchdog"
        embeds   = @(
            @{
                title       = $Title
                description = $Description
                color       = $Color
            }
        )
    }

    try {
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $body -ContentType "application/json" | Out-Null
        Write-Host "  [>] Notification sent to Discord." -ForegroundColor Cyan
    } catch {
        Write-Host "  [!] Failed to send: $_" -ForegroundColor Red
    }
}

# -- MAIN LOOP -----------------------------------------------
$host.UI.RawUI.WindowTitle = "AFK Watchdog"
Clear-Host

Write-Host "============================================" -ForegroundColor DarkCyan
Write-Host "  AFK Watchdog  |  Monitoring Roblox..."    -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Checking every $CheckInterval seconds. Close this window to stop." -ForegroundColor DarkGray
Write-Host ""

$wasRunning   = $false
$sessionStart = $null
$crashCount   = 0

while ($true) {
    $proc      = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    $isRunning = ($null -ne $proc)
    $timeStamp = (Get-Date).ToString("HH:mm:ss")

    # Roblox just OPENED
    if ($isRunning -and -not $wasRunning) {
        $sessionStart = Get-Date
        $wasRunning   = $true
        Write-Host "  [$timeStamp] Roblox STARTED." -ForegroundColor Green
        Send-Discord -Title "Roblox Started" -Description "Roblox has launched. AFK session beginning." -Color 3329380
    }

    # Roblox just CLOSED or CRASHED
    if (-not $isRunning -and $wasRunning) {
        $wasRunning = $false
        $crashCount++

        $duration = ""
        if ($null -ne $sessionStart) {
            $elapsed  = (Get-Date) - $sessionStart
            $duration = "`nSession lasted $([int]$elapsed.Hours)h $([int]$elapsed.Minutes)m $([int]$elapsed.Seconds)s."
        }

        Write-Host "  [$timeStamp] Roblox CLOSED or CRASHED! (#$crashCount)" -ForegroundColor Red
        Send-Discord -Title "Roblox Closed / Crashed" -Description "Roblox process has stopped. Auto-clicking is offline.$duration" -Color 15418960
    }

    # Status line while running
    if ($isRunning) {
        $elapsedStr = "unknown"
        if ($null -ne $sessionStart) {
            $e = (Get-Date) - $sessionStart
            $elapsedStr = "$([int]$e.Hours)h $([int]$e.Minutes)m $([int]$e.Seconds)s"
        }
        Write-Host "  [$timeStamp] Roblox running -- session: $elapsedStr" -ForegroundColor DarkGray
    }

    Start-Sleep -Seconds $CheckInterval
}
