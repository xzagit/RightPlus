import Cocoa
import FinderSync

func rpLog(_ message: String) {
    let logFile = "/tmp/RightPlus.log"
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let line = "[\(timestamp)] \(message)\n"
    if let handle = FileHandle(forWritingAtPath: logFile) {
        handle.seekToEndOfFile()
        handle.write(line.data(using: .utf8) ?? Data())
        handle.closeFile()
    } else {
        FileManager.default.createFile(atPath: logFile, contents: line.data(using: .utf8))
    }
}

class FinderSync: FIFinderSync {

    private let settings = SettingsManager.shared

    override init() {
        super.init()
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        rpLog("init called")
        rpLog("realHome = \(AppConstants.realHomeDirectory.path)")
        rpLog("appSupportDir = \(AppConstants.appSupportDirectory.path)")
        let settingsPath = AppConstants.appSupportDirectory.appendingPathComponent("settings.plist").path
        rpLog("settings file exists = \(FileManager.default.fileExists(atPath: settingsPath))")
        rpLog("showNewFileMenu = \(settings.bool(for: .showNewFileMenu))")
        rpLog("showNewPowerPoint = \(settings.bool(for: .showNewPowerPoint))")
        rpLog("showOpenTerminal = \(settings.bool(for: .showOpenTerminal))")
        rpLog("terminalAppName = \(settings.terminalAppName)")
    }

    // MARK: - Menu Building

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        settings.reload()
        rpLog("menu() called: showNewFileMenu=\(settings.bool(for: .showNewFileMenu)), showNewPowerPoint=\(settings.bool(for: .showNewPowerPoint)), showCopyItemPath=\(settings.bool(for: .showCopyItemPath))")
        let menu = NSMenu(title: "RightPlus")

