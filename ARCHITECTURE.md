# Hot Button Clicker - Architecture Overview

This document provides a high-level overview of the technical architecture of the Hot Button Clicker application. It is intended for developers who want to understand how the application works internally.

---

## Core Components

The application is built around three main systems that work together to provide its functionality:

1.  **Hot Button Detection System**
2.  **Idle Monitoring System**
3.  **Cursor and Window Management System**

Below is a detailed explanation of each component.

---

### 1. Hot Button Detection System

The core of the application is its ability to find and click predefined images on the screen. This system is responsible for the "hot button" functionality.

-   **Technology:** This system is primarily powered by AutoHotkey's `ImageSearch` command.
-   **Process Flow:**
    1.  **Image Definition:** The user captures a region of the screen using the "Add Hot Button" feature. This captured region is saved as a PNG image in the `hot_buttons/` directory.
    2.  **Screen Scanning:** When monitoring is active, the `ScanForHotButtons` function iterates through each image file in the `HotButtons` array.
    3.  **ImageSearch Execution:** For each image, `ImageSearch` scans the entire screen to find a matching region.
    4.  **Shade Variation:** The `*n` (shade variation) option is used with `ImageSearch`. The `n` is a value from 0 to 255, controlled by the "Shade Variation" setting in the GUI. This allows for inexact matches, which is useful if the button's color or lighting changes slightly. A value of `*0` would require a pixel-perfect match.
    5.  **Clicking:** If a match is found, the coordinates of the top-left corner of the image are returned. The application then calculates the center of the image (`FoundX + button.w/2`, `FoundY + button.h/2`) and programmatically clicks at that location.

---

### 2. Idle Monitoring System

To prevent the application from interfering with the user's work, it includes a system to detect user inactivity.

-   **Technology:** This system relies on AutoHotkey's built-in variable `A_TimeIdlePhysical`.
-   **Process Flow:**
    1.  **Idle Check:** At the beginning of each `ScanForHotButtons` cycle, the application checks the value of `A_TimeIdlePhysical`. This variable returns the number of milliseconds that have passed since the last physical keyboard or mouse input.
    2.  **Pausing:** If the idle time is less than a set threshold (currently 30,000 ms), the application assumes the user is active. It then temporarily disables the main scanning timer (`SetTimer(ScanForHotButtons, "Off")`).
    3.  **Resuming:** After pausing, a one-time, delayed timer is set using `SetTimer(EnableMonitoring, -10000)`. This timer calls the `EnableMonitoring` function after 10 seconds.
    4.  **Re-activation:** The `EnableMonitoring` function checks if monitoring is still supposed to be active and, if so, re-enables the main `ScanForHotButtons` timer. This creates a loop where the application "sleeps" and wakes up to check for inactivity, ensuring it only runs when the user is away.

---

### 3. Cursor and Window Management System

To ensure that the automated clicks do not disrupt the user's current context, the application saves and restores the state of the mouse cursor and the active window.

-   **Technology:** This system uses AutoHotkey's `MouseGetPos`, `WinGetID`, `MouseMove`, and `WinActivate` commands.
-   **Process Flow:**
    1.  **State Saving:** Immediately before a click is performed on a found hot button, the application calls:
        -   `MouseGetPos(&origX, &origY)` to store the current X and Y coordinates of the mouse cursor.
        -   `WinGetID("A")` to get the unique ID of the currently active window.
    2.  **Action Execution:** The application then moves the mouse to the center of the hot button and performs the click.
    3.  **State Restoration:** Immediately after the click, the application:
        -   Calls `MouseMove(origX, origY)` to return the cursor to its original position.
        -   Calls `WinActivate("ahk_id " activeWin)` to re-activate the window that was active before the click.

This ensures that the user's workflow is not interrupted, as the cursor and active window are restored to their original state almost instantly.