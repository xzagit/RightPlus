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
