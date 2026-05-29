import SwiftUI

struct DiagnosticsView: View {
    @State private var diagnosticInfo = ""

    var body: some View {
        Form {
            Section("权限状态") {
                StatusRow(title: "Finder Extension", status: "请在系统设置中确认", isOK: true)
            }

            Section("操作") {
                Button("打开系统设置 - 扩展") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("打开系统设置 - 隐私与安全性") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("重启 Finder") {
                    restartFinder()
                }
            }

            Section("诊断信息") {
                Button("复制诊断信息") {
                    let info = buildDiagnosticInfo()
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(info, forType: .string)
                    diagnosticInfo = "已复制到剪贴板"
                }
                if !diagnosticInfo.isEmpty {
                    Text(diagnosticInfo)
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("权限与诊断")
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

    private func buildDiagnosticInfo() -> String {
        let fm = FileManager.default
        var lines: [String] = []
        lines.append("RightPlus Diagnostics")
        lines.append("macOS \(ProcessInfo.processInfo.operatingSystemVersionString)")
        lines.append("Terminal: \(SettingsManager.shared.terminalAppName)")
        lines.append("Editor: \(SettingsManager.shared.editorAppName)")
        lines.append("iTerm2 installed: \(fm.fileExists(atPath: "/Applications/iTerm.app"))")
        lines.append("VSCode installed: \(fm.fileExists(atPath: "/Applications/Visual Studio Code.app"))")
        return lines.joined(separator: "\n")
    }
}
