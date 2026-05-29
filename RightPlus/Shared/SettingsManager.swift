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
        Key.onboardingCompleted.rawValue: false,
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
        case onboardingCompleted = "onboarding_completed"
    }

    private init() {
        fileURL = AppConstants.appSupportDirectory.appendingPathComponent("settings.plist")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            cache = Self.readFile(at: fileURL) ?? [:]
        } else {
            cache = defaults
            writeFile()
        }
    }

    private static func readFile(at url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    }

    private func writeFile() {
        let data = try? PropertyListSerialization.data(fromPropertyList: cache, format: .xml, options: 0)
        try? data?.write(to: fileURL, options: .atomic)
    }

    func bool(for key: Key) -> Bool {
        cache[key.rawValue] as? Bool ?? (defaults[key.rawValue] as? Bool ?? true)
    }

    func set(_ value: Bool, for key: Key) {
        cache[key.rawValue] = value
        writeFile()
    }

    func string(for key: Key) -> String? {
        cache[key.rawValue] as? String ?? (defaults[key.rawValue] as? String)
    }

    func set(_ value: String, for key: Key) {
        cache[key.rawValue] = value
        writeFile()
    }

    func isCustomTemplateEnabled(fileName: String) -> Bool {
        let key = "custom_template_enabled_\(fileName)"
        return cache[key] as? Bool ?? true
    }

    func setCustomTemplateEnabled(_ enabled: Bool, fileName: String) {
        let key = "custom_template_enabled_\(fileName)"
        cache[key] = enabled
        writeFile()
    }

    var terminalAppName: String {
        get { string(for: .terminalAppName) ?? "iTerm" }
        set { set(newValue, for: .terminalAppName) }
    }

    var editorAppName: String {
        get { string(for: .editorAppName) ?? "Visual Studio Code" }
        set { set(newValue, for: .editorAppName) }
    }
}
