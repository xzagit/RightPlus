import SwiftUI

struct MenuSettingsView: View {
    @State private var showCopyItemPath: Bool = SettingsManager.shared.bool(for: .showCopyItemPath)
    @State private var showCopyParentPath: Bool = SettingsManager.shared.bool(for: .showCopyParentPath)
    @State private var showOpenTerminal: Bool = SettingsManager.shared.bool(for: .showOpenTerminal)
    @State private var showOpenEditor: Bool = SettingsManager.shared.bool(for: .showOpenEditor)
    @State private var showNewFileMenu: Bool = SettingsManager.shared.bool(for: .showNewFileMenu)
    @State private var showNewMarkdown: Bool = SettingsManager.shared.bool(for: .showNewMarkdown)
    @State private var showNewWord: Bool = SettingsManager.shared.bool(for: .showNewWord)
    @State private var showNewExcel: Bool = SettingsManager.shared.bool(for: .showNewExcel)
    @State private var showNewPowerPoint: Bool = SettingsManager.shared.bool(for: .showNewPowerPoint)
    @State private var showNewBlankFile: Bool = SettingsManager.shared.bool(for: .showNewBlankFile)
    @State private var customTemplates: [TemplateConfig] = TemplateStore.loadCustom()
    @State private var customTemplateStates: [String: Bool] = [:]

    var body: some View {
        Form {
            Section("复制路径") {
                Toggle("复制当前路径", isOn: binding(for: .showCopyItemPath, state: $showCopyItemPath))
                Toggle("复制父目录路径", isOn: binding(for: .showCopyParentPath, state: $showCopyParentPath))
                if showCopyItemPath && showCopyParentPath {
                    Text("两项都开启时，将以二级菜单形式显示")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if showCopyItemPath || showCopyParentPath {
                    Text("仅开启一项时，将直接显示为一级菜单")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("打开方式") {
                Toggle("用终端打开", isOn: binding(for: .showOpenTerminal, state: $showOpenTerminal))
                Toggle("用编辑器打开", isOn: binding(for: .showOpenEditor, state: $showOpenEditor))
                Text("可在「打开方式」页面自定义应用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("新建文件") {
                Toggle("显示新建菜单", isOn: binding(for: .showNewFileMenu, state: $showNewFileMenu))
                if showNewFileMenu {
                    Toggle("新建 Markdown 文件", isOn: binding(for: .showNewMarkdown, state: $showNewMarkdown))
                        .padding(.leading, 20)
                    Toggle("新建 Word 文档", isOn: binding(for: .showNewWord, state: $showNewWord))
                        .padding(.leading, 20)
                    Toggle("新建 Excel 表格", isOn: binding(for: .showNewExcel, state: $showNewExcel))
                        .padding(.leading, 20)
                    Toggle("新建 PowerPoint 演示", isOn: binding(for: .showNewPowerPoint, state: $showNewPowerPoint))
                        .padding(.leading, 20)
                    Toggle("新建空白文件", isOn: binding(for: .showNewBlankFile, state: $showNewBlankFile))
                        .padding(.leading, 20)
                }
            }

            if showNewFileMenu && !customTemplates.isEmpty {
                Section("自定义模板") {
                    ForEach(customTemplates) { template in
                        Toggle(template.displayName, isOn: Binding(
                            get: { customTemplateStates[template.fileName] ?? true },
                            set: { newValue in
                                customTemplateStates[template.fileName] = newValue
                                SettingsManager.shared.setCustomTemplateEnabled(newValue, fileName: template.fileName)
                            }
                        ))
                        .padding(.leading, 20)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("右键菜单")
        .onAppear {
            customTemplates = TemplateStore.loadCustom()
            for t in customTemplates {
                customTemplateStates[t.fileName] = SettingsManager.shared.isCustomTemplateEnabled(fileName: t.fileName)
            }
        }
    }

    private func binding(for key: SettingsManager.Key, state: Binding<Bool>) -> Binding<Bool> {
        Binding(
            get: { state.wrappedValue },
            set: { newValue in
                state.wrappedValue = newValue
                SettingsManager.shared.set(newValue, for: key)
            }
        )
    }
}
