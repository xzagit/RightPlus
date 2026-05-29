<div align="center">

<img src="https://img.shields.io/badge/platform-macOS%2013%2B-blue?style=flat-square&logo=apple" alt="macOS 13+">
<img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift" alt="Swift 5.9">
<img src="https://img.shields.io/badge/license-MIT-green?style=flat-square" alt="MIT License">
<img src="https://img.shields.io/badge/status-active-brightgreen?style=flat-square" alt="Active">

# RightPlus

**The right-click menu Finder always should have had.**

Create files, copy paths, open in terminal or editor — all from a single right-click.

[中文](README.md) · [Report a Bug](https://github.com/xzagit/RightPlus/issues) · [Request a Feature](https://github.com/xzagit/RightPlus/issues)

</div>

---

## Why RightPlus?

macOS Finder has long been missing a few essential power-user features:

- No way to **create a new file** in the current folder (only folders)
- No easy way to **copy a file or folder path**
- No way to **open the current directory in a terminal**
- No way to **open the current folder in a code editor**

RightPlus fills these gaps using macOS's native **Finder Sync Extension** mechanism — no Finder replacement, no process injection. Just a lightweight, stable, configurable enhancement that lives exactly where it belongs: in the right-click menu.

---

## Features

### New File

Right-click any empty area in Finder to instantly create:

| Type | Extension | Notes |
|------|-----------|-------|
| Markdown | `.md` | Creates an empty Markdown file |
| Word Document | `.docx` | Copied from built-in template |
| Excel Spreadsheet | `.xlsx` | Copied from built-in template |
| PowerPoint Presentation | `.pptx` | Copied from built-in template |
| Blank File | none | Empty file, rename and add extension as needed |
| New Folder | — | Quick folder creation |
| Custom Templates | any | Add your own template files |

> Filenames automatically increment to avoid conflicts: `New Word Document.docx` → `New Word Document 2.docx`

### Copy Path

Copy the path of any item in Finder. The menu label adapts to context:

| Context | Menu Items |
|---------|------------|
| Empty area | Copy current folder path / Copy parent directory path |
| Folder selected | Copy folder path / Copy parent directory path |
| File selected | Copy file path / Copy containing folder path |
| Multi-select | Copy all paths, one per line |

> When both copy options are enabled, they appear in a submenu. When only one is enabled, it shows as a top-level item for a cleaner menu.

### Open in Terminal

Right-click any folder or empty area to open it in your terminal, with `cd` already run. Supports:

- iTerm2
- Terminal (built-in macOS)
- Warp
- Or any terminal app you choose

### Open in Editor

Right-click any folder or empty area to open it in your code editor. Supports:

- Visual Studio Code
- Cursor
- PyCharm
- IntelliJ IDEA
- Sublime Text
- Or any editor app you choose

---

## Settings App

RightPlus includes a full settings app with sidebar navigation:

```
RightPlus
├── Overview       — Extension status, permissions, installed app detection
├── Menu Items     — Toggle each menu item on or off
├── Open With      — Choose your terminal and editor apps
├── Templates      — Manage Office templates, add custom templates
├── Diagnostics    — Permission checks, restart Finder, view logs
└── About          — Version info
```

All settings take effect immediately — changes are reflected the next time you open the right-click menu, no Finder restart required.

---

## Installation

### Requirements

- macOS 13 Ventura or later
- Xcode 15+ (for building from source)

### Build from Source

```bash
git clone https://github.com/xzagit/RightPlus.git
cd RightPlus
open RightPlus.xcodeproj
```

Select the `RightPlus` scheme in Xcode and build (`⌘R`).

> On first launch, you'll need to enable the RightPlus extension in **System Settings → Privacy & Security → Extensions → Finder**.

### First Launch

1. Open the RightPlus app
2. Go to Overview and follow the prompts to enable the Finder extension
3. If you want "Open in Terminal", grant Automation permission in System Settings
4. Right-click in Finder — the RightPlus menu should now appear

---

## Architecture

```
RightPlus
├── RightPlus/                        # Main App (Settings UI)
│   ├── Views/                        # SwiftUI views
│   ├── Shared/                       # Code shared with the Extension
│   │   ├── Constants.swift           # Path constants (getpwuid for real home dir)
│   │   ├── SettingsManager.swift     # Settings read/write via plist
│   │   └── TemplateConfig.swift      # Custom template data model
│   └── RightPlusApp.swift
│
└── FinderSyncExtension/              # Finder Sync Extension
    ├── FinderSync.swift              # Menu building and dynamic responses
    ├── Actions/
    │   ├── NewFileAction.swift       # File creation logic
    │   ├── CopyPathAction.swift      # Path copy logic
    │   ├── OpenTerminalAction.swift  # Terminal open (.command script approach)
    │   └── OpenEditorAction.swift    # Editor open
    ├── Templates/                    # Built-in Office templates
    │   ├── 未命名.docx
    │   ├── 未命名.xlsx
    │   └── 未命名.pptx
    ├── SettingsManager.swift         # Read-only, reloads on every menu build
    ├── TemplateConfig.swift
    └── Constants.swift
```

### Key Design Decisions

**Cross-process settings sync**: The main app and the Extension run in separate sandboxed processes. They share configuration via `~/Library/Application Support/RightPlus/settings.plist`. The Extension reloads this file at the start of every `menu()` call, so settings changes are immediately visible.

**Real home directory**: macOS sandboxing redirects `FileManager.homeDirectoryForCurrentUser` to the app's container. We use `getpwuid(getuid())` to get the real system home directory (`/Users/username`), ensuring both processes read and write the same config file.

**Terminal open approach**: Terminal apps are opened via a `.command` script file and `open -a appName`, bypassing macOS TCC restrictions that would otherwise require an explicit user authorization dialog when controlling iTerm2 via AppleScript on macOS 13+.

---

## Custom Templates

Beyond the built-in Office templates, you can add templates in any format:

1. Open RightPlus → Template Management
2. Click "Add Template..." and pick any file to use as a template
3. Set a display name (shown in the right-click menu)
4. In Menu Settings, you can toggle each custom template on or off individually

Template files are stored in `~/Library/Application Support/RightPlus/Templates/`. You can also replace the built-in Word/Excel/PowerPoint templates there with your own versions.

---

## Permissions

| Permission | Purpose | Required |
|------------|---------|---------|
| Finder Extension | Show right-click menu | Yes |
| Full Disk Access | Create files in any directory | Recommended |
| Automation (Finder) | Auto-select newly created files | Optional |

---

## Contributing

Issues and pull requests are welcome!

1. Fork the repository
2. Create your feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'feat: add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">

If RightPlus is useful to you, consider leaving a Star ⭐

</div>
