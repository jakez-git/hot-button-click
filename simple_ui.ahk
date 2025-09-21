#Requires AutoHotkey v2.0
#Include <lib\AHKv2_Screenshot_Tools.ahk>

; --- Global Variables ---
global pToken := Gdip_Startup()
global HotButtons := []
global isMonitoring := false
global shadeVariation := 10
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

; Add shade variation option
MyGui.Add("Text",, "Shade Variation (0-255):")
MyGui.Add("Edit", "w50 vshadeVariation", shadeVariation).OnEvent("Change", UpdateShadeVariation)

; Add a status bar
global MyStatusBar := MyGui.Add("StatusBar")
MyStatusBar.SetText("Stopped")

; Show the GUI
MyGui.Show("w400")

; --- Event Handlers ---
UpdateShadeVariation(control, info) {
    global shadeVariation := control.Value
}

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

            Gdip_GetImageDimensions(pBitmap, &imgW, &imgH)
            HotButtons.Push({path: imagePath, w: imgW, h: imgH})

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
        SetTimer(ScanForHotButtons, "Off")
        SetTimer(EnableMonitoring, -10000) ; one-time timer
        return
    }

    MyStatusBar.SetText("Scanning for hot buttons...")
    for button in HotButtons {
        ImageSearch(&FoundX, &FoundY, 0, 0, A_ScreenWidth, A_ScreenHeight, "*" shadeVariation " " button.path)
        if (FoundX != "") {
            MouseGetPos(&origX, &origY)
            activeWin := WinGetID("A")

            Click(FoundX + button.w/2, FoundY + button.h/2)
            Sleep(100)

            MouseMove(origX, origY)
            WinActivate("ahk_id " activeWin)
            break
        }
    }
    MyStatusBar.SetText("Monitoring...")
}

EnableMonitoring() {
    if (isMonitoring) {
        MyStatusBar.SetText("Monitoring...")
        SetTimer(ScanForHotButtons, 1000)
    }
}

MyGui.OnEvent("Close", (*) => Gdip_Shutdown(pToken) & ExitApp())
