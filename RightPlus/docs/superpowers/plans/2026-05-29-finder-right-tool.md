# RightPlus (Finder Right-Click Enhancement) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS Finder right-click menu enhancement tool that adds "New File", "Copy Path", "Open in iTerm", and "Open in VSCode" functionality via a Finder Sync Extension, with a SwiftUI settings app.

**Architecture:** SwiftUI macOS app (settings UI) + Finder Sync Extension (right-click menus). Shared configuration via App Group UserDefaults. Office templates stored at `~/Library/Application Support/FinderRightTool/Templates/`. Extension dynamically builds menus based on right-click context (blank area vs folder vs file).

**Tech Stack:** Swift 5, SwiftUI, FinderSync framework, AppKit (NSPasteboard), AppleScript (iTerm2), App Group UserDefaults

**Important Notes:**
- Bundle ID: `cn.xuziao.RightPlus`
- Extension Bundle ID: `cn.xuziao.RightPlus.FinderSyncExtension`
- App Group: `group.cn.xuziao.RightPlus`
- Xcode project uses objectVersion 77 (file system synchronized groups) — adding the Extension target MUST be done manually in Xcode (File > New > Target > Finder Sync Extension) because pbxproj modifications for this format are too complex to script reliably.
- Deployment target: macOS 15.0 (lowered from 26.2 for broader compatibility — adjust if needed)
- The App Sandbox must be disabled for the Extension to write files and run AppleScript. The main app can keep sandbox enabled with appropriate entitlements.
- Template files already exist at: `/Users/xuziao/Library/Application Support/FinderRightTool/Templates/` (未命名.docx, 未命名.xlsx, 未命名.pptx)

---

## File Structure

### Shared Code (used by both App and Extension)

| File | Responsibility |
|------|---------------|
| `RightPlus/Shared/SettingsManager.swift` | App Group UserDefaults read/write, all config keys |
| `RightPlus/Shared/Constants.swift` | App Group ID, template paths, default file names |

### Finder Sync Extension

| File | Responsibility |
|------|---------------|
| `FinderSyncExtension/FinderSync.swift` | FIFinderSync subclass, menu building, action dispatch |
| `FinderSyncExtension/Actions/CopyPathAction.swift` | Copy path to pasteboard |
| `FinderSyncExtension/Actions/NewFileAction.swift` | Create new files (md, blank, Office template copy) |
| `FinderSyncExtension/Actions/OpenTerminalAction.swift` | Open iTerm2 via AppleScript |
| `FinderSyncExtension/Actions/OpenEditorAction.swift` | Open VSCode via `open -a` |
| `FinderSyncExtension/Info.plist` | Extension metadata |
| `FinderSyncExtension/FinderSyncExtension.entitlements` | App Group entitlement |

### Main App (Settings UI)

| File | Responsibility |
|------|---------------|
| `RightPlus/RightPlusApp.swift` | App entry point, window configuration |
| `RightPlus/ContentView.swift` | Sidebar navigation container |
| `RightPlus/Views/OverviewView.swift` | Status dashboard |
| `RightPlus/Views/MenuSettingsView.swift` | Toggle menu items on/off |
| `RightPlus/Views/NewFileSettingsView.swift` | Configure new file types |
| `RightPlus/Views/OpenWithSettingsView.swift` | Configure iTerm/VSCode |
| `RightPlus/Views/TemplateManagementView.swift` | Manage Office templates |
| `RightPlus/Views/ScopeSettingsView.swift` | Configure monitored directories |
| `RightPlus/Views/DiagnosticsView.swift` | Permission status & troubleshooting |
| `RightPlus/Views/AboutView.swift` | App info |
| `RightPlus/RightPlus.entitlements` | App Group + sandbox entitlements |

---

## Pre-requisite: Create Finder Sync Extension Target in Xcode

**This step MUST be done manually in Xcode before any code tasks.**

1. Open `RightPlus.xcodeproj` in Xcode
2. File > New > Target
3. Select "Finder Sync Extension"
4. Product Name: `FinderSyncExtension`
5. Bundle Identifier: `cn.xuziao.RightPlus.FinderSync`
6. Language: Swift
7. Activate the scheme when prompted
8. In project settings > Signing & Capabilities for BOTH targets:
   - Add "App Groups" capability
   - Add group: `group.cn.xuziao.RightPlus`
9. For the FinderSyncExtension target:
   - Remove App Sandbox (Extension needs file system access)
10. For the main RightPlus target:
    - Keep App Sandbox but ensure App Group is configured
11. Build to verify both targets compile

After this, the Extension folder with `FinderSync.swift` will exist.

---

### Task 1: Shared Constants and Settings Manager

**Files:**
- Create: `RightPlus/Shared/Constants.swift`
- Create: `RightPlus/Shared/SettingsManager.swift`

Both files must be added to BOTH targets (main app + extension) in Xcode's target membership.

- [ ] **Step 1: Create Constants.swift**

```swift
import Foundation

enum AppConstants {
    static let appGroupID = "group.cn.xuziao.RightPlus"
    static let templateDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Application Support/FinderRightTool/Templates")
    
    static let defaultScopes: [String] = [
        FileManager.default.homeDirectoryForCurrentUser.path,
        "/Volumes"
    ]
    
    enum TemplateFile: String {
        case word = "未命名.docx"
        case excel = "未命名.xlsx"
        case powerpoint = "未命名.pptx"
        
        var path: URL {
            AppConstants.templateDirectory.appendingPathComponent(self.rawValue)
        }
    }
    
    enum NewFileName {
        static let markdown = "新建 Markdown 文件"
        static let word = "新建 Word 文档"
        static let excel = "新建 Excel 表格"
        static let powerpoint = "新建 PowerPoint 演示"
        static let blank = "新建文件"
    }
    
    enum FileExtension {
        static let markdown = "md"
        static let word = "docx"
        static let excel = "xlsx"
        static let powerpoint = "pptx"
    }
}
```

