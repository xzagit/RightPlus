import Foundation

enum AppConstants {
    static let realHomeDirectory: URL = {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: dir))
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }()

    static let appSupportDirectory: URL = {
        let dir = realHomeDirectory.appendingPathComponent("Library/Application Support/RightPlus")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static let templateDirectory: URL = {
        let dir = appSupportDirectory.appendingPathComponent("Templates")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
}
