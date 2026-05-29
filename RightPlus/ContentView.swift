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
    @State private var showExtensionBanner = false

    var body: some View {
        VStack(spacing: 0) {
            if showExtensionBanner {
                ExtensionBannerView {
                    showExtensionBanner = false
                }
            }

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
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .onAppear {
            if !SettingsManager.shared.bool(for: .onboardingCompleted) {
                showOnboarding = true
                showExtensionBanner = true
            }
        }
    }
}

struct ExtensionBannerView: View {
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)

            Text("请确保已在「系统设置 → 扩展 → 已添加的扩展」中启用 RightPlus 的 Finder 扩展")
                .font(.callout)

            Spacer()

            Button("打开系统设置") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.1))
    }
}
