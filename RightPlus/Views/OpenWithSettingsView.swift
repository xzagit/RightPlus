import SwiftUI
import UniformTypeIdentifiers

struct OpenWithSettingsView: View {
    @State private var terminalEnabled: Bool = SettingsManager.shared.bool(for: .showOpenTerminal)
    @State private var editorEnabled: Bool = SettingsManager.shared.bool(for: .showOpenEditor)
    @State private var terminalAppName: String = SettingsManager.shared.terminalAppName
    @State private var editorAppName: String = SettingsManager.shared.editorAppName

    private let terminalApps = ["iTerm", "Terminal", "Warp", "Alacritty", "Kitty", "Hyper"]
    private let editorApps = ["Visual Studio Code", "Cursor", "PyCharm", "IntelliJ IDEA", "WebStorm", "Sublime Text", "Zed", "Nova"]

    var body: some View {
        Form {
            Section("终端应用") {
                Toggle("启用「用终端打开」", isOn: Binding(
                    get: { terminalEnabled },
                    set: { terminalEnabled = $0; SettingsManager.shared.set($0, for: .showOpenTerminal) }
                ))
                if terminalEnabled {
                    Picker("选择应用", selection: Binding(
                        get: { terminalApps.contains(terminalAppName) ? terminalAppName : "__other__" },
                        set: { newValue in
                            if newValue == "__other__" { return }
                            terminalAppName = newValue
                            SettingsManager.shared.terminalAppName = newValue
                        }
                    )) {
                        ForEach(terminalApps, id: \.self) { app in
                            Text(app).tag(app)
                        }
                        Text("其他: \(terminalApps.contains(terminalAppName) ? "" : terminalAppName)")
                            .tag("__other__")
                    }

                    Button("从应用程序文件夹选择…") {
                        if let name = pickApp() {
                            terminalAppName = name
                            SettingsManager.shared.terminalAppName = name
                        }
                    }

                    AppStatusRow(appName: terminalAppName)
                }
            }

            Section("编辑器应用") {
                Toggle("启用「用编辑器打开」", isOn: Binding(
                    get: { editorEnabled },
                    set: { editorEnabled = $0; SettingsManager.shared.set($0, for: .showOpenEditor) }
                ))
                if editorEnabled {
                    Picker("选择应用", selection: Binding(
                        get: { editorApps.contains(editorAppName) ? editorAppName : "__other__" },
                        set: { newValue in
                            if newValue == "__other__" { return }
                            editorAppName = newValue
                            SettingsManager.shared.editorAppName = newValue
                        }
                    )) {
                        ForEach(editorApps, id: \.self) { app in
                            Text(app).tag(app)
                        }
                        Text("其他: \(editorApps.contains(editorAppName) ? "" : editorAppName)")
                            .tag("__other__")
                    }

                    Button("从应用程序文件夹选择…") {
                        if let name = pickApp() {
                            editorAppName = name
                            SettingsManager.shared.editorAppName = name
                        }
                    }

                    AppStatusRow(appName: editorAppName)
                }
            }

            Section {
                Text("右键菜单将显示为「用 XXX 打开」。\n终端类应用会自动 cd 到目标路径。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("打开方式")
    }

    private func pickApp() -> String? {
        let panel = NSOpenPanel()
        panel.title = "选择应用程序"
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return url.deletingPathExtension().lastPathComponent
    }
}

struct AppStatusRow: View {
    let appName: String

    var body: some View {
        HStack {
            Text("当前选择")
            Spacer()
            Text(appName)
                .fontWeight(.medium)
            if Self.isInstalled(appName) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
            }
        }
        .font(.caption)
    }

    static func isInstalled(_ appName: String) -> Bool {
        let paths = [
            "/Applications/\(appName).app",
            "/System/Applications/\(appName).app",
            "/System/Applications/Utilities/\(appName).app",
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }
}
