@echo off
echo "Stopping Hot Button Clicker..."
taskkill /FI "WINDOWTITLE eq Hot Button Clicker" /IM "AutoHotkey*.exe" /F /T > nul
echo "Application stopped."
exit
