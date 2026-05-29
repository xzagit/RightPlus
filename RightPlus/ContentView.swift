import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case overview = "总览"
    case menuSettings = "右键菜单"
    case newFile = "新建文件"
    case openWith = "打开方式"
    case templates = "模板管理"
    case diagnostics = "权限与诊断"
    case about = "关于"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "house"
        case .menuSettings: return "contextualmenu.and.cursorarrow"
        case .newFile: return "doc.badge.plus"
        case .openWith: return "arrow.up.forward.app"
        case .templates: return "doc.on.doc"
        case .diagnostics: return "stethoscope"
        case .about: return "info.circle"
        }
    }
}

struct ContentView: View {
    @State private var selection: SidebarItem = .overview
    @State private var showOnboarding = false
    @State private var extensionEnabled = true

    var body: some View {
        Group {
            if extensionEnabled {
                NavigationSplitView {
                    List(SidebarItem.allCases, selection: $selection) { item in
                        Label(item.rawValue, systemImage: item.icon)
                            .tag(item)
                    }
                    .navigationSplitViewColumnWidth(min: 160, ideal: 180)
                } detail: {
                    switch selection {
                    case .overview:
                        OverviewView()
                    case .menuSettings:
                        MenuSettingsView()
                    case .newFile:
                        NewFileSettingsView()
                    case .openWith:
                        OpenWithSettingsView()
                    case .templates:
                        TemplateManagementView()
                    case .diagnostics:
                        DiagnosticsView()
                    case .about:
                        AboutView()
                    }
                }
            } else {
                ExtensionDisabledView {
                    checkExtensionStatus()
                }
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .onAppear {
            if !SettingsManager.shared.bool(for: .onboardingCompleted) {
                showOnboarding = true
            }
            checkExtensionStatus()
        }
    }

    private func checkExtensionStatus() {
        let extensionBundleID = "cn.xuziao.RightPlus.FinderSyncExtension"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pluginkit")
        process.arguments = ["-m", "-i", extensionBundleID]
        let pipe = Pipe()
        process.standardOutput = pipe
        try? process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        extensionEnabled = output.contains(extensionBundleID)
    }
}

struct ExtensionDisabledView: View {
    var onRecheck: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 56))
                .foregroundColor(.orange)

            Text("Finder 扩展未启用")
                .font(.title)
                .fontWeight(.bold)

            Text("RightPlus 需要 Finder 扩展才能工作。\n请在系统设置中启用扩展，然后点击下方「重新检测」。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)

            VStack(spacing: 12) {
                Button("打开系统设置 - 扩展") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("重新检测") {
                    onRecheck()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