        switch menuKind {
        case .contextualMenuForContainer:
            addNewFileMenu(to: menu)
            addCopyPathMenu(to: menu, isContainer: true)
            addOpenActions(to: menu)

        case .contextualMenuForItems:
            let items = FIFinderSyncController.default().selectedItemURLs() ?? []
            let isSingleFolder = items.count == 1 && isDirectory(items[0])

            addNewFileMenu(to: menu)
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

        let customTemplates = TemplateStore.loadCustom()
        rpLog("addNewFileMenu: customTemplates count=\(customTemplates.count), storeURL=\(TemplateStore.debugStoreURL)")
        let enabledCustomTemplates = customTemplates.enumerated().filter { (_, t) in
            settings.isCustomTemplateEnabled(fileName: t.fileName)
        }
        if !enabledCustomTemplates.isEmpty {
            if !newMenu.items.isEmpty {
                newMenu.addItem(NSMenuItem.separator())
            }
            for (index, template) in enabledCustomTemplates {
                let item = NSMenuItem(title: template.displayName, action: #selector(newCustomFile(_:)), keyEquivalent: "")
                item.target = self
                item.tag = index
                newMenu.addItem(item)
            }
        }

        newMenu.addItem(withTitle: "新建文件夹", action: #selector(newFolder(_:)), keyEquivalent: "")

        menu.addItem(newItem)
    }

    private func addCopyPathMenu(to menu: NSMenu, isContainer: Bool) {
        let showItem = settings.bool(for: .showCopyItemPath)
        let showParent = settings.bool(for: .showCopyParentPath)

        guard showItem || showParent else { return }

        if isContainer {
            if showItem && showParent {
                let copyMenu = NSMenu(title: "复制路径")
                let copyItem = NSMenuItem(title: "复制路径", action: nil, keyEquivalent: "")
                copyItem.submenu = copyMenu
                copyMenu.addItem(withTitle: "复制当前文件夹路径", action: #selector(copyCurrentFolderPath(_:)), keyEquivalent: "")
                copyMenu.addItem(withTitle: "复制所在目录路径", action: #selector(copyParentPath(_:)), keyEquivalent: "")
                menu.addItem(copyItem)
            } else if showItem {
                menu.addItem(withTitle: "复制当前文件夹路径", action: #selector(copyCurrentFolderPath(_:)), keyEquivalent: "")
            } else {
                menu.addItem(withTitle: "复制所在目录路径", action: #selector(copyParentPath(_:)), keyEquivalent: "")
            }
        } else {
            let items = FIFinderSyncController.default().selectedItemURLs() ?? []
            let isSingleFolder = items.count == 1 && isDirectory(items[0])

            let title1 = isSingleFolder ? "复制文件夹路径" : "复制文件路径"
            let title2 = isSingleFolder ? "复制父目录路径" : "复制所在文件夹路径"

            if showItem && showParent {
                let copyMenu = NSMenu(title: "复制路径")
                let copyItem = NSMenuItem(title: "复制路径", action: nil, keyEquivalent: "")
                copyItem.submenu = copyMenu
                copyMenu.addItem(withTitle: title1, action: #selector(copySelectedItemPath(_:)), keyEquivalent: "")
                copyMenu.addItem(withTitle: title2, action: #selector(copySelectedParentPath(_:)), keyEquivalent: "")
                menu.addItem(copyItem)
            } else if showItem {
                menu.addItem(withTitle: title1, action: #selector(copySelectedItemPath(_:)), keyEquivalent: "")
            } else {
                menu.addItem(withTitle: title2, action: #selector(copySelectedParentPath(_:)), keyEquivalent: "")
            }
        }
    }

    private func addOpenActions(to menu: NSMenu) {
        if settings.bool(for: .showOpenTerminal) {
            let name = settings.terminalAppName
            menu.addItem(withTitle: "用 \(name) 打开", action: #selector(openInTerminal(_:)), keyEquivalent: "")
        }
        if settings.bool(for: .showOpenEditor) {
            let name = settings.editorAppName
            menu.addItem(withTitle: "用 \(name) 打开", action: #selector(openInEditor(_:)), keyEquivalent: "")
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

    // MARK: - Copy Path Actions

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

    // MARK: - Open Actions

    @objc func openInTerminal(_ sender: Any?) {
        let path: String
        if let items = FIFinderSyncController.default().selectedItemURLs(), let first = items.first {
            path = first.path
        } else if let target = targetDirectory() {
            path = target.path
        } else {
            return
        }
        let appName = settings.terminalAppName
        OpenTerminalAction.open(path: path, appName: appName)
    }

    @objc func openInEditor(_ sender: Any?) {
        let path: String
        if let items = FIFinderSyncController.default().selectedItemURLs(), let first = items.first {
            path = first.path
        } else if let target = targetDirectory() {
            path = target.path
        } else {
            return
        }
        let appName = settings.editorAppName
        OpenEditorAction.open(path: path, appName: appName)
    }

    // MARK: - New File Actions

    private func newFileDirectory() -> URL? {
        if let items = FIFinderSyncController.default().selectedItemURLs(), let first = items.first {
            if isDirectory(first) {
                return first
            }
        }
        return targetDirectory()
    }

    @objc func newMarkdownFile(_ sender: Any?) {
        guard let dir = newFileDirectory() else { return }
        NewFileAction.createFile(type: .markdown, in: dir)
    }

    @objc func newWordFile(_ sender: Any?) {
        guard let dir = newFileDirectory() else { return }
        NewFileAction.createFile(type: .word, in: dir)
    }

    @objc func newExcelFile(_ sender: Any?) {
        guard let dir = newFileDirectory() else { return }
        NewFileAction.createFile(type: .excel, in: dir)
    }

    @objc func newPowerPointFile(_ sender: Any?) {
        guard let dir = newFileDirectory() else { return }
        NewFileAction.createFile(type: .powerpoint, in: dir)
    }

    @objc func newBlankFile(_ sender: Any?) {
        guard let dir = newFileDirectory() else { return }
        NewFileAction.createFile(type: .blank, in: dir)
    }

    @objc func newFolder(_ sender: Any?) {
        guard let dir = newFileDirectory() else { return }
        NewFileAction.createFile(type: .folder, in: dir)
    }

    @objc func newCustomFile(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else { return }
        let customTemplates = TemplateStore.loadCustom()
        guard menuItem.tag >= 0 && menuItem.tag < customTemplates.count else { return }
        guard let dir = newFileDirectory() else { return }
        let template = customTemplates[menuItem.tag]
        NewFileAction.createFile(type: .custom(template), in: dir)
    }
}
