; ======================================================================================================================
; Auto Button Clicker - AHK v2
; Author: Jules
; Version: 1.0
; Description: Automatically detects and clicks common UI buttons.
; ======================================================================================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ======================================================================================================================
; --- CONFIGURATION ---
; Customize the script's behavior here.
; ======================================================================================================================
class Config {
    static ScanInterval := 2000  ; Milliseconds between each scan (e.g., 2000 = 2 seconds)
    static ClickDelay := 1000    ; Milliseconds to wait after a click before resuming scan
    static EnableSound := True   ; Play a sound on successful click? (True/False)
    static LogFile := "click_log.txt" ; Name of the log file. Leave blank to disable logging.

    ; --- Button Text To Find (Case-Insensitive, Partial Match) ---
    static ButtonTexts := [
        "Accept All", "Run", "Continue", "OK", "Yes", "Confirm",
        "Next", "Start", "Launch", "Execute"
    ]

    ; --- Custom Button Images ---
    ; Place your .bmp, .png, .jpg files in a subfolder named 'images'
    ; Add the filenames to this list.
    ; Example: static ButtonImages := ["custom_accept.png", "another_button.bmp"]
    static ButtonImages := []

    ; --- Application Whitelist / Blacklist ---
    ; Use 'ahk_exe' for executable names or 'ahk_class' for window classes.
    ; If Whitelist is not empty, ONLY windows matching the list will be scanned.
    ; Blacklist prevents scanning of matching windows. Blacklist is checked first.
    ; Example: static AppWhitelist := ["ahk_exe notepad.exe"]
    ; Example: static AppBlacklist := ["ahk_exe explorer.exe", "ahk_class TaskManagerWindow"]
    static AppWhitelist := []
    static AppBlacklist := [
        "ahk_exe explorer.exe",
        "ahk_class Progman",
        "ahk_class WorkerW",
        "ahk_class Shell_TrayWnd",
        "ahk_exe dwm.exe",
        "ahk_exe SystemSettings.exe",
        "ahk_class Windows.UI.Core.CoreWindow", ; UAC, other modern prompts
        "ahk_exe consent.exe" ; UAC
    ]
}

; ======================================================================================================================
; --- SCRIPT STATE ---
; Global variables to manage the script's operation.
; ======================================================================================================================
global isPaused := False
global mainTimer := ""

; ======================================================================================================================
; --- HOTKEYS ---
; ======================================================================================================================
F9:: {
    global isPaused
    isPaused := !isPaused
    if (isPaused) {
        mainTimer.Stop()
        ToolTip("Auto-Clicker Paused")
    } else {
        mainTimer.Start()
        ToolTip("Auto-Clicker Resumed")
    }
    SetTimer(RemoveToolTip, -1000)
}

F10:: {
    ExitApp()
}

RemoveToolTip() => ToolTip()

; ======================================================================================================================
; --- INITIALIZATION ---
; ======================================================================================================================
A_OnExit(Cleanup) ; Register cleanup function to run on exit

; Create the 'images' directory if it doesn't exist
if (Config.ButtonImages.Length > 0 && !IsDir("images")) {
    DirCreate("images")
    MsgBox("Created 'images' folder. Please place your custom button image files there and restart the script.", "Auto-Clicker Info", 4160)
}

; Start the main scanning loop
mainTimer := SetTimer(ScanAndClick, Config.ScanInterval)
ToolTip("Auto-Clicker is running. Press F9 to pause, F10 to exit.")
SetTimer(RemoveToolTip, -3000)

; ======================================================================================================================
; --- MAIN SCANNING LOOP ---
; ======================================================================================================================
ScanAndClick() {
    if isPaused
        return

    ; --- Step 1: Text-based Scan ---
    foundWindow := ScanForTextButtons()
    if (IsObject(foundWindow)) {
        PerformClick(foundWindow.x, foundWindow.y, foundWindow.winId, "Text: '" foundWindow.text "'")
        return ; Stop after first found button to avoid multiple clicks
    }

    ; --- Step 2: Image-based Scan ---
    if (Config.ButtonImages.Length > 0) {
        foundImage := ScanForImageButtons()
        if (IsObject(foundImage)) {
            PerformClick(foundImage.x, foundImage.y, WinActive("A"), "Image: '" foundImage.imageName "'")
            return
        }
    }
}

; ======================================================================================================================
; --- DETECTION FUNCTIONS ---
; ======================================================================================================================

/**
 * Scans all visible windows for controls with specified button text.
 * @returns {Object} An object with button info if found, otherwise null.
 */
