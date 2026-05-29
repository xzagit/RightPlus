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

        let escapedPath = dirPath.replacingOccurrences(of: "'", with: "'\\''")

        let scriptContent = """
        #!/bin/bash
        cd '\(escapedPath)'
        exec $SHELL
        """

        let scriptFile = "/tmp/.RightPlus_open_terminal.command"
        try? scriptContent.write(toFile: scriptFile, atomically: true, encoding: .utf8)

        let chmod = Process()
        chmod.executableURL = URL(fileURLWithPath: "/bin/chmod")
        chmod.arguments = ["+x", scriptFile]
        try? chmod.run()
        chmod.waitUntilExit()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appName, scriptFile]
        do {
            try process.run()
            rpLog("OpenTerminalAction: launched \(appName)")
        } catch {
            rpLog("OpenTerminalAction: failed: \(error)")
        }
    }
}
