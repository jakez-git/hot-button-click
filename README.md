# Hot Button Clicker

## About

Hot Button Clicker is a simple AutoHotkey application that allows you to define "hot buttons" by taking screenshots of specific regions on your screen. The application can then monitor your screen and automatically click these buttons when they appear. This is useful for automating repetitive clicking tasks.

## Requirements

- [AutoHotkey v2](httpshttps://www.autohotkey.com/v2/) must be installed on your system.

## How to Use

### Starting and Stopping the Application

- **To start the application:** Double-click on `start.bat`. This will launch the Hot Button Clicker GUI.
- **To stop the application:** Double-click on `stop.bat`. This will close the application.

### Using the Application

1.  **Launch the application** using `start.bat`.
2.  **Add a Hot Button:**
    -   Click the "Add Hot Button" button. The application window will hide.
    -   Click and drag your mouse to select a region of the screen you want to define as a button.
    -   Release the mouse button. A screenshot of the selected region will be saved in the `hot_buttons` folder, and the image path will be added to the list in the GUI.
3.  **Start Monitoring:**
    -   Click the "Start Monitoring" button. The application will begin scanning the screen for any of the hot buttons you have added.
    -   The status bar will indicate that the application is "Monitoring...".
    -   If a hot button is found, the application will click on the center of it.
    -   To avoid interfering with your work, the monitoring will pause if you are actively using the computer. It will resume after a period of inactivity.
4.  **Stop Monitoring:**
    -   Click the "Stop Monitoring" button to stop the screen scanning.
5.  **Shade Variation:**
    -   The "Shade Variation" setting allows you to control how closely the image on the screen must match your hot button screenshot. A higher value allows for more variation in color and shading. The value can be between 0 and 255.