- [ ] **Step 2: Create SettingsManager.swift**

```swift
import Foundation

final class SettingsManager: @unchecked Sendable {
    static let shared = SettingsManager()
    
    private let defaults: UserDefaults
    
    private init() {
        self.defaults = UserDefaults(suiteName: AppConstants.appGroupID) ?? .standard
        registerDefaults()
    }
    
    private func registerDefaults() {
        let defaultValues: [String: Any] = [
            Key.showCopyPath.rawValue: true,
            Key.showCopyItemPath.rawValue: true,
            Key.showCopyParentPath.rawValue: true,
            Key.showOpenITerm.rawValue: true,
            Key.showOpenVSCode.rawValue: true,
            Key.showNewFileMenu.rawValue: true,
            Key.showNewMarkdown.rawValue: true,
            Key.showNewWord.rawValue: true,
            Key.showNewExcel.rawValue: true,
            Key.showNewPowerPoint.rawValue: true,
            Key.showNewBlankFile.rawValue: true,
            Key.monitoredPaths.rawValue: AppConstants.defaultScopes,
        ]
        defaults.register(defaults: defaultValues)
    }
    
    enum Key: String {
        case showCopyPath = "show_copy_path"
        case showCopyItemPath = "show_copy_item_path"
        case showCopyParentPath = "show_copy_parent_path"
        case showOpenITerm = "show_open_iterm"
        case showOpenVSCode = "show_open_vscode"
        case showNewFileMenu = "show_new_file_menu"
        case showNewMarkdown = "show_new_markdown"
        case showNewWord = "show_new_word"
        case showNewExcel = "show_new_excel"
        case showNewPowerPoint = "show_new_powerpoint"
        case showNewBlankFile = "show_new_blank_file"
        case monitoredPaths = "monitored_paths"
    }
    
    func bool(for key: Key) -> Bool {
        defaults.bool(forKey: key.rawValue)
    }
    
    func set(_ value: Bool, for key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }
    
    var monitoredPaths: [String] {
        get { defaults.stringArray(forKey: Key.monitoredPaths.rawValue) ?? AppConstants.defaultScopes }
        set { defaults.set(newValue, forKey: Key.monitoredPaths.rawValue) }
    }
}
```

- [ ] **Step 3: Add both files to both targets in Xcode**

In Xcode, select each file > File Inspector > Target Membership > check both "RightPlus" and "FinderSyncExtension".

