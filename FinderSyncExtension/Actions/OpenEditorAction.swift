import Foundation
import AppKit

enum OpenEditorAction {
    static func open(path: String, appName: String) {
        let fileURL = URL(fileURLWithPath: path)

        let appPaths = [
            "/Applications/\(appName).app",
            "/Applications/Utilities/\(appName).app",
            "/System/Applications/\(appName).app",
        ]

        guard let appPath = appPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            rpLog("OpenEditorAction: app not found: \(appName)")
            return
        }

        let appURL = URL(fileURLWithPath: appPath)
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: config) { _, error in
            if let error = error {
                rpLog("OpenEditorAction: NSWorkspace error: \(error)")
            }
        }
    }
}
