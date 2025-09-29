; ======================================================================================================================
; Title:         Hot Button Clicker
; Description:   An AutoHotkey v2 application that allows users to define "hot buttons" by screenshotting
;                screen regions and then automatically clicking them when they appear.
; Author:        Your Name
; Version:       1.0.0
; Requires:      AutoHotkey v2.0, GDI+ Library (included)
; ======================================================================================================================

#Requires AutoHotkey v2.0
#Include <lib\AHKv2_Screenshot_Tools.ahk>

; --- Global Variables ---
global pToken := Gdip_Startup()      ; Initialize GDI+ library and store the token.
global HotButtons := []              ; Array to store hot button objects {path, w, h}.
global isMonitoring := false         ; Flag to track if the application is currently scanning.
global shadeVariation := 10          ; Default shade variation for ImageSearch.
FileCreateDir("hot_buttons")         ; Ensure the directory for storing button images exists.


; --- GUI Definition ---
; Create the main application window.
MyGui := Gui(, "Hot Button Clicker")
MyGui.SetFont("s10", "Segoe UI")

; Add control buttons.
MyGui.Add("Button", "w120", "Add Hot Button").OnEvent("Click", AddHotButton)
MyGui.Add("Button", "w120 yp x+10", "Start Monitoring").OnEvent("Click", StartMonitoring)
MyGui.Add("Button", "w120 yp x+10", "Stop Monitoring").OnEvent("Click", StopMonitoring)

; Add a list view to display the paths of captured hot buttons.
global HotButtonList := MyGui.Add("ListView", "w380 r10", ["Image Path"])
HotButtonList.ModifyCol(1, "AutoHdr") ; Auto-size the column.

; Add controls for adjusting the shade variation.
MyGui.Add("Text",, "Shade Variation (0-255):")
MyGui.Add("Edit", "w50 vshadeVariation", shadeVariation).OnEvent("Change", UpdateShadeVariation)

; Add a status bar to display application status.
global MyStatusBar := MyGui.Add("StatusBar")
MyStatusBar.SetText("Stopped")

; Show the GUI.
MyGui.Show("w400")

; --- Functions and Event Handlers ---

/**
 * Updates the global `shadeVariation` variable when the user changes the value in the Edit control.
 * @param {Gui.Edit} control The Edit control that triggered the event.
 * @param {Any} info Additional information about the event.
 */
UpdateShadeVariation(control, info) {
    global shadeVariation := control.Value
}

/**
 * Initiates the process of adding a new hot button. Hides the main GUI and prepares a full-screen overlay
 * for region selection.
 */
AddHotButton(*) {
    MyGui.Hide()
    MyStatusBar.SetText("Click and drag to select a region...")

    ; Create a transparent, full-screen GUI for selection.
    global SelectionGui := Gui("-Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs")
    SelectionGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight, "NA")

    ; Set up GDI+ resources for drawing the selection rectangle.
    global hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
    global hdc := CreateCompatibleDC()
    global obm := SelectObject(hdc, hbm)
    global G := Gdip_GraphicsFromHDC(hdc)
    global pPen := Gdip_CreatePen(0xFFFF0000, 2) ; Red pen for the rectangle.

    ; Set up message handlers to capture mouse events.
    global startX, startY, endX, endY
    OnMessage(0x201, WM_LBUTTONDOWN) ; WM_LBUTTONDOWN
    OnMessage(0x202, WM_LBUTTONUP)   ; WM_LBUTTONUP
}

/**
 * Message handler for when the left mouse button is pressed down during region selection.
 * Records the starting coordinates and starts a timer to draw the selection rectangle.
 */
WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    if (hwnd = SelectionGui.Hwnd) {
        MouseGetPos(&startX, &startY)
        SetTimer(UpdateSelection, 10)
    }
}

/**
 * Message handler for when the left mouse button is released, completing the region selection.
 * It captures the selected screen area, saves it as an image, and adds it to the hot button list.
 */