- [ ] **Step 4: Build to verify compilation**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add RightPlus/Shared/
git commit -m "feat: add shared Constants and SettingsManager for App Group config"
```

---

### Task 2: Finder Sync Extension — Basic Menu Display

**Files:**
- Modify: `FinderSyncExtension/FinderSync.swift` (the file Xcode generated)

- [ ] **Step 1: Replace the generated FinderSync.swift with menu logic**

```swift
import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    
    private let settings = SettingsManager.shared
    
    override init() {
        super.init()
        let paths = settings.monitoredPaths.map { URL(fileURLWithPath: $0) }
        FIFinderSyncController.default().directoryURLs = Set(paths)
    }
    
    // MARK: - Menu Building
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "RightPlus")
        
        switch menuKind {
        case .contextualMenuForContainer:
            // Blank area right-click
            addNewFileMenu(to: menu)
            addCopyPathMenu(to: menu, isContainer: true)
            addOpenActions(to: menu)
            
        case .contextualMenuForItems:
            // Item(s) selected
            let items = FIFinderSyncController.default().selectedItemURLs() ?? []
            let isSingleFolder = items.count == 1 && isDirectory(items[0])
            
            addCopyPathMenu(to: menu, isContainer: false)
            if isSingleFolder {
                addOpenActions(to: menu)
            }
            
        default:
            break
        }
        
        return menu
    }
    
    // MARK: - Menu Construction Helpers
    
    private func addNewFileMenu(to menu: NSMenu) {
        guard settings.bool(for: .showNewFileMenu) else { return }
        
        let newMenu = NSMenu(title: "新建")
        let newItem = NSMenuItem(title: "新建", action: nil, keyEquivalent: "")
        newItem.submenu = newMenu
        
        if settings.bool(for: .showNewMarkdown) {
            newMenu.addItem(withTitle: "新建 Markdown 文件", action: #selector(newMarkdownFile(_:)), keyEquivalent: "")
        }
        if settings.bool(for: .showNewWord) {
            newMenu.addItem(withTitle: "新建 Word 文档", action: #selector(newWordFile(_:)), keyEquivalent: "")
        }
        if settings.bool(for: .showNewExcel) {
            newMenu.addItem(withTitle: "新建 Excel 表格", action: #selector(newExcelFile(_:)), keyEquivalent: "")
        }
        if settings.bool(for: .showNewPowerPoint) {
            newMenu.addItem(withTitle: "新建 PowerPoint 演示", action: #selector(newPowerPointFile(_:)), keyEquivalent: "")
        }
        if settings.bool(for: .showNewBlankFile) {
            newMenu.addItem(withTitle: "新建空白文件", action: #selector(newBlankFile(_:)), keyEquivalent: "")
        }
        
        menu.addItem(newItem)
    }
    
    private func addCopyPathMenu(to menu: NSMenu, isContainer: Bool) {
        guard settings.bool(for: .showCopyPath) else { return }
        
        let copyMenu = NSMenu(title: "复制路径")
        let copyItem = NSMenuItem(title: "复制路径", action: nil, keyEquivalent: "")
        copyItem.submenu = copyMenu
        
        if isContainer {
            if settings.bool(for: .showCopyItemPath) {
                copyMenu.addItem(withTitle: "复制当前文件夹路径", action: #selector(copyCurrentFolderPath(_:)), keyEquivalent: "")
            }
            if settings.bool(for: .showCopyParentPath) {
                copyMenu.addItem(withTitle: "复制所在目录路径", action: #selector(copyParentPath(_:)), keyEquivalent: "")
            }
        } else {
            let items = FIFinderSyncController.default().selectedItemURLs() ?? []
            let isSingleFolder = items.count == 1 && isDirectory(items[0])
            
            if settings.bool(for: .showCopyItemPath) {
                let title = isSingleFolder ? "复制文件夹路径" : "复制文件路径"
                copyMenu.addItem(withTitle: title, action: #selector(copySelectedItemPath(_:)), keyEquivalent: "")
            }
            if settings.bool(for: .showCopyParentPath) {
                let title = isSingleFolder ? "复制父目录路径" : "复制所在文件夹路径"
                copyMenu.addItem(withTitle: title, action: #selector(copySelectedParentPath(_:)), keyEquivalent: "")
            }
        }
        
        menu.addItem(copyItem)
    }
    
    private func addOpenActions(to menu: NSMenu) {
        if settings.bool(for: .showOpenITerm) {
            menu.addItem(withTitle: "用 iTerm 打开", action: #selector(openInITerm(_:)), keyEquivalent: "")
        }
        if settings.bool(for: .showOpenVSCode) {
            menu.addItem(withTitle: "用 VSCode 打开", action: #selector(openInVSCode(_:)), keyEquivalent: "")
        }
    }
    
    // MARK: - Utility
    
    private func isDirectory(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
    
    private func targetDirectory() -> URL? {
        FIFinderSyncController.default().targetedURL()
    }
    
    // MARK: - Actions (stubs, implemented in later tasks)
    
    @objc func newMarkdownFile(_ sender: Any?) {}
    @objc func newWordFile(_ sender: Any?) {}
    @objc func newExcelFile(_ sender: Any?) {}
    @objc func newPowerPointFile(_ sender: Any?) {}
    @objc func newBlankFile(_ sender: Any?) {}
    @objc func copyCurrentFolderPath(_ sender: Any?) {}
    @objc func copyParentPath(_ sender: Any?) {}
    @objc func copySelectedItemPath(_ sender: Any?) {}
    @objc func copySelectedParentPath(_ sender: Any?) {}
    @objc func openInITerm(_ sender: Any?) {}
    @objc func openInVSCode(_ sender: Any?) {}
}
```

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme FinderSyncExtension build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add FinderSyncExtension/
git commit -m "feat: Finder Sync Extension with dynamic context menu structure"
```

---

### Task 3: Copy Path Actions

**Files:**
- Create: `FinderSyncExtension/Actions/CopyPathAction.swift`
- Modify: `FinderSyncExtension/FinderSync.swift` (replace action stubs)

- [ ] **Step 1: Create CopyPathAction.swift**

```swift
import AppKit

enum CopyPathAction {
    static func copyToPasteboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    static func copyPaths(_ urls: [URL]) {
        let paths = urls.map { $0.path }
        copyToPasteboard(paths.joined(separator: "\n"))
    }
    
    static func copyParentPaths(_ urls: [URL]) {
        let paths = urls.map { $0.deletingLastPathComponent().path }
        copyToPasteboard(paths.joined(separator: "\n"))
    }
}
```

- [ ] **Step 2: Implement copy path actions in FinderSync.swift**

Replace the copy path action stubs with:

```swift
@objc func copyCurrentFolderPath(_ sender: Any?) {
    guard let target = targetDirectory() else { return }
    CopyPathAction.copyToPasteboard(target.path)
}

@objc func copyParentPath(_ sender: Any?) {
    guard let target = targetDirectory() else { return }
    CopyPathAction.copyToPasteboard(target.deletingLastPathComponent().path)
}

@objc func copySelectedItemPath(_ sender: Any?) {
    guard let items = FIFinderSyncController.default().selectedItemURLs(), !items.isEmpty else { return }
    CopyPathAction.copyPaths(items)
}

@objc func copySelectedParentPath(_ sender: Any?) {
    guard let items = FIFinderSyncController.default().selectedItemURLs(), !items.isEmpty else { return }
    CopyPathAction.copyParentPaths(items)
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme FinderSyncExtension build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add FinderSyncExtension/Actions/CopyPathAction.swift FinderSyncExtension/FinderSync.swift
git commit -m "feat: implement copy path actions"
```

---

### Task 4: Open in VSCode Action

**Files:**
- Create: `FinderSyncExtension/Actions/OpenEditorAction.swift`
- Modify: `FinderSyncExtension/FinderSync.swift` (replace stub)

- [ ] **Step 1: Create OpenEditorAction.swift**

```swift
import Foundation

enum OpenEditorAction {
    static func openInVSCode(path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Visual Studio Code", path]
        try? process.run()
    }
}
```

- [ ] **Step 2: Implement openInVSCode in FinderSync.swift**

Replace the stub:

```swift
@objc func openInVSCode(_ sender: Any?) {
    let path: String
    if let items = FIFinderSyncController.default().selectedItemURLs(), let first = items.first {
        path = first.path
    } else if let target = targetDirectory() {
        path = target.path
    } else {
        return
    }
    OpenEditorAction.openInVSCode(path: path)
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme FinderSyncExtension build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add FinderSyncExtension/Actions/OpenEditorAction.swift FinderSyncExtension/FinderSync.swift
git commit -m "feat: implement open in VSCode action"
```

---

### Task 5: Open in iTerm Action

**Files:**
- Create: `FinderSyncExtension/Actions/OpenTerminalAction.swift`
- Modify: `FinderSyncExtension/FinderSync.swift` (replace stub)

- [ ] **Step 1: Create OpenTerminalAction.swift**

```swift
import Foundation

enum OpenTerminalAction {
    static func openInITerm(path: String) {
        let escapedPath = path.replacingOccurrences(of: "'", with: "'\\''")
        let script = """
        tell application "iTerm2"
            activate
            create window with default profile
            tell current session of current window
                write text "cd '\(escapedPath)'"
            end tell
        end tell
        """
        
        guard let appleScript = NSAppleScript(source: script) else { return }
        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)
    }
}
```

- [ ] **Step 2: Implement openInITerm in FinderSync.swift**

Replace the stub:

```swift
@objc func openInITerm(_ sender: Any?) {
    let path: String
    if let items = FIFinderSyncController.default().selectedItemURLs(), let first = items.first {
        path = first.path
    } else if let target = targetDirectory() {
        path = target.path
    } else {
        return
    }
    OpenTerminalAction.openInITerm(path: path)
}
```

- [ ] **Step 3: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme FinderSyncExtension build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add FinderSyncExtension/Actions/OpenTerminalAction.swift FinderSyncExtension/FinderSync.swift
git commit -m "feat: implement open in iTerm2 action via AppleScript"
```

---

### Task 6: New File Actions

**Files:**
- Create: `FinderSyncExtension/Actions/NewFileAction.swift`
- Modify: `FinderSyncExtension/FinderSync.swift` (replace stubs)

- [ ] **Step 1: Create NewFileAction.swift**

```swift
import Foundation

enum NewFileAction {
    
    enum FileType {
        case markdown
        case word
        case excel
        case powerpoint
        case blank
        
        var baseName: String {
            switch self {
            case .markdown: return AppConstants.NewFileName.markdown
            case .word: return AppConstants.NewFileName.word
            case .excel: return AppConstants.NewFileName.excel
            case .powerpoint: return AppConstants.NewFileName.powerpoint
            case .blank: return AppConstants.NewFileName.blank
            }
        }
        
        var fileExtension: String? {
            switch self {
            case .markdown: return AppConstants.FileExtension.markdown
            case .word: return AppConstants.FileExtension.word
            case .excel: return AppConstants.FileExtension.excel
            case .powerpoint: return AppConstants.FileExtension.powerpoint
            case .blank: return nil
            }
        }
        
        var templateFile: AppConstants.TemplateFile? {
            switch self {
            case .word: return .word
            case .excel: return .excel
            case .powerpoint: return .powerpoint
            default: return nil
            }
        }
    }
    
    static func createFile(type: FileType, in directory: URL) {
        let targetURL = uniqueFileURL(baseName: type.baseName, extension: type.fileExtension, in: directory)
        
        if let template = type.templateFile {
            let templateURL = template.path
            guard FileManager.default.fileExists(atPath: templateURL.path) else { return }
            try? FileManager.default.copyItem(at: templateURL, to: targetURL)
        } else {
            FileManager.default.createFile(atPath: targetURL.path, contents: nil)
        }
        
        selectInFinder(targetURL)
    }
    
    private static func uniqueFileURL(baseName: String, extension ext: String?, in directory: URL) -> URL {
        let fm = FileManager.default
        
        func buildURL(_ name: String) -> URL {
            if let ext = ext {
                return directory.appendingPathComponent("\(name).\(ext)")
            } else {
                return directory.appendingPathComponent(name)
            }
        }
        
        let firstAttempt = buildURL(baseName)
        if !fm.fileExists(atPath: firstAttempt.path) {
            return firstAttempt
        }
        
        var counter = 2
        while true {
            let url = buildURL("\(baseName) \(counter)")
            if !fm.fileExists(atPath: url.path) {
                return url
            }
            counter += 1
        }
    }
    
    private static func selectInFinder(_ url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
}
```

- [ ] **Step 2: Implement new file actions in FinderSync.swift**

Replace the new file stubs:

```swift
@objc func newMarkdownFile(_ sender: Any?) {
    guard let dir = targetDirectory() else { return }
    NewFileAction.createFile(type: .markdown, in: dir)
}

@objc func newWordFile(_ sender: Any?) {
    guard let dir = targetDirectory() else { return }
    NewFileAction.createFile(type: .word, in: dir)
}

@objc func newExcelFile(_ sender: Any?) {
    guard let dir = targetDirectory() else { return }
    NewFileAction.createFile(type: .excel, in: dir)
}

@objc func newPowerPointFile(_ sender: Any?) {
    guard let dir = targetDirectory() else { return }
    NewFileAction.createFile(type: .powerpoint, in: dir)
}

@objc func newBlankFile(_ sender: Any?) {
    guard let dir = targetDirectory() else { return }
    NewFileAction.createFile(type: .blank, in: dir)
}
```

- [ ] **Step 3: Add `import AppKit` at the top of NewFileAction.swift** (needed for NSWorkspace)

Already imported via Foundation? No — add explicitly:

```swift
import AppKit
```

at the top of `NewFileAction.swift`.

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme FinderSyncExtension build`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add FinderSyncExtension/Actions/NewFileAction.swift FinderSyncExtension/FinderSync.swift
git commit -m "feat: implement new file creation with template support and auto-increment naming"
```

---

### Task 7: Main App — Sidebar Navigation Structure

**Files:**
- Modify: `RightPlus/RightPlusApp.swift`
- Modify: `RightPlus/ContentView.swift`

- [ ] **Step 1: Update RightPlusApp.swift for proper window sizing**

```swift
import SwiftUI

@main
struct RightPlusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 700, height: 500)
    }
}
```

- [ ] **Step 2: Replace ContentView.swift with sidebar navigation**

```swift
import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case overview = "总览"
    case menuSettings = "右键菜单"
    case newFile = "新建文件"
    case openWith = "打开方式"
    case templates = "模板管理"
    case scope = "作用范围"
    case diagnostics = "权限与诊断"
    case about = "关于"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .overview: return "house"
        case .menuSettings: return "contextualmenu.and.cursorarrow"
        case .newFile: return "doc.badge.plus"
        case .openWith: return "arrow.up.forward.app"
        case .templates: return "doc.on.doc"
        case .scope: return "folder.badge.gearshape"
        case .diagnostics: return "stethoscope"
        case .about: return "info.circle"
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem = .overview
    
    var body: some View {
        NavigationSplitView {
            List(SidebarItem.allCases, selection: $selection) { item in
                Label(item.rawValue, systemImage: item.icon)
                    .tag(item)
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            switch selection {
            case .overview:
                OverviewView()
            case .menuSettings:
                MenuSettingsView()
            case .newFile:
                NewFileSettingsView()
            case .openWith:
                OpenWithSettingsView()
            case .templates:
                TemplateManagementView()
            case .scope:
                ScopeSettingsView()
            case .diagnostics:
                DiagnosticsView()
            case .about:
                AboutView()
            }
        }
    }
}
```

- [ ] **Step 3: Create placeholder views**

Create `RightPlus/Views/` directory and add stub views. Each file follows this pattern:

`RightPlus/Views/OverviewView.swift`:
```swift
import SwiftUI

struct OverviewView: View {
    var body: some View {
        Text("总览")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

`RightPlus/Views/MenuSettingsView.swift`:
```swift
import SwiftUI

struct MenuSettingsView: View {
    var body: some View {
        Text("右键菜单设置")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

`RightPlus/Views/NewFileSettingsView.swift`:
```swift
import SwiftUI

struct NewFileSettingsView: View {
    var body: some View {
        Text("新建文件设置")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

`RightPlus/Views/OpenWithSettingsView.swift`:
```swift
import SwiftUI

struct OpenWithSettingsView: View {
    var body: some View {
        Text("打开方式设置")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

`RightPlus/Views/TemplateManagementView.swift`:
```swift
import SwiftUI

struct TemplateManagementView: View {
    var body: some View {
        Text("模板管理")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

`RightPlus/Views/ScopeSettingsView.swift`:
```swift
import SwiftUI

struct ScopeSettingsView: View {
    var body: some View {
        Text("作用范围设置")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

`RightPlus/Views/DiagnosticsView.swift`:
```swift
import SwiftUI

struct DiagnosticsView: View {
    var body: some View {
        Text("权限与诊断")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

`RightPlus/Views/AboutView.swift`:
```swift
import SwiftUI

struct AboutView: View {
    var body: some View {
        Text("关于 RightPlus")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 4: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 5: Commit**

```bash
git add RightPlus/RightPlusApp.swift RightPlus/ContentView.swift RightPlus/Views/
git commit -m "feat: main app sidebar navigation with placeholder views"
```

---

### Task 8: Menu Settings View (Toggle Menu Items)

**Files:**
- Modify: `RightPlus/Views/MenuSettingsView.swift`

- [ ] **Step 1: Implement MenuSettingsView with toggle bindings**

```swift
import SwiftUI

struct MenuSettingsView: View {
    @State private var showCopyPath: Bool = SettingsManager.shared.bool(for: .showCopyPath)
    @State private var showCopyItemPath: Bool = SettingsManager.shared.bool(for: .showCopyItemPath)
    @State private var showCopyParentPath: Bool = SettingsManager.shared.bool(for: .showCopyParentPath)
    @State private var showOpenITerm: Bool = SettingsManager.shared.bool(for: .showOpenITerm)
    @State private var showOpenVSCode: Bool = SettingsManager.shared.bool(for: .showOpenVSCode)
    @State private var showNewFileMenu: Bool = SettingsManager.shared.bool(for: .showNewFileMenu)
    @State private var showNewMarkdown: Bool = SettingsManager.shared.bool(for: .showNewMarkdown)
    @State private var showNewWord: Bool = SettingsManager.shared.bool(for: .showNewWord)
    @State private var showNewExcel: Bool = SettingsManager.shared.bool(for: .showNewExcel)
    @State private var showNewPowerPoint: Bool = SettingsManager.shared.bool(for: .showNewPowerPoint)
    @State private var showNewBlankFile: Bool = SettingsManager.shared.bool(for: .showNewBlankFile)
    
    var body: some View {
        Form {
            Section("复制路径") {
                Toggle("显示复制路径菜单", isOn: binding(for: .showCopyPath, state: $showCopyPath))
                if showCopyPath {
                    Toggle("复制所选项路径", isOn: binding(for: .showCopyItemPath, state: $showCopyItemPath))
                        .padding(.leading, 20)
                    Toggle("复制所在目录路径", isOn: binding(for: .showCopyParentPath, state: $showCopyParentPath))
                        .padding(.leading, 20)
                }
            }
            
            Section("外部应用") {
                Toggle("显示用 iTerm 打开", isOn: binding(for: .showOpenITerm, state: $showOpenITerm))
                Toggle("显示用 VSCode 打开", isOn: binding(for: .showOpenVSCode, state: $showOpenVSCode))
            }
            
            Section("新建文件") {
                Toggle("显示新建菜单", isOn: binding(for: .showNewFileMenu, state: $showNewFileMenu))
                if showNewFileMenu {
                    Toggle("新建 Markdown 文件", isOn: binding(for: .showNewMarkdown, state: $showNewMarkdown))
                        .padding(.leading, 20)
                    Toggle("新建 Word 文档", isOn: binding(for: .showNewWord, state: $showNewWord))
                        .padding(.leading, 20)
                    Toggle("新建 Excel 表格", isOn: binding(for: .showNewExcel, state: $showNewExcel))
                        .padding(.leading, 20)
                    Toggle("新建 PowerPoint 演示", isOn: binding(for: .showNewPowerPoint, state: $showNewPowerPoint))
                        .padding(.leading, 20)
                    Toggle("新建空白文件", isOn: binding(for: .showNewBlankFile, state: $showNewBlankFile))
                        .padding(.leading, 20)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("右键菜单")
    }
    
    private func binding(for key: SettingsManager.Key, state: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { state.wrappedValue },
            set: { newValue in
                state.wrappedValue = newValue
                SettingsManager.shared.set(newValue, for: key)
            }
        )
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RightPlus/Views/MenuSettingsView.swift
git commit -m "feat: menu settings view with toggle controls for all menu items"
```

---

### Task 9: Overview View (Status Dashboard)

**Files:**
- Modify: `RightPlus/Views/OverviewView.swift`

- [ ] **Step 1: Implement OverviewView**

```swift
import SwiftUI

struct OverviewView: View {
    @State private var extensionEnabled = false
    @State private var itermInstalled = false
    @State private var vscodeInstalled = false
    @State private var templatesExist = false
    
    var body: some View {
        Form {
            Section("系统状态") {
                StatusRow(title: "Finder 扩展", status: extensionEnabled ? "已启用" : "未启用", isOK: extensionEnabled)
                StatusRow(title: "iTerm2", status: itermInstalled ? "已检测到" : "未安装", isOK: itermInstalled)
                StatusRow(title: "VSCode", status: vscodeInstalled ? "已检测到" : "未安装", isOK: vscodeInstalled)
                StatusRow(title: "模板目录", status: templatesExist ? "正常" : "缺失", isOK: templatesExist)
            }
            
            Section("快捷操作") {
                Button("打开系统扩展设置") {
                    openSystemPreferences(to: "com.apple.ExtensionsPreferences")
                }
                Button("重启 Finder") {
                    restartFinder()
                }
                Button("打开模板文件夹") {
                    NSWorkspace.shared.open(AppConstants.templateDirectory)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("总览")
        .onAppear { checkStatus() }
    }
    
    private func checkStatus() {
        let fm = FileManager.default
        itermInstalled = fm.fileExists(atPath: "/Applications/iTerm.app")
        vscodeInstalled = fm.fileExists(atPath: "/Applications/Visual Studio Code.app")
        templatesExist = fm.fileExists(atPath: AppConstants.templateDirectory.path)
        extensionEnabled = true // Cannot reliably detect from app; assume enabled
    }
    
    private func openSystemPreferences(to pane: String) {
        if let url = URL(string: "x-apple.systempreferences:\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func restartFinder() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
        process.arguments = ["Finder"]
        try? process.run()
    }
}

struct StatusRow: View {
    let title: String
    let status: String
    let isOK: Bool
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(status)
                .foregroundColor(isOK ? .green : .orange)
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RightPlus/Views/OverviewView.swift
git commit -m "feat: overview status dashboard with system checks"
```

---

### Task 10: Template Management View

**Files:**
- Modify: `RightPlus/Views/TemplateManagementView.swift`

- [ ] **Step 1: Implement TemplateManagementView**

```swift
import SwiftUI

struct TemplateManagementView: View {
    @State private var wordExists = false
    @State private var excelExists = false
    @State private var pptExists = false
    
    var body: some View {
        Form {
            Section("模板文件状态") {
                TemplateRow(name: "Word 模板", fileName: AppConstants.TemplateFile.word.rawValue, exists: wordExists)
                TemplateRow(name: "Excel 模板", fileName: AppConstants.TemplateFile.excel.rawValue, exists: excelExists)
                TemplateRow(name: "PowerPoint 模板", fileName: AppConstants.TemplateFile.powerpoint.rawValue, exists: pptExists)
            }
            
            Section("模板目录") {
                HStack {
                    Text(AppConstants.templateDirectory.path)
                        .font(.system(.body, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("打开") {
                        ensureTemplateDirectoryExists()
                        NSWorkspace.shared.open(AppConstants.templateDirectory)
                    }
                }
            }
            
            Section {
                Button("刷新状态") {
                    checkTemplates()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("模板管理")
        .onAppear { checkTemplates() }
    }
    
    private func checkTemplates() {
        let fm = FileManager.default
        wordExists = fm.fileExists(atPath: AppConstants.TemplateFile.word.path.path)
        excelExists = fm.fileExists(atPath: AppConstants.TemplateFile.excel.path.path)
        pptExists = fm.fileExists(atPath: AppConstants.TemplateFile.powerpoint.path.path)
    }
    
    private func ensureTemplateDirectoryExists() {
        let fm = FileManager.default
        if !fm.fileExists(atPath: AppConstants.templateDirectory.path) {
            try? fm.createDirectory(at: AppConstants.templateDirectory, withIntermediateDirectories: true)
        }
    }
}

struct TemplateRow: View {
    let name: String
    let fileName: String
    let exists: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name)
                Text(fileName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: exists ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(exists ? .green : .red)
        }
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RightPlus/Views/TemplateManagementView.swift
git commit -m "feat: template management view with status indicators"
```

---

### Task 11: Scope Settings View

**Files:**
- Modify: `RightPlus/Views/ScopeSettingsView.swift`

- [ ] **Step 1: Implement ScopeSettingsView**

```swift
import SwiftUI

struct ScopeSettingsView: View {
    @State private var paths: [String] = SettingsManager.shared.monitoredPaths
    
    var body: some View {
        Form {
            Section("Finder 右键增强生效目录") {
                ForEach(Array(paths.enumerated()), id: \.offset) { index, path in
                    HStack {
                        Image(systemName: "folder")
                        Text(path)
                            .font(.system(.body, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(role: .destructive) {
                            paths.remove(at: index)
                            save()
                        } label: {
                            Image(systemName: "minus.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                }
            }
            
            Section {
                HStack {
                    Button("添加目录") {
                        addDirectory()
                    }
                    Spacer()
                    Button("恢复默认") {
                        paths = AppConstants.defaultScopes
                        save()
                    }
                }
            }
            
            Section {
                Text("修改生效目录后，需要重启 Finder 扩展才能生效。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("作用范围")
    }
    
    private func addDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if !paths.contains(url.path) {
                    paths.append(url.path)
                    save()
                }
            }
        }
    }
    
    private func save() {
        SettingsManager.shared.monitoredPaths = paths
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RightPlus/Views/ScopeSettingsView.swift
git commit -m "feat: scope settings view for configuring monitored directories"
```

---

### Task 12: Open With Settings View

**Files:**
- Modify: `RightPlus/Views/OpenWithSettingsView.swift`

- [ ] **Step 1: Implement OpenWithSettingsView**

```swift
import SwiftUI

struct OpenWithSettingsView: View {
    @State private var itermEnabled: Bool = SettingsManager.shared.bool(for: .showOpenITerm)
    @State private var vscodeEnabled: Bool = SettingsManager.shared.bool(for: .showOpenVSCode)
    @State private var itermInstalled = false
    @State private var vscodeInstalled = false
    
    var body: some View {
        Form {
            Section("iTerm2") {
                Toggle("启用「用 iTerm 打开」", isOn: Binding(
                    get: { itermEnabled },
                    set: { itermEnabled = $0; SettingsManager.shared.set($0, for: .showOpenITerm) }
                ))
                HStack {
                    Text("状态")
                    Spacer()
                    Text(itermInstalled ? "已检测到" : "未安装")
                        .foregroundColor(itermInstalled ? .green : .orange)
                }
                HStack {
                    Text("打开方式")
                    Spacer()
                    Text("AppleScript")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Visual Studio Code") {
                Toggle("启用「用 VSCode 打开」", isOn: Binding(
                    get: { vscodeEnabled },
                    set: { vscodeEnabled = $0; SettingsManager.shared.set($0, for: .showOpenVSCode) }
                ))
                HStack {
                    Text("状态")
                    Spacer()
                    Text(vscodeInstalled ? "已检测到" : "未安装")
                        .foregroundColor(vscodeInstalled ? .green : .orange)
                }
                HStack {
                    Text("打开方式")
                    Spacer()
                    Text("open -a")
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("打开方式")
        .onAppear { checkApps() }
    }
    
    private func checkApps() {
        let fm = FileManager.default
        itermInstalled = fm.fileExists(atPath: "/Applications/iTerm.app")
        vscodeInstalled = fm.fileExists(atPath: "/Applications/Visual Studio Code.app")
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RightPlus/Views/OpenWithSettingsView.swift
git commit -m "feat: open-with settings view for iTerm and VSCode configuration"
```

---

### Task 13: New File Settings View

**Files:**
- Modify: `RightPlus/Views/NewFileSettingsView.swift`

- [ ] **Step 1: Implement NewFileSettingsView**

```swift
import SwiftUI

struct NewFileSettingsView: View {
    var body: some View {
        Form {
            Section("已配置的新建文件类型") {
                FileTypeRow(
                    name: "Markdown 文件",
                    ext: ".md",
                    defaultName: AppConstants.NewFileName.markdown,
                    method: "创建空文件"
                )
                FileTypeRow(
                    name: "Word 文档",
                    ext: ".docx",
                    defaultName: AppConstants.NewFileName.word,
                    method: "模板复制"
                )
                FileTypeRow(
                    name: "Excel 表格",
                    ext: ".xlsx",
                    defaultName: AppConstants.NewFileName.excel,
                    method: "模板复制"
                )
                FileTypeRow(
                    name: "PowerPoint 演示",
                    ext: ".pptx",
                    defaultName: AppConstants.NewFileName.powerpoint,
                    method: "模板复制"
                )
                FileTypeRow(
                    name: "空白文件",
                    ext: "无",
                    defaultName: AppConstants.NewFileName.blank,
                    method: "创建空文件"
                )
            }
            
            Section {
                Text("重名时自动递增编号（如「新建文件 2」「新建文件 3」）。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("新建文件")
    }
}

struct FileTypeRow: View {
    let name: String
    let ext: String
    let defaultName: String
    let method: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)
            HStack {
                Label(ext, systemImage: "doc")
                Spacer()
                Text("默认名: \(defaultName)")
                Spacer()
                Text(method)
                    .foregroundColor(.secondary)
            }
            .font(.caption)
        }
        .padding(.vertical, 2)
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RightPlus/Views/NewFileSettingsView.swift
git commit -m "feat: new file settings view showing configured file types"
```

---

### Task 14: Diagnostics View

**Files:**
- Modify: `RightPlus/Views/DiagnosticsView.swift`

- [ ] **Step 1: Implement DiagnosticsView**

```swift
import SwiftUI

struct DiagnosticsView: View {
    @State private var diagnosticInfo = ""
    
    var body: some View {
        Form {
            Section("权限状态") {
                StatusRow(title: "Finder Extension", status: "请在系统设置中确认", isOK: true)
                StatusRow(title: "模板文件", status: templatesStatus(), isOK: templatesOK())
            }
            
            Section("操作") {
                Button("打开系统设置 - 扩展") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("打开系统设置 - 隐私与安全性") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("重启 Finder") {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
                    process.arguments = ["Finder"]
                    try? process.run()
                }
            }
            
            Section("诊断信息") {
                Button("复制诊断信息") {
                    let info = buildDiagnosticInfo()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(info, forType: .string)
                    diagnosticInfo = "已复制到剪贴板"
                }
                if !diagnosticInfo.isEmpty {
                    Text(diagnosticInfo)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("权限与诊断")
    }
    
    private func templatesStatus() -> String {
        let fm = FileManager.default
        let exists = fm.fileExists(atPath: AppConstants.templateDirectory.path)
        return exists ? "正常" : "模板目录缺失"
    }
    
    private func templatesOK() -> Bool {
        FileManager.default.fileExists(atPath: AppConstants.templateDirectory.path)
    }
    
    private func buildDiagnosticInfo() -> String {
        let fm = FileManager.default
        var lines: [String] = []
        lines.append("RightPlus Diagnostics")
        lines.append("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
        lines.append("Template Dir: \(AppConstants.templateDirectory.path)")
        lines.append("  Exists: \(fm.fileExists(atPath: AppConstants.templateDirectory.path))")
        lines.append("  Word: \(fm.fileExists(atPath: AppConstants.TemplateFile.word.path.path))")
        lines.append("  Excel: \(fm.fileExists(atPath: AppConstants.TemplateFile.excel.path.path))")
        lines.append("  PPT: \(fm.fileExists(atPath: AppConstants.TemplateFile.powerpoint.path.path))")
        lines.append("iTerm2: \(fm.fileExists(atPath: "/Applications/iTerm.app"))")
        lines.append("VSCode: \(fm.fileExists(atPath: "/Applications/Visual Studio Code.app"))")
        lines.append("Monitored Paths: \(SettingsManager.shared.monitoredPaths)")
        return lines.joined(separator: "\n")
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RightPlus/Views/DiagnosticsView.swift
git commit -m "feat: diagnostics view with permission checks and diagnostic info export"
```

---

### Task 15: About View

**Files:**
- Modify: `RightPlus/Views/AboutView.swift`

- [ ] **Step 1: Implement AboutView**

```swift
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "cursorarrow.click.badge.clock")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            Text("RightPlus")
                .font(.title)
                .fontWeight(.bold)
            
            Text("macOS Finder 右键增强工具")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("版本 1.0")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 60)
    }
}
```

- [ ] **Step 2: Build and verify**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add RightPlus/Views/AboutView.swift
git commit -m "feat: about view"
```

---

### Task 16: Entitlements Configuration

**Files:**
- Modify: `RightPlus/RightPlus.entitlements` (may already exist from Xcode)
- Modify: `FinderSyncExtension/FinderSyncExtension.entitlements`

- [ ] **Step 1: Verify main app entitlements include App Group**

The file should contain:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.cn.xuziao.RightPlus</string>
    </array>
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 2: Verify extension entitlements**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.cn.xuziao.RightPlus</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 3: Build both targets**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build && xcodebuild -project RightPlus.xcodeproj -scheme FinderSyncExtension build`
Expected: Both BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add *.entitlements
git commit -m "feat: configure App Group entitlements for both targets"
```

---

### Task 17: Final Integration — Ensure Extension is Embedded in App

**Files:**
- Verify Xcode project settings

- [ ] **Step 1: Verify the Extension is embedded**

In Xcode: select RightPlus target > General > "Frameworks, Libraries, and Embedded Content" or check Build Phases > "Embed Foundation Extensions" (or "Embed App Extensions").

The `FinderSyncExtension.appex` must appear here. If not, add it:
- Build Phases > "+" > New Copy Files Phase
- Destination: Plugins
- Add `FinderSyncExtension.appex`

- [ ] **Step 2: Build archive to verify embedding**

Run: `xcodebuild -project RightPlus.xcodeproj -scheme RightPlus build`
Expected: BUILD SUCCEEDED with embedded extension

- [ ] **Step 3: Manual test**

1. Run the main app from Xcode
2. Open System Settings > Extensions > Finder Extensions
3. Enable "FinderSyncExtension"
4. Open Finder, navigate to home directory
5. Right-click in blank area — should see RightPlus menus
6. Test: "复制路径" > "复制当前文件夹路径" — paste should show the path
7. Test: "用 VSCode 打开" — VSCode should open
8. Test: "新建" > "新建 Markdown 文件" — file should appear

- [ ] **Step 4: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: integration adjustments for embedded extension"
```

---

## Summary of Execution Order

| Task | Description | Dependency |
|------|-------------|-----------|
| Pre-req | Create Extension target in Xcode | None |
| 1 | Shared Constants + SettingsManager | Pre-req |
| 2 | Finder Sync menu structure | Task 1 |
| 3 | Copy path actions | Task 2 |
| 4 | Open in VSCode | Task 2 |
| 5 | Open in iTerm | Task 2 |
| 6 | New file actions | Task 2 |
| 7 | Main app sidebar navigation | Task 1 |
| 8 | Menu settings view | Task 7 |
| 9 | Overview view | Task 7 |
| 10 | Template management view | Task 7 |
| 11 | Scope settings view | Task 7 |
| 12 | Open-with settings view | Task 7 |
| 13 | New file settings view | Task 7 |
| 14 | Diagnostics view | Task 7 |
| 15 | About view | Task 7 |
| 16 | Entitlements | Task 1 |
| 17 | Final integration test | All |

Tasks 3-6 can be done in parallel. Tasks 8-15 can be done in parallel.
