import Foundation

enum OpenEditorAction {
    static func open(path: String, appName: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appName, path]
        try? process.run()
    }
}
