#Requires AutoHotkey v2.0

; Create the GUI window
MyGui := Gui(, "Simple UI")

; Add a text control
MyGui.Add("Text",, "Hello, this is a simple UI.")

; Add a button and assign a label to its event handler
MyGui.Add("Button", "Default", "Say Hello").OnEvent("Click", SayHello)

; Show the GUI
MyGui.Show()

; Event handler for the button
SayHello(*) {
    MsgBox("Hello, World!")
}
