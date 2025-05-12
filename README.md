
# SystemMonitorApp

A modern, lightweight macOS system monitor built with SwiftUI.

## Features

- **Live CPU Utilization Graph:** See your CPU usage in real time with a smooth animated chart.
- **Real Memory Info:** Displays live free and total memory (in GB, rounded up).
- **Real Disk Info:** Shows total, used, and free disk space (in GB).
- **System Details:** View CPU architecture, core count, OS version, boot time, uptime (in hours and minutes), and model name.
- **Running Applications:** Lists currently running user-visible applications with search and sorting.
- **Appearance Settings:** Choose between Light, Dark, or Automatic (system) appearance.
- **Clean UI:** Modern, rounded fonts and a translucent background.

## Screenshots

## Screenshots



## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/M0l0k0plv5/SystemMonitorApp.git
   cd SystemMonitorApp
   ```

2. **Open in Xcode:**

   - Double-click `SystemMonitorApp.xcodeproj` or open it from Xcode’s File > Open menu.

3. **Build & Run:**

   - Select the target `SystemMonitorApp` and press ⌘R to build and run.

## Usage

- The main window displays system info on the left and live CPU/process info on the right.
- Click the **Settings** button (bottom right) to choose Light, Dark, or Automatic appearance.
- The process list is searchable and sortable by name or PID.

## Technical Notes

- **No dependencies:** Uses only native Swift and Apple frameworks.
- **App Store–safe:** No private APIs or SMC/IOKit hacks.
- **No GPU, fan speed, or CPU temperature:** (macOS does not provide these via public APIs.)
- **Process List:** Shows running applications (not all system processes).

## Contributing

Pull requests are welcome! Please open an issue first to discuss any major changes.

## License

MIT License. See [LICENSE](LICENSE) for details.


![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
