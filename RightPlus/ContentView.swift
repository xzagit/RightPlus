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

    var body: some View {
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
}
