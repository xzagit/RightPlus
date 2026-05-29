import Foundation

final class SettingsManager: @unchecked Sendable {
    static let shared = SettingsManager()

    private let fileURL: URL
    private var cache: [String: Any] = [:]

    private let defaults: [String: Any] = [
        Key.showCopyItemPath.rawValue: true,
        Key.showCopyParentPath.rawValue: true,
        Key.showOpenTerminal.rawValue: true,
        Key.showOpenEditor.rawValue: true,
        Key.terminalAppName.rawValue: "iTerm",
        Key.editorAppName.rawValue: "Visual Studio Code",
        Key.showNewFileMenu.rawValue: true,
        Key.showNewMarkdown.rawValue: true,
        Key.showNewWord.rawValue: true,
        Key.showNewExcel.rawValue: true,
        Key.showNewPowerPoint.rawValue: true,
        Key.showNewBlankFile.rawValue: true,
    ]

    enum Key: String {
        case showCopyItemPath = "show_copy_item_path"
        case showCopyParentPath = "show_copy_parent_path"
        case showOpenTerminal = "show_open_terminal"
        case showOpenEditor = "show_open_editor"
        case terminalAppName = "terminal_app_name"
        case editorAppName = "editor_app_name"
        case showNewFileMenu = "show_new_file_menu"
        case showNewMarkdown = "show_new_markdown"
        case showNewWord = "show_new_word"
        case showNewExcel = "show_new_excel"
        case showNewPowerPoint = "show_new_powerpoint"
        case showNewBlankFile = "show_new_blank_file"
    }

    private init() {
        fileURL = AppConstants.appSupportDirectory.appendingPathComponent("settings.plist")
        reload()
    }

    func reload() {
        guard let data = try? Data(contentsOf: fileURL),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            cache = defaults
            return
        }
        cache = dict
    }

    func bool(for key: Key) -> Bool {
        cache[key.rawValue] as? Bool ?? (defaults[key.rawValue] as? Bool ?? true)
    }

    func string(for key: Key) -> String? {
        cache[key.rawValue] as? String ?? (defaults[key.rawValue] as? String)
    }

    func isCustomTemplateEnabled(fileName: String) -> Bool {
        let key = "custom_template_enabled_\(fileName)"
        return cache[key] as? Bool ?? true
    }

    var terminalAppName: String {
        string(for: .terminalAppName) ?? "iTerm"
    }

    var editorAppName: String {
        string(for: .editorAppName) ?? "Visual Studio Code"
    }
}
