# Windsurf UI Automator

This is an AutoHotkey v2 script that automates clicking buttons in the Windsurf code editor. It is designed to run in the background, detect instances of Windsurf, and click specific buttons when the user is idle.

## Features

*   Detects all visible running instances of Windsurf.
*   Scans for buttons within each Windsurf window.
*   Matches button text against a configurable list of targets.
*   Clicks matching buttons automatically when the system is idle.
*   Comprehensive logging of all actions.

## Requirements

*   [AutoHotkey v2](https://www.autohotkey.com/v2/)

## Setup

1.  **Configure Windsurf Executable Name**:
    *   Open `windsurf_automator.ahk`.
    *   Find the line `local windsurf_exe := "windsurf.exe"`.
    *   If your Windsurf executable has a different name, change it here.

2.  **Configure Button Targets**:
    *   Open `config/button_targets.txt`.
    *   Add the text of the buttons you want to click, one per line.
    *   Lines starting with a semicolon (`;`) are ignored as comments.

## Running the Script

1.  Make sure you have AutoHotkey v2 installed.
2.  Double-click `windsurf_automator.ahk` to run it.
3.  The script will run in the background. A log file, `windsurf_automator.log`, will be created in the same directory, tracking the script's actions.

## How it Works

The script works in a continuous loop:

1.  **Idle Check**: It first checks if the user has been idle for a configurable amount of time (default: 3 seconds).
2.  **Window Detection**: If the user is idle, it scans for all visible windows with the configured Windsurf executable name.
3.  **Button Scanning**: For each Windsurf window found, it scans for visible buttons. (Note: This part is currently a placeholder and needs to be implemented with a UI Automation library).
4.  **Matching and Clicking**: It compares the text of each found button against the list in `config/button_targets.txt`. If a match is found, it clicks the button and then waits for the next cycle.
5.  **Logging**: All steps are logged to `windsurf_automator.log`.
