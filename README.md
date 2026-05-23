# DevKit v2

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg?style=flat-square)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0+-blue.svg?style=flat-square)](https://apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

**DevKit v2** is a personal macOS utility designed to streamline my local development workflow. It is a high-performance native application with a stunning "Liquid Glass" aesthetic, built to consolidate the daily chores I encounter while developing on Intel-based Macs.

> **Note:** This is a personal project tailored specifically to my development needs and environment. While shared as open-source, it is primarily optimized for a Homebrew-based setup on Intel Mac.

---

## ✨ Features

### 🛠 Service Management
- **Live Monitoring:** Real-time status tracking for Apache (`httpd`) and MySQL.
- **One-Click Controls:** Start, stop, and restart services directly from the menu bar or main window.
- **DocumentRoot Switcher:** Instantly change Apache's DocumentRoot and `<Directory>` paths with automatic configuration backups.

### 🔌 Port & Process Manager
- **Active Port Lister:** View all listening ports and their associated PIDs/Process names.
- **Fast Kill:** Terminate dev ports (3000, 5173, 8000, etc.) with a single click or manual PID entry.

### 📝 Hosts & DNS
- **Hosts Editor:** Manage `/etc/hosts` entries through a clean GUI (supports sudo privilege escalation).
- **DNS Flush:** Instantly flush macOS DNS cache.

### 🧹 Maintenance Tools
- **Screenshot Cleaner:** Bulk-move macOS desktop screenshots to the Trash to keep your workspace clean.
- **Environment Checker:** Instant version reports for Node.js, npm, PHP, Python, Git, Composer, and Homebrew.
- **Disk Usage:** Visual breakdown of partition usage and free space.
- **Dev Clipboard:** Save and quickly copy frequently used code snippets, tokens, or terminal commands.

---

## 🎨 Aesthetic: Liquid Glass
DevKit v2 features a bespoke **Liquid Glass** design language. 
- **Translucency:** Leverages `.ultraThinMaterial` for a native, glass-morphic feel.
- **Dynamic Glows:** Interactive elements feature subtle glows and shimmer effects that respond to system theme changes.
- **Minimalist:** A focus on high-signal data with minimal visual clutter.

---

## 💻 Tech Stack
- **Language:** Swift 5.9+
- **Frameworks:** SwiftUI, Foundation, AppKit
- **Architecture:** MVVM (Model-View-ViewModel)
- **Zero Dependencies:** Built entirely with native Apple frameworks. No external package managers required.
- **Privilege Management:** Uses `osascript` for secure, native macOS credential prompts for system-level changes.

---

## 🚀 Installation

### Prerequisites
- macOS 13.0 (Ventura) or higher.
- Intel-based Mac (Homebrew installed at `/usr/local`).

### Download
*Note: As this is an open-source tool, you can build it from source or check the [Releases](https://github.com/yerros/DevKit/releases) page for the latest `.dmg`.*

---

## 🛠 Building from Source

### 1. Clone the repository
```bash
git clone https://github.com/yerros/DevKit.git
cd DevKit
```

### 2. Generate the Xcode Project
This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to manage project files.
```bash
brew install xcodegen
xcodegen generate
```

### 3. Build & Run
You can open `DevKit.xcodeproj` in Xcode or use the CLI:
```bash
# Build Debug
xcodebuild -scheme DevKit -configuration Debug build

# Build Release DMG
./scripts/build-dmg.sh
```

---

## ⚙️ Configuration
The application stores its configuration at `~/.devkit/config.json`. This includes:
- Refresh intervals
- DocumentRoot presets
- Saved clipboard snippets
- Custom port presets

---

## 🤝 Contributing
Contributions are welcome! Please feel free to submit a Pull Request.
1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License
Distributed under the MIT License. See `LICENSE` for more information.

---

## 🙏 Acknowledgements
- Inspired by the original DevKit Python version.
- Glassmorphism techniques inspired by modern macOS design trends.
