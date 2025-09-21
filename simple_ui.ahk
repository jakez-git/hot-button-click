#Requires AutoHotkey v2.0
#Include <lib\AHKv2_Screenshot_Tools.ahk>

; --- Global Variables ---
global pToken := Gdip_Startup()
global HotButtons := []
global isMonitoring := false
FileCreateDir("hot_buttons")


; Create the GUI window
MyGui := Gui(, "Hot Button Clicker")
MyGui.SetFont("s10", "Segoe UI")

; Add buttons
MyGui.Add("Button", "w120", "Add Hot Button").OnEvent("Click", AddHotButton)
MyGui.Add("Button", "w120 yp x+10", "Start Monitoring").OnEvent("Click", StartMonitoring)
MyGui.Add("Button", "w120 yp x+10", "Stop Monitoring").OnEvent("Click", StopMonitoring)

; Add a list view for hot buttons
global HotButtonList := MyGui.Add("ListView", "w380 r10", ["Image Path"])
HotButtonList.ModifyCol(1, "AutoHdr")


; Add a status bar
global MyStatusBar := MyGui.Add("StatusBar")
MyStatusBar.SetText("Stopped")

; Show the GUI
MyGui.Show("w400")

; --- Event Handlers ---
AddHotButton(*) {
    MyGui.Hide()
    MyStatusBar.SetText("Click on the button to capture...")
    KeyWait("LButton", "D") ; Wait for the left mouse button to be pressed
    KeyWait("LButton", "U") ; Wait for the left mouse button to be released

    MouseGetPos(,, &hWnd, &Control)

    if (Control != "")
    {
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " hWnd)
        ControlGetPos(&conX, &conY, &conW, &conH, Control)

        x := winX + conX
        y := winY + conY
        w := conW
        h := conH

        ; Capture the control image
        pBitmap := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)

        ; Save the image to a file
        imagePath := "hot_buttons\" A_TickCount ".png"
        Gdip_SaveBitmapToFile(pBitmap, imagePath)

        ; Add to our list
        HotButtons.Push(imagePath)
        HotButtonList.Add(, imagePath)

        Gdip_DisposeImage(pBitmap)
        MyStatusBar.SetText("Button added.")
    }
    else
    {
        MyStatusBar.SetText("Failed to identify a control. Please try again.")
    }

    MyGui.Show()
}

StartMonitoring(*) {
    if (isMonitoring) {
        return
    }
    isMonitoring := true
    MyStatusBar.SetText("Monitoring...")
    SetTimer(ScanForHotButtons, 1000)
}

StopMonitoring(*) {
    isMonitoring := false
    MyStatusBar.SetText("Stopped")
    SetTimer(ScanForHotButtons, "Off")
}

ScanForHotButtons() {
    if (!isMonitoring) {
        return
    }

    ; If there has been any keyboard or mouse activity in the last 30 seconds,
    ; the application will do an idle sleep for 10 seconds.
    if (A_TimeIdlePhysical < 30000) {
        MyStatusBar.SetText("User active. Pausing for 10 seconds...")
        Sleep(10000)
        MyStatusBar.SetText("Monitoring...")
        return
    }

    for path in HotButtons {
        ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, path)
        if (FoundX != "") {
            ; Get the size of the image to calculate the center
            pBitmap := Gdip_CreateBitmapFromFile(path)
            if (pBitmap = -1) {
                ; Could not load the image, maybe it's an invalid path
                continue
            }
            Gdip_GetImageDimensions(pBitmap, &w, &h)
            Gdip_DisposeImage(pBitmap)

            ; Store original mouse position and active window
            MouseGetPos(&origX, &origY)
            activeWin := WinGetTitle("A")

            ; Click the center of the button
            Click(FoundX + w/2, FoundY + h/2)
            Sleep(100) ; Give the click time to register

            ; Restore mouse and focus
            MouseMove(origX, origY)
            WinActivate(activeWin)
            break ; Click one button at a time
        }
    }
}

MyGui.OnEvent("Close", (*) => Gdip_Shutdown(pToken) & ExitApp())
