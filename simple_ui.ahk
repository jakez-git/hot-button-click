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
    MyStatusBar.SetText("Click and drag to select a region...")

    global SelectionGui := Gui("-Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs")
    SelectionGui.Show("x0 y0 w" A_ScreenWidth " h" A_ScreenHeight, "NA")

    global hbm := CreateDIBSection(A_ScreenWidth, A_ScreenHeight)
    global hdc := CreateCompatibleDC()
    global obm := SelectObject(hdc, hbm)
    global G := Gdip_GraphicsFromHDC(hdc)

    global pPen := Gdip_CreatePen(0xFFFF0000, 2)

    global startX, startY, endX, endY
    OnMessage(0x201, WM_LBUTTONDOWN)
    OnMessage(0x202, WM_LBUTTONUP)
}

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    if (hwnd = SelectionGui.Hwnd) {
        MouseGetPos(&startX, &startY)
        SetTimer(UpdateSelection, 10)
    }
}

WM_LBUTTONUP(wParam, lParam, msg, hwnd) {
    if (hwnd = SelectionGui.Hwnd) {
        SetTimer(UpdateSelection, "Off")
        OnMessage(0x201, "")
        OnMessage(0x202, "")
        MouseGetPos(&endX, &endY)

        Gdip_DeletePen(pPen)
        SelectObject(hdc, obm)
        DeleteObject(hbm)
        DeleteDC(hdc)
        Gdip_DeleteGraphics(G)

        SelectionGui.Destroy()

        x := Min(startX, endX)
        y := Min(startY, endY)
        w := Abs(startX - endX)
        h := Abs(startY - endY)

        if (w > 0 && h > 0) {
            pBitmap := Gdip_BitmapFromScreen(x "|" y "|" w "|" h)
            imagePath := "hot_buttons\" A_TickCount ".png"
            Gdip_SaveBitmapToFile(pBitmap, imagePath)
            HotButtons.Push(imagePath)
            HotButtonList.Add(, imagePath)
            Gdip_DisposeImage(pBitmap)
            MyStatusBar.SetText("Button added.")
        } else {
            MyStatusBar.SetText("Invalid region selected.")
        }

        MyGui.Show()
    }
}


UpdateSelection() {
    MouseGetPos(&currX, &currY)
    Gdip_GraphicsClear(G)
    w := Abs(startX - currX)
    h := Abs(startY - currY)
    x := Min(startX, currX)
    y := Min(startY, currY)
    Gdip_DrawRectangle(G, pPen, x, y, w, h)
    UpdateLayeredWindow(SelectionGui.Hwnd, hdc)
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

    if (A_TimeIdlePhysical < 30000) {
        MyStatusBar.SetText("User active. Pausing for 10 seconds...")
        Sleep(10000)
        MyStatusBar.SetText("Monitoring...")
        return
    }

    MyStatusBar.SetText("Scanning for hot buttons...")
    for path in HotButtons {
        ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*10 " path)
        if (FoundX != "") {
            pBitmap := Gdip_CreateBitmapFromFile(path)
            if (pBitmap = -1) {
                continue
            }
            Gdip_GetImageDimensions(pBitmap, &w, &h)
            Gdip_DisposeImage(pBitmap)

            MouseGetPos(&origX, &origY)
            activeWin := WinGetID("A")

            Click(FoundX + w/2, FoundY + h/2)
            Sleep(100)

            MouseMove(origX, origY)
            WinActivate("ahk_id " activeWin)
            break
        }
    }
    MyStatusBar.SetText("Monitoring...")
}

MyGui.OnEvent("Close", (*) => Gdip_Shutdown(pToken) & ExitApp())
