import Foundation
import AppKit

enum OpenTerminalAction {
    static func open(path: String, appName: String) {
        rpLog("OpenTerminalAction: path=\(path), appName=\(appName)")

        let dirPath: String
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
            dirPath = path
        } else {
            dirPath = (path as NSString).deletingLastPathComponent
        }

        let folderURL = URL(fileURLWithPath: dirPath, isDirectory: true)

        let appPaths = [
            "/Applications/\(appName).app",
            "/Applications/Utilities/\(appName).app",
            "/System/Applications/Utilities/\(appName).app",
        ]

        guard let appPath = appPaths.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
            rpLog("OpenTerminalAction: app not found: \(appName)")
            return
        }

        let appURL = URL(fileURLWithPath: appPath)
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        NSWorkspace.shared.open([folderURL], withApplicationAt: appURL, configuration: config) { _, error in
            if let error = error {
                rpLog("OpenTerminalAction: NSWorkspace error: \(error)")
            } else {
                rpLog("OpenTerminalAction: success")
            }
        }
    }
}