WM_LBUTTONUP(wParam, lParam, msg, hwnd) {
    if (hwnd = SelectionGui.Hwnd) {
        ; Stop the drawing timer and unregister message handlers.
        SetTimer(UpdateSelection, "Off")
        OnMessage(0x201, "")
        OnMessage(0x202, "")
        MouseGetPos(&endX, &endY)

        ; Clean up GDI+ resources.
        Gdip_DeletePen(pPen)
        SelectObject(hdc, obm)
        DeleteObject(hbm)
        DeleteDC(hdc)
        Gdip_DeleteGraphics(G)

        ; Destroy the selection GUI.
        SelectionGui.Destroy()

        ; Calculate the dimensions of the selected rectangle.
        x := Min(startX, endX)
        y := Min(startY, endY)
        w := Abs(startX - endX)
        h := Abs(startY - endY)

        ; If the selection has a valid size, capture and save the image.
        if (w > 0 && h > 0) {
            pBitmap := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
            imagePath := "hot_buttons\" A_TickCount ".png"
            Gdip_SaveBitmapToFile(pBitmap, imagePath)

            ; Store button info and update the GUI list.
            Gdip_GetImageDimensions(pBitmap, &imgW, &imgH)
            HotButtons.Push({path: imagePath, w: imgW, h: imgH})
            HotButtonList.Add(, imagePath)
            Gdip_DisposeImage(pBitmap)
            MyStatusBar.SetText("Button added.")
        } else {
            MyStatusBar.SetText("Invalid region selected.")
        }

        ; Show the main GUI again.
        MyGui.Show()
    }
}

/**
 * Timer function that continuously updates the selection rectangle on the screen as the user
 * drags the mouse.
 */
UpdateSelection() {
    MouseGetPos(&currX, &currY)
    Gdip_GraphicsClear(G) ; Clear the previous rectangle.
    w := Abs(startX - currX)
    h := Abs(startY - currY)
    x := Min(startX, currX)
    y := Min(startY, currY)
    Gdip_DrawRectangle(G, pPen, x, y, w, h)
    UpdateLayeredWindow(SelectionGui.Hwnd, hdc)
}

/**
 * Starts the monitoring process. Sets the `isMonitoring` flag and starts a recurring timer
 * that calls `ScanForHotButtons`.
 */
StartMonitoring(*) {
    if (isMonitoring) {
        return
    }
    isMonitoring := true
    MyStatusBar.SetText("Monitoring...")
    SetTimer(ScanForHotButtons, 1000) ; Scan every 1 second.
}

/**
 * Stops the monitoring process. Clears the `isMonitoring` flag and disables the timer.
 */
StopMonitoring(*) {
    isMonitoring := false
    MyStatusBar.SetText("Stopped")
    SetTimer(ScanForHotButtons, "Off")
}

/**
 * The core scanning function. It checks for user inactivity and then searches the screen for
 * each defined hot button. If a button is found, it is clicked.
 */
ScanForHotButtons() {
    if (!isMonitoring) {
        return
    }

    ; Pause monitoring if the user is active to avoid interference.
    if (A_TimeIdlePhysical < 30000) { ; 30 seconds idle threshold.
        MyStatusBar.SetText("User active. Pausing for 10 seconds...")
        SetTimer(ScanForHotButtons, "Off")
        SetTimer(EnableMonitoring, -10000) ; Check again after 10 seconds.
        return
    }

    MyStatusBar.SetText("Scanning for hot buttons...")
    for button in HotButtons {
        ; Search for the button image on the screen.
        ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*" shadeVariation " " button.path)

        ; If the image is found...
        if (FoundX != "") {
            ; Save original mouse position and active window.
            MouseGetPos(&origX, &origY)
            activeWin := WinGetID("A")

            ; Click in the center of the found button.
            Click(FoundX + button.w/2, FoundY + button.h/2)
            Sleep(100)

            ; Restore original mouse position and activate the previous window.
            MouseMove(origX, origY)
            WinActivate("ahk_id " activeWin)
            break ; Stop scanning after finding one button.
        }
    }
    MyStatusBar.SetText("Monitoring...")
}

/**
 * Re-enables the monitoring timer after it has been paused due to user activity.
 */
EnableMonitoring() {
    if (isMonitoring) {
        MyStatusBar.SetText("Monitoring...")
        SetTimer(ScanForHotButtons, 1000)
    }
}

/**
 * Handles the GUI's close event. Shuts down the GDI+ library and exits the application.
 */
MyGui.OnEvent("Close", (*) => Gdip_Shutdown(pToken) & ExitApp())