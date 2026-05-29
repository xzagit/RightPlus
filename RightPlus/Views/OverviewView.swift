import SwiftUI
import ServiceManagement

struct OverviewView: View {
    @State private var extensionEnabled = false
    @State private var itermInstalled = false
    @State private var vscodeInstalled = false
    @State private var launchAtLogin = false
    @State private var silentLaunch = false
    @State private var hideDockOnClose = true

    var body: some View {
        Form {
            Section("系统状态") {
                StatusRow(title: "Finder 扩展", status: extensionEnabled ? "已启用" : "未启用", isOK: extensionEnabled)
                StatusRow(title: "终端应用", status: terminalStatus(), isOK: itermInstalled)
                StatusRow(title: "编辑器", status: editorStatus(), isOK: vscodeInstalled)
                StatusRow(title: "模板文件", status: "已内置", isOK: true)
            }

            Section("启动设置") {
                Toggle("开机自动启动", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }

                Toggle("静默启动（不显示窗口）", isOn: $silentLaunch)
                    .onChange(of: silentLaunch) { _, newValue in
                        SettingsManager.shared.set(newValue, for: .silentLaunch)
                    }

                Toggle("关闭窗口后隐藏 Dock 图标", isOn: $hideDockOnClose)
                    .onChange(of: hideDockOnClose) { _, newValue in
                        SettingsManager.shared.set(newValue, for: .hideDockOnClose)
                    }
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
        .onAppear {
            checkStatus()
            launchAtLogin = SettingsManager.shared.bool(for: .launchAtLogin)
            silentLaunch = SettingsManager.shared.bool(for: .silentLaunch)
            hideDockOnClose = SettingsManager.shared.bool(for: .hideDockOnClose)
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        SettingsManager.shared.set(enabled, for: .launchAtLogin)
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLogin = !enabled
        }
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
