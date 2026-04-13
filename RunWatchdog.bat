@echo off
title Roblox AFK Watchdog
echo Starting AFK Watchdog...
echo This window must stay open to monitor Roblox.
echo.
powershell -ExecutionPolicy Bypass -File "Watchdog.ps1"
pause
