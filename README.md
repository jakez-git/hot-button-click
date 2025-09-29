# Hot Button Clicker

A simple AutoHotkey application to automate repetitive clicking tasks by identifying and clicking on-screen buttons from screenshots.

---

## Table of Contents

- [About The Project](#about-the-project)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Contributing](#contributing)
- [License](#license)

---

## About The Project

Hot Button Clicker is a utility built with AutoHotkey v2 that allows users to automate clicks on specific UI elements. You can define these elements, or "hot buttons," by taking a screenshot of any region on your screen.

The application then monitors the screen for these hot buttons to appear and automatically clicks them for you. It's designed to be "user-aware," meaning it will pause its monitoring if it detects that you are actively using the computer, preventing any interference with your work.

This tool is ideal for automating repetitive tasks in games, software testing, or any workflow that involves clicking the same buttons over and over.

### Key Features

-   **Define Hot Buttons via Screenshots:** Easily capture any part of the screen to create a clickable hot button.
-   **Automatic Clicking:** The application finds and clicks the hot buttons for you.
-   **Idle Monitoring:** Smartly pauses when you are using your computer and resumes when you're idle.
-   **Adjustable Match Tolerance:** Control the "shade variation" to find buttons even if their appearance changes slightly.
-   **Simple GUI:** An intuitive interface to manage your hot buttons and control the monitoring process.

---

## Getting Started

Follow these simple steps to get the Hot Button Clicker up and running on your system.

### Prerequisites

You must have **AutoHotkey v2** installed. If you don't have it, you can download it from the official website:

-   [Download AutoHotkey v2](https://www.autohotkey.com/v2/)

### Installation

1.  **Clone the repository or download the source code:**
    ```sh
    git clone https://github.com/your-username/hot-button-click.git
    ```
2.  **Navigate to the project directory:**
    ```sh
    cd hot-button-click
    ```
3.  That's it! No complex installation is required.

---

## Usage

### 1. Start the Application

-   Double-click `start.bat` to launch the application. The main GUI window will appear.

### 2. Add a Hot Button

-   Click the **"Add Hot Button"** button. The application window will hide.
-   Your cursor will change, indicating it's ready to capture. Click and drag your mouse to select the screen region you want to define as a hot button.
-   Release the mouse. A screenshot of the selected area will be saved in the `hot_buttons/` folder, and its path will appear in the list view.

### 3. Configure Shade Variation

-   The **"Shade Variation"** input allows you to control how strictly the application matches the hot button image.
-   The value can range from `0` (exact match) to `255` (very loose match). A higher value can help find buttons that have slight variations in color or shading. The default is `10`.

### 4. Start and Stop Monitoring

-   Click **"Start Monitoring"** to begin scanning the screen for your defined hot buttons. The status bar will update to "Monitoring...".
-   If a hot button is found, the application will click it.
-   The application will automatically pause if it detects mouse or keyboard activity and will resume after 30 seconds of inactivity.
-   Click **"Stop Monitoring"** at any time to halt the process.

### 5. Stop the Application

-   Double-click `stop.bat` to completely exit the application.

---

## How It Works

The application's logic is handled by `simple_ui.ahk` and relies on a few core concepts:

-   **Image Search:** It uses AutoHotkey's built-in `ImageSearch` command to scan the screen for the PNG images saved in the `hot_buttons/` directory.
-   **Idle Time Monitoring:** It checks the `A_TimeIdlePhysical` built-in variable to determine if the user has been inactive. This prevents the script from interfering with the user's actions.
-   **GDI+ Library:** The screenshot functionality is powered by the included `AHKv2_Screenshot_Tools.ahk` library, which provides advanced graphics and screen capture capabilities.

---

## Contributing

Contributions are welcome! Please read the `CONTRIBUTING.md` file for details on our code of conduct and the process for submitting pull requests.

---

## License

This project is licensed under the MIT License. See the `LICENSE.md` file for details.