# Flask Development Guide - Fast Change Visibility

## The Problem
This project uses Tornado (not Flask's dev server), so template/code changes require a server restart.

## After Every Code Change

1. **Restart Flask server**
   - Stop: Close the terminal running `cps.py` or kill Python process
   - Start: `venv\Scripts\python.exe cps.py`

2. **Hard refresh browser**: `Ctrl+Shift+R`

## Quick Restart Script (Optional)
Save as `restart-dev.ps1` in project root:ershell
Get-Process python -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
cd c:\github\long_node\repo
Start-Process -FilePath "venv\Scripts\python.exe" -ArgumentList "cps.py"
Write-Host "Server restarting... wait 5 seconds then refresh browser"
