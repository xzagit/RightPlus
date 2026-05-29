import Foundation

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

        let lowerName = appName.lowercased()

        if lowerName.contains("iterm") {
            openITerm(at: dirPath)
        } else if lowerName.contains("terminal") {
            openTerminalApp(at: dirPath)
        } else {
            openGeneric(at: dirPath, appName: appName)
        }
    }

    private static func openITerm(at path: String) {
        let escapedPath = path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "iTerm"
            activate
            create window with default profile command "/bin/bash -c 'cd \\"\(escapedPath)\\" && exec $SHELL'"
        end tell
        """
        runAppleScript(script)
    }

    private static func openTerminalApp(at path: String) {
        let escapedPath = path.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "Terminal"
            activate
            do script "cd \\"\(escapedPath)\\""
        end tell
        """
        runAppleScript(script)
    }

    private static func openGeneric(at path: String, appName: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appName, path]
        try? process.run()
    }

    private static func runAppleScript(_ source: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", source]
        do {
            try process.run()
            rpLog("OpenTerminalAction: AppleScript launched")
        } catch {
            rpLog("OpenTerminalAction: AppleScript failed: \(error)")
        }
    }
}