ScanForTextButtons() {
    winList := WinGetList()
    for id in winList {
        try {
            if !WinGetTitle("ahk_id " id) || !IsWindowVisible(id) || IsWindowExcluded(id)
                continue

            controls := WinGetControls("ahk_id " id)
            for ctrlHwnd in controls {
                text := ControlGetText("ahk_id " ctrlHwnd)
                if (text = "")
                    continue

                for pattern in Config.ButtonTexts {
                    if (InStr(text, pattern, true)) { ; Case-insensitive search
                        if (IsControlVisible(ctrlHwnd)) {
                            ControlGetPos(&x, &y, &w, &h, "ahk_id " ctrlHwnd)
                            ; Convert control-relative coords to screen coords
                            WinGetPos(&winX, &winY, ,, "ahk_id " id)
                            btnX := winX + x + (w // 2)
                            btnY := winY + y + (h // 2)

                            return {x: btnX, y: btnY, winId: id, text: text}
                        }
                    }
                }
            }
        } catch Error as e {
            ; Window might have closed during scan, just ignore it.
            continue
        }
    }
    return null
}

/**
 * Scans the screen for specified button images.
 * @returns {Object} An object with image info if found, otherwise null.
 */
ScanForImageButtons() {
    CoordMode("Pixel", "Screen")
    CoordMode("Mouse", "Screen")

    for imageName in Config.ButtonImages {
        imagePath := "images\" imageName
        if !FileExist(imagePath)
            continue

        ; Search on the entire screen
        result := ImageSearch(&foundX, &foundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*" imagePath)

        if (result = 0) { ; Found
            return {x: foundX, y: foundY, imageName: imageName}
        }
    }
    return null
}


; ======================================================================================================================
; --- MOUSE & FOCUS MANAGEMENT ---
; ======================================================================================================================

/**
 * Manages the process of saving state, clicking, and restoring state.
 * @param {Integer} x - The x-coordinate to click.
 * @param {Integer} y - The y-coordinate to click.
 * @param {Integer} targetWinId - The HWND of the window containing the button.
 * @param {String} reason - A description of what was clicked for logging.
 */
PerformClick(x, y, targetWinId, reason) {
    mainTimer.Stop() ; Pause scanning temporarily

    ; --- Save current state ---
    origMousePos := MouseGetPos()
    activeWinId := WinActive("A")

    ; --- Perform the click ---
    Log("Attempting to click " reason " at (" x ", " y ") in window ID " targetWinId)
    Click(x, y)

    if (Config.EnableSound) {
        SoundBeep(1000, 150) ; Frequency, Duration
    }

    ; --- Restore state ---
    Sleep(500) ; Give the click time to register
    MouseMove(origMousePos.X, origMousePos.Y, 0) ; Restore mouse position instantly

    try {
        if (WinExist("ahk_id " activeWinId)) {
            WinActivate("ahk_id " activeWinId)
        }
    } catch {
        Log("Could not restore focus to original window ID " activeWinId)
    }

    Log("Click successful. Resuming scan after delay.")
    ToolTip("Clicked " reason ". Resuming...")
    SetTimer(RemoveToolTip, -2000)

    ; --- Resume scanning after delay ---
    Sleep(Config.ClickDelay)
    mainTimer.Start()
}

; ======================================================================================================================
; --- HELPER & SAFETY FUNCTIONS ---
; ======================================================================================================================

/**
 * Checks if a window should be excluded based on the blacklist/whitelist.
 * @param {Integer} winId - The HWND of the window to check.
 * @returns {Boolean} True if the window should be excluded, otherwise False.
 */
IsWindowExcluded(winId) {
    idString := "ahk_id " winId

    ; Check blacklist first
    for pattern in Config.AppBlacklist {
        if (WinExist(pattern . " " . idString)) {
            return true
        }
    }

    ; If whitelist is enabled, check if the window is on it
    if (Config.AppWhitelist.Length > 0) {
        isWhitelisted := false
        for pattern in Config.AppWhitelist {
            if (WinExist(pattern . " " . idString)) {
                isWhitelisted := true
                break
            }
        }
        if (!isWhitelisted) {
            return true ; Exclude if not on the whitelist
        }
    }

    return false
}

/**
 * Checks if a window is truly visible and not minimized.
 * @param {Integer} winId - The HWND of the window to check.
 * @returns {Boolean} True if the window is visible on screen.
 */
IsWindowVisible(winId) {
    return WinGetStyle("ahk_id " winId) & 0x10000000 ; WS_VISIBLE
        && !(WinGetMinMax("ahk_id " winId) = -1) ; Not minimized
}

/**
 * Checks if a control is visible.
 * @param {Integer} ctrlHwnd - The HWND of the control to check.
 * @returns {Boolean} True if the control is visible.
 */
IsControlVisible(ctrlHwnd) {
    return DllCall("IsWindowVisible", "Ptr", ctrlHwnd)
}

/**
 * Logs a message to the configured log file.
 * @param {String} message - The text to log.
 */
Log(message) {
    if (Config.LogFile != "") {
        try {
            logEntry := FormatTime(,"yyyy-MM-dd HH:mm:ss") . " - " . message . "`n"
            FileAppend(logEntry, Config.LogFile)
        } catch {
            ; Could not write to log file, maybe a permissions issue.
            ; Silently fail to avoid interrupting the script.
        }
    }
}

/**
 * Cleanup function called when the script exits.
 * @param {String} ExitReason - The reason for exiting.
 * @param {Integer} ExitCode - The exit code.
 */
Cleanup(ExitReason, ExitCode) {
    Log("Script exiting. Reason: " ExitReason)
}
