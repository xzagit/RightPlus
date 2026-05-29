import SwiftUI

struct OverviewView: View {
    @State private var extensionEnabled = false
    @State private var itermInstalled = false
    @State private var vscodeInstalled = false

    var body: some View {
        Form {
            Section("系统状态") {
                StatusRow(title: "Finder 扩展", status: extensionEnabled ? "已启用" : "未启用", isOK: extensionEnabled)
                StatusRow(title: "终端应用", status: terminalStatus(), isOK: itermInstalled)
                StatusRow(title: "编辑器", status: editorStatus(), isOK: vscodeInstalled)
                StatusRow(title: "模板文件", status: "已内置", isOK: true)
            }

            Section("快捷操作") {
                Button("打开系统扩展设置") {
                    openSystemPreferences(to: "com.apple.ExtensionsPreferences")
                }
                Button("重启 Finder") {
                    restartFinder()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("总览")
        .onAppear { checkStatus() }
    }

    private func terminalStatus() -> String {
        let name = SettingsManager.shared.terminalAppName
        return itermInstalled ? "\(name) 已检测到" : "\(name) 未安装"
    }

    private func editorStatus() -> String {
        let name = SettingsManager.shared.editorAppName
        return vscodeInstalled ? "\(name) 已检测到" : "\(name) 未安装"
    }

    private func checkStatus() {
        let terminalName = SettingsManager.shared.terminalAppName
        let editorName = SettingsManager.shared.editorAppName
        itermInstalled = isAppInstalled(terminalName)
        vscodeInstalled = isAppInstalled(editorName)
        extensionEnabled = true
    }

    private func isAppInstalled(_ appName: String) -> Bool {
        let paths = [
            "/Applications/\(appName).app",
            "/System/Applications/\(appName).app",
            "/System/Applications/Utilities/\(appName).app",
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    private func openSystemPreferences(to pane: String) {
        if let url = URL(string: "x-apple.systempreferences:\(pane)") {
            NSWorkspace.shared.open(url)
        }
    }

    private func restartFinder() {
        let script = """
        tell application "Finder"
            quit
        end tell
        delay 1
        tell application "Finder"
            activate
        end tell
        """
        guard let appleScript = NSAppleScript(source: script) else { return }
        var error: NSDictionary?
        appleScript.executeAndReturnError(&error)
    }
}

struct StatusRow: View {
    let title: String
    let status: String
    let isOK: Bool

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(status)
                .foregroundColor(isOK ? .green : .orange)
        }
    }
}
