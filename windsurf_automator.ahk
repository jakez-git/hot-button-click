; Windsurf UI Automator
; --------------------
; This script detects running instances of Windsurf, scans for specific buttons,
; and clicks them when the system is idle.
;
; AutoHotkey v2 is required.

#Requires AutoHotkey v2.0
#SingleInstance Force

#include <UIA>

; --- Configuration ---
global BUTTON_TARGETS_FILE := "config\button_targets.txt"
global LOG_FILE := "windsurf_automator.log"
global IDLE_THRESHOLD := 3000 ; 3 seconds
global ButtonTargets := []

; --- Main Loop ---
Main() {
    Log("Script started.")
    LoadButtonTargets()
    SetTimer(ScanAndClick, 5000) ; Run every 5 seconds
}

; --- Core Functions ---
ScanAndClick() {
    ; Check for user idle time
    if (A_TimeIdle < IDLE_THRESHOLD) {
        ; Log("User is active. Skipping scan.")
        return
    }

    Log("User is idle. Starting scan for Windsurf windows.")

    ; 1. Detect Windsurf Windows
    local windsurf_windows := DetectWindsurfWindows()
    if (windsurf_windows.Length = 0) {
        ; Log("No Windsurf windows found.")
        return
    }

    Log("Found " . windsurf_windows.Length . " Windsurf window(s).")

    for hwnd in windsurf_windows {
        Log("Processing window: " . hwnd)

        ; 2. Scan for Buttons in each window
        local buttons := ScanWindowForButtons(hwnd)
        Log("Found " . buttons.Length . " buttons in window " . hwnd)

        ; 3. Compare with targets and click
        for button in buttons {
            for target in ButtonTargets {
                if (button.Name = target) {
                    Log("Match found: '" . button.Name . "'. Preparing to click.")
                    ClickButton(button)
                    return ; Exit after first click to avoid multiple actions
                }
            }
        }
    }
}

ClickButton(button) {
    try {
        Log("Attempting to click button '" . button.Name . "'")
        ; Most buttons can be clicked via the InvokePattern
        button.Element.Invoke()
        Log("Successfully clicked button '" . button.Name . "'")
        Sleep(1000) ; Wait for a second to allow UI to update
    } catch as e {
        Log("Error clicking button '" . button.Name . "': " . e.Message)
    }
}

ScanWindowForButtons(hwnd) {
    Log("Scanning for buttons in window: " . hwnd)
    local found_buttons := []
    try {
        local window_element := UIA.ElementFromHandle(hwnd)
        ; Find all button elements in the window
        local button_elements := window_element.FindAll({Type: "Button"})

        if (button_elements.Length > 0) {
            for button_el in button_elements {
                try {
                    ; Create an object with the button's name and the UIA element
                    found_buttons.Push({Name: button_el.Name, Element: button_el})
                } catch as e {
                    Log("Error getting button name: " . e.Message)
                }
            }
        }
    } catch as e {
        Log("UIA Error in ScanWindowForButtons: " . e.Message)
    }
    return found_buttons
}

DetectWindsurfWindows() {
    local windsurf_windows := []
    local windsurf_exe := "windsurf.exe" ; Assumed executable name. Change if necessary.

    for hwnd in WinGetList(, , , "ahk_exe " . windsurf_exe) {
        if WinExist("ahk_id " . hwnd) { ; Check if window is visible
            windsurf_windows.Push(hwnd)
        }
    }
    return windsurf_windows
}

LoadButtonTargets() {
    Log("Loading button targets from " . BUTTON_TARGETS_FILE)
    if not FileExist(BUTTON_TARGETS_FILE) {
        Log("Error: Button targets file not found at " . BUTTON_TARGETS_FILE)
        return
    }

    global ButtonTargets := []
    loop read, BUTTON_TARGETS_FILE {
        local line := Trim(A_LoopReadLine)
        if (line != "" and !InStr(line, ";")) { ; Ignore comments and empty lines
            ButtonTargets.Push(line)
        }
    }
    Log("Loaded " . ButtonTargets.Length . " button targets.")
}

Log(message) {
    FileAppend("[" . A_Now . "] " . message . "`n", LOG_FILE)
}

; --- Entry Point ---
Main()
